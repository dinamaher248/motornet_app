import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motorent/models/driver_models.dart';
import 'package:motorent/services/driver_api.dart';
import 'package:motorent/services/merchant_owner_api.dart';
import 'package:motorent/widgets/auth/auth_shell.dart';

class DriverSettlementPage extends StatefulWidget {
  final DriverDuesSummary summary;
  final bool isMerchant;

  const DriverSettlementPage({
    super.key,
    required this.summary,
    this.isMerchant = false,
  });

  @override
  State<DriverSettlementPage> createState() => _DriverSettlementPageState();
}

class _DriverSettlementPageState extends State<DriverSettlementPage> {
  final _driverApi = DriverApi();
  final _merchantApi = MerchantOwnerApi();
  String? _proofPath;
  bool _isSubmitting = false;

  Future<void> _pickProof() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _proofPath = file.path);
  }

  Future<void> _submit() async {
    if (_proofPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب رفع صورة التحويل')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (widget.isMerchant) {
        await _merchantApi.submitSettlement(_proofPath!);
      } else {
        await _driverApi.submitSettlement(_proofPath!);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب السداد — بانتظار مراجعة الإدارة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = widget.summary.walletNumber;
    final insta = widget.summary.instapayNumber;

    return Scaffold(
      appBar: AppBar(title: const Text('سداد مستحقات التطبيق')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'الرصيد المستحق: ${widget.summary.duesBalance} ج.م',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          if (wallet.isNotEmpty) ...[
            const Text('رقم المحفظة'),
            Text(wallet, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: wallet));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم نسخ رقم المحفظة')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('انسخ رقم التحويل'),
            ),
          ],
          if (insta.isNotEmpty && insta != wallet) ...[
            const SizedBox(height: 12),
            const Text('انستا باي'),
            Text(insta, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickProof,
            icon: const Icon(Icons.upload_file),
            label: Text(
              _proofPath == null ? 'ارفع صورة التحويل' : 'تم رفع الصورة',
            ),
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: 'تأكيد السداد',
            isLoading: _isSubmitting,
            onPressed: _proofPath != null && !_isSubmitting ? _submit : null,
          ),
        ],
      ),
    );
  }
}
