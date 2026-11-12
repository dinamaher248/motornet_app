import 'package:flutter_map/flutter_map.dart';

/// بلاطات خريطة للتطبيق.
/// Carto Voyager بقى يطلب API key، لذلك نستخدم Esri World Street Map.
class AppMapTiles {
  AppMapTiles._();

  /// Esri World Street Map — بدون مفتاح، ترتيب البلاط {z}/{y}/{x}.
  static const urlTemplate =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';

  static const userAgentPackageName = 'com.koshy.koshy.motorent';

  static TileLayer layer({double maxZoom = 19}) {
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: userAgentPackageName,
      maxZoom: maxZoom,
    );
  }
}
