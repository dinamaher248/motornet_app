import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/services/core/utils/location_util.dart';
import 'package:motorent/features/services/data/models/service_models.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/services/place_booking_service.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class ProfessionsTab extends StatefulWidget {
  const ProfessionsTab({super.key});

  @override
  State<ProfessionsTab> createState() => _ProfessionsTabState();
}

class _ProfessionsTabState extends State<ProfessionsTab> {
  final _search = TextEditingController();
  List<Store> _all = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Store> get _filtered {
    final q = _search.text.trim();
    if (q.isEmpty) return _all;
    return _all.where((p) {
      final haystack = [
        p.name,
        p.address ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(q.toLowerCase());
    }).toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = CacheHelper.getData(key: 'token');
      final q = _search.text.trim();
      final location = await getUserLatLng();
      final res = await Dio().get(
        servicesProfessionsEP,
        queryParameters: {
          'kind': 'profession',
          if (q.isNotEmpty) 'q': q,
          if (location != null) 'lat': location.lat,
          if (location != null) 'lng': location.lng,
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
        throw Exception('تعذر تحميل المهن');
      }

      final data = res.data;
      List list = const [];
      if (data is Map) {
        final raw = data['data'] ?? data['places'] ?? data['stores'];
        if (raw is List) list = raw;
      } else if (data is List) {
        list = data;
      }

      final items = list
          .whereType<Map>()
          .map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        // الأقرب أولاً
        ..sort((a, b) {
          final da = a.distanceM;
          final db = b.distanceM;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

      if (!mounted) return;
      setState(() {
        _all = items;
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

  Future<void> _call(Store store) async {
    final ok = await PlaceBookingService.callAndBook(
      phone: store.phone,
      storeId: store.id,
      kind: 'profession',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'تم الاتصال وتسجيل الحجز' : 'لا يوجد رقم اتصال لهذه المهنة',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'ابحث عن مهنة...',
              hintStyle: const TextStyle(fontFamily: 'Cairo'),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AuthTheme.fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AuthTheme.fieldBorder),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Text(
                                _error ??
                                    (_search.text.trim().isEmpty
                                        ? 'لا توجد مهن متاحة حالياً'
                                        : 'لا توجد مهنة بهذه الكلمة'),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AuthTheme.textMuted,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _ProfessionCard(
                              store: item,
                              onCall: () => _call(item),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

class _ProfessionCard extends StatelessWidget {
  final Store store;
  final VoidCallback onCall;

  const _ProfessionCard({required this.store, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AuthTheme.fieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              store.name,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            if ((store.address ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: AuthTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      store.address!,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AuthTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.call, size: 18),
                label: const Text(
                  'اتصال',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0C9F6A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
