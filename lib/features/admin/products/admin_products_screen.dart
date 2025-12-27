import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ailin_tattileri_app/core/models/product_model.dart';
import 'package:ailin_tattileri_app/core/services/product_service.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';
import 'package:ailin_tattileri_app/core/services/category_service.dart';
import 'package:ailin_tattileri_app/core/models/category_model.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  String _searchQuery = "";
  String _selectedCategoryId = "all"; // Use "all" or empty string

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.actionManageMenu,
          style: theme.textTheme.titleLarge,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.push('/admin/add-product'),
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
            ),
            tooltip: AppLocalizations.of(context)!.addProductTooltip,
          ),
        ],
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: _categoryService.getCategories(),
        builder: (context, categorySnapshot) {
          if (categorySnapshot.hasError) {
            return Center(
              child: Text("Ошибка категорий: ${categorySnapshot.error}"),
            );
          }
          // We continue even if loading, to show empty state or defaults

          final categories = categorySnapshot.data ?? [];
          final categoryMap = {
            for (var c in categories) c.id: c.nameRu,
          }; // Map ID -> Name (RU)

          return Column(
            children: [
              // Search and Filter
              Container(
                color: theme.cardTheme.color,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        )!.searchProductHint,
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length + 1, // +1 for "All"
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // "All" chip
                            final isSelected = _selectedCategoryId == "all";
                            return ChoiceChip(
                              label: const Text("Все"),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected)
                                  setState(() => _selectedCategoryId = "all");
                              },
                              selectedColor: AppColors.primary.withOpacity(0.2),
                            );
                          }

                          final category = categories[index - 1];
                          final isSelected = _selectedCategoryId == category.id;
                          return ChoiceChip(
                            label: Text(category.nameRu), // Admin always RU
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected)
                                setState(
                                  () => _selectedCategoryId = category.id,
                                );
                            },
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : theme.textTheme.bodyMedium?.color,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Products List
              Expanded(
                child: StreamBuilder<List<Product>>(
                  stream: _productService.getProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Ошибка: ${snapshot.error}"));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allProducts = snapshot.data ?? [];
                    final filteredProducts = allProducts.where((p) {
                      final matchesSearch = p.name.toLowerCase().contains(
                        _searchQuery,
                      );
                      // Compare IDs
                      final matchesCategory =
                          _selectedCategoryId == "all" ||
                          p.category == _selectedCategoryId;
                      return matchesSearch && matchesCategory;
                    }).toList();

                    if (filteredProducts.isEmpty) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(context)!.nothingFound,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        // Resolving Category Name
                        final catName =
                            categoryMap[product.category] ??
                            product
                                .category; // Fallback to ID/String if not found

                        return _ProductAdminCard(
                          product: product,
                          categoryName: catName,
                          onEdit: () {
                            context.push('/admin/add-product', extra: product);
                          },
                          onDelete: () => _confirmDelete(product),
                          onToggleAvailability: (val) {
                            _productService.toggleAvailability(
                              product.id,
                              !val,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteProductTitle),
        content: Text(
          AppLocalizations.of(context)!.deleteProductContent(product.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await _productService.deleteProduct(product.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductAdminCard extends StatelessWidget {
  final Product product;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggleAvailability;

  const _ProductAdminCard({
    required this.product,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'ru_RU');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Theme.of(context).disabledColor.withOpacity(0.1),
                  child: Icon(
                    Icons.image_not_supported,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    categoryName, // Display Resolved Name
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${formatter.format(product.price).replaceAll(',', ' ')} ₸",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      onPressed: onEdit,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: onDelete,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: product.isAvailable,
                    activeColor: Colors.green,
                    onChanged: onToggleAvailability,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
