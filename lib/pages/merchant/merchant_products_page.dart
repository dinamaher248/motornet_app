import 'package:flutter/material.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/merchant_owner_models.dart';
import 'package:motorent/pages/merchant/merchant_product_edit_page.dart';
import 'package:motorent/services/merchant_owner_api.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class MerchantProductsPage extends StatefulWidget {
  const MerchantProductsPage({super.key});

  @override
  State<MerchantProductsPage> createState() => _MerchantProductsPageState();
}

class _MerchantProductsPageState extends State<MerchantProductsPage> {
  final _api = MerchantOwnerApi();
  bool _loading = true;
  String? _error;
  MerchantProductsPayload? _payload;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final payload = await _api.fetchProducts();
      if (!mounted) return;
      setState(() {
        _payload = payload;
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

  Future<void> _openEditor({MerchantProductItem? product}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantProductEditPage(product: product),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final payload = _payload;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('منتجاتي'),
        centerTitle: true,
        actions: [
          if (payload != null && payload.canAddMore)
            IconButton(
              tooltip: 'إضافة منتج',
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_circle_outline),
            ),
        ],
      ),
      floatingActionButton: payload != null && payload.canAddMore
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              backgroundColor: AuthTheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('إضافة منتج', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView(_error!)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _buildBody(payload!),
                ),
    );
  }

  Widget _errorView(String message) {
    final needsProfile = message.contains('بيانات النشاط');
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                needsProfile ? Icons.store_outlined : Icons.error_outline,
                size: 56,
                color: AuthTheme.textMuted,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(MerchantProductsPayload payload) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _headerCard(payload),
        const SizedBox(height: 12),
        if (payload.products.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                'لم تُضف منتجات بعد\nيمكنك إضافة حتى 10 منتجات',
                textAlign: TextAlign.center,
                style: TextStyle(color: AuthTheme.textMuted, height: 1.5),
              ),
            ),
          )
        else
          ...payload.products.map(_productCard),
      ],
    );
  }

  Widget _headerCard(MerchantProductsPayload payload) {
    return Card(
      color: const Color(0xFFE8F5EE),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.inventory_2, color: AuthTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payload.merchantName.isNotEmpty
                        ? payload.merchantName
                        : 'نشاطي',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${payload.count} / ${payload.maxProducts} منتجات',
                    style: const TextStyle(color: AuthTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (!payload.canAddMore)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'الحد الأقصى',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(MerchantProductItem product) {
    final imageUrl = resolveStorageImageUrl(product.image);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _openEditor(product: product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(0)} ج.م',
                      style: const TextStyle(
                        color: AuthTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (product.description != null &&
                        product.description!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          product.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AuthTheme.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  _statusChip(product.isActive),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_left, color: AuthTheme.textMuted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFF3F4F6),
      child: const Icon(Icons.image_outlined, color: AuthTheme.textMuted),
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.green : Colors.grey.shade400,
        ),
      ),
      child: Text(
        isActive ? 'متاح' : 'غير متاح',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isActive ? Colors.green.shade800 : Colors.grey.shade700,
        ),
      ),
    );
  }
}
