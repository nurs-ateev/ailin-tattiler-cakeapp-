import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/models/chat_model.dart';
import 'package:ailin_tattileri_app/core/services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or Create a chat room for a specific user (Client)
  Future<String> getChatRoomId(String userId, String adminId) async {
    // Check if room exists
    final query = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    // Create new room
    final docRef = await _firestore.collection('chats').add({
      'participants': [
        userId,
        'admin',
      ], // 'admin' is a reserved ID or use actual Admin UID
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTime': null,
    });

    return docRef.id;
  }

  // Send a message
  Future<void> sendMessage(String roomId, String senderId, String text) async {
    // Add message
    await _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .add({
          'senderId': senderId,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });

    // Update room info
    await _firestore.collection('chats').doc(roomId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // Send Notification
    await _sendChatNotification(roomId, senderId, text);
  }

  // Internal Logic to determine who to notify
  Future<void> _sendChatNotification(
    String roomId,
    String senderId,
    String text,
  ) async {
    try {
      final doc = await _firestore.collection('chats').doc(roomId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);

      // Determine Recipient
      // If I am Admin (or 'admin'), send to the other guy
      // If I am normal user, send to 'admin'

      String? receiverId;

      if (senderId == 'admin') {
        // I am admin, send to the user (the one who is NOT 'admin')
        receiverId = participants.firstWhere(
          (p) => p != 'admin',
          orElse: () => '',
        );
      } else {
        // I am user, send to admin
        receiverId = 'admin';
      }

      if (receiverId.isNotEmpty) {
        final NotificationService ns = NotificationService();
        await ns.sendNotification(
          receiverId: receiverId,
          title: "Новое сообщение",
          body: text,
          type: 'chat',
          data: {'roomId': roomId},
        );
      }
    } catch (e) {
      print("Error sending chat notification: $e");
    }
  }

  // Stream messages for a room
  Stream<List<ChatMessage>> getMessages(String roomId) {
    return _firestore
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Get all chats for Admin
  Stream<List<ChatRoom>> getAdminChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: 'admin')
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatRoom.fromMap(doc.data(), doc.id))
              .toList();

          // Sort on client side (null-safe)
          chats.sort((a, b) {
            if (a.lastMessageTime == null && b.lastMessageTime == null)
              return 0;
            if (a.lastMessageTime == null) return 1; // null goes to end
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(
              a.lastMessageTime!,
            ); // descending
          });

          return chats;
        });
  }

  // Update chat metadata (topic, order context)
  Future<void> updateChatMetadata(
    String roomId, {
    String? topic,
    String? orderId,
    String? orderNumber,
  }) async {
    final Map<String, dynamic> updateData = {};
    if (topic != null) updateData['topic'] = topic;
    if (orderId != null) updateData['orderId'] = orderId;
    if (orderNumber != null) updateData['orderNumber'] = orderNumber;

    if (updateData.isNotEmpty) {
      await _firestore.collection('chats').doc(roomId).update(updateData);
    }
  }

  // Stream a specific chat room
  Stream<ChatRoom> getChatRoomStream(String roomId) {
    return _firestore.collection('chats').doc(roomId).snapshots().map((doc) {
      if (!doc.exists) {
        // Return placeholder or handle error
        // For simplicity returning a dummy object might be risky, usually UI handles error
        throw Exception("Chat room not found");
      }
      return ChatRoom.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }
}
