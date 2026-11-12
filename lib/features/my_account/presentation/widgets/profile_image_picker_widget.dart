import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/storage_network_avatar.dart';

class ProfileImagePickerWidget extends StatelessWidget {
  final String? networkImagePath;
  final File? localImage;
  final ValueChanged<File> onImagePicked;
  final bool enabled;

  const ProfileImagePickerWidget({
    super.key,
    required this.networkImagePath,
    required this.localImage,
    required this.onImagePicked,
    this.enabled = true,
  });

  Future<void> _pick(BuildContext context) async {
    if (!enabled) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار من المعرض'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('التقاط صورة'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;
    onImagePicked(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final initial = 'م';

    return Center(
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _pick(context),
            child: localImage != null
                ? ClipOval(
                    child: Image.file(
                      localImage!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  )
                : StorageNetworkAvatar(
                    imagePath: networkImagePath,
                    initial: initial,
                    size: 110,
                    backgroundColor: AuthTheme.primary.withValues(alpha: 0.15),
                    textColor: AuthTheme.primaryDark,
                    fontSize: 40,
                  ),
          ),
          Positioned(
            bottom: 2,
            left: 2,
            child: Material(
              color: AuthTheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _pick(context),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper kept for potential preview URL building.
String? profileImagePreviewUrl(String? path) {
  final url = resolveStorageImageUrl(path);
  return url.isEmpty ? null : url;
}
