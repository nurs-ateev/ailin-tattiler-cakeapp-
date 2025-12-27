import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ailin_tattileri_app/core/services/language_service.dart';
import 'package:ailin_tattileri_app/core/theme/app_colors.dart';
import 'package:ailin_tattileri_app/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ailin_tattileri_app/core/services/auth_service.dart';
import 'package:ailin_tattileri_app/core/providers/theme_provider.dart';
import 'package:ailin_tattileri_app/core/services/chat_service.dart';
import 'package:ailin_tattileri_app/features/common/chat/chat_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final languageService = Provider.of<LanguageService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = AuthService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final isLoggedIn = user != null;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(text.menuProfile),
            centerTitle: false,
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: isLoggedIn ? AppColors.primary : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name / Email
                  if (isLoggedIn)
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        final userData =
                            userSnapshot.data?.data() as Map<String, dynamic>?;
                        final displayName =
                            userData?['fullName'] ??
                            user.displayName ??
                            user.email ??
                            text.guestUser;
                        final phoneNumber =
                            userData?['phone'] ?? user.phoneNumber;
                        return Column(
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (phoneNumber != null)
                              Text(
                                phoneNumber,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        );
                      },
                    )
                  else
                    Text(
                      text.homeGreeting,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Personal Data Link
                  if (isLoggedIn) ...[
                    _buildSection(
                      context,
                      title: text.profileMySection,
                      children: [
                        _buildListTile(
                          context,
                          icon: Icons.person_outline,
                          title: text.profilePersonalData,
                          subtitle: text.profilePersonalSubtitle,
                          onTap: () => context.push('/profile/personal-data'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Support Section (Chat with Admin)
                  if (isLoggedIn) ...[
                    _buildSection(
                      context,
                      title: "Помощь и поддержка",
                      children: [
                        _buildListTile(
                          context,
                          icon: Icons.support_agent,
                          title: "Написать в поддержку",
                          subtitle: "Свяжитесь с администратором",
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () async {
                            final chatService = ChatService();
                            final roomId = await chatService.getChatRoomId(
                              user.uid,
                              'admin',
                            );

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    roomId: roomId,
                                    chatTitle: "Поддержка",
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Settings Section
                  _buildSection(
                    context,
                    title: text.settingsSection,
                    children: [
                      _buildListTile(
                        context,
                        icon: Icons.language,
                        title: text.settingsLanguage,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LangChip(
                              label: "KZ",
                              isActive:
                                  languageService.currentLocale.languageCode ==
                                  'kk',
                              onTap: () => languageService.switchLanguage('kk'),
                            ),
                            const SizedBox(width: 8),
                            _LangChip(
                              label: "RU",
                              isActive:
                                  languageService.currentLocale.languageCode ==
                                  'ru',
                              onTap: () => languageService.switchLanguage('ru'),
                            ),
                          ],
                        ),
                      ),
                      // Theme Switcher
                      _buildListTile(
                        context,
                        icon: isDark ? Icons.dark_mode : Icons.light_mode,
                        title: text.settingsTheme,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LangChip(
                              label: text.themeLight,
                              isActive:
                                  themeProvider.themeMode == ThemeMode.light,
                              onTap: () =>
                                  themeProvider.setThemeMode(ThemeMode.light),
                            ),
                            const SizedBox(width: 8),
                            const SizedBox(width: 8),
                            _LangChip(
                              label: text.themeDark,
                              isActive:
                                  themeProvider.themeMode == ThemeMode.dark,
                              onTap: () =>
                                  themeProvider.setThemeMode(ThemeMode.dark),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Worker Actions
                  if (isLoggedIn)
                    FutureBuilder<String?>(
                      future: authService.getUserRole(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.data == 'worker') {
                          return Column(
                            children: [
                              _buildSection(
                                context,
                                title: text.workerFinanceSection,
                                children: [
                                  _buildListTile(
                                    context,
                                    icon: Icons.payments_outlined,
                                    title: text.workerPayoutHistory,
                                    onTap: () =>
                                        context.push('/worker/payments'),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                  // Admin Actions - Only for admins
                  if (isLoggedIn)
                    FutureBuilder<String?>(
                      future: authService.getUserRole(user.uid),
                      builder: (context, roleSnapshot) {
                        final userRole = roleSnapshot.data;

                        // Only show admin panel if role is 'admin'
                        if (userRole != 'admin') {
                          return const SizedBox.shrink();
                        }

                        return _buildSection(
                          context,
                          title: text.adminSection,
                          children: [
                            _buildListTile(
                              context,
                              icon: Icons.dashboard,
                              title: text.menuAdmin,
                              onTap: () => context.push('/admin/home'),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                            _buildListTile(
                              context,
                              icon: Icons.add_circle_outline,
                              title: text.menuAddProduct,
                              onTap: () => context.push('/admin/add-product'),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // Auth Button (Login or Logout)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (isLoggedIn) {
                          // Show confirmation dialog
                          final bool? shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(text.logoutDialogTitle),
                              content: Text(text.logoutDialogContent),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(text.dialogNo),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(text.dialogYesLogout),
                                ),
                              ],
                            ),
                          );

                          // If user confirmed, logout (but keep cart)
                          // If user confirmed, logout (but keep cart)
                          if (shouldLogout == true) {
                            await authService.signOut();
                            if (context.mounted) {
                              context.go('/home');
                            }
                          }
                        } else {
                          context.push('/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isLoggedIn
                            ? Colors.red[50]
                            : AppColors.primary,
                        foregroundColor: isLoggedIn ? Colors.red : Colors.white,
                        elevation: isLoggedIn ? 0 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isLoggedIn ? text.logoutButton : text.loginButton,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: theme.textTheme.bodyLarge?.color,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color ?? Colors.grey,
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LangChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
