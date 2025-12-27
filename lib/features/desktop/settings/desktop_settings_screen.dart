import 'package:flutter/material.dart';

class DesktopSettingsScreen extends StatelessWidget {
  const DesktopSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Общие настройки',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.print),
                  title: const Text('Настройки принтера'),
                  subtitle: const Text('Настроить принтер для печати чеков'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Printer settings
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Уведомления'),
                  subtitle: const Text('Настроить уведомления'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Notification settings
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Язык'),
                  subtitle: const Text('Русский'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Language settings
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'Профиль',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Мой профиль'),
                  subtitle: const Text('Просмотр и редактирование профиля'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Profile
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Выйти',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    // TODO: Logout
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          const Text(
            'О приложении',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ailin Tattileri Desktop',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Версия: 1.1.0'),
                  SizedBox(height: 4),
                  Text('© 2025 Ailin Tattileri'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
