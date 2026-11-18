import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motorent/constants/app_brand.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/services/core/utils/payment_methods_util.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/presentation/bloc/service_bloc.dart';
import 'package:motorent/features/services/presentation/pages/checkout_screen.dart';
import 'package:motorent/features/services/presentation/pages/custom_order_form_screen.dart';
import 'package:motorent/features/services/presentation/pages/place_booking_screen.dart';
import 'package:motorent/features/services/presentation/pages/stores_list_screen.dart';
import 'package:motorent/features/services/services_injection.dart';
import 'package:motorent/widgets/app_logo.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class StoreDetailsScreen extends StatefulWidget {
  final int storeId;
  final StoreListOpenMode openMode;

  /// تصنيف القسم المفتوح منه المكان — يُمرَّر لنموذج الحجز الديناميكي.
  final int? categoryId;

  const StoreDetailsScreen({
    super.key,
    required this.storeId,
    this.openMode = StoreListOpenMode.order,
    this.categoryId,
  });

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  double? _userLat;
  double? _userLng;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = ServicesInjection.createBloc();
        _loadDetails(bloc);
        return bloc;
      },
      child: _StoreDetailsView(
        userLat: _userLat,
        userLng: _userLng,
        openMode: widget.openMode,
        categoryId: widget.categoryId,
      ),
    );
  }

  Future<void> _loadDetails(ServiceBloc bloc) async {
    double? lat;
    double? lng;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
        if (mounted) {
          setState(() {
            _userLat = lat;
            _userLng = lng;
          });
        }
      }
    } catch (_) {}
    bloc.add(FetchStoreDetailsEvent(widget.storeId, lat: lat, lng: lng));
  }
}

class _StoreDetailsView extends StatelessWidget {
  final double? userLat;
  final double? userLng;
  final StoreListOpenMode openMode;
  final int? categoryId;

  const _StoreDetailsView({
    required this.userLat,
    required this.userLng,
    this.openMode = StoreListOpenMode.order,
    this.categoryId,
  });

