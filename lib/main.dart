import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:ailin_tattileri_app/core/theme/app_theme.dart';
import 'package:ailin_tattileri_app/firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';
import 'package:ailin_tattileri_app/core/router/app_router.dart';
import 'package:ailin_tattileri_app/core/services/cart_service.dart';
import 'package:ailin_tattileri_app/core/services/language_service.dart';
import 'package:ailin_tattileri_app/core/services/favorites_service.dart';
import 'package:ailin_tattileri_app/core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => FavoritesService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ThemeProvider>(
      builder: (context, languageService, themeProvider, child) {
        return MaterialApp.router(
          title: 'Ailin Tattileri',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: AppRouter.router,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ru'), Locale('kk')],
          locale: languageService.currentLocale,
        );
      },
    );
  }
}
