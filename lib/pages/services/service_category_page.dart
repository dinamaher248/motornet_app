import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/local_service_models.dart';
import 'package:motorent/pages/services/merchant_detail_page.dart';
import 'package:motorent/widgets/rating_stars.dart';

import 'package:motorent/services/local_service_api.dart';
import 'package:motorent/widgets/storage_network_avatar.dart';

class ServiceCategoryPage extends StatefulWidget {
  final ServiceCategoryItem category;

  const ServiceCategoryPage({super.key, required this.category});

  @override
  State<ServiceCategoryPage> createState() => _ServiceCategoryPageState();
}

class _ServiceCategoryPageState extends State<ServiceCategoryPage> {
  final _api = LocalServiceApi();
  String _title = '';
  List<MerchantListItem> _merchants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    double? lat;
    double? lng;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    try {
      final result = await _api.fetchMerchants(
        widget.category.slug,
        lat: lat,
        lng: lng,
      );
      if (!mounted) return;
      setState(() {
        _title = result.title.isNotEmpty
            ? result.title
            : '${widget.category.name} قريبة منك';
        _merchants = result.merchants;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title.isEmpty ? widget.category.name : _title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _merchants.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('لا توجد متاجر في هذا القسم حالياً')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(14),
                      itemCount: _merchants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final m = _merchants[index];
                        return Card(
                          child: ListTile(
                            leading: StorageNetworkAvatar(
                              imagePath: resolveStorageImageUrl(m.image),
                              initial: m.name.isNotEmpty ? m.name.characters.first : 'م',
                              size: 48,
                            ),
                            title: Text(m.name,
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RatingStars(
                                  rating: m.avgRating,
                                  count: m.ratingsCount,
                                  compact: true,
                                ),
                                if (m.distanceLabel != null)
                                  Text('يبعد ${m.distanceLabel}'),
                                Text(
                                  m.isOpen ? 'مفتوح الآن' : 'مغلق',
                                  style: TextStyle(
                                    color: m.isOpen ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            trailing: const Icon(Icons.chevron_left),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MerchantDetailPage(
                                    merchantId: m.id,
                                    distanceLabel: m.distanceLabel,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
