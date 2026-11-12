import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/models/order_tracking_models.dart';
import 'package:motorent/services/order_tracking_api.dart';
import 'package:motorent/services/ride_chat_lock.dart';
import 'package:motorent/widgets/app_map_tiles.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/rating_stars.dart';
import 'package:motorent/widgets/storage_network_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

/// شاشة جاري التنفيذ — خريطة + متابعة + اتصال مباشر.
class ActiveOrderTrackingPage extends StatefulWidget {
  final String type;
  final int id;
  final bool isDriverView;

  const ActiveOrderTrackingPage({
    super.key,
    required this.type,
    required this.id,
    this.isDriverView = false,
  });

  @override
  State<ActiveOrderTrackingPage> createState() =>
      _ActiveOrderTrackingPageState();
}

class _ActiveOrderTrackingPageState extends State<ActiveOrderTrackingPage> {
  final _api = OrderTrackingApi();
  MapController? _mapController;
  OrderTrackingData? _data;
  bool _loading = true;
  bool _acting = false;
  bool _mapReady = false;
  Timer? _poll;
  bool _ratingShown = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _load();
    _poll =
        Timer.periodic(const Duration(seconds: 8), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final data = await _api.fetch(widget.type, widget.id);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
      // لا نحرّك الكاميرا إلا بعد onMapReady لتفادي LateInitializationError
      if (_mapReady) {
        _scheduleFitMap(data);
      }
      if (data.isCompleted) {
        _poll?.cancel();
        await RideChatLock.closeRoom(
          data.effectiveChatRoomId,
          orderType: data.type,
          orderId: data.id,
        );
        await _maybeRate(data);
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  void _scheduleFitMap(OrderTrackingData data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fitMap(data);
    });
  }

  void _fitMap(OrderTrackingData data) {
    final controller = _mapController;
    if (!_mapReady || controller == null) return;
    final points = <LatLng>[];
    if (data.pickupLat != null && data.pickupLng != null) {
      points.add(LatLng(data.pickupLat!, data.pickupLng!));
    }
    if (data.dropoffLat != null && data.dropoffLng != null) {
      points.add(LatLng(data.dropoffLat!, data.dropoffLng!));
    }
    final d = data.driver;
    if (d?.lat != null && d?.lng != null) {
      points.add(LatLng(d!.lat!, d.lng!));
    }
    if (points.isEmpty) return;
    try {
      if (points.length == 1) {
        controller.move(points.first, 14);
        return;
      }
      final bounds = LatLngBounds.fromPoints(points);
      controller.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    } catch (_) {
      // تجاهل إن الخريطة اتعملت dispose أو لسه مش متوصلة
    }
  }

  Future<void> _maybeRate(OrderTrackingData data) async {
    if (_ratingShown || !mounted) return;
    _ratingShown = true;
    final ratee = data.rateeUserId;
    if (ratee == null || ratee <= 0) return;
    final contextType = data.type == 'bidding_trip'
        ? 'bidding_trip'
        : data.type == 'service_order'
            ? 'service_order'
            : 'trip_request';
    await showRateSheet(
      context,
      title: widget.isDriverView ? 'قيّم العميل' : 'قيّم السائق',
      contextType: contextType,
      contextId: data.id,
      rateeUserId: ratee,
    );
  }

