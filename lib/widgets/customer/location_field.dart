import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:motorent/pages/map_page.dart';
import 'package:motorent/pages/map_view_page.dart';
import 'package:motorent/services/google_maps_service.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class LocationField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final LatLng? point;
  final VoidCallback onMapPick;
  final ValueChanged<LatLng?>? onPointChanged;

  const LocationField({
    super.key,
    required this.label,
    required this.controller,
    required this.point,
    required this.onMapPick,
    this.onPointChanged,
  });

  @override
  State<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends State<LocationField> {
  List<PlaceSuggestion> _suggestions = const [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _openMap(BuildContext context) async {
    final result = await Navigator.push<MapLocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPage(
          initialPoint: widget.point,
          title: widget.label,
        ),
      ),
    );

    if (result != null) {
      widget.controller.text = result.address;
      widget.onPointChanged?.call(result.point);
      widget.onMapPick();
      setState(() => _suggestions = const []);
    }
  }

  Future<void> _openView(BuildContext context) async {
    if (widget.point != null) {
      await openLocationOnMap(
        context,
        title: widget.label,
        address: widget.controller.text.trim(),
        lat: widget.point!.latitude,
        lng: widget.point!.longitude,
      );
      return;
    }
    final address = widget.controller.text.trim();
    if (address.isNotEmpty) {
      await openLocationOnMap(
        context,
        title: widget.label,
        address: address,
      );
      return;
    }
    await _openMap(context);
  }

  void _onChanged(String value) {
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
        bias: widget.point,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _searching = false;
      });
    });
  }

  Future<void> _pickSuggestion(PlaceSuggestion item) async {
    setState(() {
      _searching = true;
      _suggestions = const [];
    });
    final details = await GoogleMapsService.placeDetails(item.placeId);
    if (!mounted) return;
    setState(() => _searching = false);
    if (details == null) return;
    widget.controller.text = details.address;
    widget.onPointChanged?.call(details.point);
    widget.onMapPick();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            color: AuthTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'ابحث عن مكان أو حدده من الخريطة',
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searching)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                IconButton(
                  tooltip: 'عرض الموقع على الخريطة',
                  onPressed: () => _openView(context),
                  icon: const Icon(Icons.place_outlined, color: AuthTheme.primary),
                ),
                IconButton(
                  tooltip: 'تحديد من الخريطة',
                  onPressed: () => _openMap(context),
                  icon: const Icon(Icons.map_outlined, color: AuthTheme.primary),
                ),
              ],
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'برجاء إدخال ${widget.label}';
            }
            return null;
          },
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AuthTheme.fieldBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length > 5 ? 5 : _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.search, color: AuthTheme.primary),
                  title: Text(
                    item.description,
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                  ),
                  onTap: () => _pickSuggestion(item),
                );
              },
            ),
          ),
      ],
    );
  }
}
