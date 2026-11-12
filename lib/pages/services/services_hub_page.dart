import 'package:flutter/material.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/models/local_service_models.dart';
import 'package:motorent/pages/orders_tab_page.dart';
import 'package:motorent/pages/services/my_service_orders_page.dart';
import 'package:motorent/pages/services/service_category_page.dart';
import 'package:motorent/services/local_service_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/services/driver_service_orders_section.dart';

class ServicesHubPage extends StatefulWidget {
  const ServicesHubPage({super.key});

  @override
  State<ServicesHubPage> createState() => _ServicesHubPageState();
}

class _ServicesHubPageState extends State<ServicesHubPage> {
  final _api = LocalServiceApi();
  List<ServiceCategoryItem> _categories = [];
  bool _loading = true;
  final String _role = CacheHelper.getData(key: 'title')?.toString() ?? 'user';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _api.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = items;
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('خدمات'),
        centerTitle: true,
        actions: [
          if (_role == 'user')
            IconButton(
              tooltip: 'طلباتي',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyServiceOrdersPage()),
                );
              },
              icon: const Icon(Icons.receipt_long),
            ),
          IconButton(
            tooltip: 'متابعة المشاوير',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersPage()),
              );
            },
            icon: const Icon(Icons.local_shipping_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AuthTheme.primary.withOpacity(0.15),
                          const Color(0xFF059669).withOpacity(0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'كل الخدمات اللي محتاجها في مكان واحد مع توصيلة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'مشاوير — مطاعم، صيدليات، سوبر ماركت، فنادق',
                          style: TextStyle(
                            color: AuthTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'مشاوير',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (_categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('لا توجد أقسام متاحة حالياً')),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.35,
                      ),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return _CategoryCard(
                          category: cat,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ServiceCategoryPage(category: cat),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  if (_role == 'driver') ...[
                    const SizedBox(height: 20),
                    const DriverServiceOrdersSection(),
                  ],
                ],
              ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ServiceCategoryItem category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AuthTheme.primary.withOpacity(0.12),
                child: Icon(category.materialIcon, color: AuthTheme.primary),
              ),
              const SizedBox(height: 10),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
