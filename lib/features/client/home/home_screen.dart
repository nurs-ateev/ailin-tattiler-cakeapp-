import 'package:ailin_tattileri_app/core/models/product_model.dart';
import 'package:ailin_tattileri_app/core/services/product_service.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/core/services/cart_service.dart';
import 'package:ailin_tattileri_app/core/services/favorites_service.dart';
import 'package:ailin_tattileri_app/features/client/home/widgets/product_card.dart';
import 'package:ailin_tattileri_app/features/client/home/widgets/banner_carousel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';
import 'package:ailin_tattileri_app/core/services/category_service.dart';
import 'package:ailin_tattileri_app/core/models/category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategoryId = "all";
  final _productService = ProductService();
  final _categoryService = CategoryService();

  @override
  Widget build(BuildContext context) {
    // Note: We removed the local Drawer and BottomNavBar because
    // this screen will now be a tab inside MainScreen.

    final text = AppLocalizations.of(context)!;
    final cartService = Provider.of<CartService>(context);
    final favoritesService = Provider.of<FavoritesService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Keep AppBar
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      theme.scaffoldBackgroundColor,
                      theme.scaffoldBackgroundColor,
                    ]
                  : [Colors.white, Colors.grey[50]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        elevation: 0,
        title: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.3,
                  child: Image.asset(
                    'assets/images/brand_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.7),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    "Tattileri".toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 2.5,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Notifications
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => context.push('/notifications'),
              icon: Icon(
                Icons.notifications_outlined,
                color: theme.iconTheme.color,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Favorites with gradient badge
          Stack(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => context.push('/favorites'),
                  icon: Icon(
                    Icons.favorite_border,
                    color: theme.iconTheme.color,
                    size: 22,
                  ),
                ),
              ),
              if (favoritesService.count > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.red, Colors.redAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${favoritesService.count}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          // Cart with gradient badge
          Stack(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => context.push('/cart'),
                  icon: Icon(
                    Icons.shopping_cart_outlined,
                    color: theme.iconTheme.color,
                    size: 22,
                  ),
                ),
              ),
              if (cartService.itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${cartService.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      // NO DRAWER
      // NO BOTTOM NAVIGATION BAR
      body: SafeArea(
        child: StreamBuilder<List<CategoryModel>>(
          stream: _categoryService.getCategories(),
          builder: (context, categorySnapshot) {
            final categories = categorySnapshot.data ?? [];
            final isKazakh =
                Localizations.localeOf(context).languageCode == 'kk';

            final categoryMap = {
              for (var c in categories) c.id: (isKazakh ? c.nameKk : c.nameRu),
            };

            return StreamBuilder<List<Product>>(
              stream: _productService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  // !hasData to avoid flickering if we have cached data
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data ?? [];
                final filteredProducts = products.where((p) {
                  return _selectedCategoryId == "all" ||
                      p.category == _selectedCategoryId;
                }).toList();

                return CustomScrollView(
                  slivers: [
                    // 1. Marketing Banner with Carousel
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 8),
                        child: BannerCarousel(),
                      ),
                    ),

                    // 2. Categories (Chips)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 50,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories.length + 1,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              // "All" Chip
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedCategoryId = "all"),
                                child: _buildCategoryChip(
                                  context,
                                  "🔥 ${text.categoryAll}",
                                  _selectedCategoryId == "all",
                                ),
                              );
                            }
                            final c = categories[index - 1];
                            final name = isKazakh ? c.nameKk : c.nameRu;
                            final icon = c.icon;

                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCategoryId = c.id),
                              child: _buildCategoryChip(
                                context,
                                "$icon $name",
                                _selectedCategoryId == c.id,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // 3. Product List Title
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          text.homeQuestion, // Using "What do you want to order?" as title
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // 4. Products List
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: filteredProducts.isEmpty
                          ? SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.cookie_outlined,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        text.cartEmpty, // Reusing empty string or similar -> "Пусто"
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 0.72,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final p = filteredProducts[index];
                                final cName = categoryMap[p.category];
                                return ProductCard(
                                  product: p,
                                  localizedCategory: cName,
                                  onTap: () {
                                    context.push('/product/details', extra: p);
                                  },
                                );
                              }, childCount: filteredProducts.length),
                            ),
                    ),

                    // Safe area padding
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppColors.primary
              : Theme.of(context).dividerColor.withOpacity(0.1),
          width: isActive ? 0 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: -3,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isActive
                ? Colors.white
                : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
