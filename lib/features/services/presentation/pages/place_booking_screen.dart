import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/presentation/bloc/service_bloc.dart';
import 'package:motorent/features/services/presentation/pages/my_bookings_screen.dart';
import 'package:motorent/features/services/presentation/widgets/reservation_form_section.dart';
import 'package:motorent/features/services/services_injection.dart';
import 'package:motorent/services/place_booking_service.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class PlaceBookingScreen extends StatefulWidget {
  final int storeId;

  /// تصنيف الحجز (مثل فنادق) — يحدد حقول النموذج الديناميكي.
  /// لو لم يُمرَّر نستخدم `store.categoryId` القادم من السيرفر.
  final int? categoryId;

  const PlaceBookingScreen({
    super.key,
    required this.storeId,
    this.categoryId,
  });

  @override
  State<PlaceBookingScreen> createState() => _PlaceBookingScreenState();
}

class _PlaceBookingScreenState extends State<PlaceBookingScreen> {
  bool _showCall = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = ServicesInjection.createBloc();
        _load(bloc);
        return bloc;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F8),
        appBar: AppBar(
          title: const Text(
            'طلب حجز',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<ServiceBloc, ServiceState>(
          builder: (context, state) {
            if (state is ServiceLoading || state is ServiceInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            final store = state is StoreDetailsLoaded ? state.store : null;
            if (store == null) {
              return Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('رجوع'),
                ),
              );
            }

            final photos = <String>[];
            final cover = resolveStorageImageUrl(store.image);
            if (cover.isNotEmpty) photos.add(cover);
            for (final product in store.products) {
              final url = resolveStorageImageUrl(product.image);
              if (url.isNotEmpty && !photos.contains(url)) {
                photos.add(url);
              }
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (photos.isEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AuthTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.photo_outlined,
                        size: 56, color: AuthTheme.primary),
                  )
                else
                  SizedBox(
                    height: 210,
                    child: PageView.builder(
                      itemCount: photos.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            photos[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AuthTheme.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  store.name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                if ((store.address ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 18, color: AuthTheme.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          store.address!,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AuthTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                if ((store.categoryId ?? widget.categoryId) != null)
                  ReservationFormSection(
                    merchantId: store.id,
                    categoryId: (store.categoryId ?? widget.categoryId)!,
                    onSubmitted: _onSubmitted,
                  )
                else if (!_showCall)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => setState(() => _showCall = true),
                      icon: const Icon(Icons.schedule),
                      label: const Text(
                        'حجز',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
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
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _call(store),
                      icon: const Icon(Icons.call),
                      label: const Text(
                        'اتصال بالمكان',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C9F6A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onSubmitted(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    // بعد إرسال الاستفسار نفتح «حجوزاتي» لمتابعة رد المكان.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
    );
  }

  Future<void> _load(ServiceBloc bloc) async {
    double? lat;
    double? lng;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}
    bloc.add(FetchStoreDetailsEvent(widget.storeId, lat: lat, lng: lng));
  }

  Future<void> _call(Store store) async {
    final ok = await PlaceBookingService.callAndBook(
      phone: store.phone,
      storeId: store.id,
      kind: 'place',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'تم تسجيل الحجز والاتصال بالمكان' : 'لا يوجد رقم اتصال لهذا المكان',
        ),
      ),
    );
  }
}
