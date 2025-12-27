import 'package:flutter/material.dart';
import 'package:ailin_tattileri_app/core/models/product_model.dart';
import 'package:ailin_tattileri_app/core/services/product_service.dart';
import 'package:ailin_tattileri_app/features/client/home/widgets/product_card.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';

class ReturnProductSelectScreen extends StatelessWidget {
  const ReturnProductSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Выбор товара для возврата",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<Product>>(
        stream: productService.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text("Ошибка: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Товары не найдены"));
          }

          final products = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onTap: () {
                  Navigator.pop(context, product);
                },
              );
            },
          );
        },
      ),
    );
  }
}
