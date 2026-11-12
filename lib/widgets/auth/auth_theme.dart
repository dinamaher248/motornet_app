import 'package:flutter/material.dart';

class AuthTheme {
  static const Color primary = Color(0xFFFF8C00);
  static const Color primaryDark = Color(0xFFE67A00);
  static const Color textDark = Color(0xFF1A242F);
  static const Color textMuted = Color(0xFF8A93A0);
  static const Color fieldBorder = Color(0xFFE6E8EC);
  static const Color cardShadow = Color(0x1A000000);
  static const Color creamBg = Color(0xFFFFF9F2);
  static const Color skyline = Color(0xFFEDE6DC);

  static BoxDecoration screenBackground() {
    return const BoxDecoration(
      color: creamBg,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFF9F2),
          Color(0xFFFFFBF7),
          Color(0xFFFFF9F2),
        ],
      ),
    );
  }
}
