import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/services/data/models/service_models.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/presentation/pages/place_booking_screen.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/services/nearby_store_card.dart';

class PlacesBookingTab extends StatefulWidget {
  const PlacesBookingTab({super.key});

  @override
  State<PlacesBookingTab> createState() => _PlacesBookingTabState();
}

class _PlacesBookingTabState extends State<PlacesBookingTab> {
  List<Store> _places = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      double? lat;
      double? lng;
      try {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.whileInUse ||
            perm == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition();
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {}

      final token = CacheHelper.getData(key: 'token');
      final res = await Dio().get(
        servicesPlacesEP,
        queryParameters: {
          'kind': 'place',
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
        },
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (s) => s != null && s < 600,
        ),
      );

      if (res.statusCode != 200) {
        throw Exception('تعذر تحميل الأماكن');
      }

      final data = res.data;
      List list = const [];
      if (data is Map) {
        final raw = data['data'] ?? data['places'] ?? data['stores'];
        if (raw is List) list = raw;
      } else if (data is List) {
        list = data;
      }

      final places = list
          .whereType<Map>()
          .map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;
      setState(() {
        _places = places;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          const Text(
            'احجز ساعة في المكان',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AuthTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'اختار المكان واتصل مباشرة للحجز',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: AuthTheme.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null && _places.isEmpty)
            Center(
              child: Column(
                children: [
                  Text(_error!, style: const TextStyle(fontFamily: 'Cairo')),
                  TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                ],
              ),
            )
          else if (_places.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: Text(
                  'لا توجد أماكن متاحة حالياً',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AuthTheme.textMuted,
                  ),
                ),
              ),
            )
          else
            ..._places.map(
              (place) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NearbyStoreCard(
                  store: place,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaceBookingScreen(storeId: place.id),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
