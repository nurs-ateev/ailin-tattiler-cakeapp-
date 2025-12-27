import 'package:flutter/material.dart';
import 'package:ailin_tattileri_app/core/models/chat_model.dart';
import 'package:ailin_tattileri_app/core/services/chat_service.dart';
import 'package:intl/intl.dart';

class DesktopChatScreen extends StatelessWidget {
  const DesktopChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatService chatService = ChatService();

    return Scaffold(
      appBar: AppBar(title: const Text('Чат с клиентами')),
      body: Row(
        children: [
          // Chat List
          SizedBox(
            width: 350,
            child: StreamBuilder<List<ChatRoom>>(
              stream: chatService.getAdminChats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Нет чатов'));
                }

                final chats = snapshot.data!;

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final name = chat.userData?['name'] ?? 'Клиент';
                    final lastMsg = chat.lastMessage ?? 'Нет сообщений';
                    final time = chat.lastMessageTime != null
                        ? DateFormat('HH:mm').format(chat.lastMessageTime!)
                        : '';

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(name.substring(0, 1).toUpperCase()),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(time),
                      onTap: () {
                        // TODO: Open chat
                      },
                    );
                  },
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          // Chat Messages
          const Expanded(child: Center(child: Text('Выберите чат'))),
        ],
      ),
    );
  }
}
