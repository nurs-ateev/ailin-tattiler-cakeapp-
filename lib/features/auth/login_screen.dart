import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ailin_tattileri_app/core/services/auth_service.dart';
import 'package:ailin_tattileri_app/core/services/cart_service.dart';
import 'package:ailin_tattileri_app/core/services/favorites_service.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        // Load user's cart and favorites
        final cartService = Provider.of<CartService>(context, listen: false);
        final favoritesService = Provider.of<FavoritesService>(
          context,
          listen: false,
        );
        final user = _authService.currentUser;
        await cartService.loadCart(user?.uid);
        await favoritesService.loadFavorites(user?.uid);

        // Get user role and navigate accordingly
        if (user != null) {
          final role = await _authService.getUserRole(user.uid);

          if (role == 'admin') {
            // Admin goes to admin home (main screen for admin)
            context.go('/admin/home');
          } else if (role == 'partner') {
            context.go('/partner/home');
          } else if (role == 'worker') {
            context.go('/worker/home');
          } else {
            // Worker, Client go to /home
            context.go('/home');
          }
        } else {
          // Fallback to home
          context.go('/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          switch (e.code) {
            case 'user-not-found':
              _errorMessage = 'Пользователь с таким Email не найден';
              break;
            case 'wrong-password':
              _errorMessage = 'Неверный пароль. Попробуйте еще раз';
              break;
            case 'invalid-email':
              _errorMessage = 'Некорректный формат Email адреса';
              break;
            case 'user-disabled':
              _errorMessage = 'Данный аккаунт заблокирован';
              break;
            case 'invalid-credential':
              _errorMessage = 'Неверный логин или пароль';
              break;
            case 'too-many-requests':
              _errorMessage = 'Слишком много попыток. Попробуйте позже';
              break;
            default:
              _errorMessage =
                  'Ошибка входа: ${e.message ?? 'Неизвестная ошибка'}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Произошла непредвиденная ошибка';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Вход"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Column(
                  children: [
                    Container(
                      height: 120,
                      width: 120,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Transform.scale(
                          scale: 1.5,
                          child: Image.asset(
                            'assets/images/brand_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Tattileri".toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите Email';
                    if (!value.contains('@')) return 'Некорректный Email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Пароль",
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Введите пароль';
                    if (value.length < 6)
                      return 'Пароль должен быть от 6 символов';
                    return null;
                  },
                ),

                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "ВОЙТИ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Register Link
                TextButton(
                  onPressed: () {
                    context.push('/register');
                  },
                  child: const Text("Нет аккаунта? Зарегистрироваться"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
