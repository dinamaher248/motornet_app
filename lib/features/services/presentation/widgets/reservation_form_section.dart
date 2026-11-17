import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motorent/features/services/domain/entities/reservation_entities.dart';
import 'package:motorent/features/services/presentation/cubit/reservation_cubits.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

/// نموذج الحجز الديناميكي: يجلب الحقول من
/// `GET /reservations/categories/{id}/fields` ويرسل الاستفسار بزر
/// «إرسال لمعرفة السعر والتفاصيل» بدل الدفع المباشر.
class ReservationFormSection extends StatelessWidget {
  final int merchantId;
  final int categoryId;
  final ValueChanged<String> onSubmitted;

  const ReservationFormSection({
    super.key,
    required this.merchantId,
    required this.categoryId,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReservationFormCubit()..load(categoryId),
      child: _ReservationFormView(
        merchantId: merchantId,
        categoryId: categoryId,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class _ReservationFormView extends StatefulWidget {
  final int merchantId;
  final int categoryId;
  final ValueChanged<String> onSubmitted;

  const _ReservationFormView({
    required this.merchantId,
    required this.categoryId,
    required this.onSubmitted,
  });

  @override
  State<_ReservationFormView> createState() => _ReservationFormViewState();
}

class _ReservationFormViewState extends State<_ReservationFormView> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, String> _choices = {};
  final Map<int, String> _images = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(int fieldId) =>
      _controllers.putIfAbsent(fieldId, () => TextEditingController());

  Future<void> _pickImage(int fieldId, FormFieldState<String> field) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _images[fieldId] = file.path);
    field.didChange(file.path);
  }

  void _submit(List<ReservationField> fields) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    final texts = <int, String>{};
    final images = <int, String>{};
    for (final f in fields) {
      switch (f.type) {
        case ReservationFieldType.text:
          final textValue = _controllerFor(f.id).text.trim();
          if (textValue.isNotEmpty) texts[f.id] = textValue;
        case ReservationFieldType.number:
          final numberValue = _normalizeDigits(_controllerFor(f.id).text.trim())
              .replaceAll(',', '.');
          if (numberValue.isNotEmpty) texts[f.id] = numberValue;
        case ReservationFieldType.select:
        case ReservationFieldType.radio:
          final choiceValue = (_choices[f.id] ?? '').trim();
          if (choiceValue.isNotEmpty) texts[f.id] = choiceValue;
        case ReservationFieldType.image:
          final imagePath = _images[f.id];
          if (imagePath != null && imagePath.isNotEmpty) {
            images[f.id] = imagePath;
          }
      }
    }

    context.read<ReservationFormCubit>().submit(
          merchantId: widget.merchantId,
          categoryId: widget.categoryId,
          textAnswers: texts,
          imageAnswers: images,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReservationFormCubit, ReservationFormState>(
      listener: (context, state) {
        if (state.status == ReservationFormStatus.submitted) {
          widget.onSubmitted(state.message ?? 'تم إرسال طلبك');
        } else if (state.status == ReservationFormStatus.failure &&
            state.fields.isNotEmpty &&
            (state.message ?? '').isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == ReservationFormStatus.loading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == ReservationFormStatus.failure &&
            state.fields.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(
                  state.message ?? 'تعذر تحميل نموذج الحجز',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                TextButton(
                  onPressed: () => context
                      .read<ReservationFormCubit>()
                      .load(widget.categoryId),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
          );
        }

        final submitting = state.status == ReservationFormStatus.submitting;
        final fields = state.fields;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'بيانات الحجز',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AuthTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'املأ البيانات وسنرسلها للمكان ليرد عليك بالسعر والتفاصيل',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AuthTheme.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              for (final f in fields) ...[
                _buildField(f, submitting),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 4),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: submitting ? null : () => _submit(fields),
                  icon: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: const Text(
                    'إرسال لمعرفة السعر والتفاصيل',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _labelOf(ReservationField f) =>
      f.isRequired ? '${f.label} *' : f.label;

  String? _requiredMessage(ReservationField f, String? value) {
    if (f.isRequired && (value == null || value.trim().isEmpty)) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  Widget _buildField(ReservationField f, bool busy) {
    switch (f.type) {
      case ReservationFieldType.text:
        return TextFormField(
          controller: _controllerFor(f.id),
          enabled: !busy,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: _labelOf(f),
            border: const OutlineInputBorder(),
          ),
          validator: (v) => _requiredMessage(f, v),
        );

      case ReservationFieldType.number:
        return TextFormField(
          controller: _controllerFor(f.id),
          enabled: !busy,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,]')),
          ],
          decoration: InputDecoration(
            labelText: _labelOf(f),
            border: const OutlineInputBorder(),
          ),
          validator: (v) {
            final required = _requiredMessage(f, v);
            if (required != null) return required;
            final text = (v ?? '').trim();
            if (text.isEmpty) return null;
            // يقبل الأرقام العربية والفاصلة.
            final normalized = _normalizeDigits(text).replaceAll(',', '.');
            return double.tryParse(normalized) == null
                ? 'أدخل رقماً صحيحاً'
                : null;
          },
        );

      case ReservationFieldType.select:
        return DropdownButtonFormField<String>(
          initialValue: _choices[f.id],
          isExpanded: true,
          decoration: InputDecoration(
            labelText: _labelOf(f),
            border: const OutlineInputBorder(),
          ),
          items: f.options
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(o, style: const TextStyle(fontFamily: 'Cairo')),
                ),
              )
              .toList(),
          onChanged: busy
              ? null
              : (v) {
                  if (v == null) return;
                  _choices[f.id] = v;
                },
          validator: (v) => _requiredMessage(f, v),
        );

      case ReservationFieldType.radio:
        return FormField<String>(
          initialValue: _choices[f.id],
          validator: (v) => _requiredMessage(f, v),
          builder: (field) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelOf(f),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                for (final option in f.options)
                  InkWell(
                    onTap: busy
                        ? null
                        : () {
                            setState(() => _choices[f.id] = option);
                            field.didChange(option);
                          },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            _choices[f.id] == option
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: _choices[f.id] == option
                                ? AuthTheme.primary
                                : AuthTheme.textMuted,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              option,
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      field.errorText!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            );
          },
        );

      case ReservationFieldType.image:
        return FormField<String>(
          initialValue: _images[f.id],
          validator: (v) => _requiredMessage(f, v),
          builder: (field) {
            final path = _images[f.id];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelOf(f),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: busy ? null : () => _pickImage(f.id, field),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: field.hasError
                            ? Colors.red
                            : AuthTheme.fieldBorder,
                      ),
                    ),
                    child: path != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(File(path), fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36,
                                color: AuthTheme.textMuted,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'اضغط لاختيار صورة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AuthTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      field.errorText!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
    }
  }

  static String _normalizeDigits(String input) {
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      final idx = arabic.indexOf(ch);
      buffer.write(idx >= 0 ? idx.toString() : ch);
    }
    return buffer.toString();
  }
}
