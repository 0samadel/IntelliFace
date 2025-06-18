// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/login/widgets/login_form_card.dart
// Purpose: A theme-aware login form with professional, high-feedback input fields.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoginFormCard extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController identifierController;
  final TextEditingController passwordController;
  final ValueNotifier<bool> isLoadingNotifier;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;

  const LoginFormCard({
    super.key,
    required this.formKey,
    required this.identifierController,
    required this.passwordController,
    required this.isLoadingNotifier,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onLogin,
    required this.onForgotPassword,
  });

  @override
  State<LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends State<LoginFormCard> {
  bool _isPasswordObscured = true;
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const BorderRadius cardBorderRadius = BorderRadius.all(Radius.circular(16));

    Widget formContent = _buildFormContent(context, isDark: isDark);

    return ClipRRect(
      borderRadius: cardBorderRadius,
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: isDark ? 15 : 0, sigmaY: isDark ? 15 : 0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: isDark
                ? BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.1),
              borderRadius: cardBorderRadius,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.0),
            )
                : BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: cardBorderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: formContent,
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, {required bool isDark}) {
    final theme = Theme.of(context);

    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      color: isDark ? Colors.white : theme.textTheme.headlineSmall?.color,
    );
    final subtitleStyle = theme.textTheme.titleMedium?.copyWith(
      color: isDark ? Colors.white70 : theme.textTheme.bodySmall?.color,
    );

    return SizedBox(
      height: 420, // THE FIX IS HERE: Reduced height for a more compact form.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Admin Portal', textAlign: TextAlign.center, style: titleStyle),
              const SizedBox(height: 8),
              Text('Sign in to manage the system.', textAlign: TextAlign.center, style: subtitleStyle),

              const Spacer(flex: 1), // THE FIX IS HERE: Reduced top spacing

              _buildStyledFormField(
                theme: theme,
                isDark: isDark,
                controller: widget.identifierController,
                labelText: 'Username or Email',
                prefixIcon: LucideIcons.user,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
              ),
              const SizedBox(height: 16), // Reduced space between fields
              _buildStyledFormField(
                theme: theme,
                isDark: isDark,
                controller: widget.passwordController,
                focusNode: _passwordFocusNode,
                labelText: 'Password',
                prefixIcon: LucideIcons.lock,
                obscureText: _isPasswordObscured,
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordObscured ? LucideIcons.eyeOff : LucideIcons.eye),
                  onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => widget.onLogin(),
              ),
              const SizedBox(height: 16),
              _buildOptionsRow(theme, isDark),

              const Spacer(flex: 1), // Reduced bottom spacing

              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW, PROFESSIONAL FORM FIELD BUILDER ---
  Widget _buildStyledFormField({
    required ThemeData theme,
    required bool isDark,
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    FocusNode? focusNode,
    bool obscureText = false,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
  }) {
    final inputStyle = theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white : null);

    // In dark mode, fill with a darker, semi-transparent color for the glass effect.
    final fillColor = isDark ? Colors.black.withOpacity(0.2) : theme.inputDecorationTheme.fillColor;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      style: inputStyle,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        // The global theme handles most styles, but we can override for dark mode
        labelStyle: TextStyle(color: isDark ? Colors.white70 : null),
        floatingLabelStyle: TextStyle(color: theme.colorScheme.primary), // Always accent color when focused
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // No border when not focused
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? '$labelText is required' : null,
    );
  }

  // --- Other helper methods remain the same ---
  Widget _buildOptionsRow(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: CheckboxListTile(
            value: widget.rememberMe, onChanged: widget.onRememberMeChanged,
            title: Text('Remember me', style: theme.textTheme.bodyMedium?.copyWith(color: isDark ? Colors.white70 : null)),
            controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero,
            activeColor: theme.colorScheme.primary, checkColor: isDark ? Colors.black : theme.colorScheme.onPrimary, dense: true,
          ),
        ),
        TextButton(onPressed: widget.onForgotPassword, child: const Text('Forgot password?')),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isLoadingNotifier,
      builder: (context, isLoading, child) {
        return SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : widget.onLogin,
            icon: isLoading
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Theme.of(context).colorScheme.onPrimary))
                : const Icon(LucideIcons.arrowRight, size: 20),
            label: const Text('Sign In Securely'),
          ),
        );
      },
    );
  }
}