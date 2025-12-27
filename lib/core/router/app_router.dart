import 'package:go_router/go_router.dart';
import 'package:ailin_tattileri_app/features/client/welcome/welcome_screen.dart';
import 'package:ailin_tattileri_app/core/models/product_model.dart';
import 'package:ailin_tattileri_app/features/client/product_details/product_details_screen.dart';
import 'package:ailin_tattileri_app/features/client/main_screen.dart';
import 'package:ailin_tattileri_app/features/client/cart/cart_screen.dart';
import 'package:ailin_tattileri_app/features/client/cart/return_product_select_screen.dart';
import 'package:ailin_tattileri_app/features/client/orders/client_orders_screen.dart';
import 'package:ailin_tattileri_app/features/client/profile/profile_screen.dart';
import 'package:ailin_tattileri_app/features/client/favorites/favorites_screen.dart';
import 'package:ailin_tattileri_app/features/client/notifications/notifications_screen.dart';
import 'package:ailin_tattileri_app/features/auth/login_screen.dart';
import 'package:ailin_tattileri_app/features/auth/register_screen.dart';
import 'package:ailin_tattileri_app/features/admin/dashboard/admin_dashboard_screen.dart';
import 'package:ailin_tattileri_app/features/admin/admin_main_screen.dart';
import 'package:ailin_tattileri_app/features/admin/orders/admin_orders_screen.dart';
import 'package:ailin_tattileri_app/features/admin/products/admin_products_screen.dart';
import 'package:ailin_tattileri_app/features/admin/categories/admin_categories_screen.dart';
import 'package:ailin_tattileri_app/features/admin/debts/partner_debts_screen.dart';
import 'package:ailin_tattileri_app/features/admin/salary/admin_payments_screen.dart';
import 'package:ailin_tattileri_app/features/admin/advance/admin_advance_screen.dart';
import 'package:ailin_tattileri_app/features/admin/warehouse/warehouse_screen.dart';
import 'package:ailin_tattileri_app/features/admin/expenses/admin_expenses_screen.dart';
import 'package:ailin_tattileri_app/features/admin/analytics/analytics_screen.dart';
import 'package:ailin_tattileri_app/features/admin/products/add_product_screen.dart';
import 'package:ailin_tattileri_app/features/partner/partner_main_screen.dart';
import 'package:ailin_tattileri_app/features/worker/worker_main_screen.dart';
import 'package:ailin_tattileri_app/features/worker/salary/worker_payment_history_screen.dart';
import 'package:ailin_tattileri_app/features/worker/qr_scanner/qr_scanner_screen.dart';
import 'package:ailin_tattileri_app/features/desktop/desktop_main_screen.dart';

import 'package:ailin_tattileri_app/features/splash/splash_screen.dart';

import 'package:flutter/foundation.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (kIsWeb && !state.uri.toString().startsWith('/desktop/home')) {
        return '/desktop/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const ClientMainScreen(),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(
        path: '/cart/select-return-product',
        builder: (context, state) => const ReturnProductSelectScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const ClientOrdersScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/home',
        builder: (context, state) => const AdminMainScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        builder: (context, state) {
          return const AdminOrdersScreen();
        },
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: '/admin/categories',
        builder: (context, state) => const AdminCategoriesScreen(),
      ),
      GoRoute(
        path: '/admin/debts',
        builder: (context, state) => const PartnerDebtsScreen(),
      ),
      GoRoute(
        path: '/admin/payments',
        builder: (context, state) => const AdminPaymentsScreen(),
      ),
      GoRoute(
        path: '/admin/advance',
        builder: (context, state) => const AdminAdvanceScreen(),
      ),
      GoRoute(
        path: '/admin/warehouse',
        builder: (context, state) => const WarehouseScreen(),
      ),
      GoRoute(
        path: '/admin/expenses',
        builder: (context, state) => const AdminExpensesScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/add-product',
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: '/partner/home',
        builder: (context, state) => const PartnerMainScreen(),
      ),
      GoRoute(
        path: '/worker/home',
        builder: (context, state) => const WorkerMainScreen(),
      ),
      GoRoute(
        path: '/product/details',
        builder: (context, state) {
          final product = state.extra as Product;
          return ProductDetailsScreen(product: product);
        },
      ),
      GoRoute(
        path: '/worker/payments',
        builder: (context, state) => const WorkerPaymentHistoryScreen(),
      ),
      GoRoute(
        path: '/worker/qr-scanner',
        builder: (context, state) => const QRScannerScreen(),
      ),
      GoRoute(
        path: '/desktop/home',
        builder: (context, state) => const DesktopMainScreen(),
      ),
    ],
  );
}
