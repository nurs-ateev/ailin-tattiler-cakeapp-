import 'package:ailin_tattileri_app/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoRevealAnimation;
  late Animation<double> _textOpacityAnimation;
  late Future<String?> _roleFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Faster 0.8s animation
    );

    // Reveal logo from left to right
    _logoRevealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    // Fade in text
    _textOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Start fetching data IMMEDIATELY
    _roleFuture = _fetchUserRole();

    // Wait for both animation and data
    _navigateToNext();
  }

  Future<String?> _fetchUserRole() async {
    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null) {
      // Use a timeout to prevent hanging forever if network is bad
      return authService
          .getUserRole(user.uid)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => null, // Default to client/null on timeout
          );
    }
    return null;
  }

  Future<void> _navigateToNext() async {
    // Wait for the animation to be visually pleasing (1.5s min)
    // AND for the data to be ready.
    // If data is fast, we wait 1.5s. If data is slow (up to 5s), we wait for data.
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 500)),
      _roleFuture,
    ]);

    if (!mounted) return;

    final authService = AuthService();
    final user = authService.currentUser;

    if (user == null) {
      context.go('/welcome');
    } else {
      final role = await _roleFuture;
      if (!mounted) return;

      // DEBUG: Force desktop for web to see if it works
      if (kIsWeb) {
        context.go('/desktop/home');
        return;
      }

      if (role == 'admin') {
        bool isDesktop = false;
        if (kIsWeb) {
          isDesktop = true;
        } else {
          if (defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux) {
            isDesktop = true;
          }
        }

        if (isDesktop) {
          context.go('/desktop/home');
        } else {
          context.go('/admin/home');
        }
      } else if (role == 'partner') {
        context.go('/partner/home');
      } else if (role == 'worker') {
        context.go('/worker/home');
      } else {
        // Workers and Clients go to /home.
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Container
                Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A), // and premium dark bg
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: _logoRevealAnimation.value,
                          child: ClipOval(
                            child: Transform.scale(
                              scale: 1.5,
                              child: Image.asset(
                                'assets/images/brand_logo.png',
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // TATTILERI Text
                Opacity(
                  opacity: _textOpacityAnimation.value,
                  child: Text(
                    "TATTILERI",
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8, // Wide spacing for premium look
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
