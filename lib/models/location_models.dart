class AreaModel {
  final int? id;
  final String name;

  AreaModel({this.id, required this.name});

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: _parseId(json['id']),
      name: _parseName(json),
    );
  }
}

class GovernorateModel {
  final int? id;
  final String name;
  final List<AreaModel> areas;

  GovernorateModel({
    this.id,
    required this.name,
    required this.areas,
  });

  factory GovernorateModel.fromJson(Map<String, dynamic> json) {
    final areasJson =
        (json['areas'] ?? json['children'] ?? json['locations'] ?? [])
            as List?;
    return GovernorateModel(
      id: _parseId(json['id']),
      name: _parseName(json),
      areas: (areasJson ?? [])
          .map((e) => AreaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LocationsParser {
  static List<GovernorateModel> parse(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return [];
    }

    final rawList = responseData['locations'] ??
        responseData['governorates'] ??
        responseData['data'];

    if (rawList is! List) {
      return [];
    }

    return _parseList(rawList);
  }

  static List<GovernorateModel> _parseList(List list) {
    if (list.isEmpty) {
      return [];
    }

    final first = list.first;
    if (first is! Map<String, dynamic>) {
      return [];
    }

    final hasNestedChildren = first.containsKey('areas') ||
        first.containsKey('children') ||
        first.containsKey('locations');

    if (hasNestedChildren) {
      return list
          .map((e) => GovernorateModel.fromJson(e as Map<String, dynamic>))
          .where((g) => g.name.isNotEmpty)
          .toList();
    }

    if (first.containsKey('parent_id')) {
      return _buildTreeFromFlat(list);
    }

    return list
        .map((e) => GovernorateModel.fromJson(e as Map<String, dynamic>))
        .where((g) => g.name.isNotEmpty)
        .toList();
  }

  static List<GovernorateModel> _buildTreeFromFlat(List list) {
    final parents = <int, String>{};
    final children = <int, List<AreaModel>>{};

    for (final item in list) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      if (item['is_active'] == 0 || item['is_active'] == false) {
        continue;
      }

      final id = _parseId(item['id']);
      final name = _parseName(item);
      if (id == null || name.isEmpty) {
        continue;
      }

      final parentId = _parseId(item['parent_id']);
      if (parentId == null) {
        parents[id] = name;
      } else {
        children.putIfAbsent(parentId, () => []);
        children[parentId]!.add(AreaModel(id: id, name: name));
      }
    }

    final result = parents.entries
        .map(
          (entry) => GovernorateModel(
            id: entry.key,
            name: entry.value,
            areas: children[entry.key] ?? [],
          ),
        )
        .toList();

    result.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    return result;
  }
}

String _parseName(Map<String, dynamic> json) {
  final name = json['name']?.toString();
  if (name != null && name.isNotEmpty) {
    return name;
  }

  final nameAr = json['name_ar']?.toString();
  if (nameAr != null && nameAr.isNotEmpty) {
    return nameAr;
  }

  final nameEn = json['name_en']?.toString();
  if (nameEn != null && nameEn.isNotEmpty) {
    return nameEn;
  }

  return '';
}

int? _parseId(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  return int.tryParse(value.toString());
}

class LocationMatch {
  final GovernorateModel governorate;
  final AreaModel? area;
  final String displayName;

  const LocationMatch({
    required this.governorate,
    this.area,
    required this.displayName,
  });
}
