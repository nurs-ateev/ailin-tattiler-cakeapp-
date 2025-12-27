import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/services/debt_service.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';

Future<void> showAdminPaymentDialog(
  BuildContext context,
  OrderModel order,
  String partnerId,
) async {
  final amountController = TextEditingController(
    text: order.debtAmount.toStringAsFixed(0),
  );
  final noteController = TextEditingController();
  bool isLoading = false;

  return showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("Төлем қабылдау"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Тапсырыс: #${order.id.substring(0, 5).toUpperCase()}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Қарыз: ${order.debtAmount.toStringAsFixed(0)} ₸",
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: "Төлем сомасы (₸)",
                hintText: "Мысалы: ${order.debtAmount.toStringAsFixed(0)}",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 2,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: "Ескертпе (міндетті емес)",
                hintText: "Мысалы: Қолма-қол ақша",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.note),
              ),
            ),
            if (isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : () => Navigator.pop(context),
            child: const Text("Болдырмау"),
          ),
          ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Дұрыс сома енгізіңіз")),
                      );
                      return;
                    }

                    if (amount > order.debtAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Сома қарыздан көп болмауы керек"),
                        ),
                      );
                      return;
                    }

                    setState(() => isLoading = true);

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) return;

                      final debtService = DebtService();
                      await debtService.recordAdminPayment(
                        orderId: order.id,
                        partnerId: partnerId,
                        amount: amount,
                        adminId: user.uid,
                        note: noteController.text.isNotEmpty
                            ? noteController.text
                            : null,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Төлем сәтті қабылданды!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() => isLoading = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Қате: $e")));
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text("Қабылдау"),
          ),
        ],
      ),
    ),
  );
}
