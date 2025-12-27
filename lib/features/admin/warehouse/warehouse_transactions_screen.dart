import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WarehouseTransactionsScreen extends StatelessWidget {
  const WarehouseTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('warehouse_transactions')
          .orderBy('date', descending: true)
          .limit(100) // Limit to last 100 transactions for performance
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Ошибка: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text('История пуста'));
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final type = data['type'] as String; // 'incoming', 'usage', etc.
            final date = (data['date'] as Timestamp).toDate();
            final quantity = (data['quantity'] as num).toDouble();
            final name = data['ingredientName'] ?? 'Ингредиент';
            final note = data['note'] ?? '';

            Color color;
            IconData icon;
            String prefix;

            switch (type) {
              case 'incoming':
                color = Colors.green;
                icon = Icons.add_circle_outline;
                prefix = '+';
                break;
              case 'usage':
                color = Colors.blue;
                icon = Icons.restaurant;
                prefix = '-';
                break;
              case 'writeoff': // Spoilage/Unknown loss
                color = Colors.red;
                icon = Icons.delete_outline;
                prefix = '-';
                break;
              case 'correction': // Inventory check
                color = Colors.orange;
                icon = Icons.edit;
                prefix = quantity >= 0 ? '+' : '';
                break;
              default:
                color = Colors.grey;
                icon = Icons.help_outline;
                prefix = '';
            }

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                note.isNotEmpty
                    ? "${DateFormat('dd.MM.yyyy HH:mm').format(date)}\n$note"
                    : DateFormat('dd.MM.yyyy HH:mm').format(date),
              ),
              trailing: Text(
                "$prefix${quantity.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
