import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/services/fcm_sender_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send notification to a specific user (or 'admin')
  Future<bool> sendNotification({
    required String receiverId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1. Save to In-App History
      await _firestore.collection('notifications').add({
        'receiverId': receiverId,
        'title': title,
        'body': body,
        'type': type,
        'createdAt': Timestamp.now(),
        'isRead': false,
        ...?data,
      });

      // 2. Send Push Notification (Bypass Cloud Functions via Direct API)
      String? targetUserId;
      print(
        "🔔 [DEBUG] SendNotification called for receiverId: $receiverId, type: $type",
      );

      if (receiverId == 'admin') {
        print("🔔 [DEBUG] Sending push to all Admins");
        final adminSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .get();

        if (adminSnapshot.docs.isEmpty) {
          print(
            "⚠️ [DEBUG] No admins found in 'users' collection with role='admin'",
          );
          return false;
        }

        bool atLeastOneSent = false;
        for (var doc in adminSnapshot.docs) {
          final adminToken = doc.data()['fcmToken'];
          if (adminToken != null) {
            print("🔔 [DEBUG] Sending to Admin: ${doc.id}");
            await FCMSenderService().sendNotification(
              fcmToken: adminToken,
              title: title,
              body: body,
              data: {
                'type': type,
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            );
            atLeastOneSent = true;
          }
        }
        return atLeastOneSent;
      } else {
        // Assume receiverId is a Worker ID (from Workers collection)
        print("🔔 [DEBUG] Fetching worker doc for ID: $receiverId");
        final workerDoc = await _firestore
            .collection('workers')
            .doc(receiverId)
            .get();

        if (workerDoc.exists) {
          targetUserId = workerDoc.data()?['userId']; // Linked Auth User ID
          print("🔔 [DEBUG] Found Worker doc. Linked UserId: $targetUserId");
        } else {
          // Maybe receiverId IS already a User ID (fallback)
          targetUserId = receiverId;
          print(
            "🔔 [DEBUG] Worker doc not found. Assuming receiverId is UserId: $targetUserId",
          );
        }
      }

      if (targetUserId != null) {
        print("🔔 [DEBUG] Fetching user doc for UserId: $targetUserId");
        final userDoc = await _firestore
            .collection('users')
            .doc(targetUserId)
            .get();

        if (!userDoc.exists) {
          print("❌ [DEBUG] User doc does not exist for $targetUserId");
          return false;
        }

        final fcmToken = userDoc.data()?['fcmToken'];
        print("🔔 [DEBUG] FCM Token found: ${fcmToken != null ? 'YES' : 'NO'}");

        if (fcmToken != null) {
          print("🚀 [DEBUG] Initiating send via FCMSenderService...");
          await FCMSenderService().sendNotification(
            fcmToken: fcmToken,
            title: title,
            body: body,
            data: {'type': type, 'click_action': 'FLUTTER_NOTIFICATION_CLICK'},
          );
          return true; // Success
        } else {
          print(
            "❌ [DEBUG] Cannot send push: FCM Token is NULL. Worker needs to login/re-open app.",
          );
          return false; // Token missing
        }
      } else {
        print("❌ [DEBUG] TargetUserId is NULL. Cannot resolve recipient.");
        return false;
      }
    } catch (e) {
      print("Error sending notification: $e");
      return false;
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print("Error marking all as read: $e");
    }
  }
}
