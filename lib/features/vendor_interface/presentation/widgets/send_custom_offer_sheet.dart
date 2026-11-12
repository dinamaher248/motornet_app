import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';
import 'package:motorent/features/vendor_interface/presentation/bloc/vendor_orders_bloc.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

Future<void> showSendCustomOfferSheet(
  BuildContext context, {
  required VendorOrder order,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return BlocProvider.value(
        value: context.read<VendorOrdersBloc>(),
        child: _SendCustomOfferSheet(order: order),
      );
    },
  );
}

class _SendCustomOfferSheet extends StatefulWidget {
  final VendorOrder order;

  const _SendCustomOfferSheet({required this.order});

  @override
  State<_SendCustomOfferSheet> createState() => _SendCustomOfferSheetState();
}

class _SendCustomOfferSheetState extends State<_SendCustomOfferSheet> {
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _priceController.text.trim();
    final price = raw.isEmpty ? null : double.tryParse(raw.replaceAll(',', '.'));
    if (raw.isNotEmpty && price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل سعراً صحيحاً أو اترك الحقل فارغاً')),
      );
      return;
    }

    context.read<VendorOrdersBloc>().add(
          SendCustomOfferEvent(
            SendCustomOfferParams(
              orderId: widget.order.id,
              totalPrice: price,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'إرسال العرض',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4E5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD59A)),
              ),
              child: const Text(
                'تنبيه: إذا كان الطلب أو جزء منه غير متوفر، اكتب ذلك في الملاحظات. وإذا كان الطلب غير متوفر بالكامل، اترك السعر فارغًا ثم اضغط إرسال العرض.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.5,
                  height: 1.5,
                  color: Color(0xFF8A5A00),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'السعر الإجمالي',
                hintText: 'اختياري',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 3,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'ملاحظات للتوضيح',
                hintText: 'اختياري',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AuthTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إرسال العرض',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
