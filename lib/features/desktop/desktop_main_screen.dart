import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:ailin_tattileri_app/core/models/product_model.dart';
import 'package:ailin_tattileri_app/core/models/order_model.dart';
// Import Admin screens for non-POS tabs
import 'package:ailin_tattileri_app/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:ailin_tattileri_app/features/admin/orders/admin_orders_screen.dart';
import 'package:ailin_tattileri_app/features/admin/products/admin_products_screen.dart';
import 'package:ailin_tattileri_app/features/admin/warehouse/warehouse_screen.dart';
import 'package:ailin_tattileri_app/features/admin/analytics/analytics_screen.dart';

class DesktopMainScreen extends StatefulWidget {
  const DesktopMainScreen({super.key});

  @override
  State<DesktopMainScreen> createState() => _DesktopMainScreenState();
}

class _DesktopMainScreenState extends State<DesktopMainScreen> {
  int _selectedIndex = 0;
  bool _isExpanded = true;

  // Controller for Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Cart State
  final List<Map<String, dynamic>> _cartItems = [];

  final List<String> _menuItems = [
    "Касса (POS)",
    "Басты бет",
    "Заказдар",
    "Тауарлар",
    "Склад",
    "Аналитика",
  ];

  final List<IconData> _menuIcons = [
    Icons.point_of_sale,
    Icons.dashboard,
    Icons.shopping_bag,
    Icons.category,
    Icons.inventory_2,
    Icons.bar_chart,
  ];

