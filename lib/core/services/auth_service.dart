import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth changes
  Stream<User?> get user => _auth.authStateChanges();

  // Current User
  User? get currentUser => _auth.currentUser;

  // Create Partner Account by Admin
  Future<String?> createPartnerAccountByAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'PartnerCreator',
        options: Firebase.app().options,
      );

      UserCredential result = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
            email: email.toLowerCase().trim(),
            password: password,
          );

      if (result.user != null) {
        final uid = result.user!.uid;

        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email.toLowerCase().trim(),
          'name': name,
          'phone': phone,
          'role': 'partner',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await result.user!.updateDisplayName(name);

        return uid;
      }
      return null;
    } catch (e) {
      print("Error creating partner account: $e");
      rethrow;
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  // Create Worker Account by Admin (no logout for admin)
  Future<String?> createWorkerAccountByAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. Create a secondary Firebase App to avoid logging out the admin
      secondaryApp = await Firebase.initializeApp(
        name: 'WorkerCreator',
        options: Firebase.app().options,
      );

      // 2. Create user with secondary Auth
      UserCredential result = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
            email: email.toLowerCase().trim(),
            password: password,
          );

      if (result.user != null) {
        final uid = result.user!.uid;

        // 3. Save to Firestore (main app instance)
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email.toLowerCase().trim(),
          'name': name,
          'phone': phone,
          'role': 'worker',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. Update display name in Firebase Auth
        await result.user!.updateDisplayName(name);

        // 5. Link with worker profile if it exists
        final workersQuery = await _firestore
            .collection('workers')
            .where('phone', isEqualTo: phone) // Simple match first
            .get();

        if (workersQuery.docs.isNotEmpty) {
          await workersQuery.docs.first.reference.update({'userId': uid});
        }

        return uid;
      }
      return null;
    } catch (e) {
      print("Error creating worker account: $e");
      rethrow;
    } finally {
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
    }
  }

  // Sign Up (Refined)
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    String role = 'client',
  }) async {
    try {
      // Create user in Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // EXTRA: Auto-detect worker role if email matches special invited list
      String finalRole = role;
      if (finalRole == 'client') {
        final workerInvites = await _firestore
            .collection('workers')
            .where('invitedEmail', isEqualTo: email.toLowerCase().trim())
            .get();
        if (workerInvites.docs.isNotEmpty) {
          finalRole = 'worker';
        }
      }

      // Save extra details in Firestore
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'uid': result.user!.uid,
          'email': email.toLowerCase().trim(),
          'name': name,
          'phone': phone,
          'role': finalRole,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await result.user!.updateDisplayName(name);

        // Save FCM token immediately
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await _firestore.collection('users').doc(result.user!.uid).update({
              'fcmToken': fcmToken,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            // Also save to workers collection if worker
            if (finalRole == 'worker') {
              final workersQuery = await _firestore
                  .collection('workers')
                  .where('invitedEmail', isEqualTo: email.toLowerCase().trim())
                  .get();
              for (var doc in workersQuery.docs) {
                await doc.reference.update({
                  'userId': result.user!.uid,
                  'fcmToken': fcmToken,
                });
              }
            }

            // Also save to partners collection if partner
            if (finalRole == 'partner') {
              final partnersQuery = await _firestore
                  .collection('partners')
                  .where('userId', isEqualTo: result.user!.uid)
                  .get();
              for (var doc in partnersQuery.docs) {
                await doc.reference.update({'fcmToken': fcmToken});
              }
            }
          }
        } catch (e) {
          print('FCM token error: $e');
        }
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign In
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save FCM token after successful sign in
      if (result.user != null) {
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            // Update token in users collection
            await _firestore.collection('users').doc(result.user!.uid).update({
              'fcmToken': fcmToken,
              'lastLoginAt': FieldValue.serverTimestamp(),
            });

            // Also update token in workers collection if user is a worker
            final userDoc = await _firestore
                .collection('users')
                .doc(result.user!.uid)
                .get();
            if (userDoc.exists && userDoc.data()?['role'] == 'worker') {
              final workerQuery = await _firestore
                  .collection('workers')
                  .where('userId', isEqualTo: result.user!.uid)
                  .get();

              for (var doc in workerQuery.docs) {
                await doc.reference.update({'fcmToken': fcmToken});
              }
            }

            // Also update token in partners collection if user is a partner
            if (userDoc.exists && userDoc.data()?['role'] == 'partner') {
              final partnerQuery = await _firestore
                  .collection('partners')
                  .where('userId', isEqualTo: result.user!.uid)
                  .get();

              for (var doc in partnerQuery.docs) {
                await doc.reference.update({'fcmToken': fcmToken});
              }
            }

            print('✅ FCM token saved on sign in');
          }
        } catch (e) {
          print('FCM token error on sign in: $e');
          // Don't throw - allow sign in to succeed even if token save fails
        }
      }

      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Get User Role from Firestore (Single Fetch)
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get User Role Stream (Real-time)
  Stream<String?> getUserRoleStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['role'] as String?);
  }

  // Sign Out
  Future<void> signOut() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Delete token from users collection
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });

        // Also delete token from workers collection if user is a worker
        final workerQuery = await _firestore
            .collection('workers')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var doc in workerQuery.docs) {
          await doc.reference.update({'fcmToken': FieldValue.delete()});
        }

        // Also delete token from partners collection if user is a partner
        final partnerQuery = await _firestore
            .collection('partners')
            .where('userId', isEqualTo: user.uid)
            .get();

        for (var doc in partnerQuery.docs) {
          await doc.reference.update({'fcmToken': FieldValue.delete()});
        }

        print('✅ FCM tokens removed from user, worker, and partner profiles');
      } catch (e) {
        // Proceed even if delete fails (e.g. offline)
        print("Warning: Failed to delete fcmToken on logout: $e");
      }
    }
    await _auth.signOut();
  }
}
