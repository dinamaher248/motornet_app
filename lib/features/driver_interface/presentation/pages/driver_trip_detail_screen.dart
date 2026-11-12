import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/driver_interface/domain/entities/driver_entities.dart';
import 'package:motorent/features/driver_interface/presentation/bloc/driver_home_bloc.dart';
import 'package:motorent/pages/map_view_page.dart';
import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class DriverTripDetailScreen extends StatelessWidget {
  final DriverTrip trip;

  const DriverTripDetailScreen({super.key, required this.trip});

  DriverTrip _resolveTrip(DriverHomeState state) {
    for (final t in state.trips) {
      if (t.id == trip.id && t.type == trip.type) return t;
    }
    return trip;
  }

  Future<void> _showOfferSheet(BuildContext context, DriverTrip current) async {
    final controller = TextEditingController(
      text: current.myOfferAmount != null
          ? current.myOfferAmount!.toStringAsFixed(0)
          : (current.customerPrice != null
              ? current.customerPrice!.toStringAsFixed(0)
              : ''),
    );
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'تعديل السعر وإرساله للعميل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                current.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AuthTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'السعر (ج.م)',
                  helperText: current.customerPrice != null
                      ? 'سعر العميل: ${current.customerPrice!.toStringAsFixed(0)} ج.م — زوّد أو انقص ثم أرسل'
                      : 'يمكنك زيادة أو إنقاص السعر ثم إرساله للعميل',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final v = double.tryParse(controller.text.trim());
                    if (v == null || v <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('أدخل سعراً صحيحاً')),
                      );
                      return;
                    }
                    Navigator.pop(ctx, v);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'إرسال للعميل',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (amount == null || !context.mounted) return;
    context.read<DriverHomeBloc>().add(
          MakeOfferEvent(
            tripId: current.id,
            type: current.type,
            amount: amount,
          ),
        );
  }

  void _openTracking(BuildContext context, DriverTrip current) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveOrderTrackingPage(
          type: current.type,
          id: current.id,
          isDriverView: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تفاصيل الطلب',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<DriverHomeBloc, DriverHomeState>(
        listener: (context, state) {
          final msg = state.message;
          if (msg == null || msg.isEmpty) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: state.status == DriverHomeStatus.failure
                  ? Colors.red.shade700
                  : null,
            ),
          );
          if (state.tripStarted && context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ActiveOrderTrackingPage(
                  type: trip.type,
                  id: trip.id,
                  isDriverView: true,
                ),
              ),
            );
            return;
          }
          if (msg.contains('رفض الطلب') && context.mounted) {
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          final current = _resolveTrip(state);
          final distanceText = (current.distanceLabel ?? '').trim().isNotEmpty
              ? current.distanceLabel!
              : 'غير محددة';
          final customerPrice = current.customerPrice ?? current.amount;
          final hasCustomerPrice = customerPrice != null && customerPrice > 0;
          final offerText = current.myOfferAmount != null
              ? '${current.myOfferAmount!.toStringAsFixed(0)} ج.م'
              : (hasCustomerPrice
                  ? '${customerPrice.toStringAsFixed(0)} ج.م'
                  : 'لم يُقدَّم بعد');

          return Container(
            decoration: AuthTheme.screenBackground(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AuthTheme.fieldBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.title,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.trip_origin,
                        label: 'الاستلام',
                        value: current.pickup ?? '-',
                        onTap: () => openLocationOnMap(
                          context,
                          title: 'موقع الاستلام',
                          address: current.pickup,
                          lat: current.pickupLat,
                          lng: current.pickupLng,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.flag_outlined,
                        label: 'التوصيل',
                        value: current.dropoff ?? '-',
                        onTap: () => openLocationOnMap(
                          context,
                          title: 'موقع التسليم',
                          address: current.dropoff,
                          lat: current.dropoffLat,
                          lng: current.dropoffLng,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.near_me_outlined,
                        label: 'المسافة بينك والاستلام',
                        value: distanceText,
                      ),
                      if ((current.routeDistanceLabel ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.route_outlined,
                          label: 'المسافة بين النقطتين',
                          value: current.routeDistanceLabel!,
                        ),
                      ],
                      if (current.customerRating != null) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.star_rounded,
                          label: 'تقييم العميل',
                          value:
                              '${current.customerRating!.toStringAsFixed(1)}${current.customerRatingsCount != null ? ' (${current.customerRatingsCount})' : ''}',
                        ),
                      ],
                      const SizedBox(height: 12),
                      _DetailRow(
                        icon: Icons.notes,
                        label: 'الوصف',
                        value: (current.description ?? '').trim().isEmpty
                            ? '-'
                            : current.description!,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط على عنوان الاستلام أو التسليم لعرض الخريطة',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AuthTheme.primary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _HighlightCard(
                        icon: Icons.straighten,
                        label: 'حتى الاستلام',
                        value: distanceText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HighlightCard(
                        icon: Icons.payments_outlined,
                        label: current.myOfferAmount != null
                            ? 'عرضك'
                            : 'سعر العميل',
                        value: offerText,
                        accent: AuthTheme.primary,
                      ),
                    ),
                  ],
                ),
                if (current.offerStatus != null &&
                    current.offerStatus!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AuthTheme.fieldBorder),
                    ),
                    child: Text(
                      'حالة العرض: ${_offerStatusLabel(current.offerStatus)}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (current.showContact) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0C9F6A).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'جاري التنفيذ',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openTracking(context, current),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text(
                              'متابعة التنفيذ / تم التسليم',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AuthTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (current.canOffer) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      current.myOfferAmount != null
                          ? 'تم إرسال السعر الجديد للعميل. انتظر قبوله أو عدّل العرض.'
                          : hasCustomerPrice
                              ? 'سعر العميل ${customerPrice!.toStringAsFixed(0)} ج.م — اقبل أو عدّل أو ارفض.'
                              : 'العميل لم يحدد سعراً — قدّم عرضك أو ارفض الطلب.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (hasCustomerPrice) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: state.submittingOffer
                            ? null
                            : () {
                                context.read<DriverHomeBloc>().add(
                                      MakeOfferEvent(
                                        tripId: current.id,
                                        type: current.type,
                                        amount: customerPrice!,
                                      ),
                                    );
                              },
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          current.myOfferAmount != null
                              ? 'قبول سعر العميل مرة أخرى'
                              : 'قبول سعر العميل',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0C9F6A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: hasCustomerPrice
                        ? OutlinedButton.icon(
                            onPressed: state.submittingOffer
                                ? null
                                : () => _showOfferSheet(context, current),
                            icon: state.submittingOffer
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.edit_outlined),
                            label: const Text(
                              'تعديل السعر (زيادة / نقصان)',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: state.submittingOffer
                                ? null
                                : () => _showOfferSheet(context, current),
                            icon: state.submittingOffer
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.local_offer_outlined),
                            label: Text(
                              current.myOfferAmount != null
                                  ? 'تعديل عرضي'
                                  : 'تقديم عرض سعر',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AuthTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: state.submittingOffer
                          ? null
                          : () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text(
                                    'رفض الطلب',
                                    style: TextStyle(fontFamily: 'Cairo'),
                                  ),
                                  content: const Text(
                                    'لن يظهر لك هذا الطلب مرة أخرى.',
                                    style: TextStyle(fontFamily: 'Cairo'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('رجوع'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('رفض'),
                                    ),
                                  ],
                                ),
                              );
                              if (ok == true && context.mounted) {
                                context.read<DriverHomeBloc>().add(
                                      DeclineTripEvent(
                                        tripId: current.id,
                                        type: current.type,
                                      ),
                                    );
                              }
                            },
                      child: const Text(
                        'رفض الطلب',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB42318),
                        ),
                      ),
                    ),
                  ),
                ] else if (state.hasActiveTrip && !current.showContact) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'لا يمكن تقديم عرض الآن — لديك طلب قيد التنفيذ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A5A00),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

String _offerStatusLabel(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'pending':
      return 'بانتظار قبول العميل للسعر الجديد';
    case 'accepted':
      return 'مقبول — الرحلة بدأت';
    case 'rejected':
      return 'مرفوض';
    default:
      return status ?? '';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AuthTheme.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AuthTheme.textDark,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: AuthTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: onTap != null
                        ? AuthTheme.primaryDark
                        : AuthTheme.textDark,
                    decoration:
                        onTap != null ? TextDecoration.underline : null,
                    fontWeight:
                        onTap != null ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onTap != null)
          const Icon(Icons.map_outlined, size: 18, color: AuthTheme.primary),
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: row,
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  const _HighlightCard({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AuthTheme.textDark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthTheme.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AuthTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
