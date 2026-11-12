import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:motorent/config/google_maps_config.dart';

class PlaceSuggestion {
  final String placeId;
  final String description;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
  });
}

class MapLocationResult {
  final LatLng point;
  final String address;

  const MapLocationResult({
    required this.point,
    required this.address,
  });
}

class RouteDirectionsResult {
  final List<LatLng> points;
  final double distanceMeters;
  final int durationSeconds;
  final String distanceText;
  final String durationText;

  const RouteDirectionsResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.distanceText,
    required this.durationText,
  });

  double get distanceKm => distanceMeters / 1000.0;
}

class GoogleMapsService {
  GoogleMapsService._();

  static const _base = 'https://maps.googleapis.com/maps/api';
  static final _distance = Distance();

  static Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    LatLng? bias,
  }) async {
    final q = input.trim();
    if (q.length < 2) return const [];

    final params = <String, String>{
      'input': q,
      'key': kGoogleMapsApiKey,
      'language': 'ar',
      'components': 'country:eg',
    };
    if (bias != null) {
      params['location'] = '${bias.latitude},${bias.longitude}';
      params['radius'] = '50000';
    }

    final uri = Uri.parse('$_base/place/autocomplete/json').replace(
      queryParameters: params,
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return const [];

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
      return const [];
    }

    final predictions = (data['predictions'] as List?) ?? const [];
    return predictions
        .map((e) => PlaceSuggestion(
              placeId: (e['place_id'] ?? '').toString(),
              description: (e['description'] ?? '').toString(),
            ))
        .where((e) => e.placeId.isNotEmpty)
        .toList();
  }

  static Future<MapLocationResult?> placeDetails(String placeId) async {
    final uri = Uri.parse('$_base/place/details/json').replace(
      queryParameters: {
        'place_id': placeId,
        'fields': 'geometry,formatted_address,name',
        'language': 'ar',
        'key': kGoogleMapsApiKey,
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;

    final result = data['result'] as Map<String, dynamic>?;
    final loc = result?['geometry']?['location'] as Map<String, dynamic>?;
    if (loc == null) return null;

    final address = (result?['formatted_address'] ?? result?['name'] ?? '')
        .toString()
        .trim();
    return MapLocationResult(
      point: LatLng(
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      ),
      address: address.isEmpty
          ? '${loc['lat']}, ${loc['lng']}'
          : address,
    );
  }

  static Future<String> reverseGeocode(LatLng point) async {
    final uri = Uri.parse('$_base/geocode/json').replace(
      queryParameters: {
        'latlng': '${point.latitude},${point.longitude}',
        'language': 'ar',
        'key': kGoogleMapsApiKey,
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? const [];
    if (results.isEmpty) {
      return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    }
    final address = (results.first['formatted_address'] ?? '').toString().trim();
    if (address.isEmpty) {
      return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    }
    return address;
  }

  static Future<RouteDirectionsResult?> directions(
    LatLng origin,
    LatLng destination, {
    String mode = 'driving',
  }) async {
    final uri = Uri.parse('$_base/directions/json').replace(
      queryParameters: {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': mode,
        'language': 'ar',
        'key': kGoogleMapsApiKey,
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;

    final routes = (data['routes'] as List?) ?? const [];
    if (routes.isEmpty) return null;

    final route = routes.first as Map<String, dynamic>;
    final overview = route['overview_polyline']?['points']?.toString();
    final legs = (route['legs'] as List?) ?? const [];
    if (legs.isEmpty || overview == null || overview.isEmpty) return null;

    final leg = legs.first as Map<String, dynamic>;
    final distance = leg['distance'] as Map<String, dynamic>?;
    final duration = leg['duration'] as Map<String, dynamic>?;

    return RouteDirectionsResult(
      points: decodePolyline(overview),
      distanceMeters: (distance?['value'] as num?)?.toDouble() ?? 0,
      durationSeconds: (duration?['value'] as num?)?.toInt() ?? 0,
      distanceText: (distance?['text'] ?? '').toString(),
      durationText: (duration?['text'] ?? '').toString(),
    );
  }

  /// مسافة خط مستقيم (احتياطي لو فشل Directions).
  static double straightLineKm(LatLng a, LatLng b) {
    return _distance.as(LengthUnit.Kilometer, a, b);
  }

  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
