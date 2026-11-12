import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/local_service_models.dart';
import 'package:motorent/pages/services/custom_order_page.dart';
import 'package:motorent/pages/services/service_order_confirm_page.dart';
import 'package:motorent/services/local_service_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/rating_stars.dart';
import 'package:motorent/widgets/storage_network_avatar.dart';

class MerchantDetailPage extends StatefulWidget {
  final int merchantId;
  final String? distanceLabel;

  const MerchantDetailPage({
    super.key,
    required this.merchantId,
    this.distanceLabel,
  });

  @override
  State<MerchantDetailPage> createState() => _MerchantDetailPageState();
}

class _MerchantDetailPageState extends State<MerchantDetailPage> {
  final _api = LocalServiceApi();
  MerchantDetail? _merchant;
  MerchantProductItem? _selected;
  bool _loading = true;
  double? _userLat;
  double? _userLng;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _resolveUserLocation();
      final merchant = await _api.fetchMerchant(widget.merchantId);
      if (!mounted) return;
      setState(() {
        _merchant = merchant;
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

  Future<void> _resolveUserLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _userLat = pos.latitude;
        _userLng = pos.longitude;
      });
    } catch (_) {}
  }

  String _distanceOf(MerchantDetail merchant) {
    final fromProp = (widget.distanceLabel ?? '').trim();
    if (fromProp.isNotEmpty && !fromProp.contains('غير')) return fromProp;
    final sLat = merchant.lat;
    final sLng = merchant.lng;
    if (sLat == null || sLng == null || (sLat == 0 && sLng == 0)) {
      return 'المتجر لم يحدد موقعه';
    }
    if (_userLat == null || _userLng == null) {
      return 'جاري حساب المسافة…';
    }
    final meters =
        Geolocator.distanceBetween(_userLat!, _userLng!, sLat, sLng);
    if (meters < 1000) return '${meters.round()} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  @override
  Widget build(BuildContext context) {
    final merchant = _merchant;
    final imageUrl =
        merchant == null ? '' : resolveStorageImageUrl(merchant.image);
    final payments = merchant == null
        ? const <PaymentMethodOption>[]
        : PaymentMethodOption.dedupe(merchant.paymentMethods);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      bottomNavigationBar: _selected == null || merchant == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceOrderConfirmPage(
                          merchant: merchant,
                          product: _selected!,
                          distanceLabel: _distanceOf(merchant),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'احجز الآن',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : merchant == null
              ? const Center(child: Text('تعذر تحميل المتجر'))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 200,
                      backgroundColor: AuthTheme.primary,
                      foregroundColor: Colors.white,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (imageUrl.isNotEmpty)
                              Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AuthTheme.primary,
                                  child: const Icon(
                                    Icons.storefront,
                                    size: 72,
                                    color: Colors.white70,
                                  ),
                                ),
                              )
                            else
                              Container(
                                color: AuthTheme.primary,
                                child: const Icon(
                                  Icons.storefront,
                                  size: 72,
                                  color: Colors.white70,
                                ),
                              ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.15),
                                    Colors.black.withValues(alpha: 0.65),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: Text(
                                merchant.name,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AuthTheme.fieldBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    merchant.name,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  RatingStars(
                                    rating: merchant.avgRating,
                                    count: merchant.ratingsCount,
                                    compact: true,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.near_me_outlined,
                                        size: 16,
                                        color: AuthTheme.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          _distanceOf(merchant),
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            color: AuthTheme.textMuted,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        merchant.isOpen ? 'مفتوح الآن' : 'مغلق',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: merchant.isOpen
                                              ? const Color(0xFF0C9F6A)
                                              : Colors.red,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'طرق الدفع المتاحة',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: payments
                                        .map(
                                          (p) => Chip(
                                            label: Text(
                                              p.label,
                                              style: const TextStyle(
                                                fontFamily: 'Cairo',
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AuthTheme.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CustomOrderPage(merchant: merchant),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.edit_note),
                                label: const Text(
                                  'اطلب أي شيء',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'المنتجات',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (merchant.products.isEmpty)
                              const Text(
                                'لا توجد منتجات حالياً',
                                style: TextStyle(fontFamily: 'Cairo'),
                              )
                            else
                              ...merchant.products.map((product) {
                                final selected = _selected?.id == product.id;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: selected
                                          ? AuthTheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () =>
                                        setState(() => _selected = product),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          if (product.image != null &&
                                              product.image!.isNotEmpty)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                resolveStorageImageUrl(
                                                    product.image),
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          else
                                            StorageNetworkAvatar(
                                              imagePath: null,
                                              initial:
                                                  product.name.characters.first,
                                              size: 56,
                                            ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  style: const TextStyle(
                                                    fontFamily: 'Cairo',
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  '${product.price} ج.م',
                                                  style: const TextStyle(
                                                    fontFamily: 'Cairo',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (selected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: AuthTheme.primary,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
