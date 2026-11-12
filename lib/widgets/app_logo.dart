import 'package:flutter/material.dart';
import 'package:motorent/constants/app_assets.dart';
import 'package:motorent/constants/app_brand.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final bool showName;

  const AppLogo({
    super.key,
    this.height = 52,
    this.showName = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppAssets.appIcon,
          height: height,
          fit: BoxFit.contain,
        ),
        if (showName) ...[
          const SizedBox(width: 8),
          Text(
            AppBrand.name,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: height * 0.38,
              fontWeight: FontWeight.w800,
              color: AuthTheme.textDark,
            ),
          ),
        ],
      ],
    );
  }
}
