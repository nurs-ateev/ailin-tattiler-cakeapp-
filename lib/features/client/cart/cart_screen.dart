import 'package:ailin_tattileri_app/core/models/order_model.dart';
import 'package:ailin_tattileri_app/core/services/order_service.dart';
import 'package:ailin_tattileri_app/core/services/cart_service.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';
import 'package:ailin_tattileri_app/core/models/product_model.dart';
import 'package:ailin_tattileri_app/core/services/auth_service.dart';
import 'package:ailin_tattileri_app/core/utils/currency_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ailin_tattileri_app/features/client/orders/order_success_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null) {
      final role = await authService.getUserRole(user.uid);
      if (mounted) {
        setState(() {
          _userRole = role;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);
    final text = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPartner = _userRole == 'partner' || _userRole == 'admin';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text.cartTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
            if (cart.items.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cart.items.length}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (cart.items.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () => cart.clearCart(),
              ),
            ),
        ],
      ),
      body: (cart.items.isEmpty && cart.returnItems.isEmpty)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    text.cartEmpty,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Добавьте товары чтобы продолжить',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shopping_bag_outlined),
                        const SizedBox(width: 8),
                        Text(
                          text.menuMain,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (cart.items.isNotEmpty) ...[
                        _buildSectionHeader(
                          text.cartTitle,
                          Icons.shopping_bag,
                          theme,
                        ),
                        const SizedBox(height: 12),
                        ...cart.items.map(
                          (item) => _buildCartItem(item, cart, isDark, theme),
                        ),
                      ],
                      if (isPartner) ...[
                        const SizedBox(height: 32),
                        _buildSectionHeader(
                          "Возврат продукции",
                          Icons.assignment_return,
                          theme,
                          action: TextButton.icon(
                            onPressed: () =>
                                _showAddReturnDialog(context, cart),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                            label: const Text("Добавить"),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange[800],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (cart.returnItems.isEmpty)
                          _buildEmptyReturnState(theme)
                        else
                          ...cart.returnItems.map(
                            (item) =>
                                _buildReturnItem(item, cart, isDark, theme),
                          ),
                      ],
                    ],
                  ),
                ),

                // Summary Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Товары (${cart.itemCount})",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              "${cart.subtotal.toInt()} ₸",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (cart.returnItems.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Возвраты",
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                "-${cart.totalReturnAmount.toInt()} ₸",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              "Доставка",
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              "Бесплатно",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              text.cartTotal,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${cart.totalAmount.toInt()} ₸",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Container(
                            decoration: cart.isDeliveryAvailable
                                ? BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(
                                          0.4,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                        spreadRadius: -5,
                                      ),
                                    ],
                                  )
                                : BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                            child: ElevatedButton(
                              onPressed: cart.isDeliveryAvailable
                                  ? () => _showCheckoutDialog(context, cart)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                cart.isDeliveryAvailable
                                    ? text.cartCheckout
                                    : text.deliveryUnavailable,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!cart.isDeliveryAvailable)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              text.locationRestricted,
                              style: TextStyle(
                                color: Colors.red[400],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    ThemeData theme, {
    Widget? action,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        if (action != null) action,
      ],
    );
  }

  Widget _buildEmptyReturnState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[400]),
          const SizedBox(height: 8),
          const Text(
            "Нет товаров на возврат. Нажмите «Добавить», если хотите вернуть просрочку или неликвид.",
            style: TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    dynamic item,
    CartService cart,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _itemDecoration(isDark, theme),
      child: Row(
        children: [
          _itemImage(item.product.imageUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${item.totalPrice.toInt()} ₸",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildQtyControls(
                      item.quantity,
                      onAdd: () => cart.addItem(item.product),
                      onRemove: () => cart.removeSingleItem(item.product.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnItem(
    dynamic item,
    CartService cart,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _itemDecoration(
        isDark,
        theme,
      ).copyWith(border: Border.all(color: Colors.orange.withOpacity(0.3))),
      child: Row(
        children: [
          _itemImage(item.product.imageUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getReasonText(item.reason),
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "-${item.totalPrice.toInt()} ₸",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    _buildQtyControls(
                      item.quantity,
                      onAdd: () =>
                          cart.addReturnItem(item.product, reason: item.reason),
                      onRemove: () => cart.removeSingleReturnItem(
                        item.product.id,
                        item.reason,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getReasonText(String reason) {
    switch (reason) {
      case 'expired':
        return 'Просрочка';
      case 'unsold':
        return 'Не продано';
      case 'damaged':
        return 'Брак';
      default:
        return 'Возврат';
    }
  }

  BoxDecoration _itemDecoration(bool isDark, ThemeData theme) {
    return BoxDecoration(
      color: theme.cardTheme.color,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _itemImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildQtyControls(
    int quantity, {
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _QtyBtn(icon: Icons.remove, onTap: onRemove),
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text(
              "$quantity",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          _QtyBtn(icon: Icons.add, onTap: onAdd, isActive: true),
        ],
      ),
    );
  }

  void _showAddReturnDialog(BuildContext context, CartService cart) async {
    // 1. Navigate to the visual selection screen
    final selectedProduct = await context.push<Product>(
      '/cart/select-return-product',
    );

    if (selectedProduct == null || !context.mounted) return;

    // 2. Show the sheet to specify reason and quantity
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _AddReturnSheet(selectedProduct: selectedProduct, cart: cart),
    );
  }
}

class _AddReturnSheet extends StatefulWidget {
  final Product selectedProduct;
  final CartService cart;

  const _AddReturnSheet({required this.selectedProduct, required this.cart});

  @override
  State<_AddReturnSheet> createState() => _AddReturnSheetState();
}

class _AddReturnSheetState extends State<_AddReturnSheet> {
  late Product _selectedProduct;
  String _reason = 'expired';
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _selectedProduct = widget.selectedProduct;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Добавить товар на возврат",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (_selectedProduct.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _selectedProduct.imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedProduct.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  "${_selectedProduct.price} ₸",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text("Причина возврата:", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _reason,
            items: const [
              DropdownMenuItem(
                value: 'expired',
                child: Text("Истек срок годности"),
              ),
              DropdownMenuItem(value: 'unsold', child: Text("Не продано")),
              DropdownMenuItem(
                value: 'damaged',
                child: Text("Брак/Повреждение"),
              ),
            ],
            onChanged: (val) => setState(() => _reason = val!),
            decoration: _inputDecoration("Причина", Icons.info_outline),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.cart.addReturnItem(
                  _selectedProduct,
                  quantity: _quantity,
                  reason: _reason,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text("Добавить в корзину"),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

void _showCheckoutDialog(BuildContext context, CartService cart) async {
  final authService = AuthService();
  final user = authService.currentUser;

  if (user == null) {
    // Prompt for Login
    final bool? shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Вход"),
        content: const Text("Войдите, чтобы сохранить историю заказов."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Продолжить как гость"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text("Войти"),
          ),
        ],
      ),
    );

    if (shouldLogin == true) {
      if (context.mounted) context.push('/login');
      return;
    }
  }

  if (!context.mounted) return;
  final text = AppLocalizations.of(context)!;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String userRole = 'client';

  // Загружаем данные из Firestore профиля пользователя
  if (user != null) {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        nameController.text = data['fullName'] ?? data['name'] ?? '';
        phoneController.text = data['phone'] ?? '';
        addressController.text = data['address'] ?? '';
        userRole = data['role'] ?? 'client';
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  bool isLoading = false;
  String deliveryType = 'delivery'; // 'delivery' or 'pickup'
  String paymentMethod = 'paid'; // 'paid', 'debt', 'mixed'
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController commentController = TextEditingController();
  String? selectedDeliveryTime;

  // GPS Logic
  bool _isLocationDetermined = false; // To track if we successfully got GPS
  bool _isOutsideZone = false; // Track if outside 20km
  bool _allowManualEntry =
      false; // Allow manual entry if GPS fails/outside zone
  final double zhetysayLat = 40.7833;
  final double zhetysayLng = 68.3167; // Approx coordinates
  final double maxDistanceMeters = 20000; // 20km

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(32),
      ), // Круглые углы!
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          text.checkoutTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Выбор доставки/самовывоза
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // Круглые углы!
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      deliveryType = 'delivery';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: deliveryType == 'delivery'
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                        16,
                                      ), // Круглые углы!
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.delivery_dining,
                                          color: deliveryType == 'delivery'
                                              ? Colors.white
                                              : Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Доставка',
                                          style: TextStyle(
                                            color: deliveryType == 'delivery'
                                                ? Colors.white
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      deliveryType = 'pickup';
                                      // Only switch to debt if PARTNER. Client stays on 'paid'.
                                      if (userRole == 'partner' ||
                                          userRole == 'admin') {
                                        if (paymentMethod == 'paid') {
                                          paymentMethod = 'debt';
                                        }
                                      } else {
                                        // Ensure client is 'paid'
                                        paymentMethod = 'paid';
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: deliveryType == 'pickup'
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(
                                        16,
                                      ), // Круглые углы!
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_bag,
                                          color: deliveryType == 'pickup'
                                              ? Colors.white
                                              : Colors.grey[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Самовывоз',
                                          style: TextStyle(
                                            color: deliveryType == 'pickup'
                                                ? Colors.white
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nameController,
                          enabled: !isLoading,
                          decoration: _inputDecoration(
                            text.checkoutName,
                            Icons.person,
                          ),
                          validator: (value) => value?.isEmpty ?? true
                              ? text.checkoutNameError
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          enabled: !isLoading,
                          decoration: _inputDecoration(
                            text.checkoutPhone,
                            Icons.phone,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) => value?.isEmpty ?? true
                              ? text.checkoutPhoneError
                              : null,
                        ),
                        const SizedBox(height: 12),
                        // Показываем адрес только для доставки
                        if (deliveryType == 'delivery') ...[
                          if (userRole == 'client' &&
                              addressController.text.isEmpty &&
                              !_isLocationDetermined)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  setState(() => isLoading = true);
                                  try {
                                    // 1. Permission check
                                    LocationPermission permission =
                                        await Geolocator.checkPermission();
                                    if (permission ==
                                        LocationPermission.denied) {
                                      permission =
                                          await Geolocator.requestPermission();
                                      if (permission ==
                                          LocationPermission.denied) {
                                        throw 'Location permissions are denied';
                                      }
                                    }
                                    if (permission ==
                                        LocationPermission.deniedForever) {
                                      throw 'Location permissions are permanently denied, we cannot request permissions.';
                                    }

                                    // 2. Get Position
                                    final position =
                                        await Geolocator.getCurrentPosition();

                                    // 3. Check Distance
                                    final distance = Geolocator.distanceBetween(
                                      position.latitude,
                                      position.longitude,
                                      zhetysayLat,
                                      zhetysayLng,
                                    );

                                    if (distance > maxDistanceMeters) {
                                      // Outside Zone - Allow Manual Entry
                                      setState(() {
                                        _isOutsideZone =
                                            true; // Just for warning UI
                                        _isLocationDetermined = true;
                                        _allowManualEntry = true;
                                        isLoading = false;
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Вы находитесь далеко от центра. Пожалуйста, введите адрес вручную.",
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                      }
                                      return;
                                    }

                                    // 4. Inside Zone - Get Address
                                    try {
                                      final placemarks =
                                          await placemarkFromCoordinates(
                                            position.latitude,
                                            position.longitude,
                                          );
                                      if (placemarks.isNotEmpty) {
                                        final place = placemarks.first;
                                        final address =
                                            "${place.street}, ${place.name}";
                                        addressController.text = address;

                                        // Save to profile immediately
                                        if (user != null) {
                                          await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(user.uid)
                                              .update({'address': address});
                                        }
                                      } else {
                                        addressController.text =
                                            "${position.latitude}, ${position.longitude}";
                                      }
                                    } catch (e) {
                                      // Fallback to coords if geocoding fails
                                      addressController.text =
                                          "${position.latitude}, ${position.longitude}";
                                    }

                                    setState(() {
                                      _isOutsideZone = false;
                                      _isLocationDetermined = true;
                                      _allowManualEntry = false;
                                      isLoading = false;
                                    });
                                  } catch (e) {
                                    setState(() => isLoading = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text("Error: $e")),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.gps_fixed),
                                label: const Text("Определить адрес (GPS)"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            )
                          else
                            // Allow manual edit if partner OR _allowManualEntry (outside zone)
                            TextFormField(
                              controller: addressController,
                              enabled:
                                  !isLoading &&
                                  (userRole == 'partner' || _allowManualEntry),
                              decoration: _inputDecoration(
                                text.checkoutAddress,
                                Icons.location_on,
                              ),
                              validator: (value) => value?.isEmpty ?? true
                                  ? text.checkoutAddressError
                                  : null,
                              onChanged: (value) => setState(() {}),
                            ),
                          if (_isOutsideZone)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                "Вы находитесь за пределами стандартной зоны. Уточните адрес вручную.",
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                        if (deliveryType == 'pickup')
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(
                                16,
                              ), // Круглые углы!
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Адрес самовывоза:\nЖетысай, beket ata 73',
                                    style: TextStyle(
                                      color: Colors.blue[900],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Delivery Time Selection (only for delivery)
                        // Delivery Time Selection (only for delivery AND partners)
                        if (deliveryType == 'delivery' &&
                            (userRole == 'partner' || userRole == 'admin')) ...[
                          const Text(
                            "Время доставки:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text("Выберите время"),
                                value: selectedDeliveryTime,
                                items:
                                    [
                                      '08:00 - 10:00',
                                      '10:00 - 12:00',
                                      '12:00 - 14:00',
                                      '14:00 - 16:00',
                                      '16:00 - 18:00',
                                      '18:00 - 20:00',
                                    ].map((time) {
                                      return DropdownMenuItem(
                                        value: time,
                                        child: Text(time),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedDeliveryTime = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Comment Field
                        TextFormField(
                          controller: commentController,
                          enabled: !isLoading,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: "Комментарий к заказу",
                            hintText:
                                "Например: позвоните за 30 минут до доставки",
                            prefixIcon: const Icon(Icons.comment),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Payment Method Selection
                        const Text(
                          "Способ оплаты:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: [
                            // Show 'paid' option for delivery OR if client (pickup triggers this too)
                            // Basically, if Client => Always show 'paid' (which means "Pay on Receipt")
                            // If Partner => Show 'paid' (Pay on Delivery) only if delivery?
                            // Let's simplify: Show 'paid' for EVERYONE, but maybe styled differently?
                            // Actually, Partners usually use Debt.
                            // But Clients MUST use 'paid'.
                            if (userRole == 'client' ||
                                deliveryType == 'delivery')
                              _PaymentMethodTile(
                                title: deliveryType == 'pickup'
                                    ? "При самовывозе"
                                    : "При получении",
                                subtitle: "Оплата полной суммы",
                                icon: Icons.payments,
                                value: 'paid',
                                groupValue: paymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    paymentMethod = value!;
                                    paidAmountController.clear();
                                  });
                                },
                              ),
                            if (deliveryType == 'delivery')
                              const SizedBox(height: 8),
                            if (userRole == 'partner' ||
                                userRole == 'admin') ...[
                              _PaymentMethodTile(
                                title: "В долг",
                                subtitle: "Оплата позже",
                                icon: Icons.schedule,
                                value: 'debt',
                                groupValue: paymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    paymentMethod = value!;
                                    paidAmountController.clear();
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              _PaymentMethodTile(
                                title: "Смешанный",
                                subtitle: "Частичная оплата",
                                icon: Icons.account_balance_wallet,
                                value: 'mixed',
                                groupValue: paymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    paymentMethod = value!;
                                  });
                                },
                              ),
                            ],
                          ],
                        ),

                        if (paymentMethod == 'mixed') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: paidAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Сумма к оплате сейчас",
                              hintText: "Введите сумму",
                              prefixIcon: const Icon(Icons.attach_money),
                              suffixText: "₸",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              helperText:
                                  "Максимум: ${CurrencyFormatter.format(cart.totalAmount)} ₸",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Введите сумму";
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return "Неверная сумма";
                              }
                              if (amount > cart.totalAmount) {
                                return "Сумма превышает общую стоимость";
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                isLoading ||
                                    (deliveryType == 'delivery' &&
                                        addressController.text.isEmpty)
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      setState(() => isLoading = true);

                                      try {
                                        final orderService = OrderService();

                                        // Calculate payment amounts
                                        double paidAmount = 0;
                                        double debtAmount = 0;
                                        String paymentStatus = 'paid';

                                        if (paymentMethod == 'paid') {
                                          paidAmount = 0;
                                          debtAmount = 0;
                                          paymentStatus = 'unpaid';
                                        } else if (paymentMethod == 'debt') {
                                          paidAmount = 0;
                                          debtAmount = cart.totalAmount;
                                          paymentStatus = 'unpaid';
                                        } else if (paymentMethod == 'mixed') {
                                          paidAmount = double.parse(
                                            paidAmountController.text,
                                          );
                                          debtAmount =
                                              cart.totalAmount - paidAmount;
                                          paymentStatus = 'partial';
                                        }

                                        final order = OrderModel(
                                          id: '',
                                          userId: user?.uid,
                                          userName: nameController.text,
                                          userPhone: phoneController.text,
                                          userAddress: deliveryType == 'pickup'
                                              ? 'Самовывоз: Жетысай, beket ata 73'
                                              : addressController.text,
                                          items: cart.items
                                              .map(
                                                (item) => {
                                                  'productId': item.product.id,
                                                  'name': item.product.name,
                                                  'quantity': item.quantity,
                                                  'price': item.product.price,
                                                  'imageUrl':
                                                      item.product.imageUrl,
                                                },
                                              )
                                              .toList(),
                                          returnItems: cart.returnItems
                                              .map((item) => item.toMap())
                                              .toList(),
                                          totalAmount: cart.totalAmount,
                                          refundAmount: cart.totalReturnAmount,
                                          status: 'new',
                                          deliveryType: deliveryType,
                                          createdAt: DateTime.now(),
                                          paymentStatus: paymentStatus,
                                          paidAmount: paidAmount,
                                          debtAmount: debtAmount,
                                          deliveryTime: selectedDeliveryTime,
                                          comment:
                                              commentController.text.isNotEmpty
                                              ? commentController.text
                                              : null,
                                          // Set isPendingApproval to true if partner is ordering on debt
                                          isPendingApproval:
                                              (paymentMethod == 'debt' ||
                                                  paymentMethod == 'mixed') &&
                                              debtAmount > 0,
                                        );

                                        final orderId = await orderService
                                            .createOrder(order);
                                        cart.clearCart();

                                        final updatedOrder = order.copyWith(
                                          id: orderId,
                                        );

                                        if (context.mounted) {
                                          context
                                              .pop(); // Close checkout dialog

                                          // Navigate to Success Screen
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OrderSuccessScreen(
                                                    order: updatedOrder,
                                                    userRole: userRole,
                                                  ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          setState(() => isLoading = false);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: $e"),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  20,
                                ), // Круглые углы!
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    text.checkoutConfirm,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

InputDecoration _inputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Colors.grey),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16), // Круглые углы!
      borderSide: BorderSide(color: Colors.grey[200]!),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16), // Круглые углы!
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
  );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _QtyBtn({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12), // Круглые углы!
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 18,
          color: isActive ? AppColors.primary : Colors.grey,
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _PaymentMethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
