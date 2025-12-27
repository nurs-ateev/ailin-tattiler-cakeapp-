import 'package:flutter/material.dart';
import 'package:ailin_tattileri_app/core/models/category_model.dart';
import 'package:ailin_tattileri_app/core/services/category_service.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _categoryService = CategoryService();

  void _showCategoryDialog({CategoryModel? category}) {
    showDialog(
      context: context,
      builder: (context) => _CategoryDialog(
        category: category,
        onSave: (nameRu, nameKk, icon) async {
          if (category == null) {
            await _categoryService.addCategory(
              nameRu: nameRu,
              nameKk: nameKk,
              icon: icon,
            );
          } else {
            await _categoryService.updateCategory(
              id: category.id,
              nameRu: nameRu,
              nameKk: nameKk,
              icon: icon,
            );
          }
        },
      ),
    );
  }

  void _deleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить категорию?'),
        content: Text('Вы уверены, что хотите удалить "${category.nameRu}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _categoryService.deleteCategory(category.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Управление категориями')),
      body: StreamBuilder<List<CategoryModel>>(
        stream: _categoryService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Center(child: Text('Нет категорий. Добавьте первую!'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      category.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text("${category.nameRu} / ${category.nameKk}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _showCategoryDialog(category: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteCategory(category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final CategoryModel? category;
  final Function(String nameRu, String nameKk, String icon) onSave;

  const _CategoryDialog({this.category, required this.onSave});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late TextEditingController _nameRuController;
  late TextEditingController _nameKkController;
  late TextEditingController _iconController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameRuController = TextEditingController(
      text: widget.category?.nameRu ?? '',
    );
    _nameKkController = TextEditingController(
      text: widget.category?.nameKk ?? '',
    );
    _iconController = TextEditingController(text: widget.category?.icon ?? '');
  }

  @override
  void dispose() {
    _nameRuController.dispose();
    _nameKkController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.category == null ? 'Новая категория' : 'Редактировать',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameRuController,
              decoration: const InputDecoration(
                labelText: 'Название (RU)',
                hintText: 'Супы',
              ),
              validator: (v) => v?.isEmpty == true ? 'Обязательно' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameKkController,
              decoration: const InputDecoration(
                labelText: 'Название (KK)',
                hintText: 'Сорпалар',
              ),
              validator: (v) => v?.isEmpty == true ? 'Обязательно' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _iconController,
              decoration: const InputDecoration(
                labelText: 'Иконка (Эмодзи)',
                hintText: '🍲',
              ),
              validator: (v) => v?.isEmpty == true ? 'Обязательно' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _nameRuController.text.trim(),
                _nameKkController.text.trim(),
                _iconController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
