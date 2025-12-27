import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:ailin_tattileri_app/core/models/product_model.dart';
import 'package:ailin_tattileri_app/core/services/product_service.dart';
import 'package:ailin_tattileri_app/core/services/cloudinary_service.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';
import 'package:ailin_tattileri_app/core/services/category_service.dart';
import 'package:ailin_tattileri_app/core/models/category_model.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product; // Add this for editing

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _categoryService = CategoryService();
  final _picker = ImagePicker();

  // Form Fields
  late String _name;
  late double _price;
  late String _description;
  String? _category; // Stores Category ID
  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize fields with product data if editing
    _name = widget.product?.name ?? '';
    _price = widget.product?.price ?? 0;
    _description = widget.product?.description ?? '';
    _category = widget.product?.category;
    _existingImageUrl = widget.product?.imageUrl;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    final text = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      String imageUrl =
          _existingImageUrl ??
          'https://placehold.co/600x400/FFC0CB/white?text=No+Photo';

      // Upload to Cloudinary if image selected
      if (_imageFile != null) {
        final cloudinary = CloudinaryService();
        final url = await cloudinary.uploadImage(_imageFile!);
        if (url != null) {
          imageUrl = url;
        } else {
          throw Exception(text.errorImageUpload);
        }
      }

      if (widget.product != null) {
        // Edit Mode
        await _productService.updateProduct(
          id: widget.product!.id,
          name: _name,
          price: _price,
          description: _description,
          category: _category!,
          imageUrl: imageUrl,
        );
      } else {
        // Add Mode
        await _productService.addProduct(
          name: _name,
          price: _price,
          description: _description,
          category: _category!,
          imageUrl: imageUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product != null ? text.productUpdated : text.productAdded,
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? text.editProductTitle : text.menuAddProduct),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Picker Area
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? theme.colorScheme.surfaceContainerHighest
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withOpacity(0.2),
                      ),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : (_existingImageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_existingImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                    ),
                    child: (_imageFile == null && _existingImageUrl == null)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: theme.disabledColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                text.addPhoto,
                                style: TextStyle(color: theme.disabledColor),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                // Name Field
                TextFormField(
                  initialValue: _name,
                  decoration: InputDecoration(
                    labelText: text.productName,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: const Icon(Icons.restaurant),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? text.enterName : null,
                  onSaved: (value) => _name = value!,
                ),
                const SizedBox(height: 16),

                // Price Field
                TextFormField(
                  initialValue: isEditing ? _price.toInt().toString() : null,
                  decoration: InputDecoration(
                    labelText: text.productPrice,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return text.enterPrice;
                    if (double.tryParse(value) == null)
                      return text.enterValidAmount;
                    return null;
                  },
                  onSaved: (value) => _price = double.parse(value!),
                ),
                const SizedBox(height: 16),

                // Category Dropdown (Dynamic)
                StreamBuilder<List<CategoryModel>>(
                  stream: _categoryService.getCategories(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text(
                        'Error loading categories: ${snapshot.error}',
                      );
                    }

                    final categories = snapshot.data ?? [];

                    // Validate if selected category still exists or matches ID
                    // If existing product has "Супы" (Name), it won't match ID.
                    // We simply default to null if not found.
                    // Or we default to the first one? No, force select.
                    final validIds = categories.map((e) => e.id).toSet();

                    String? currentValue = _category;
                    if (currentValue != null &&
                        !validIds.contains(currentValue)) {
                      // If key exists but not in valid list (legacy name?), set null
                      currentValue = null;
                    }

                    return DropdownButtonFormField<String>(
                      value: currentValue,
                      decoration: InputDecoration(
                        labelText: text.productCategory,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: categories.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            "${c.icon} ${c.nameRu}",
                          ), // Admin view is Russian
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _category = value!),
                      validator: (value) =>
                          value == null ? 'Выберите категорию' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  initialValue: _description,
                  decoration: InputDecoration(
                    labelText: text.productDescription,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    prefixIcon: const Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty
                      ? text.enterDescription
                      : null,
                  onSaved: (value) => _description = value!,
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          (isEditing ? text.save : text.menuAddProduct)
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