  // --- CART LOGIC ---
  void _addToCart(Product product) {
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

  void _updateQty(int index, int delta) {
    setState(() {
      int newQty = (_cartItems[index]['qty'] as int) + delta;
      if (newQty <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index]['qty'] = newQty;
      }
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
  }

  double get _totalAmount {
    return _cartItems.fold(0, (sum, item) {
      final p = item['product'] as Product;
      final q = item['qty'] as int;
      return sum + (p.price * q);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1024x768 Optimization:
    // Sidebar: 60px (collapsed) or 220px (expanded)
    // Cart: 300px Fixed
    // Content: Remaining

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Row(
        children: [
          // SIDEBAR
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isExpanded ? 220 : 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2C3E50),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5),
              ],
            ),
            child: Column(
              children: [
                // LOGO
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    color: const Color(0xFF243342),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.store, color: Colors.white, size: 24),
                        if (_isExpanded) ...[
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Ailin POS",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // MENU ITEMS
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _selectedIndex = index),
                          child: Container(
                            height: 48, // Touch friendly height
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: isSelected
                                  ? const Border(
                                      left: BorderSide(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                    )
                                  : null,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Icon(
                                  _menuIcons[index],
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[400],
                                  size: 22,
                                ),
                                if (_isExpanded) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _menuItems[index],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[300],
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // LOGOUT
                Divider(color: Colors.grey[700], height: 1),
                InkWell(
                  onTap: () {
                    context.go('/login');
                    FirebaseAuth.instance.signOut();
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: _isExpanded
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Шығу",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          )
                        : const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
          ),

          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                // HEADER (Minimalist for low height)
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            setState(() => _isExpanded = !_isExpanded),
                        icon: Icon(_isExpanded ? Icons.menu_open : Icons.menu),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 24,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _menuItems[_selectedIndex],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const Spacer(),
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Hide text on very small screens if needed, but 1024 is ok
                      const Text(
                        "Админ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // BODY
                Expanded(child: _buildPageContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    // Return actual screens if selected
    switch (_selectedIndex) {
      case 0: // POS
        return _buildPOSContent();
      case 1: // Dashboard
        return const AdminDashboardScreen();
      case 2: // Orders
        return const AdminOrdersScreen();
      case 3: // Products
        return const AdminProductsScreen();
      case 4: // Warehouse
        return const WarehouseScreen();
      case 5: // Analytics
        return const AnalyticsScreen();
      default:
        return const Center(child: Text("Бет табылмады"));
    }
  }

  Widget _buildPOSContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT: PRODUCTS GRID
        Expanded(
          child: Column(
            children: [
              // SEARCH BAR
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "Штрихкод немесе атауы...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () {
                        // Logical placeholder for scanner focus
                      },
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              // GRID
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError)
                      return const Center(child: Text("Қате шықты"));
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data!.docs;
                    final products = docs
                        .map((d) {
                          return Product.fromMap(
                            d.data() as Map<String, dynamic>,
                            d.id,
                          );
                        })
                        .where((p) {
                          final q = _searchQuery.toLowerCase();
                          return p.name.toLowerCase().contains(q);
                        })
                        .toList();

                    if (products.isEmpty) {
                      return const Center(
                        child: Text(
                          "Тауар жоқ",
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      // Responsive grid based on available width
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent:
                                180, // Allow roughly 3-4 items on 1024px
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return GestureDetector(
                          onTap: () => _addToCart(product),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                    child: product.imageUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: product.imageUrl,
                                            fit: BoxFit.cover,
                                            errorWidget: (context, url, err) =>
                                                Container(
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                            placeholder: (context, url) =>
                                                Container(
                                                  color: Colors.grey[200],
                                                ),
                                          )
                                        : Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.image,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    6,
                                    8,
                                    8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${CurrencyFormatter.format(product.price)} ₸",
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
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
          ),
        ),

        // RIGHT: CART
        Container(
          width:
              320, // Fixed width suitable for 1024px (leaves ~704-60 = 640px for grid)
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            children: [
              // CART HEADER
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: const Color(0xFF2C3E50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Чек",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: _clearCart,
                      child: const Icon(
                        Icons.delete_sweep,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // CART ITEMS
              Expanded(
                child: _cartItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Себет бос",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _cartItems.length,
                        separatorBuilder: (c, i) => const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          final p = item['product'] as Product;
                          final qty = item['qty'] as int;
                          return Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      "${CurrencyFormatter.format(p.price)} ₸",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  _qtyButton(
                                    Icons.remove,
                                    () => _updateQty(index, -1),
                                  ),
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      "$qty",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  _qtyButton(
                                    Icons.add,
                                    () => _updateQty(index, 1),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${CurrencyFormatter.format(p.price * qty)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // CART TOTALS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Барлығы:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${CurrencyFormatter.format(_totalAmount)} ₸",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48, // Good height for touch
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _cartItems.isEmpty ? null : _processPayment,
                        child: const Text(
                          "ТӨЛЕУ",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        splashRadius: 16,
        style: IconButton.styleFrom(
          backgroundColor: Colors.grey[200],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Төлемді растау"),
        content: Text(
          "Жалпы сома: ${CurrencyFormatter.format(_totalAmount)} ₸\n\nТөлемді қабылдауға сенімдісіз бе?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Бас тарту"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Қолма-қол / Kaspi"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show Loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (_cartItems.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();

      // 1. Prepare Items Data
      List<Map<String, dynamic>> orderItems = [];
      for (var item in _cartItems) {
        final p = item['product'] as Product;
        final qty = item['qty'] as int;

        // Add to order items list
        orderItems.add({
          'productId': p.id,
          'productName': p.name,
          'productPrice': p.price,
          'quantity': qty,
          'imageUrl': p.imageUrl,
          'totalPrice': p.price * qty,
        });

        // 2. Decrement Stock
        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(p.id);
        batch.update(productRef, {'stockQuantity': FieldValue.increment(-qty)});
      }

      // 3. Create Order Object
      final newOrder = OrderModel(
        id: orderRef.id,
        userId: "walk_in_guest",
        userName: "Дүкен қонағы",
        userPhone: "",
        userAddress: "Өзі алып кету (Дүкен)",
        items: orderItems,
        totalAmount: _totalAmount,
        status: 'completed', // Immediately completed
        paymentStatus: 'paid',
        paidAmount: _totalAmount,
        deliveryType: 'pickup',
        orderType: 'walk_in', // NEW FIELD
        createdAt: DateTime.now(),
        orderNumber:
            "POS-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}", // Simple ID
      );

      batch.set(orderRef, newOrder.toMap());

      // 4. Commit
      await batch.commit();

      // 5. Success UI
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      _clearCart();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Сауда сәтті аяқталды!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              Text(
                "Чек №${newOrder.orderNumber}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Тапсырыс базаға сақталды."),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Жабу"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Қате: $e"), backgroundColor: Colors.red),
      );
    }
  }
}
