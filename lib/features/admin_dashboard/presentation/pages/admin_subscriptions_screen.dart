import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

/// موافقة طلبات اشتراك السائقين / أصحاب النشاط.
class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen> {
  String _filter = 'pending';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];
  bool _acting = false;

  Options get _auth => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        validateStatus: (s) => s != null && s < 600,
      );

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
      final res = await Dio().get(
        adminSubscriptionsEP,
        queryParameters: {'status': _filter},
        options: _auth,
      );
      if (res.statusCode != 200 || res.data is! Map) {
        throw Exception('تعذر تحميل طلبات الاشتراك');
      }
      final map = Map<String, dynamic>.from(res.data as Map);
      final raw = map['data'] ?? map['subscriptions'];
      final list = raw is List ? raw : const [];
      setState(() {
        _items = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _handle(int id, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          action == 'approve' ? 'قبول الاشتراك؟' : 'رفض الاشتراك؟',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
        ),
        content: Text(
          action == 'approve'
              ? 'سيتم تفعيل الحساب وبدء مدة الباقة.'
              : 'سيتم رفض طلب الاشتراك.',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  action == 'approve' ? AuthTheme.primary : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              action == 'approve' ? 'قبول' : 'رفض',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _acting = true);
    try {
      final res = await Dio().post(
        adminSubscriptionHandleEP(id),
        data: {'action': action},
        options: _auth,
      );
      final msg = res.data is Map
          ? (res.data['message']?.toString() ?? '')
          : '';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.isNotEmpty
                ? msg
                : (action == 'approve' ? 'تم القبول' : 'تم الرفض'),
          ),
          backgroundColor:
              res.statusCode == 200 ? null : Colors.red.shade700,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تنفيذ العملية: $e')),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdminSectionCard(
          title: 'طلبات الاشتراك',
          actions: [
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
              tooltip: 'تحديث',
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final f in const [
                    ('pending', 'قيد المراجعة'),
                    ('approved', 'مقبولة'),
                    ('rejected', 'مرفوضة'),
                    ('all', 'الكل'),
                  ])
                    ChoiceChip(
                      label: Text(
                        f.$2,
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                      ),
                      selected: _filter == f.$1,
                      onSelected: (_) {
                        setState(() => _filter = f.$1);
                        _load();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading || _acting)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(fontFamily: 'Cairo', color: Colors.red),
                )
              else if (_items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لا توجد طلبات في هذه الحالة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Cairo', color: AuthTheme.textMuted),
                  ),
                )
              else
                ..._items.map(_card),
            ],
          ),
        ),
      ],
    );
  }

  Widget _card(Map<String, dynamic> item) {
    final id = int.tryParse('${item['id']}') ?? 0;
    final status = item['status']?.toString() ?? '';
    final statusLabel = item['status_label']?.toString() ?? status;
    final user = item['user'] is Map
        ? Map<String, dynamic>.from(item['user'] as Map)
        : <String, dynamic>{};
    final plan = item['plan'] is Map
        ? Map<String, dynamic>.from(item['plan'] as Map)
        : <String, dynamic>{};
    final image = item['payment_image']?.toString();
    final pending = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    user['name']?.toString() ?? 'مستخدم',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pending
                        ? Colors.orange.withValues(alpha: 0.15)
                        : status == 'approved'
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pending
                          ? Colors.orange.shade800
                          : status == 'approved'
                              ? Colors.green.shade800
                              : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'هاتف: ${user['phone'] ?? '-'} · ${user['title'] ?? ''}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AuthTheme.textMuted,
              ),
            ),
            Text(
              'الباقة: ${plan['name'] ?? '-'}'
              '${plan['price'] != null ? ' · ${plan['price']} ج.م' : ''}',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
            if ((image ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final url = resolveStorageImageUrl(image);
                  if (url.isEmpty) return const SizedBox.shrink();
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        height: 80,
                        child: Center(
                          child: Text(
                            'تعذر تحميل صورة الإيصال',
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            if (pending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handle(id, 'approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C9F6A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('قبول',
                          style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handle(id, 'reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('رفض',
                          style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
