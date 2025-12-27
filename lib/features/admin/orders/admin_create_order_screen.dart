import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/models/product_model.dart';
import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';

class AdminCreateOrderScreen extends StatefulWidget {
  const AdminCreateOrderScreen({super.key});

  @override
  State<AdminCreateOrderScreen> createState() => _AdminCreateOrderScreenState();
}

class _AdminCreateOrderScreenState extends State<AdminCreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _deliveryType = 'pickup';
  String _paymentStatus = 'paid';

  final List<Map<String, dynamic>> _cartItems = [];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    return _cartItems.fold(0, (sum, item) {
      final p = item['product'] as Product;
      final qty = item['qty'] as int;
      return sum + (p.price * qty);
    });
  }

  void _addProduct(Product product) {
    setState(() {
      final index = _cartItems.indexWhere(
        (item) => (item['product'] as Product).id == product.id,
      );
      if (index != -1) {
        _cartItems[index]['qty'] = (_cartItems[index]['qty'] as int) + 1;
      } else {
        _cartItems.add({'product': product, 'qty': 1});
      }
    });
  }

  void _updateQty(int index, int change) {
    setState(() {
      int newQty = (_cartItems[index]['qty'] as int) + change;
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index]['qty'] = newQty;
      }
    });
  }

  Future<void> _submitOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Тауар таңдаңыз")));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();

      List<Map<String, dynamic>> itemsList = _cartItems.map((item) {
        final p = item['product'] as Product;
        final qty = item['qty'] as int;
        return {
          'productId': p.id,
          'productName': p.name,
          'productPrice': p.price,
          'quantity': qty,
          'imageUrl': p.imageUrl,
          'totalPrice': p.price * qty,
        };
      }).toList();

      for (var item in _cartItems) {
        final p = item['product'] as Product;
        final qty = item['qty'] as int;
        batch.update(
          FirebaseFirestore.instance.collection('products').doc(p.id),
          {'stockQuantity': FieldValue.increment(-qty)},
        );
      }

      final order = OrderModel(
        id: orderRef.id,
        userId: "manual_admin",
        userName: _nameController.text.isEmpty
            ? "Клиент"
            : _nameController.text,
        userPhone: _phoneController.text,
        userAddress: _deliveryType == 'pickup'
            ? "Самовывоз"
            : _addressController.text,
        items: itemsList,
        totalAmount: _totalAmount,
        status: 'new',
        paymentStatus: _paymentStatus,
        paidAmount: _paymentStatus == 'paid' ? _totalAmount : 0,
        debtAmount: _paymentStatus == 'paid' ? 0 : _totalAmount,
        deliveryType: _deliveryType,
        orderType: 'walk_in',
        createdAt: DateTime.now(),
        orderNumber:
            "ADM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
      );

      batch.set(orderRef, order.toMap());
      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Тапсырыс сәтті құрылды!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Қате: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Жаңа тапсырыс",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: CLIENT
                    _buildSectionHeader("Клиент", theme),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: _nameController,
                      label: "Есімі",
                      icon: Icons.person_outline,
                      theme: theme,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildModernTextField(
                      controller: _phoneController,
                      label: "Телефон нөмірі",
                      icon: Icons.phone_outlined,
                      inputType: TextInputType.phone,
                      theme: theme,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),
                    // SECTION 2: DELIVERY & PAYMENT
                    _buildSectionHeader("Жеткізу & Төлем", theme),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isDark
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                        border: isDark
                            ? Border.all(color: Colors.white12)
                            : null,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildSelectionCard(
                                  title: "Самовывоз",
                                  icon: Icons.store,
                                  isSelected: _deliveryType == 'pickup',
                                  onTap: () =>
                                      setState(() => _deliveryType = 'pickup'),
                                  theme: theme,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSelectionCard(
                                  title: "Жеткізу",
                                  icon: Icons.local_shipping_outlined,
                                  isSelected: _deliveryType == 'delivery',
                                  onTap: () => setState(
                                    () => _deliveryType = 'delivery',
                                  ),
                                  theme: theme,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          if (_deliveryType == 'delivery') ...[
                            const SizedBox(height: 12),
                            _buildModernTextField(
                              controller: _addressController,
                              label: "Мекен-жайы",
                              icon: Icons.location_on_outlined,
                              validator: (v) =>
                                  v!.isEmpty ? "Мекен-жайды енгізіңіз" : null,
                              theme: theme,
                              isDark: isDark,
                            ),
                          ],
                          const SizedBox(height: 20),
                          Divider(height: 1, color: theme.dividerColor),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSelectionCard(
                                  title: "Төленді",
                                  icon: Icons.check_circle_outline,
                                  isSelected: _paymentStatus == 'paid',
                                  color: Colors.green,
                                  onTap: () =>
                                      setState(() => _paymentStatus = 'paid'),
                                  theme: theme,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSelectionCard(
                                  title: "Кейін (Қарыз)",
                                  icon: Icons.access_time,
                                  isSelected: _paymentStatus == 'unpaid',
                                  color: Colors.orange,
                                  onTap: () =>
                                      setState(() => _paymentStatus = 'unpaid'),
                                  theme: theme,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    // SECTION 3: PRODUCTS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader("Тауарлар", theme),
                        TextButton.icon(
                          onPressed: () => _showProductSelector(theme, isDark),
                          icon: const Icon(Icons.add_circle, size: 20),
                          label: const Text("Қосу"),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_cartItems.isEmpty)
                      _buildEmptyState(theme, isDark)
                    else
                      ...List.generate(_cartItems.length, (index) {
                        return _buildProductItem(index, theme, isDark);
                      }),

                    const SizedBox(height: 100), // Space for bottom bar
                  ],
                ),
              ),
            ),
          ),

          // BOTTOM FLOATING BAR
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
              border: isDark
                  ? const Border(top: BorderSide(color: Colors.white12))
                  : null,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Жалпы сома",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${CurrencyFormatter.format(_totalAmount)} ₸",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text("Сақтау"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required ThemeData theme,
    required bool isDark,
    TextInputType? inputType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
        border: isDark ? Border.all(color: Colors.white12) : null,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: theme.hintColor),
          prefixIcon: Icon(
            icon,
            color: theme.iconTheme.color?.withOpacity(0.5) ?? Colors.grey,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required bool isDark,
    Color color = AppColors.primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? color
                  : theme.iconTheme.color?.withOpacity(0.5),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? color
                    : theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor,
          style: BorderStyle.values[1],
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.add_shopping_cart, size: 40, color: theme.disabledColor),
          const SizedBox(height: 8),
          Text(
            "Тауарлар қосылмаған",
            style: TextStyle(color: theme.disabledColor),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(int index, ThemeData theme, bool isDark) {
    final item = _cartItems[index];
    final p = item['product'] as Product;
    final qty = item['qty'] as int;

    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) {
        setState(() {
          _cartItems.removeAt(index);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: isDark ? Border.all(color: Colors.white12) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: p.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        p.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.image, color: theme.disabledColor),
                      ),
                    )
                  : Icon(Icons.image, color: theme.disabledColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${CurrencyFormatter.format(p.price)} ₸",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _qtyButton(Icons.remove, () => _updateQty(index, -1), theme),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "$qty",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _qtyButton(Icons.add, () => _updateQty(index, 1), theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: theme.iconTheme.color),
      ),
    );
  }

  void _showProductSelector(ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: theme.iconTheme.color),
                      const SizedBox(width: 12),
                      Text(
                        "Тауар таңдау",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .orderBy('name')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;

                      return ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final p = Product.fromMap(
                            docs[index].data() as Map<String, dynamic>,
                            docs[index].id,
                          );
                          return InkWell(
                            onTap: () {
                              _addProduct(p);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: p.imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              p.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(
                                                    Icons.image,
                                                    color: theme.disabledColor,
                                                  ),
                                            ),
                                          )
                                        : Icon(
                                            Icons.image,
                                            color: theme.disabledColor,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        Text(
                                          "${CurrencyFormatter.format(p.price)} ₸",
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.add_circle_outline,
                                    color: AppColors.primary,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
