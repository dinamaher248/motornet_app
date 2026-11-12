import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:motorent/services/google_maps_service.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

/// شاشة اختيار موقع احترافية (ليست ملاحة).
/// Google Maps Normal + Places + موقعي الحالي + تحريك حر + تثبيت الإحداثيات والعنوان.
class MapPage extends StatefulWidget {
  final LatLng? initialPoint;
  final String? title;

  const MapPage({super.key, this.initialPoint, this.title});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  gmaps.GoogleMapController? _mapController;
  LatLng _center = const LatLng(30.0444, 31.2357);
  LatLng? _selectedPoint;
  String? _selectedAddress;
  List<PlaceSuggestion> _suggestions = const [];
  bool _searching = false;
  bool _resolving = false;
  bool _mapReady = false;
  bool _programmaticMove = false;
  Timer? _debounce;
  Timer? _idleDebounce;

  static const _egypt = gmaps.LatLng(30.0444, 31.2357);

  @override
  void initState() {
    super.initState();
    if (widget.initialPoint != null) {
      _center = widget.initialPoint!;
      _selectedPoint = widget.initialPoint;
    } else {
      _goToMyLocation(silent: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _idleDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  gmaps.LatLng _toG(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);

  LatLng _fromG(gmaps.LatLng p) => LatLng(p.latitude, p.longitude);

  Future<void> _animateTo(LatLng point, {double zoom = 16}) async {
    _programmaticMove = true;
    setState(() {
      _center = point;
      _selectedPoint = point;
    });
    final c = _mapController;
    if (c != null && _mapReady) {
      await c.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(target: _toG(point), zoom: zoom),
        ),
      );
    }
    // بعد حركة برمجية نسمح بالـ reverse geocode مرة واحدةحدة
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _programmaticMove = false;
  }

  Future<void> _goToMyLocation({bool silent = false}) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فعّل خدمة الموقع أولاً')),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final point = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      await _animateTo(point, zoom: 16);
      await _resolveAddress(point, updateSearch: true);
    } catch (_) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الحصول على موقعك الحالي')),
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = value.trim();
      if (q.length < 2) {
        if (mounted) setState(() => _suggestions = const []);
        return;
      }
      setState(() => _searching = true);
      final results = await GoogleMapsService.autocomplete(
        q,
        bias: _selectedPoint ?? _center,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _searching = false;
      });
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    setState(() {
      _resolving = true;
      _suggestions = const [];
      _searchController.text = suggestion.description;
    });
    _searchFocus.unfocus();
    final details = await GoogleMapsService.placeDetails(suggestion.placeId);
    if (!mounted) return;
    if (details == null) {
      setState(() => _resolving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر جلب تفاصيل المكان')),
      );
      return;
    }
    setState(() {
      _selectedPoint = details.point;
      _selectedAddress = details.address;
      _resolving = false;
    });
    await _animateTo(details.point, zoom: 17);
  }

  Future<void> _resolveAddress(LatLng point, {bool updateSearch = false}) async {
    setState(() {
      _resolving = true;
      _selectedPoint = point;
    });
    final address = await GoogleMapsService.reverseGeocode(point);
    if (!mounted) return;
    setState(() {
      _selectedAddress = address;
      _resolving = false;
      if (updateSearch || _searchController.text.trim().isEmpty) {
        _searchController.text = address;
      }
    });
  }

  void _onCameraMove(gmaps.CameraPosition position) {
    _center = _fromG(position.target);
  }

  void _onCameraIdle() {
    if (_programmaticMove) return;
    _idleDebounce?.cancel();
    _idleDebounce = Timer(const Duration(milliseconds: 280), () {
      final point = _center;
      _resolveAddress(point, updateSearch: true);
    });
  }

  void _confirm() {
    final point = _selectedPoint ?? _center;
    final address = (_selectedAddress ?? _searchController.text).trim();
    Navigator.pop(
      context,
      MapLocationResult(
        point: point,
        address: address.isEmpty
            ? '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}'
            : address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialPoint != null
        ? _toG(widget.initialPoint!)
        : _egypt;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ?? 'تحديد الموقع',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'موقعي الحالي',
            onPressed: () => _goToMyLocation(),
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Stack(
        children: [
          gmaps.GoogleMap(
            initialCameraPosition: gmaps.CameraPosition(
              target: initial,
              zoom: 14,
            ),
            mapType: gmaps.MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
            buildingsEnabled: true,
            indoorViewEnabled: false,
            trafficEnabled: false,
            onMapCreated: (controller) async {
              _mapController = controller;
              _mapReady = true;
              if (widget.initialPoint != null) {
                await _animateTo(widget.initialPoint!, zoom: 16);
                await _resolveAddress(widget.initialPoint!, updateSearch: true);
              }
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
          ),

          // دبوس ثابت في منتصف الشاشة — حرّك الخريطة تحته
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(
                  Icons.location_on,
                  color: AuthTheme.primary,
                  size: 48,
                  shadows: [
                    Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(14),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    textInputAction: TextInputAction.search,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن شارع أو معلم أو مكان...',
                      hintStyle: const TextStyle(fontFamily: 'Cairo'),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searching || _resolving
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : (_searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _suggestions = const []);
                                  },
                                  icon: const Icon(Icons.clear),
                                )),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _suggestions[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.place_outlined,
                            color: AuthTheme.primary,
                          ),
                          title: Text(
                            item.description,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                            ),
                          ),
                          onTap: () => _selectSuggestion(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            right: 16,
            bottom: 170,
            child: FloatingActionButton.small(
              heroTag: 'my_loc',
              backgroundColor: Colors.white,
              foregroundColor: AuthTheme.primary,
              onPressed: () => _goToMyLocation(),
              child: const Icon(Icons.my_location),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        (_selectedAddress ?? 'حرّك الخريطة لتحديد الموقع').trim(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(_selectedPoint ?? _center).latitude.toStringAsFixed(5)}, '
                        '${(_selectedPoint ?? _center).longitude.toStringAsFixed(5)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _resolving ? null : _confirm,
                    child: Text(
                      _resolving ? 'جاري تحديد العنوان...' : 'تأكيد الموقع',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