  Future<void> _handToDriver() async {
    setState(() => _acting = true);
    try {
      final data = await _api.handToDriver(widget.type, widget.id);
      if (!mounted) return;
      setState(() {
        _data = data;
        _acting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تأكيد تسليم الطلب للسائق')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _endOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الطلب'),
        content: Text(
          (_data?.handedToDriver == true)
              ? 'هل تريد إنهاء الطلب الآن؟'
              : 'هل تريد إنهاء الطلب؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('رجوع'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _acting = true);
    try {
      await _api.cancel(widget.type, widget.id);
      if (!mounted) return;
      await RideChatLock.closeRoom(
        _data?.effectiveChatRoomId,
        orderType: _data?.type,
        orderId: _data?.id,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmDelivery() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تم التسليم',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'هل أنت متأكد من التسليم؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('رجوع', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0C9F6A),
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'نعم',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _acting = true);
    try {
      await _api.confirmDelivery(widget.type, widget.id);
      if (!mounted) return;
      final data = await _api.fetch(widget.type, widget.id);
      await RideChatLock.closeRoom(
        data.effectiveChatRoomId,
        orderType: data.type,
        orderId: data.id,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _acting = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنهاء الطلب بعد التسليم')),
      );
      await _maybeRate(data);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openGoogleMaps({
    required double? lat,
    required double? lng,
    String? address,
  }) async {
    final uris = <Uri>[];
    if (lat != null && lng != null) {
      uris.add(Uri.parse('google.navigation:q=$lat,$lng&mode=d'));
      uris.add(Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
      ));
      uris.add(Uri.parse('geo:$lat,$lng?q=$lat,$lng'));
    } else if ((address ?? '').trim().isNotEmpty) {
      final q = Uri.encodeComponent(address!.trim());
      uris.add(Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$q&travelmode=driving',
      ));
    }
    if (uris.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد إحداثيات لفتح الخريطة')),
      );
      return;
    }
    for (final uri in uris) {
      try {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return;
      } catch (_) {}
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذر فتح Google Maps')),
    );
  }

  Future<void> _goToPickup() async {
    setState(() => _acting = true);
    try {
      final data = await _api.updateProgress(
        widget.type,
        widget.id,
        action: 'going_to_pickup',
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _acting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إشعار العميل: السائق في الطريق')),
      );
      await _openGoogleMaps(
        lat: data.pickupLat,
        lng: data.pickupLng,
        address: data.pickupAddress,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _markPickedUp() async {
    setState(() => _acting = true);
    try {
      final data = await _api.updateProgress(
        widget.type,
        widget.id,
        action: 'picked_up',
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _acting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إشعار العميل: تم استلام الطلب')),
      );
      await _openGoogleMaps(
        lat: data.dropoffLat,
        lng: data.dropoffLng,
        address: data.dropoffAddress,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _acting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String? _normalizePhone(String? raw) {
    const western = '0123456789';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    var phone = (raw ?? '').trim();
    final mapped = StringBuffer();
    for (final ch in phone.split('')) {
      final a = arabic.indexOf(ch);
      final p = persian.indexOf(ch);
      if (a >= 0) {
        mapped.write(western[a]);
      } else if (p >= 0) {
        mapped.write(western[p]);
      } else {
        mapped.write(ch);
      }
    }
    phone = mapped.toString().replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.startsWith('00')) {
      phone = '+${phone.substring(2)}';
    }
    return phone.isEmpty ? null : phone;
  }

  bool get _isVendorView {
    final fromApi = (_data?.viewerRole ?? '').toLowerCase();
    if (fromApi == 'vendor' || fromApi == 'merchant') return true;
    final title = (CacheHelper.getData(key: 'title') ??
            CacheHelper.getData(key: 'role') ??
            '')
        .toString()
        .toLowerCase();
    return title == 'merchant' || title == 'vendor';
  }

  bool _showPlaceOwner(OrderTrackingData data) =>
      data.showPlaceOwner && !_isVendorView && !widget.isDriverView;

  String? _partnerPhone(OrderTrackingData data) {
    if (_isVendorView || widget.isDriverView) {
      final fromOrder = (data.contactPhone ?? '').trim();
      if (fromOrder.isNotEmpty) return fromOrder;
      final fromCustomer = (data.customer?.phone ?? '').trim();
      return fromCustomer.isEmpty ? null : fromCustomer;
    }
    if (data.showPlaceOwner) {
      final merchant = (data.merchantPhone ?? '').trim();
      if (merchant.isNotEmpty) return merchant;
    }
    final raw = (data.driver?.phone ?? data.merchantPhone ?? '').trim();
    return raw.isEmpty ? null : raw;
  }

  OrderTrackingDriver? _partner(OrderTrackingData data) {
    if (_isVendorView || widget.isDriverView) return data.customer;
    if (data.showPlaceOwner) return data.placeOwner;
    return data.driver;
  }

  bool _canContactPartner(OrderTrackingData data) {
    if (data.isCompleted) return false;
    if (data.canCall) return true;
    if (_partnerPhone(data) != null) return true;
    final partner = _partner(data);
    if (partner != null && partner.id > 0) return true;
    final s = data.status.toLowerCase().trim();
    return const {
      'in_progress',
      'going_to_pickup',
      'picked_up',
      'driver_assigned',
      'preparing',
      'accepted',
      'handed_to_driver',
      'priced',
      'new',
    }.contains(s);
  }

  Future<void> _callPartner() async {
    final data = _data;
    if (data == null) return;

    final phone = _normalizePhone(_partnerPhone(data));
    if (phone == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (_isVendorView || widget.isDriverView)
                ? 'لا يوجد رقم هاتف للعميل'
                : 'لا يوجد رقم هاتف للتواصل',
          ),
        ),
      );
      return;
    }

    final uri = Uri.parse('tel:$phone');
    try {
      var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح تطبيق الاتصال')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر بدء المكالمة')),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    final data = _data;
    if (data == null) return;
    final phone = _normalizePhone(_partnerPhone(data));
    if (phone == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد رقم واتساب متاح')),
      );
      return;
    }
    var digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('0') && digits.length == 11) {
      digits = '20${digits.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$digits');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح واتساب')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح واتساب')),
      );
    }
  }

  bool _driverCanGoToPickup(OrderTrackingData data) {
    if (data.canGoToPickup) return true;
    final s = data.status.toLowerCase().trim();
    return const {
      'in_progress',
      'driver_assigned',
      'preparing',
      'accepted',
    }.contains(s);
  }

  bool _driverCanMarkPickedUp(OrderTrackingData data) {
    if (data.canMarkPickedUp) return true;
    final s = data.status.toLowerCase().trim();
    return const {
      'in_progress',
      'going_to_pickup',
      'driver_assigned',
      'preparing',
      'accepted',
    }.contains(s);
  }

  bool _driverCanConfirmDelivery(OrderTrackingData data) {
    if (data.canConfirmDelivery) return true;
    final s = data.status.toLowerCase().trim();
    return const {
      'in_progress',
      'going_to_pickup',
      'picked_up',
    }.contains(s);
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isDriverView ? 'الطلب النشط' : 'متابعة الطلب',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: _loading && data == null
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? Center(
                  child: TextButton(
                    onPressed: _load,
                    child: const Text('إعادة المحاولة'),
                  ),
                )
              : Column(
                  children: [
                    Expanded(flex: 5, child: _map(data)),
                    Expanded(
                      flex: 6,
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPad),
                        children: [
                          _statusChip(data),
                          const SizedBox(height: 12),
                          widget.isDriverView || _isVendorView
                              ? _personCard(
                                  data.customer,
                                  fallbackName: 'العميل',
                                  subtitle: 'عميل الطلب',
                                  showContactActions: _canContactPartner(data),
                                )
                              : _personCard(
                                  _showPlaceOwner(data)
                                      ? data.placeOwner
                                      : data.driver,
                                  fallbackName: _showPlaceOwner(data)
                                      ? 'صاحب المكان'
                                      : 'سائق',
                                  subtitle: _showPlaceOwner(data)
                                      ? 'صاحب المكان'
                                      : 'سائق الطلب',
                                  showContactActions: _canContactPartner(data),
                                ),
                          const SizedBox(height: 12),
                          _addresses(data),
                          if (!widget.isDriverView) ...[
                            const SizedBox(height: 12),
                            Text(
                              data.price > 0
                                  ? '${data.price.toStringAsFixed(0)} ج.م'
                                  : '—',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: AuthTheme.primaryDark,
                              ),
                            ),
                            const Text(
                              'سعر الطلب',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AuthTheme.textMuted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          if (_canContactPartner(data)) ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _acting ? null : _callPartner,
                                icon: const Icon(Icons.phone, size: 20),
                label: Text(
                  (_isVendorView || widget.isDriverView)
                      ? 'اتصال بالعميل'
                      : 'اتصال',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AuthTheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            if (_partnerPhone(data) != null) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed: _acting ? null : _openWhatsApp,
                                  icon: const Icon(
                                    Icons.chat,
                                    color: Color(0xFF25D366),
                                    size: 20,
                                  ),
                                  label: Text(
                                    (_isVendorView || widget.isDriverView)
                                        ? 'واتساب العميل'
                                        : 'واتساب',
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF128C7E),
                                    side: const BorderSide(
                                      color: Color(0xFF25D366),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                          if (widget.isDriverView) ...[
                            if (_driverCanGoToPickup(data) &&
                                !data.isCompleted) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _acting ? null : _goToPickup,
                                  icon: const Icon(Icons.navigation_outlined),
                                  label: const Text(
                                    'التوجه إلى العميل',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AuthTheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            if (_driverCanMarkPickedUp(data) &&
                                !data.isCompleted) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _acting ? null : _markPickedUp,
                                  icon: const Icon(Icons.inventory_2_outlined),
                                  label: const Text(
                                    'تم استلام الطلب',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E88E5),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                            if (_driverCanConfirmDelivery(data) &&
                                !data.isCompleted) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _acting ? null : _confirmDelivery,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0C9F6A),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text(
                                    'تم التسليم',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ] else ...[
                            if (data.canHandToDriver) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _acting ? null : _handToDriver,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0C9F6A),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text(
                                    'تم تسليم الطلب للسائق',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if (data.showEndOrderButton) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: _acting ? null : _endOrder,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  child: const Text(
                                    'إنهاء الطلب',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            if ((data.handedToDriver ||
                                    data.status == 'picked_up') &&
                                !data.isCompleted)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  'تم استلام الطلب من السائق — جارٍ التوصيل. لا يمكن إنهاء الطلب الآن.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AuthTheme.textMuted,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _map(OrderTrackingData data) {
    final center = () {
      if (data.driver?.lat != null && data.driver?.lng != null) {
        return LatLng(data.driver!.lat!, data.driver!.lng!);
      }
      if (data.pickupLat != null && data.pickupLng != null) {
        return LatLng(data.pickupLat!, data.pickupLng!);
      }
      if (data.dropoffLat != null && data.dropoffLng != null) {
        return LatLng(data.dropoffLat!, data.dropoffLng!);
      }
      return const LatLng(30.0444, 31.2357);
    }();

    final markers = <Marker>[];
    if (data.pickupLat != null && data.pickupLng != null) {
      markers.add(_pin(
        LatLng(data.pickupLat!, data.pickupLng!),
        Colors.green,
        Icons.my_location,
        'استلام',
      ));
    }
    if (data.dropoffLat != null && data.dropoffLng != null) {
      markers.add(_pin(
        LatLng(data.dropoffLat!, data.dropoffLng!),
        Colors.redAccent,
        Icons.flag,
        'تسليم',
      ));
    }
    if (data.driver?.lat != null && data.driver?.lng != null) {
      markers.add(_pin(
        LatLng(data.driver!.lat!, data.driver!.lng!),
        AuthTheme.primary,
        Icons.two_wheeler,
        'سائق',
      ));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 13,
        onMapReady: () {
          if (!mounted) return;
          _mapReady = true;
          final data = _data;
          if (data != null) {
            _scheduleFitMap(data);
          }
        },
      ),
      children: [
        AppMapTiles.layer(),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Marker _pin(LatLng point, Color color, IconData icon, String label) {
    return Marker(
      point: point,
      width: 70,
      height: 70,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(OrderTrackingData data) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0C9F6A).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          data.displayStatusLabel,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            color: Color(0xFF0C9F6A),
          ),
        ),
      ),
    );
  }

  Widget _personCard(
    OrderTrackingDriver? person, {
    required String fallbackName,
    required String subtitle,
    bool showContactActions = false,
  }) {
    final d = person;
    final name = (d?.name ?? '').trim().isEmpty ? fallbackName : d!.name;
    final hasPhone = (d?.phone ?? '').trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthTheme.fieldBorder),
      ),
      child: Row(
        children: [
          StorageNetworkAvatar(
            imagePath: d?.image,
            initial: name.isNotEmpty ? name.characters.first : '؟',
            size: 54,
            backgroundColor: AuthTheme.primary.withValues(alpha: 0.15),
            textColor: AuthTheme.primaryDark,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AuthTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                RatingStars(
                  rating: d?.rating ?? 0,
                  count: d?.ratingsCount,
                ),
              ],
            ),
          ),
          if (showContactActions) ...[
            IconButton(
              tooltip: 'اتصال',
              onPressed: _acting ? null : _callPartner,
              style: IconButton.styleFrom(
                backgroundColor: AuthTheme.primary.withValues(alpha: 0.12),
              ),
              icon: Icon(
                Icons.phone,
                color: hasPhone ? AuthTheme.primaryDark : AuthTheme.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addresses(OrderTrackingData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AuthTheme.fieldBorder),
      ),
      child: Column(
        children: [
          _addr(Icons.my_location, 'الاستلام', data.pickupAddress),
          const SizedBox(height: 10),
          _addr(Icons.flag_outlined, 'التسليم', data.dropoffAddress),
          if ((data.distanceDriverToPickupLabel ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _addr(
              Icons.near_me_outlined,
              'المسافة للسائق من الاستلام',
              data.distanceDriverToPickupLabel!,
            ),
          ],
          if ((data.routeDistanceLabel ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _addr(
              Icons.route_outlined,
              'مسافة الرحلة',
              data.routeDistanceLabel!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _addr(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AuthTheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: value.isEmpty ? '—' : value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
