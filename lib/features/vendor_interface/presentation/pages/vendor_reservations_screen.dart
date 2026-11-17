import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/services/domain/entities/reservation_entities.dart';
import 'package:motorent/features/services/presentation/widgets/reservation_answers_view.dart';
import 'package:motorent/features/vendor_interface/presentation/bloc/vendor_reservations_cubit.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// استفسارات الحجز عند التاجر: طلبات جديدة، بانتظار العميل، ومؤكدة.
class VendorReservationsScreen extends StatelessWidget {
  const VendorReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorReservationsCubit()..load(),
      child: const _VendorReservationsView(),
    );
  }
}

class _VendorReservationsView extends StatelessWidget {
  const _VendorReservationsView();

  Future<void> _openQuoteDialog(
    BuildContext context,
    ReservationBooking booking,
  ) async {
    final cubit = context.read<VendorReservationsCubit>();
    final result = await showDialog<_QuoteInput>(
      context: context,
      builder: (_) => const _QuoteDialog(),
    );
    if (result == null) return;
    await cubit.sendQuote(
      id: booking.id,
      price: result.price,
      details: result.details,
    );
  }

  Future<void> _confirmUnavailable(
    BuildContext context,
    ReservationBooking booking,
  ) async {
    final cubit = context.read<VendorReservationsCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'غير متوفر حالياً',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        content: const Text(
          'سيتم إبلاغ العميل بعدم التوفر. هل تريد المتابعة؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'تأكيد',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await cubit.markUnavailable(booking.id);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'الحجوزات',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelStyle:
                TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
            tabs: [
              Tab(text: 'طلبات جديدة'),
              Tab(text: 'بانتظار العميل'),
              Tab(text: 'مؤكدة'),
            ],
          ),
        ),
        body: BlocConsumer<VendorReservationsCubit, VendorReservationsState>(
          listenWhen: (prev, curr) =>
              curr.message != null && prev.message != curr.message,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          },
          builder: (context, state) {
            if (state.status == VendorReservationsStatus.loading &&
                state.incoming.isEmpty &&
                state.awaitingCustomer.isEmpty &&
                state.confirmed.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            Widget list(
              List<ReservationBooking> items,
              String emptyText, {
              required bool actionable,
            }) {
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<VendorReservationsCubit>().load(silent: true),
                child: items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              state.status == VendorReservationsStatus.failure
                                  ? (state.message ?? 'تعذر تحميل الحجوزات')
                                  : emptyText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                color: AuthTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final b = items[i];
                          return _ReservationCard(
                            booking: b,
                            busy: state.busyId == b.id,
                            actionable: actionable,
                            onUnavailable: () => _confirmUnavailable(context, b),
                            onQuote: () => _openQuoteDialog(context, b),
                          );
                        },
                      ),
              );
            }

            return TabBarView(
              children: [
                list(
                  state.incoming,
                  'لا توجد طلبات جديدة',
                  actionable: true,
                ),
                list(
                  state.awaitingCustomer,
                  'لا توجد عروض بانتظار رد العميل',
                  actionable: false,
                ),
                list(
                  state.confirmed,
                  'لا توجد حجوزات مؤكدة',
                  actionable: false,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationBooking booking;
  final bool busy;
  final bool actionable;
  final VoidCallback onUnavailable;
  final VoidCallback onQuote;

  const _ReservationCard({
    required this.booking,
    required this.busy,
    required this.actionable,
    required this.onUnavailable,
    required this.onQuote,
  });

  Future<void> _callCustomer(BuildContext context) async {
    final raw = booking.customerPhone ?? '';
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.length < 8) return;
    await launchUrl(Uri(scheme: 'tel', path: cleaned));
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final hasPhone = (b.customerPhone ?? '').trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthTheme.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (b.customerName ?? '').isEmpty
                      ? 'طلب #${b.id}'
                      : b.customerName!,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (b.isConfirmed && hasPhone)
                IconButton(
                  tooltip: 'اتصال بالعميل',
                  onPressed: () => _callCustomer(context),
                  icon: const Icon(Icons.call, color: Color(0xFF0C9F6A)),
                ),
            ],
          ),
          if ((b.categoryName ?? '').isNotEmpty)
            Text(
              b.categoryName!,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AuthTheme.textMuted,
              ),
            ),
          if (b.answers.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ReservationAnswersView(answers: b.answers),
          ],
          if (b.quotedPrice != null) ...[
            const SizedBox(height: 4),
            Text(
              'السعر المرسل: ${b.quotedPrice!.toStringAsFixed(b.quotedPrice! % 1 == 0 ? 0 : 2)} ج.م',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                color: AuthTheme.primaryDark,
              ),
            ),
            if ((b.quoteDetails ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  b.quoteDetails!,
                  style: const TextStyle(fontFamily: 'Cairo', height: 1.5),
                ),
              ),
          ],
          if (actionable && b.isPendingQuote) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: busy ? null : onUnavailable,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'غير متوفر حالياً',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: busy ? null : onQuote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuthTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'إرسال السعر والتفاصيل',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _QuoteInput {
  final double price;
  final String details;

  const _QuoteInput(this.price, this.details);
}

/// حوار إدخال السعر والتفاصيل ← `POST /merchant/reservations/{id}/quote`.
class _QuoteDialog extends StatefulWidget {
  const _QuoteDialog();

  @override
  State<_QuoteDialog> createState() => _QuoteDialogState();
}

class _QuoteDialogState extends State<_QuoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();

  @override
  void dispose() {
    _priceCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
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

  double? _parsePrice() => double.tryParse(
        _normalizeDigits(_priceCtrl.text.trim()).replaceAll(',', '.'),
      );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _QuoteInput(_parsePrice()!, _detailsCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'إرسال السعر والتفاصيل',
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _priceCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'السعر (ج.م)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final price = _parsePrice();
                  if (price == null || price <= 0) return 'أدخل سعراً صحيحاً';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _detailsCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'التفاصيل',
                  hintText: 'مثال: السعر شامل الإفطار — الحد الأقصى 3 أفراد',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'اكتب تفاصيل العرض' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AuthTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'إرسال',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