  String _distanceOf(Store store) {
    final fromApi = (store.distanceLabel ?? '').trim();
    if (fromApi.isNotEmpty &&
        !fromApi.contains('غير محددة') &&
        !fromApi.contains('غير متاح')) {
      return fromApi;
    }
    final sLat = store.lat;
    final sLng = store.lng;
    if (sLat == null || sLng == null || (sLat == 0 && sLng == 0)) {
      return 'المتجر لم يحدد موقعه';
    }
    if (userLat == null || userLng == null) {
      return 'جاري حساب المسافة…';
    }
    final meters = Geolocator.distanceBetween(userLat!, userLng!, sLat, sLng);
    if (meters < 1000) return '${meters.round()} م';
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: BlocConsumer<ServiceBloc, ServiceState>(
        listener: (context, state) {
          if (state is ServiceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ServiceLoading || state is ServiceInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final store = state is StoreDetailsLoaded
              ? state.store
              : (state is OrderSubmitting ? state.store : null);

          if (store == null) {
            return Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('رجوع', style: TextStyle(fontFamily: 'Cairo')),
              ),
            );
          }

          final imageUrl = resolveStorageImageUrl(store.image);
          final payments = normalizePaymentMethods(store.paymentMethods);
          final distance = _distanceOf(store);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _StoreBanner(
                  imageUrl: imageUrl,
                  storeName: store.name,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: _StoreInfoCard(
                          store: store,
                          imageUrl: imageUrl,
                          distance: distance,
                          payments: payments,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _openPrimaryAction(context, store),
                          icon: Icon(_primaryIcon, size: 22),
                          label: Text(
                            _primaryLabel,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuthTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      if (openMode == StoreListOpenMode.order) ...[
                        const SizedBox(height: 22),
                        const Text(
                          'المنتجات',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AuthTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (store.products.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'لا توجد منتجات حالياً',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AuthTheme.textMuted,
                                ),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: store.products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.68,
                            ),
                            itemBuilder: (context, index) {
                              final product = store.products[index];
                              return _ProductCard(
                                product: product,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CheckoutScreen(
                                        store: store,
                                        product: product,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                      ] else ...[
                        const SizedBox(height: 22),
                        const Text(
                          'صور المكان',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AuthTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (store.products.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'لا توجد صور حالياً',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: AuthTheme.textMuted,
                                ),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: store.products.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.68,
                            ),
                            itemBuilder: (context, index) {
                              final product = store.products[index];
                              return _ProductCard(
                                product: product,
                                showAddButton: false,
                                onTap: () {},
                              );
                            },
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String get _primaryLabel {
    return switch (openMode) {
      StoreListOpenMode.booking => 'حجز',
      StoreListOpenMode.profession => 'اتصال',
      StoreListOpenMode.order => 'اطلب أي شيء',
    };
  }

  IconData get _primaryIcon {
    return switch (openMode) {
      StoreListOpenMode.booking => Icons.schedule,
      StoreListOpenMode.profession => Icons.call,
      StoreListOpenMode.order => Icons.shopping_bag_outlined,
    };
  }

  void _openPrimaryAction(BuildContext context, Store store) {
    switch (openMode) {
      case StoreListOpenMode.booking:
      case StoreListOpenMode.profession:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlaceBookingScreen(
              storeId: store.id,
              categoryId: store.categoryId ?? categoryId,
            ),
          ),
        );
      case StoreListOpenMode.order:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CustomOrderFormScreen(store: store),
          ),
        );
    }
  }
}

class _StoreCoverFallback extends StatelessWidget {
  const _StoreCoverFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AuthTheme.primary.withValues(alpha: 0.15),
            const Color(0xFFFFF1E3),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            bottom: 8,
            child: Icon(
              Icons.delivery_dining,
              size: 110,
              color: AuthTheme.primary.withValues(alpha: 0.35),
            ),
          ),
          const Positioned(
            right: 16,
            top: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppLogo(height: 44, showName: false),
                SizedBox(height: 6),
                Text(
                  AppBrand.name,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AuthTheme.textDark,
                  ),
                ),
                Text(
                  'خدمات نقل وتوصيل',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AuthTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreBanner extends StatelessWidget {
  final String imageUrl;
  final String storeName;

  const _StoreBanner({
    required this.imageUrl,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _StoreCoverFallback(),
            )
          else
            const _StoreCoverFallback(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  _CircleIconButton(
                    icon: Icons.share_outlined,
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: storeName),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تم نسخ اسم المتجر',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AuthTheme.textDark),
        ),
      ),
    );
  }
}

class _StoreInfoCard extends StatelessWidget {
  final Store store;
  final String imageUrl;
  final String distance;
  final List<PaymentMethod> payments;

  const _StoreInfoCard({
    required this.store,
    required this.imageUrl,
    required this.distance,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: (store.isOpen
                        ? const Color(0xFF0C9F6A)
                        : Colors.red)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                store.statusLabel,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: store.isOpen
                      ? const Color(0xFF0C9F6A)
                      : Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumb(),
                      )
                    : _thumb(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AuthTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StoreRatingRow(store: store),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AuthTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            distance,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AuthTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((store.address ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 16,
                  color: AuthTheme.textMuted,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    store.address!,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AuthTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'طرق الدفع المتاحة',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AuthTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (payments.isEmpty
                    ? const [
                        PaymentMethod(key: 'cash', label: 'دفع عند الاستلام'),
                      ]
                    : payments)
                .map((m) => _PaymentChip(method: m))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _thumb() {
    return Container(
      width: 72,
      height: 72,
      color: AuthTheme.primary.withValues(alpha: 0.12),
      child: const Icon(Icons.storefront, color: AuthTheme.primary),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final PaymentMethod method;

  const _PaymentChip({required this.method});

  @override
  Widget build(BuildContext context) {
    final isWallet = method.isWallet;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AuthTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AuthTheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWallet
                ? Icons.account_balance_wallet_outlined
                : Icons.payments_outlined,
            size: 16,
            color: AuthTheme.primaryDark,
          ),
          const SizedBox(width: 6),
          Text(
            method.label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AuthTheme.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreRatingRow extends StatelessWidget {
  final Store store;

  const _StoreRatingRow({required this.store});

  @override
  Widget build(BuildContext context) {
    final rating = store.avgRating <= 0 ? 0.0 : store.avgRating;
    final count = store.ratingsCount;
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
        const SizedBox(width: 4),
        Text(
          rating <= 0 ? 'جديد' : rating.toStringAsFixed(1),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: AuthTheme.textDark,
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($count تقييم)',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AuthTheme.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ServiceProduct product;
  final VoidCallback onTap;
  final bool showAddButton;

  const _ProductCard({
    required this.product,
    required this.onTap,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveStorageImageUrl(product.image);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECECEC)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _ph(),
                            )
                          : _ph(),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: showAddButton
                          ? Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: AuthTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    if ((product.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AuthTheme.textMuted,
                        ),
                      ),
                    ],
                    // السعر يظهر في «الطلبات» فقط — صور الحجوزات بدون سعر
                    if (showAddButton) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${product.price.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AuthTheme.primaryDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ph() => Container(
        color: AuthTheme.primary.withValues(alpha: 0.08),
        child: const Icon(Icons.fastfood, color: AuthTheme.primary, size: 36),
      );
}
