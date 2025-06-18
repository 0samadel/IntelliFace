// ────────────────────────────────────────────────────────────
// File    : lib/screens/login/login_screen.dart
// Purpose : Ultra-modernist login screen with theme selection options.
// ────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'widgets/animated_aurora_background.dart';
import 'widgets/login_branding_view.dart';
import 'widgets/login_form_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  bool _rememberMe = true;

  late AnimationController _animationController;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _contentSlideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart));
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _isLoadingNotifier.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoadingNotifier.value || !(_formKey.currentState?.validate() ?? false)) return;
    _isLoadingNotifier.value = true;
    try {
      final response = await AuthService.login(_identifierController.text.trim(), _passwordController.text.trim());
      final user = response['user'] as Map<String, dynamic>?;
      if (user?['role'] == 'admin') {
        _showSnackBar("Welcome back, Admin!", isError: false);
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
        }
      } else {
        await AuthService.logout();
        _showSnackBar(user?['role'] == 'employee' ? 'Access denied. This portal is for Admins only.' : 'Invalid credentials or user role.');
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) _isLoadingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0b0c10),
      body: Stack(
        children: [
          const AnimatedAuroraBackground(),

          // THEME SWITCH BUTTON IN THE CORNER
          const Positioned(
            top: 16,
            right: 16,
            child: _LoginThemeSwitcher(),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWideScreen = constraints.maxWidth >= 1000;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: SlideTransition(
                    position: _contentSlideAnimation,
                    child: FadeTransition(
                      opacity: _contentFadeAnimation,
                      child: isWideScreen ? _buildWideLayout() : _buildNarrowLayout(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Flexible(flex: 6, child: Padding(padding: EdgeInsets.only(right: 60.0), child: LoginBrandingView())),
          Flexible(flex: 4, child: _buildForm()),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const LoginBrandingView(),
        const SizedBox(height: 48),
        Center(child: _buildForm()),
      ],
    );
  }

  Widget _buildForm() {
    return LoginFormCard(
      formKey: _formKey,
      identifierController: _identifierController,
      passwordController: _passwordController,
      isLoadingNotifier: _isLoadingNotifier,
      rememberMe: _rememberMe,
      onRememberMeChanged: (val) => setState(() => _rememberMe = val ?? false),
      onLogin: _handleLogin,
      onForgotPassword: () => _showSnackBar('Forgot Password feature is not yet implemented.', isError: false),
    );
  }
}

// A new private widget specifically for the login screen's theme switcher
class _LoginThemeSwitcher extends StatelessWidget {
  const _LoginThemeSwitcher();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isCurrentlyDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<ThemePreference>(
      onSelected: (ThemePreference preference) {
        Provider.of<ThemeProvider>(context, listen: false).setTheme(preference);
      },
      tooltip: 'Change Theme',
      color: Colors.black.withOpacity(0.5), // Semi-transparent background
      icon: Icon(
        isCurrentlyDark ? LucideIcons.moon : LucideIcons.sun,
        color: Colors.white,
        size: 22,
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemePreference>>[
        _buildThemeMenuItem(
          preference: ThemePreference.light,
          icon: LucideIcons.sun,
          text: 'Light',
          currentPreference: themeProvider.themePreference,
        ),
        _buildThemeMenuItem(
          preference: ThemePreference.dark,
          icon: LucideIcons.moon,
          text: 'Dark',
          currentPreference: themeProvider.themePreference,
        ),
        const PopupMenuDivider(color: Colors.white30),
        _buildThemeMenuItem(
          preference: ThemePreference.system,
          icon: LucideIcons.laptop,
          text: 'System',
          currentPreference: themeProvider.themePreference,
        ),
      ],
    );
  }

  PopupMenuItem<ThemePreference> _buildThemeMenuItem({
    required ThemePreference preference,
    required IconData icon,
    required String text,
    required ThemePreference currentPreference,
  }) {
    final bool isSelected = preference == currentPreference;
    final color = isSelected ? Colors.cyanAccent : Colors.white;

    return PopupMenuItem<ThemePreference>(
      value: preference,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}