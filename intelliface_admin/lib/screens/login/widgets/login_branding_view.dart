// ─────────────────────────────────────────────────────────────────────────────
// File   : lib/screens/login/widgets/login_branding_view.dart
// Purpose: Displays branding using the dedicated LoginTextStyles.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../../../utils/app_styles.dart';

class LoginBrandingView extends StatelessWidget {
  const LoginBrandingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          'assets/logo_white.png',
          width: 220,
        ),

        const SizedBox(height: 48),

        Text(
          'Intelligent Attendance\nAdmin Panel',
          style: LoginTextStyles.screenTitle,
        ),
        const SizedBox(height: 24),

        Text(
          'Manage your workforce efficiently with our advanced attendance system. Secure, reliable, and powerful.',
          style: LoginTextStyles.screenSubtitle,
        ),
      ],
    );
  }
}