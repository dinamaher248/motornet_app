import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/bidding_system/presentation/pages/dynamic_vehicle_select_page.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/hub_access.dart';
import 'package:motorent/features/services/presentation/pages/my_bookings_screen.dart';
import 'package:motorent/features/services/presentation/pages/stores_list_screen.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class CustomerHubController {
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);
}

class CustomerHubPage extends StatefulWidget {
  final int initialTab;

  const CustomerHubPage({super.key, this.initialTab = 0});

  @override
  State<CustomerHubPage> createState() => _CustomerHubPageState();
}

class _CustomerHubPageState extends State<CustomerHubPage> {
  int _tab = 0;
  List<ServiceCategory> _categories = const [];
  bool _loading = true;
  String? _error;

  static const _sections = ['orders', 'bookings', 'services'];

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab.clamp(0, 2);
    CustomerHubController.tabIndex.value = _tab;
    CustomerHubController.tabIndex.addListener(_onExternalTab);
    _load();
  }

  void _onExternalTab() {
    final next = CustomerHubController.tabIndex.value.clamp(0, 2);
    if (_tab != next && mounted) {
      setState(() => _tab = next);
    }
  }

  @override
  void dispose() {
    CustomerHubController.tabIndex.removeListener(_onExternalTab);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = CacheHelper.getData(key: 'token');
      final urls = [
        servicesCategoriesEP,
        '$BASE_URL/local-services/categories',
      ];
      List<ServiceCategory> categories = const [];
      for (final url in urls) {
        try {
          final res = await Dio().get(
            url,
            options: Options(
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
              validateStatus: (s) => s != null && s < 600,
              sendTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );
          if (res.statusCode != 200) continue;
          final parsed = _parseCategories(res.data);
          if (parsed.isNotEmpty) {
            categories = parsed;
            break;
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _categories =
            categories.isNotEmpty ? categories : ServiceCategory.defaults;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = ServiceCategory.defaults;
        _loading = false;
        _error = null;
      });
    }
  }

  List<ServiceCategory> _parseCategories(dynamic data) {
    List list = const [];
    if (data is Map) {
      final raw = data['data'] ?? data['categories'];
      if (raw is List) list = raw;
    } else if (data is List) {
      list = data;
    }
    return list
        .whereType<Map>()
        .map((e) => ServiceCategory.fromApi(Map<String, dynamic>.from(e)))
        .where((c) => c.slug.isNotEmpty && c.name.trim().isNotEmpty)
        .toList();
  }

  List<ServiceCategory> get _visibleCategories {
    final key = _sections[_tab];
    final matched = _categories
        .where((c) => c.hubSection == key && c.hubSection != 'transport')
        .toList();
    if (matched.isNotEmpty) {
      return matched;
    }
    return _categories.where((c) => c.hubSection != 'transport').toList();
  }

  bool get _isShowingFallbackCategories {
    final key = _sections[_tab];
    return !_categories.any((c) => c.hubSection == key && c.hubSection != 'transport') &&
        _categories.any((c) => c.hubSection != 'transport');
  }

  void _selectTab(int index) {
    if (_tab == index) return;
    setState(() => _tab = index);
    CustomerHubController.tabIndex.value = index;
  }

  void _openCategory(ServiceCategory category) {
    if (category.hubSection == 'transport') {
      _openTransportCategory(category);
      return;
    }

    if (category.hubSection == 'bookings' && !HubAccess.canUseBookings) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحجوزات ستحتاج اشتراك قريباً')),
      );
      return;
    }

    final mode = switch (category.hubSection) {
      'bookings' => StoreListOpenMode.booking,
      'services' => StoreListOpenMode.profession,
      _ => StoreListOpenMode.order,
    };
    final kind = switch (category.hubSection) {
      'bookings' => 'place',
      'services' => 'profession',
      _ => null,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoresListScreen(
          category: category,
          listingKind: kind,
          openMode: mode,
        ),
      ),
    );
  }

  void _openTransportCategory(ServiceCategory category) {
    final hay = '${category.slug} ${category.name}'.toLowerCase();
    final isGoods = hay.contains('goods') ||
        hay.contains('بضاع') ||
        hay.contains('شحن');
    if (isGoods) {
      _openGoodsTrip();
    } else {
      _openQuickTrip();
    }
  }

  void _openQuickTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DynamicVehicleSelectPage(
          category: 'quick_trip',
          pageTitle: 'اختر وسيلة النقل',
          serviceTitle: 'مشوار سريع',
          descriptionLabel: 'وصف الطلب',
          accentColor: AuthTheme.primary,
        ),
      ),
    );
  }

  void _openGoodsTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DynamicVehicleSelectPage(
          category: 'goods',
          pageTitle: 'اختر نوع المركبة',
          serviceTitle: 'نقل بضائع',
          accentColor: Color(0xFF0C9F6A),
          descriptionLabel: 'وصف البضاعة',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AuthTheme.screenBackground(),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            const _HubHeader(),
            const SizedBox(height: 14),
            const _PromoBanner(),
            const SizedBox(height: 22),
            const Text(
              'اختر الخدمة التي تناسبك',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AuthTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _SectionPills(
              index: _tab,
              onChanged: _selectTab,
            ),
            const SizedBox(height: 14),
            if (_tab == 1) ...[
              _MyBookingsEntry(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      TextButton(
                        onPressed: _load,
                        child: const Text(
                          'إعادة المحاولة',
                          style: TextStyle(fontFamily: 'Cairo'),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isShowingFallbackCategories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4D8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF2D38A)),
                    ),
                    child: const Text(
                      'لا توجد أقسام مخصصة لهذا التبويب حالياً من لوحة التحكم، لذلك نعرض كل الأقسام المتاحة مؤقتاً حتى تقدر تكمل التجربة.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AuthTheme.textDark,
                      ),
                    ),
                  ),
                ),
              _SectionGrid(
                tab: _tab,
                categories: _visibleCategories,
                onCategory: _openCategory,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Text(
        'الخدمات',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AuthTheme.textDark,
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E3),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                  color: AuthTheme.textDark,
                ),
                children: [
                  TextSpan(text: 'كل اللي تحتاجه\n'),
                  TextSpan(
                    text: 'في مكان واحد',
                    style: TextStyle(color: AuthTheme.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AuthTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: AuthTheme.primary,
              size: 42,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPills extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _SectionPills({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = ['طلبات', 'حجوزات', 'خدمات الصنايعيه والحرفيين'];
    return Row(
      children: List.generate(3, (i) {
        final selected = index == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: i == 2 ? 0 : 8),
            child: Material(
              color: selected ? AuthTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AuthTheme.primary
                          : AuthTheme.fieldBorder,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: i == 2 ? 11 : 14,
                      height: 1.15,
                      color: selected ? Colors.white : AuthTheme.textDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// اختصار «حجوزاتي» — متابعة استفسارات الأسعار وقبول/رفض العروض.
class _MyBookingsEntry extends StatelessWidget {
  final VoidCallback onTap;

  const _MyBookingsEntry({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AuthTheme.fieldBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AuthTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_note_outlined,
                  color: AuthTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حجوزاتي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AuthTheme.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'تابع ردود الأسعار واقبل أو ارفض العروض',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AuthTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AuthTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionGrid extends StatelessWidget {
  final int tab;
  final List<ServiceCategory> categories;
  final ValueChanged<ServiceCategory> onCategory;

  const _SectionGrid({
    required this.tab,
    required this.categories,
    required this.onCategory,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = <_HubTile>[];

    for (final category in categories) {
      tiles.add(
        _HubTile(
          title: category.name,
          icon: category.icon,
          color: category.color,
          image: category.image,
          onTap: () => onCategory(category),
        ),
      );
    }

    if (tiles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 36),
        child: Text(
          tab == 1
              ? 'لا توجد أقسام حجوزات حالياً'
              : tab == 2
                  ? 'لا توجد أقسام خدمات الصنايعيه والحرفيين حالياً'
                  : 'لا توجد أقسام حالياً',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AuthTheme.textMuted,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (context, index) => _HubCategoryCard(tile: tiles[index]),
    );
  }
}

class _HubTile {
  final String title;
  final IconData icon;
  final Color color;
  final String? image;
  final VoidCallback onTap;

  const _HubTile({
    required this.title,
    required this.icon,
    required this.color,
    this.image,
    required this.onTap,
  });
}

class _HubCategoryCard extends StatelessWidget {
  final _HubTile tile;

  const _HubCategoryCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveStorageImageUrl(tile.image);
    final hasImage = imageUrl.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tile.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AuthTheme.fieldBorder),
            image: hasImage
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.35),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: hasImage
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_left,
                      size: 18,
                      color: hasImage
                          ? AuthTheme.textDark
                          : AuthTheme.textMuted,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!hasImage)
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: tile.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(tile.icon, color: tile.color, size: 30),
                      ),
                    if (!hasImage) const SizedBox(height: 10),
                    Text(
                      tile.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: hasImage ? 16 : 14,
                        color: hasImage ? Colors.white : AuthTheme.textDark,
                        shadows: hasImage
                            ? const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
