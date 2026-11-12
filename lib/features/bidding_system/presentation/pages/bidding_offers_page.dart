import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/bidding_system/bidding_injection.dart';
import 'package:motorent/features/bidding_system/core/constants/bidding_vehicle_types.dart';
import 'package:motorent/features/bidding_system/domain/entities/bidding_trip.dart';
import 'package:motorent/features/bidding_system/presentation/bloc/bidding_bloc.dart';
import 'package:motorent/features/bidding_system/presentation/widgets/offer_card.dart';
import 'package:motorent/pages/map_view_page.dart';
import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class BiddingOffersPage extends StatelessWidget {
  final BiddingTrip trip;

  const BiddingOffersPage({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = BiddingInjection.createBloc();
        bloc.add(SetCurrentTripEvent(trip));
        bloc.add(FetchOffersEvent(trip.id));
        return bloc;
      },
      child: _BiddingOffersView(trip: trip),
    );
  }
}

class _BiddingOffersView extends StatefulWidget {
  final BiddingTrip trip;

  const _BiddingOffersView({required this.trip});

  @override
  State<_BiddingOffersView> createState() => _BiddingOffersViewState();
}

class _BiddingOffersViewState extends State<_BiddingOffersView> {
  Timer? _pollTimer;
  int? _acceptingOfferId;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      context.read<BiddingBloc>().add(
            FetchOffersEvent(widget.trip.id, silent: true),
          );
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'عروض السائقين',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<BiddingBloc, BiddingState>(
        listener: (context, state) {
          if (state is BiddingError) {
            setState(() => _acceptingOfferId = null);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is OfferAcceptedSuccess) {
            setState(() => _acceptingOfferId = null);
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
          final offers =
              state is OffersLoadedSuccess ? state.offers : const [];
          final loading = state is BiddingLoading && _acceptingOfferId == null;

          return Container(
            decoration: AuthTheme.screenBackground(),
            child: RefreshIndicator(
              onRefresh: () async {
                context
                    .read<BiddingBloc>()
                    .add(FetchOffersEvent(widget.trip.id));
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _TripSummaryCard(trip: widget.trip),
                  const SizedBox(height: 20),
                  const Text(
                    'اختر السائق الذي يناسبك واضغط قبول عرض السعر',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'المحادثة فقط متاحة بعد قبول العرض — بدون أرقام هاتف',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AuthTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (offers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Text(
                        'بانتظار عروض السائقين...\nسيتم تحديث القائمة تلقائيًا',
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
                        customerPrice: widget.trip.customerPrice,
                        isAccepting: _acceptingOfferId == offer.id,
                        onAccept: () {
                          setState(() => _acceptingOfferId = offer.id);
                          context
                              .read<BiddingBloc>()
                              .add(AcceptOfferEvent(offer.id));
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  final BiddingTrip trip;

  const _TripSummaryCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AuthTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'قيد الانتظار',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AuthTheme.primaryDark,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                BiddingVehicleTypes.labelOf(trip.vehicleType),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AuthTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => openLocationOnMap(
              context,
              title: 'موقع الاستلام',
              address: trip.pickupAddress,
              lat: trip.pickupLat,
              lng: trip.pickupLng,
            ),
            child: _row(Icons.my_location, 'من', trip.pickupAddress,
                showMapHint: trip.pickupLat != null),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => openLocationOnMap(
              context,
              title: 'موقع التسليم',
              address: trip.dropoffAddress,
              lat: trip.dropoffLat,
              lng: trip.dropoffLng,
            ),
            child: _row(Icons.flag_outlined, 'إلى', trip.dropoffAddress,
                showMapHint: trip.dropoffLat != null),
          ),
          if (trip.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            _row(Icons.notes_outlined, 'الوصف', trip.description),
          ],
          if ((trip.customerPrice ?? 0) > 0) ...[
            const SizedBox(height: 8),
            _row(
              Icons.payments_outlined,
              'سعرك',
              '${trip.customerPrice!.toStringAsFixed(0)} ج.م',
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value,
      {bool showMapHint = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AuthTheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AuthTheme.textDark,
                  ),
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: value),
                  ],
                ),
              ),
              if (showMapHint)
                const Text(
                  'اضغط لعرض الموقع على الخريطة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AuthTheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
