import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/presentation/pages/stores_list_screen.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class ServicesTabScreen extends StatefulWidget {
  final int refreshToken;

  const ServicesTabScreen({super.key, this.refreshToken = 0});

  @override
  State<ServicesTabScreen> createState() => _ServicesTabScreenState();
}

class _ServicesTabScreenState extends State<ServicesTabScreen> {
  List<ServiceCategory> _categories = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ServicesTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = CacheHelper.getData(key: 'token');
      final res = await Dio().get(
        servicesCategoriesEP,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (s) => s != null && s < 600,
        ),
      );

      if (res.statusCode != 200 || res.data is! Map) {
        if (!mounted) return;
        setState(() {
          _categories = ServiceCategory.defaults;
          _loading = false;
          _error = null;
        });
        return;
      }

      final map = Map<String, dynamic>.from(res.data as Map);
      final raw = map['data'] ?? map['categories'];
      final list = raw is List ? raw : const [];

      final categories = list
          .whereType<Map>()
          .map((e) => ServiceCategory.fromApi(Map<String, dynamic>.from(e)))
          .where((c) => c.slug.isNotEmpty && c.name.trim().isNotEmpty)
          .toList();

      if (!mounted) return;
      setState(() {
        _categories =
            categories.isNotEmpty ? categories : ServiceCategory.defaults;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _categories = ServiceCategory.defaults;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'الخدمات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: AuthTheme.screenBackground(),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors: [
                      AuthTheme.primary.withValues(alpha: 0.16),
                      const Color(0xFF0C9F6A).withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: const Text(
                  'كل الخدمات اللي محتاجها في مكان واحد مع توصيلة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.45,
                    color: AuthTheme.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
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
                )
              else if (_categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      'لا توجد خدمات متاحة حالياً',
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
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _CategoryCard(
                      category: category,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                StoresListScreen(category: category),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ServiceCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveStorageImageUrl(category.image);
    final hasImage = imageUrl.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!hasImage)
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(category.icon, color: category.color, size: 30),
                  ),
                if (!hasImage) const SizedBox(height: 12),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: hasImage ? 16 : 15,
                    color: hasImage ? Colors.white : AuthTheme.textDark,
                    shadows: hasImage
                        ? const [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
