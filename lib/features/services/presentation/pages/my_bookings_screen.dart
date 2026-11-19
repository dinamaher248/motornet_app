import 'package:motorent/widgets/rating_stars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/services/domain/entities/reservation_entities.dart';
import 'package:motorent/features/services/presentation/cubit/reservation_cubits.dart';
import 'package:motorent/features/services/presentation/widgets/reservation_answers_view.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

/// «حجوزاتي» — استفسارات الأسعار وعروض الأسعار والحجوزات المؤكدة للعميل.
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MyBookingsCubit()..load(),
      child: const _MyBookingsView(),
    );
  }
}

class _MyBookingsView extends StatelessWidget {
  const _MyBookingsView();

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    Color? actionColor,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontFamily: 'Cairo')),
        content: Text(body, style: const TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              action,
              style: TextStyle(fontFamily: 'Cairo', color: actionColor),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        title: const Text(
          'حجوزاتي',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<MyBookingsCubit, MyBookingsState>(
        listenWhen: (prev, curr) =>
            curr.message != null && prev.message != curr.message,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        },
        builder: (context, state) {
          if (state.status == MyBookingsStatus.loading &&
              state.bookings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => context.read<MyBookingsCubit>().load(silent: true),
            child: state.bookings.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      const Icon(
                        Icons.event_note_outlined,
                        size: 64,
                        color: AuthTheme.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          state.status == MyBookingsStatus.failure
                              ? (state.message ?? 'تعذر تحميل حجوزاتك')
                              : 'لا توجد حجوزات حتى الآن',
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
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: state.bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final b = state.bookings[index];
                      return _BookingCard(
                        booking: b,
                        busy: state.busyId == b.id,
                        onAccept: () async {
                          final cubit = context.read<MyBookingsCubit>();
                          final ok = await _confirm(
                            context,
                            title: 'قبول العرض',
                            body: 'هل تريد قبول السعر وتأكيد الحجز؟',
                            action: 'قبول',
                            actionColor: const Color(0xFF0C9F6A),
                          );
                          if (ok) cubit.accept(b.id);
                        },
                        onReject: () async {
                          final cubit = context.read<MyBookingsCubit>();
                          final ok = await _confirm(
                            context,
                            title: 'رفض العرض',
                            body: 'هل تريد رفض هذا العرض؟',
                            action: 'رفض',
                            actionColor: Colors.red,
                          );
                          if (ok) cubit.reject(b.id);
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final ReservationBooking booking;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BookingCard({
    required this.booking,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  Color get _statusColor {
    if (booking.isConfirmed) return const Color(0xFF0C9F6A);
    if (booking.isQuoted) return AuthTheme.primary;
    if (booking.isRejected || booking.isUnavailable) return Colors.red;
    return AuthTheme.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final b = booking;
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
                  b.merchantName.isEmpty ? 'حجز #${b.id}' : b.merchantName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  b.statusLabel,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          if ((b.categoryName ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              b.categoryName!,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AuthTheme.textMuted,
              ),
            ),
          ],
          if (b.answers.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ReservationAnswersView(answers: b.answers),
          ],
          if (b.isUnavailable) ...[
            const SizedBox(height: 6),
            const Text(
              'غير متوفر حالياً',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                color: Colors.red,
              ),
            ),
          ],
          if (b.isQuoted || b.isConfirmed) ..._quoteSection(),
          if (b.isConfirmed && b.merchantId != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showRateSheet(
                  context,
                  title: 'قيّم المكان',
                  contextType: 'reservation_booking',
                  contextId: b.id,
                  rateeMerchantId: b.merchantId,
                ),
                icon: const Icon(Icons.star_outline),
                label: const Text('قيّم المكان'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _quoteSection() {
    final b = booking;
    return [
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1FBF6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCDEEDD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (b.quotedPrice != null)
              Text(
                'السعر: ${b.quotedPrice!.toStringAsFixed(b.quotedPrice! % 1 == 0 ? 0 : 2)} ج.م',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AuthTheme.primaryDark,
                ),
              ),
            if ((b.quoteDetails ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                b.quoteDetails!,
                style: const TextStyle(fontFamily: 'Cairo', height: 1.5),
              ),
            ],
          ],
        ),
      ),
      if (b.isQuoted) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: busy ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C9F6A),
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
                          'قبول',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'رفض',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ];
  }
}
