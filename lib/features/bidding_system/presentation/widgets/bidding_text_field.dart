import 'package:flutter/material.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class BiddingTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool requiredField;
  final int maxLines;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;

  const BiddingTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.requiredField = true,
    this.maxLines = 1,
    this.keyboardType,
    this.suffix,
    this.validator,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            color: AuthTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AuthTheme.fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AuthTheme.primary, width: 1.4),
            ),
          ),
          validator: validator ??
              (value) {
                if (!requiredField) return null;
                if (value == null || value.trim().isEmpty) {
                  return 'برجاء إدخال $label';
                }
                return null;
              },
        ),
      ],
    );
  }
}
