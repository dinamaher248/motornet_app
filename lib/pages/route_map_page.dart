import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:motorent/services/google_maps_service.dart';
import 'package:motorent/widgets/app_map_tiles.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

/// عرض المسار بين نقطتين مع المسافة والمدة وتحريك نقطة على المسار.
class RouteMapPage extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String? originLabel;
  final String? destinationLabel;
  final String title;

  const RouteMapPage({
    super.key,
    required this.origin,
    required this.destination,
    this.originLabel,
    this.destinationLabel,
    this.title = 'المسار والمسافة',
  });

  @override
  State<RouteMapPage> createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  final _mapController = MapController();
  RouteDirectionsResult? _route;
  String? _error;
  bool _loading = true;
  bool _following = false;
  int _followIndex = 0;
  Timer? _followTimer;
  LatLng? _movingPoint;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _followTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final route = await GoogleMapsService.directions(
      widget.origin,
      widget.destination,
    );
    if (!mounted) return;

    if (route == null || route.points.isEmpty) {
      final km = GoogleMapsService.straightLineKm(
        widget.origin,
        widget.destination,
      );
      setState(() {
        _loading = false;
        _route = RouteDirectionsResult(
          points: [widget.origin, widget.destination],
          distanceMeters: km * 1000,
          durationSeconds: ((km / 40) * 3600).round(),
          distanceText: '${km.toStringAsFixed(1)} كم',
          durationText: 'تقريبي',
        );
        _error = 'تعذر جلب مسار الطريق — عرض خط تقريبي';
        _movingPoint = widget.origin;
      });
    } else {
      setState(() {
        _loading = false;
        _route = route;
        _movingPoint = route.points.first;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
  }

  void _fitBounds() {
    final points = _route?.points;
    if (points == null || points.isEmpty) return;
    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    } catch (_) {
      _mapController.move(widget.origin, 13);
    }
  }

  void _toggleFollow() {
    if (_following) {
      _followTimer?.cancel();
      setState(() => _following = false);
      return;
    }
    final points = _route?.points ?? const [];
    if (points.length < 2) return;

    setState(() {
      _following = true;
      _followIndex = 0;
      _movingPoint = points.first;
    });

    _followTimer = Timer.periodic(const Duration(milliseconds: 280), (_) {
      if (!mounted || _route == null) return;
      final pts = _route!.points;
      if (_followIndex >= pts.length - 1) {
        _followTimer?.cancel();
        setState(() => _following = false);
        return;
      }
      _followIndex++;
      final p = pts[_followIndex];
      setState(() => _movingPoint = p);

      // ميل الكاميرا باتجاه الحركة قليلاً عبر الزوم/المركز
      double bearing = 0;
      if (_followIndex > 0) {
        bearing = _bearingBetween(pts[_followIndex - 1], p);
      }
      _mapController.moveAndRotate(p, 16, bearing);
    });
  }

  double _bearingBetween(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.origin,
              initialZoom: 13,
            ),
            children: [
              AppMapTiles.layer(),
              if (route != null && route.points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route.points,
                      strokeWidth: 5,
                      color: AuthTheme.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 48,
                    height: 48,
                    point: widget.origin,
                    child: const Icon(
                      Icons.trip_origin,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                  Marker(
                    width: 48,
                    height: 48,
                    point: widget.destination,
                    child: const Icon(
                      Icons.flag,
                      color: Colors.red,
                      size: 36,
                    ),
                  ),
                  if (_movingPoint != null)
                    Marker(
                      width: 44,
                      height: 44,
                      point: _movingPoint!,
                      child: const Icon(
                        Icons.navigation,
                        color: AuthTheme.primary,
                        size: 34,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                      widget.originLabel?.isNotEmpty == true
                          ? 'من: ${widget.originLabel}'
                          : 'من: نقطة الاستلام',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.destinationLabel?.isNotEmpty == true
                          ? 'إلى: ${widget.destinationLabel}'
                          : 'إلى: نقطة التسليم',
                      style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _infoChip(
                            Icons.straighten,
                            route?.distanceText ?? '...',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _infoChip(
                            Icons.schedule,
                            route?.durationText ?? '...',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _loadRoute,
                            icon: const Icon(Icons.refresh),
                            label: const Text(
                              'تحديث',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AuthTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _loading || route == null
                                ? null
                                : _toggleFollow,
                            icon: Icon(
                              _following ? Icons.stop : Icons.play_arrow,
                            ),
                            label: Text(
                              _following ? 'إيقاف' : 'امشِ على المسار',
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AuthTheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
