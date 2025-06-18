// ─────────────────────────────────────────────────────────────────────────────
// File    : lib/screens/login_screen.dart
// Purpose : Implements the employee login user interface and logic.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../services/auth_service.dart';
import '../utils/app_styles.dart';

/// The screen where employees enter their credentials to access the application.
/// It features an initial logo animation followed by the login form.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Manages the state and animations for the [LoginScreen].
class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  /* ============================================================================
   * 1. Properties & State Variables
   * ========================================================================== */

  // --- Controllers & Keys ---
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // --- Animation State ---
  bool _showInitialLogoPhase = true; // Controls the transition from logo screen to form.
  late AnimationController _initialLogoController;
  late Animation<double> _initialLogoAnimation;
  late AnimationController _loginFormElementsController;
  late Animation<double> _loginFormLogoScaleAnimation;
  late Animation<double> _loginFormElementsOpacity;

  // --- UI & Loading State ---
  bool _isLoginButtonPressed = false; // For visual feedback on button press.
  bool _isLoading = false; // Shows a spinner during the login API call.
  final Color textFieldBackgroundColor = const Color(0xFFEAE8E8);

  /* ============================================================================
   * 2. Lifecycle Methods
   * ========================================================================== */

  @override
  void initState() {
    super.initState();

    // Setup for the initial full-screen logo animation (elastic bounce).
    _initialLogoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initialLogoAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_initialLogoController);

    // Setup for the login form elements appearing (fade-in and scale).
    _loginFormElementsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loginFormLogoScaleAnimation = Tween<double>(begin: 0.9, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_loginFormElementsController);
    _loginFormElementsOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _loginFormElementsController, curve: Curves.easeIn));

    // Orchestrate the animation sequence.
    _initialLogoController.forward();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // After 1 second, reverse the logo animation.
        _initialLogoController.reverse().whenComplete(() {
          if(mounted) {
            // Once reversed, switch to the login form and play its entrance animation.
            setState(() => _showInitialLogoPhase = false);
            _loginFormElementsController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // Clean up all controllers to prevent memory leaks.
    _usernameController.dispose();
    _passwordController.dispose();
    _initialLogoController.dispose();
    _loginFormElementsController.dispose();
    super.dispose();
  }

  /* ============================================================================
   * 3. Core Logic
   * ========================================================================== */

  /// Handles the user login process.
  Future<void> _handleLogin() async {
    // Prevent multiple login attempts while one is in progress.
    if (_isLoading) return;
    // Validate the form fields (e.g., check if they are empty).
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final String usernameValue = _usernameController.text.trim();
    final String passwordValue = _passwordController.text.trim();

    print("LOGIN SCREEN: Attempting login with username: $usernameValue");

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final loginResponse = await AuthService.login(usernameValue, passwordValue);

      if (mounted) {
        final user = loginResponse['user'] as Map<String, dynamic>?;

        if (user != null && user['role'] == 'employee') {
          // Successful employee login.
          Fluttertoast.showToast(
            msg: loginResponse['message'] as String? ?? 'Login successful!',
            backgroundColor: AppColors.success,
            textColor: Colors.white,
          );
          Navigator.pushReplacementNamed(context, '/homescreen');
        } else if (user != null && user['role'] == 'admin') {
          // Admin tried to log in to the employee app.
          await AuthService.logout(); // Log them out immediately.
          Fluttertoast.showToast(
            msg: 'Admin access is via the web panel.',
            backgroundColor: AppColors.warning,
            textColor: Colors.black87,
            toastLength: Toast.LENGTH_LONG,
          );
        } else {
          // Role is invalid or missing.
          await AuthService.logout();
          Fluttertoast.showToast(
            msg: 'Your user role is not permitted here or role is missing.',
            backgroundColor: AppColors.error,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_LONG,
          );
        }
      }
    } catch (e) {
      // Handle exceptions from the AuthService (e.g., network errors, wrong credentials).
      if (mounted) {
        Fluttertoast.showToast(
          msg: e.toString().replaceFirst("Exception: ", ""), // Clean up error message.
          backgroundColor: AppColors.error,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_LONG,
        );
      }
    } finally {
      // Ensure the loading state is reset, regardless of success or failure.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /* ============================================================================
   * 4. Build Method & UI Widgets
   * ========================================================================== */

  @override
  Widget build(BuildContext context) {
    // GestureDetector allows dismissing the keyboard by tapping anywhere on the screen.
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: Center(
          // Conditionally build either the initial logo or the login form.
          child: _showInitialLogoPhase
              ? _buildInitialLogoScreen(context)
              : _buildLoginUI(context),
        ),
      ),
    );
  }

  /// Builds the initial full-screen logo display with its animation.
  Widget _buildInitialLogoScreen(BuildContext context) {
    return AnimatedOpacity(
      opacity: _initialLogoController.status == AnimationStatus.forward || _showInitialLogoPhase ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: ScaleTransition(
        scale: _initialLogoAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hero widget enables a smooth transition of the logo to the login form.
            Hero(
              tag: "appLogo",
              child: Image.asset('assets/logo.png', width: 180, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main login interface with text fields and a login button.
  Widget _buildLoginUI(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400; // For responsive UI adjustments.
    const double commonBorderRadius = 25.0; // Standardize border radius.

    return FadeTransition(
      opacity: _loginFormElementsOpacity,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 30 : screenWidth * 0.1, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + (isSmallScreen ? 20 : 40)),
              ScaleTransition(
                scale: _loginFormLogoScaleAnimation,
                child: Hero(
                  tag: "appLogo",
                  child: Image.asset(
                    "assets/logo.png",
                    width: screenWidth * (isSmallScreen ? 0.28 : 0.22),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                'Employee Login',
                style: AppTextStyles.poppins(
                    isSmallScreen ? 22 : 26, AppColors.primaryBlue, FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Access your account',
                style: AppTextStyles.poppins(
                    isSmallScreen ? 14 : 15, AppColors.primaryBlue.withOpacity(0.7), FontWeight.normal),
              ),
              const SizedBox(height: 35),
              _buildStyledFormField(
                context: context,
                controller: _usernameController,
                hintText: 'Username or email',
                textInputAction: TextInputAction.next,
                borderRadiusValue: commonBorderRadius,
              ),
              const SizedBox(height: 20),
              _buildStyledFormField(
                context: context,
                controller: _passwordController,
                hintText: 'Password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (value) => _handleLogin(),
                borderRadiusValue: commonBorderRadius,
              ),
              const SizedBox(height: 35),
              // The main login button with tap feedback and loading indicator.
              ScaleTransition(
                scale: _loginFormLogoScaleAnimation,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isLoginButtonPressed = true),
                  onTapUp: (_) => setState(() => _isLoginButtonPressed = false),
                  onTapCancel: () => setState(() => _isLoginButtonPressed = false),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _handleLogin();
                  },
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 100),
                    opacity: _isLoginButtonPressed ? 0.85 : 1.0,
                    child: Container(
                      width: screenWidth * (isSmallScreen ? 0.8 : 0.65),
                      constraints: const BoxConstraints(maxWidth: 350),
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(commonBorderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                        'Login',
                        style: AppTextStyles.poppins(
                            isSmallScreen ? 16 : 18, Colors.white, FontWeight.w600, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isSmallScreen ? 20 : 30),
            ],
          ),
        ),
      ),
    );
  }

  /// A reusable widget factory for creating styled text form fields.
  Widget _buildStyledFormField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    required double borderRadiusValue,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 400;

    return Container(
      width: screenWidth * (isSmallScreen ? 0.8 : 0.65),
      constraints: const BoxConstraints(maxWidth: 350),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        style: AppTextStyles.poppins(
          isSmallScreen ? 15 : 16,
          AppColors.primaryBlue.withOpacity(0.9),
          FontWeight.normal,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.poppins(
            isSmallScreen ? 14 : 15,
            AppColors.primaryBlue.withOpacity(0.5),
            FontWeight.normal,
          ),
          filled: true,
          fillColor: textFieldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusValue),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusValue),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusValue),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
        // Validator function to ensure the field is not empty.
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$hintText is required.';
          }
          return null;
        },
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────