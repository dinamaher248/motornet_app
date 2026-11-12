import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:motorent/widgets/app_map_tiles.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows a pickup/delivery pin on the map. Opens external maps as optional action.
class MapViewPage extends StatelessWidget {
  final String title;
  final String? address;
  final LatLng point;

  const MapViewPage({
    super.key,
    required this.title,
    required this.point,
    this.address,
  });

  Future<void> _openExternal() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'فتح في خرائط جوجل',
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_new),
          ),
        ],
      ),
      body: Column(
        children: [
          if ((address ?? '').trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Colors.white,
              child: Text(
                address!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: AuthTheme.textDark,
                ),
              ),
            ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                AppMapTiles.layer(),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 56,
                      height: 56,
                      point: point,
                      child: const Icon(
                        Icons.location_on,
                        color: AuthTheme.primary,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> openLocationOnMap(
  BuildContext context, {
  required String title,
  String? address,
  double? lat,
  double? lng,
}) async {
  if (lat == null || lng == null) {
    final q = Uri.encodeComponent((address ?? title).trim());
    if (q.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد إحداثيات لعرض الخريطة')),
      );
      return;
    }
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return;
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MapViewPage(
        title: title,
        address: address,
        point: LatLng(lat, lng),
      ),
    ),
  );
}
