import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:motorent/features/bidding_system/bidding_injection.dart';
import 'package:motorent/features/bidding_system/core/constants/bidding_vehicle_types.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_driver.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_offer.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';
import 'package:motorent/features/bidding_system/presentation/bloc/trip_tracking_bloc.dart';
import 'package:motorent/features/bidding_system/presentation/widgets/offer_card.dart';
import 'package:motorent/pages/chat_utou_pageTwo.dart';
import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/rating_stars.dart';
import 'package:motorent/widgets/storage_network_avatar.dart';
import 'package:motorent/pages/map_view_page.dart';
import 'package:url_launcher/url_launcher.dart';

class TripDetailsScreen extends StatelessWidget {
  final int tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BiddingInjection.createTrackingBloc()
        ..add(FetchTripDetailsEvent(tripId)),
      child: _TripDetailsView(tripId: tripId),
    );
  }
}

class _TripDetailsView extends StatefulWidget {
  final int tripId;

  const _TripDetailsView({required this.tripId});

  @override
  State<_TripDetailsView> createState() => _TripDetailsViewState();
}

class _TripDetailsViewState extends State<_TripDetailsView> {
  Timer? _pollTimer;

  int get tripId => widget.tripId;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      context.read<TripTrackingBloc>().add(
            FetchTripDetailsEvent(tripId, silent: true),
          );
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<bool> _confirmCancel(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'إلغاء الطلب',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'هل أنت متأكد من إلغاء الطلب؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('رجوع'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _call(BuildContext context, String? phone) async {
    final cleaned = (phone ?? '').trim();
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم السائق غير متاح')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openChat(
    BuildContext context,
    BiddingDriver driver,
    BiddingTrip trip,
  ) async {
    final me = CacheHelper.getData(key: 'id')?.toString() ?? '';
    if (me.isEmpty || driver.id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح المحادثة')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          roomId: 'bidding_trip_${trip.id}',
          partnerId: driver.id.toString(),
          currentUserId: me,
          orderType: 'bidding_trip',
          orderId: trip.id,
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
      body: BlocConsumer<TripTrackingBloc, TripTrackingState>(
        listener: (context, state) {
          if (state is TrackingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is TripCancelledSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is TripOfferAcceptedSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ActiveOrderTrackingPage(
                  type: 'bidding_trip',
                  id: state.trip.id,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TrackingLoading || state is TrackingInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          BiddingTrip? trip;
          var cancelling = false;
          var offers = const <BiddingOffer>[];
          int? acceptingOfferId;
          if (state is TripDetailsLoadedSuccess) {
            trip = state.trip;
            cancelling = state.cancelling;
            offers = state.offers;
            acceptingOfferId = state.acceptingOfferId;
          } else if (state is TripCancelledSuccess) {
            trip = state.trip;
          }

          if (trip == null) {
            return Center(
              child: TextButton(
                onPressed: () => context
                    .read<TripTrackingBloc>()
                    .add(FetchTripDetailsEvent(tripId)),
                child: const Text('إعادة المحاولة'),
              ),
            );
          }

          final currentTrip = trip;
          final driver = currentTrip.resolvedDriver;

          return Container(
            decoration: AuthTheme.screenBackground(),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      if (trip.isCancelled) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'تم إلغاء هذا الطلب',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w800,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      _MapPlaceholder(
                        title: 'موقع الاستلام',
                        address: trip.pickupAddress,
                        lat: trip.pickupLat,
                        lng: trip.pickupLng,
                        icon: Icons.my_location,
                      ),
                      const SizedBox(height: 12),
                      _MapPlaceholder(
                        title: 'موقع التسليم',
                        address: trip.dropoffAddress,
                        lat: trip.dropoffLat,
                        lng: trip.dropoffLng,
                        icon: Icons.flag_outlined,
                      ),
                      const SizedBox(height: 14),
                      _InfoCard(
                        children: [
                          _infoRow(
                            'نوع المركبة',
                            BiddingVehicleTypes.labelOf(trip.vehicleType),
                          ),
                          _infoRow('الحالة', trip.statusLabelAr),
                          _infoRow(
                            'تاريخ الطلب',
                            trip.createdAt == null
                                ? '—'
                                : DateFormat('yyyy/MM/dd - HH:mm')
                                    .format(trip.createdAt!.toLocal()),
                          ),
                          if (trip.description.isNotEmpty)
                            _infoRow('الوصف', trip.description),
                          if (trip.notes != null &&
                              trip.notes!.trim().isNotEmpty)
                            _infoRow('ملاحظات', trip.notes!),
                        ],
                      ),
                      if (trip.isPending) ...[
                        const SizedBox(height: 18),
                        const Text(
                          'عروض السائقين',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'لما السائق يقبل سعرك أو يبعت سعر جديد هتظهر هنا تلقائيًا',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AuthTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (offers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'بانتظار عروض السائقين...\nسيتم تحديث الشاشة تلقائيًا',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AuthTheme.textMuted,
                                height: 1.5,
                              ),
                            ),
                          )
                        else
                          ...offers.map(
                            (offer) => OfferCard(
                              offer: offer,
                              customerPrice: currentTrip.customerPrice,
                              isAccepting: acceptingOfferId == offer.id,
                              onAccept: () => context
                                  .read<TripTrackingBloc>()
                                  .add(AcceptTripOfferEvent(offer.id)),
                            ),
                          ),
                      ],
                      if (trip.isInProgress || trip.isCompleted) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AuthTheme.fieldBorder),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'السعر المتفق عليه',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AuthTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trip.finalPrice == null
                                    ? '—'
                                    : '${trip.finalPrice!.toStringAsFixed(0)} ج.م',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AuthTheme.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (driver != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AuthTheme.fieldBorder),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    StorageNetworkAvatar(
                                      imagePath: driver.image,
                                      initial: driver.name.isNotEmpty
                                          ? driver.name.characters.first
                                          : 'س',
                                      size: 58,
                                      backgroundColor: AuthTheme.primary
                                          .withValues(alpha: 0.15),
                                      textColor: AuthTheme.primaryDark,
                                      fontSize: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            driver.name,
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                size: 18,
                                                color: Color(0xFFF59E0B),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                driver.rating
                                                    .toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontFamily: 'Cairo',
                                                  color: AuthTheme.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _call(context, driver.phone),
                                        icon: const Icon(Icons.call),
                                        label: const Text('اتصال'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF0C9F6A),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openChat(
                                          context,
                                          driver,
                                          currentTrip,
                                        ),
                                        icon: const Icon(
                                            Icons.chat_bubble_outline),
                                        label: const Text('محادثة'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              AuthTheme.primaryDark,
                                          side: const BorderSide(
                                              color: AuthTheme.primary),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (currentTrip.isCompleted && driver.id > 0) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () => showRateSheet(
                                        context,
                                        title: 'قيّم السائق',
                                        contextType: 'bidding_trip',
                                        contextId: currentTrip.id,
                                        rateeUserId: driver.id,
                                      ),
                                      icon: const Icon(Icons.star_outline),
                                      label: const Text('تقييم السائق'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                if (trip.isPending)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: cancelling
                              ? null
                              : () async {
                                  final ok = await _confirmCancel(context);
                                  if (!ok || !context.mounted) return;
                                  context
                                      .read<TripTrackingBloc>()
                                      .add(CancelTripEvent(currentTrip.id));
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: cancelling
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'إلغاء الطلب',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AuthTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AuthTheme.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthTheme.fieldBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final String title;
  final String address;
  final double? lat;
  final double? lng;
  final IconData icon;

  const _MapPlaceholder({
    required this.title,
    required this.address,
    required this.lat,
    required this.lng,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoords = lat != null && lng != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => openLocationOnMap(
          context,
          title: title,
          address: address,
          lat: lat,
          lng: lng,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AuthTheme.fieldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AuthTheme.primary.withValues(alpha: 0.18),
                      const Color(0xFF0C9F6A).withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: AuthTheme.primaryDark, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      hasCoords
                          ? 'اضغط لعرض الموقع على الخريطة'
                          : 'اضغط للبحث عن العنوان على الخريطة',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AuthTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        color: AuthTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: AuthTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
