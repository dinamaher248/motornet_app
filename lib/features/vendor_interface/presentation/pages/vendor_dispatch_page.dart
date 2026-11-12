import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/bidding_system/presentation/pages/bidding_home_page.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_order_dispatch_prefill.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/rating_stars.dart';

/// طلب وسيلة نقل: توصيلة برو → اختيار مركبة → نموذج مع عنوان العميل.
/// بعد النشر تظهر عروض السائقين.
class VendorDispatchPage extends StatefulWidget {
  final VendorOrder order;

  const VendorDispatchPage({super.key, required this.order});

  @override
  State<VendorDispatchPage> createState() => _VendorDispatchPageState();
}

class _VendorDispatchPageState extends State<VendorDispatchPage> {
  final _dio = Dio();
  List<Map<String, dynamic>> _offers = const [];
  bool _loadingOffers = false;
  bool _dispatching = false;
  Timer? _poll;

  late final VendorOrderDispatchPrefill _prefill =
      VendorOrderDispatchPrefill.fromOrder(widget.order);

  bool get _showOffers =>
      widget.order.canViewDeliveryOffers ||
      (widget.order.biddingTripId ?? 0) > 0;

  Options get _auth => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        validateStatus: (s) => s != null && s < 600,
      );

  Map<String, dynamic> get _orderTypePayload => {
        'order_type': widget.order.isCustom ? 'custom' : 'normal',
      };

  @override
  void initState() {
    super.initState();
    if (_showOffers) {
      _loadOffers();
      _poll = Timer.periodic(const Duration(seconds: 8), (_) => _loadOffers());
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _loadOffers() async {
    setState(() => _loadingOffers = true);
    try {
      final res = await _dio.get(
        vendorOrderDeliveryOffersEP(widget.order.id),
        queryParameters: _orderTypePayload,
        options: _auth,
      );
      if (!mounted) return;
      final list = res.data is Map
          ? (res.data['data'] ?? res.data['offers'])
          : null;
      setState(() {
        _loadingOffers = false;
        _offers = (list is List ? list : const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOffers = false);
    }
  }

  Future<void> _acceptOffer(int offerId) async {
    setState(() => _dispatching = true);
    try {
      final res = await _dio.post(
        vendorOrderAcceptDeliveryOfferEP(widget.order.id),
        data: {
          'offer_id': offerId,
          ..._orderTypePayload,
        },
        options: _auth,
      );
      if (res.statusCode != 200) {
        throw Exception(
          (res.data is Map ? res.data['message'] : null)?.toString() ??
              'تعذر قبول العرض',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم اختيار السائق',
            style: TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _dispatching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showOffers ? 'عروض وسيلة النقل' : 'طلب وسيلة نقل',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: AuthTheme.screenBackground(),
        child: _showOffers ? _offersView() : _transportHubView(),
      ),
    );
  }

  Widget _transportHubView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: BiddingHomePage(
        embedInParent: true,
        vendorDispatch: _prefill,
      ),
    );
  }

  Widget _offersView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'عروض السائقين',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(onPressed: _loadOffers, icon: const Icon(Icons.refresh)),
          ],
        ),
        if (_loadingOffers && _offers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_offers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'لا توجد عروض بعد — انتظر السائقين',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AuthTheme.textMuted,
                ),
              ),
            ),
          )
        else
          ..._offers.map((o) {
            final driver = o['driver'] is Map
                ? Map<String, dynamic>.from(o['driver'] as Map)
                : <String, dynamic>{};
            final price = double.tryParse('${o['price'] ?? 0}') ?? 0;
            final offerId = int.tryParse('${o['id'] ?? 0}') ?? 0;
            final rating =
                double.tryParse('${driver['avg_rating'] ?? 0}') ?? 0;
            final count =
                int.tryParse('${driver['ratings_count'] ?? 0}') ?? 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(
                  driver['name']?.toString() ?? 'سائق',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RatingStars(rating: rating, count: count, compact: true),
                    Text(
                      '${price.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        color: AuthTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: _dispatching || offerId <= 0
                      ? null
                      : () => _acceptOffer(offerId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'قبول',
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
