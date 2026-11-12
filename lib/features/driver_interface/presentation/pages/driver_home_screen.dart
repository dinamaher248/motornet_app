import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/constants/app_support.dart';
import 'package:motorent/features/driver_interface/domain/entities/driver_entities.dart';
import 'package:motorent/features/driver_interface/driver_interface_injection.dart';
import 'package:motorent/features/driver_interface/presentation/bloc/driver_home_bloc.dart';
import 'package:motorent/features/driver_interface/presentation/pages/driver_trip_detail_screen.dart';
import 'package:motorent/features/driver_interface/presentation/widgets/driver_shimmer.dart';
import 'package:motorent/features/driver_interface/presentation/widgets/driver_trip_card.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DriverInterfaceInjection.createHomeBloc()
            ..add(const LoadDriverHomeEvent()),
      child: const _DriverHomeView(),
    );
  }
}

class _DriverHomeView extends StatelessWidget {
  const _DriverHomeView();

  Future<void> _openSupport() async {
    final phone = AppSupport.phone;
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return;

    final whatsappDigits =
        cleaned.startsWith('0') ? '2$cleaned' : cleaned;
    final wa = Uri.parse('https://wa.me/$whatsappDigits');
    if (await canLaunchUrl(wa)) {
      await launchUrl(wa, mode: LaunchMode.externalApplication);
      return;
    }

    final tel = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(tel)) {
      await launchUrl(tel);
    }
  }

  void _openTripDetails(BuildContext context, DriverTrip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<DriverHomeBloc>(),
          child: DriverTripDetailScreen(trip: trip),
        ),
      ),
    );
  }

  bool _isActive(DriverTrip trip) {
    final status = trip.status ?? '';
    return trip.showContact ||
        status == 'in_progress' ||
        status == 'driver_assigned' ||
        status == 'handed_to_driver' ||
        status == 'in_delivery';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'الرئيسية',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _openSupport,
            icon: const Icon(Icons.support_agent_outlined, size: 20),
            label: const Text(
              'دعم فني',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
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
        },
        builder: (context, state) {
          return Container(
            decoration: AuthTheme.screenBackground(),
            child: Column(
              children: [
                _OnlineToggle(
                  isOnline: state.isOnline,
                  loading: state.togglingOnline,
                  onChanged: (v) => context
                      .read<DriverHomeBloc>()
                      .add(ToggleOnlineEvent(v)),
                ),
                if (state.hasActiveTrip)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4E5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFB74D)),
                    ),
                    child: const Text(
                      'لديك طلب قيد التنفيذ — أنهِه أولاً قبل قبول طلب جديد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF8A5A00),
                      ),
                    ),
                  ),
                Expanded(
                  child: state.status == DriverHomeStatus.loading ||
                          state.status == DriverHomeStatus.initial
                      ? const DriverListShimmer()
                      : RefreshIndicator(
                          onRefresh: () async {
                            context.read<DriverHomeBloc>().add(
                                  const RefreshAvailableBidsEvent(silent: true),
                                );
                            await Future<void>.delayed(
                              const Duration(milliseconds: 600),
                            );
                          },
                          child: _buildBody(context, state),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, DriverHomeState state) {
    if (state.trips.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              state.isOnline
                  ? 'لا توجد طلبات قريبة حالياً\nتأكد من تفعيل الموقع وأنك ضمن نطاق التغطية'
                  : 'فعّل "متاح" لعرض الطلبات القريبة — أو أكمل طلبك الجاري إن وُجد',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AuthTheme.textMuted,
                fontSize: 15,
              ),
            ),
          ),
        ],
      );
    }

    final items = <Widget>[];
    var shownActiveHeader = false;
    var shownNewHeader = false;

    for (final trip in state.trips) {
      final active = _isActive(trip);
      if (active && !shownActiveHeader) {
        shownActiveHeader = true;
        items.add(_sectionTitle('جاري التنفيذ'));
      } else if (!active && !shownNewHeader) {
        shownNewHeader = true;
        items.add(_sectionTitle('طلبات جديدة'));
      }
      items.add(
        DriverTripCard(
          trip: trip,
          offerLoading: state.submittingOffer,
          hasActiveTrip: state.hasActiveTrip,
          onTap: () => _openTripDetails(context, trip),
        ),
      );
      items.add(const SizedBox(height: 12));
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: items,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: AuthTheme.textDark,
        ),
      ),
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  final bool isOnline;
  final bool loading;
  final ValueChanged<bool> onChanged;

  const _OnlineToggle({
    required this.isOnline,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuthTheme.fieldBorder),
      ),
      child: Row(
        children: [
          Icon(
            isOnline ? Icons.wifi_tethering : Icons.wifi_tethering_off,
            color: isOnline ? const Color(0xFF0C9F6A) : AuthTheme.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isOnline ? 'متاح لاستقبال الطلبات' : 'غير متاح',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                color: isOnline
                    ? const Color(0xFF0C9F6A)
                    : AuthTheme.textMuted,
              ),
            ),
          ),
          if (loading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(
              value: isOnline,
              activeThumbColor: const Color(0xFF0C9F6A),
              onChanged: onChanged,
            ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'متاح' : 'غير متاح',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
