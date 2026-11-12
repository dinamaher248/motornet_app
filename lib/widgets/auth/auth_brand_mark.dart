import 'package:flutter/material.dart';
import 'package:motorent/constants/app_assets.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class AuthBrandMark extends StatelessWidget {
  final double fontSize;

  const AuthBrandMark({super.key, this.fontSize = 34});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        children: const [
          TextSpan(
            text: 'توصيلة',
            style: TextStyle(color: AuthTheme.textDark),
          ),
          TextSpan(text: ' '),
          TextSpan(
            text: 'برو',
            style: TextStyle(color: AuthTheme.primary),
          ),
        ],
      ),
    );
  }
}

class AuthTaglineRow extends StatelessWidget {
  const AuthTaglineRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Divider(
            color: AuthTheme.primary,
            thickness: 1.2,
            endIndent: 10,
          ),
        ),
        Text(
          'خدمات ونقل وتوصيل',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AuthTheme.textMuted,
          ),
        ),
        Expanded(
          child: Divider(
            color: AuthTheme.primary,
            thickness: 1.2,
            indent: 10,
          ),
        ),
      ],
    );
  }
}

class AuthCourierHero extends StatelessWidget {
  final double height;
  final bool showGlow;

  const AuthCourierHero({
    super.key,
    this.height = 150,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + (showGlow ? 12 : 0),
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showGlow)
            Container(
              width: height * 1.15,
              height: height * 1.15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AuthTheme.primary.withValues(alpha: 0.22),
                    AuthTheme.primary.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(height * 0.18),
            child: Image.asset(
              AppAssets.appIcon,
              height: height,
              width: height,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded register/login-style text field matching the auth mockups.
InputDecoration authFormDecoration({
  required String hint,
  required IconData icon,
  Widget? trailing,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Cairo',
      fontSize: 14,
      color: AuthTheme.textMuted,
    ),
    // RTL: prefix = right side
    prefixIcon: Icon(icon, color: AuthTheme.textMuted, size: 22),
    suffixIcon: trailing,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AuthTheme.fieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AuthTheme.fieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AuthTheme.primary, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
    ),
  );
}
