import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init(void Function(String) onNavigate) async {
    if (_isInitialized) return;

    // 1. Request Permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Setup Local Notifications (Android)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          _handleNavigation(response.payload!, onNavigate);
        }
      },
    );

    // Create Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // 3. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              icon: android.smallIcon,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: message.data['type'], // Pass type as payload
        );
      }
    });

    // 4. Background/Terminated Tap Handler
    setupInteractedMessage(onNavigate);

    // 5. Token Management
    _fcm.onTokenRefresh.listen(_saveTokenToDatabase);

    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      if (kDebugMode) print("FCM Token Error: $e");
    }

    // 6. Auth State Listener (Crucial for auto-sync)
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        try {
          String? token = await _fcm.getToken();
          if (token != null) {
            if (kDebugMode)
              print("👤 User signed in, saving FCM token autosave...");
            await _saveTokenToDatabase(token);
          }
        } catch (e) {
          if (kDebugMode) print("Error getting token on auth change: $e");
        }
      }
    });

    _isInitialized = true;
  }

  Future<void> setupInteractedMessage(void Function(String) onNavigate) async {
    // 1. App killed -> Open
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage, onNavigate);
    }

    // 2. App background -> Open
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message, onNavigate);
    });
  }

  void _handleMessage(RemoteMessage message, void Function(String) onNavigate) {
    if (message.data.containsKey('type')) {
      _handleNavigation(message.data['type'], onNavigate);
    }
  }

  void _handleNavigation(String type, void Function(String) onNavigate) {
    print("🔔 Handling Navigation for Type: $type");

    switch (type) {
      // --- Worker Destinations ---
      case 'advance': // Admin offered advance
      case 'repayment': // Debt repaid
        // Worker Advance Tab is index 2
        onNavigate('/home?tab=2');
        break;

      case 'salary': // Salary paid -> Salary Tab (Index 1)
        onNavigate('/home?tab=0');
        break;

      // --- Admin Destinations ---
      case 'advance_response': // Worker accepted/rejected
      case 'advance_request': // (If implemented later)
        // Admin Advances are NOT in the bottom menu, so we use the direct route.
        // It opens as a full screen, but that's expected as it's not a main tab.
        onNavigate('/admin/advance');
        break;

      case 'payment_confirmation':
        onNavigate('/worker/payments');
        break;

      case 'attendance_checkin':
      case 'attendance_checkout':
        // Admin 'Workers' Tab is index 1
        onNavigate('/home?tab=1');
        break;

      case 'new_order':
        // Admin 'Orders' Tab is index 2
        onNavigate('/home?tab=2');
        break;

      case 'order_status_update':
        // Client orders tab (index 1)
        onNavigate('/home?tab=1');
        break;

      case 'stock_low':
        onNavigate('/admin/warehouse');
        break;

      default:
        print(
          "⚠️ Unknown Notification Type: $type. Staying on current screen.",
        );
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Save to 'users' (Global user profile)
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Sync to 'workers' collection (for Admin Notifications)
      // Retry logic: Registration might be linking userId concurrently. Give it a moment.
      var workerQuery = await _firestore
          .collection('workers')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (workerQuery.docs.isEmpty) {
        if (kDebugMode)
          print("No worker linked yet. Retrying in 3s for race condition...");
        await Future.delayed(const Duration(seconds: 3));
        workerQuery = await _firestore
            .collection('workers')
            .where('userId', isEqualTo: user.uid)
            .get();
      }

      if (workerQuery.docs.isNotEmpty) {
        // A user might have multiple worker profiles (rare, but handle loop)
        for (var doc in workerQuery.docs) {
          await doc.reference.update({'fcmToken': token});
        }
        if (kDebugMode) print("FCM Token synced into Worker Profile (Success)");
      } else {
        if (kDebugMode)
          print("FCM Token Saved to User, but no linked Worker found.");
      }

      if (kDebugMode) print("FCM Token Saved: $token");
    } catch (e) {
      if (kDebugMode) print("Error saving token: $e");
    }
  }
}
