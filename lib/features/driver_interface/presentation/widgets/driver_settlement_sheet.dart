import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motorent/features/driver_interface/domain/entities/driver_entities.dart';
import 'package:motorent/features/driver_interface/presentation/bloc/driver_wallet_bloc.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

Future<void> showDriverSettlementSheet({
  required BuildContext context,
  required DriverWallet wallet,
  required DriverWalletBloc bloc,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _SettlementSheet(wallet: wallet),
    ),
  );
}

class _SettlementSheet extends StatefulWidget {
  final DriverWallet wallet;

  const _SettlementSheet({required this.wallet});

  @override
  State<_SettlementSheet> createState() => _SettlementSheetState();
}

class _SettlementSheetState extends State<_SettlementSheet> {
  File? _receipt;

  Future<void> _pick() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('من المعرض',
                  style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('الكاميرا',
                  style: TextStyle(fontFamily: 'Cairo')),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => _receipt = File(file.path));
  }

  @override
  Widget build(BuildContext context) {
    final walletNumber = widget.wallet.displayWallet;
    final amount = widget.wallet.dueAmount;

    return BlocConsumer<DriverWalletBloc, DriverWalletState>(
      listener: (context, state) async {
        if (state.status == DriverWalletStatus.settlementSuccess) {
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text(
                'تم بنجاح',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Text(
                state.message ??
                    'تم استلام الطلب وهو بانتظار مراجعة الإدارة',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('حسناً',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          );
          if (context.mounted) {
            Navigator.pop(context);
            context.read<DriverWalletBloc>().add(const FetchWalletStats());
          }
        } else if (state.status == DriverWalletStatus.failure &&
            state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        final submitting = state.status == DriverWalletStatus.submitting;
        final canSubmit = _receipt != null && !submitting && amount > 0;

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'سداد المستحقات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'المبلغ المستحق: ${amount.toStringAsFixed(0)} ج.م',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AuthTheme.primaryDark,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AuthTheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'رقم محفظة / إنستا باي التطبيق',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: AuthTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              walletNumber.isEmpty
                                  ? 'غير متوفر حالياً'
                                  : walletNumber,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: walletNumber.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(
                                  ClipboardData(text: walletNumber),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('تم نسخ الرقم')),
                                );
                              },
                        icon: const Icon(Icons.copy),
                        tooltip: 'نسخ الرقم',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: submitting ? null : _pick,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _receipt == null
                            ? AuthTheme.fieldBorder
                            : AuthTheme.primary,
                      ),
                      color: Colors.white,
                    ),
                    child: _receipt != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_receipt!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 36, color: AuthTheme.textMuted),
                              SizedBox(height: 8),
                              Text(
                                'ارفع صورة التحويل',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                  color: AuthTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_receipt == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'يجب رفع صورة التحويل قبل تأكيد السداد',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: canSubmit
                        ? () {
                            context.read<DriverWalletBloc>().add(
                                  SubmitSettlementEvent(
                                    receipt: _receipt!,
                                    amount: amount,
                                  ),
                                );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AuthTheme.primary.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'تأكيد السداد',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
