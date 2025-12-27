import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ailin_tattileri_app/core/models/chat_model.dart';
import 'package:ailin_tattileri_app/core/services/chat_service.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String chatTitle;

  const ChatScreen({super.key, required this.roomId, required this.chatTitle});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  // Assuming Admin uses 'admin' as ID or we check role.
  // For simplicity, let's say purely for UI, sender messages are on the right.
  // We need to know who "I" am.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatTitle),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        iconTheme: theme.iconTheme,
      ),
      body: StreamBuilder<ChatRoom?>(
        stream: _chatService.getChatRoomStream(widget.roomId),
        builder: (context, roomSnapshot) {
          final room = roomSnapshot.data;

          return Column(
            children: [
              if (room != null) _buildChatContextUI(context, room),
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: _chatService.getMessages(widget.roomId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          "Нет сообщений",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      );
                    }

                    final messages = snapshot.data!;

                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe =
                            msg.senderId == currentUserId ||
                            (currentUserId == '' && msg.senderId == 'admin');

                        return _ChatBubble(message: msg, isMe: isMe);
                      },
                    );
                  },
                ),
              ),
              _buildInputArea(theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatContextUI(BuildContext context, ChatRoom room) {
    final hasTopic = room.topic != null;
    // Assume Admin if currentUserId is empty (or check role if available)
    // But better: Check if I am the client (senderId == currentUserId and not admin)
    // Simplified: If I am authenticated user, and topic is missing, I can set it.
    // Ensure we don't show selector to Admin (who might observe).
    // For now, let's just show selector if User is Client (has UID) and topic is null.

    final isClient = currentUserId.isNotEmpty && currentUserId != 'admin';

    if (!hasTopic && isClient) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: AppColors.primary.withOpacity(0.05),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                "Выберите тему обращения:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => _showTopicSelector(),
              child: const Text("Выбрать"),
            ),
          ],
        ),
      );
    } else if (hasTopic) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.grey[100],
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              "Тема: ${room.topic}",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            if (room.orderNumber != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Заказ №${room.orderNumber}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showTopicSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Выберите тему",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text("Общий вопрос"),
                onTap: () {
                  _updateTopic("Общий вопрос");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text("Вопрос по заказу"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showOrderSelector();
                },
              ),
              ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text("Проблема с приложением"),
                onTap: () {
                  _updateTopic("Техническая проблема");
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.feedback_outlined),
                title: const Text("Предложение / Отзыв"),
                onTap: () {
                  _updateTopic("Отзыв");
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOrderSelector() {
    // Show active orders
    // Mocking order fetch for brevity or use StreamBuilder if existing service available
    // Assuming simple Firestore query for now
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: currentUserId)
                  .orderBy('createdAt', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final orders = snapshot.data?.docs ?? [];
                if (orders.isEmpty) {
                  return const Center(child: Text("Нет активных заказов"));
                }
                return ListView.builder(
                  controller: controller,
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final data = orders[index].data() as Map<String, dynamic>;
                    final id = orders[index].id;
                    final number = data['orderNumber']?.toString() ?? '???';
                    final total = data['totalAmount'] ?? 0;
                    final status = data['status'] ?? 'pending';

                    return ListTile(
                      title: Text("Заказ №$number"),
                      subtitle: Text("Статус: $status • $total ₸"),
                      onTap: () {
                        _updateTopic(
                          "Вопрос по заказу",
                          orderId: id,
                          orderNumber: number,
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _updateTopic(
    String topic, {
    String? orderId,
    String? orderNumber,
  }) async {
    await _chatService.updateChatMetadata(
      widget.roomId,
      topic: topic,
      orderId: orderId,
      orderNumber: orderNumber,
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Написать сообщение...",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    // Determine Sender ID.
    // If Admin, use 'admin' (or distinct Admin UID).
    // Ideally we should use real UIDs.
    // Let's assume for this task: current auth user is the sender.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // We might need to check if this user is actually the admin to send as 'admin'?
    // For now, send as UID.

    _chatService.sendMessage(widget.roomId, uid, _controller.text.trim());
    _controller.clear();
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
