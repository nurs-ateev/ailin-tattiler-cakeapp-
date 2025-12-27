import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';

class DesktopPartnersScreen extends StatelessWidget {
  const DesktopPartnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Партнеры и долги')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('partners').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Нет партнеров'));
          }

          final partners = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: partners.length,
            itemBuilder: (context, index) {
              final partner = partners[index].data() as Map<String, dynamic>;
              final partnerId = partners[index].id;
              final name = partner['name'] ?? 'Без имени';
              final phone = partner['phone'] ?? '';
              final totalDebt = (partner['totalDebt'] ?? 0).toDouble();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: totalDebt > 0
                        ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    child: Icon(
                      Icons.person,
                      color: totalDebt > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('📞 $phone'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Общий долг:', style: TextStyle(fontSize: 12)),
                      Text(
                        '${CurrencyFormatter.format(totalDebt)} ₸',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: totalDebt > 0 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'История платежей',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('payment_history')
                                .where('partnerId', isEqualTo: partnerId)
                                .orderBy('createdAt', descending: true)
                                .limit(10)
                                .snapshots(),
                            builder: (context, paymentSnapshot) {
                              if (!paymentSnapshot.hasData ||
                                  paymentSnapshot.data!.docs.isEmpty) {
                                return const Text('Нет платежей');
                              }

                              return Column(
                                children: paymentSnapshot.data!.docs.map((doc) {
                                  final payment =
                                      doc.data() as Map<String, dynamic>;
                                  final amount = (payment['amount'] ?? 0)
                                      .toDouble();
                                  final status = payment['status'] ?? '';
                                  final createdAt =
                                      (payment['createdAt'] as Timestamp?)
                                          ?.toDate();

                                  return ListTile(
                                    dense: true,
                                    leading: Icon(
                                      status == 'approved'
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      color: status == 'approved'
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    title: Text(
                                      '${CurrencyFormatter.format(amount)} ₸',
                                    ),
                                    subtitle: Text(
                                      createdAt != null
                                          ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
                                          : '',
                                    ),
                                    trailing: Text(
                                      status == 'approved'
                                          ? 'Одобрено'
                                          : 'Ожидает',
                                      style: TextStyle(
                                        color: status == 'approved'
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
