import 'package:flutter/material.dart';
import 'package:motorent/models/welcome_screen_config.dart';
import 'package:motorent/pages/RegisterPage.dart';
import 'package:motorent/widgets/auth/auth_shell.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class WelcomePage extends StatelessWidget {
  final WelcomeScreenConfig config;

  const WelcomePage({
    super.key,
    required this.config,
  });

  void _openRegister(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AuthTheme.screenBackground(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    children: [
                      const AuthBrandHeader(logoHeight: 160),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: const [
                            BoxShadow(
                              color: AuthTheme.cardShadow,
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              config.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AuthTheme.textDark,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              config.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 15,
                                color: AuthTheme.textMuted,
                                height: 1.7,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'مميزات الانضمام الآن',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AuthTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...config.features.map(
                              (feature) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF16A34A),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        feature,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 14,
                                          color: AuthTheme.textDark,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: AuthPrimaryButton(
                  label: config.buttonText,
                  trailingIcon: Icons.arrow_back,
                  onPressed: () => _openRegister(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
