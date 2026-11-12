import 'package:flutter/material.dart';
import 'package:motorent/data/remote/url_api.dart';

class StorageNetworkAvatar extends StatelessWidget {
  final String? imagePath;
  final String initial;
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const StorageNetworkAvatar({
    super.key,
    required this.imagePath,
    required this.initial,
    this.size = 52,
    this.backgroundColor = const Color(0x26FFFFFF),
    this.textColor = Colors.white,
    this.fontSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveStorageImageUrl(imagePath);
    if (imageUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitial(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: size,
              height: size,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildInitial();
  }

  Widget _buildInitial() {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor,
      child: Text(
        initial.isNotEmpty ? initial : '?',
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
