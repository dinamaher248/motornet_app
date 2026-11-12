import 'package:flutter/material.dart';
import 'package:motorent/features/admin_dashboard/admin_dashboard_injection.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

/// إدارة أنواع المركبات ونطاق التغطية (كم) لكل وسيلة نقل.
class AdminVehicleTypesScreen extends StatefulWidget {
  const AdminVehicleTypesScreen({super.key});

  @override
  State<AdminVehicleTypesScreen> createState() =>
      _AdminVehicleTypesScreenState();
}

class _AdminVehicleTypesScreenState extends State<AdminVehicleTypesScreen> {
  final AdminRepository _repo = AdminDashboardInjection.createRepository();
  List<AdminVehicleType> _items = const [];
  bool _loading = true;
  String? _message;
  int? _savingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await _repo.fetchVehicleTypes();
    if (!mounted) return;
    result.fold(
      (f) => setState(() {
        _loading = false;
        _message = f.message;
      }),
      (items) => setState(() {
        _loading = false;
        _items = items;
      }),
    );
  }

  Future<void> _editCoverage(AdminVehicleType type) async {
    final controller =
        TextEditingController(text: type.coverageRangeKm.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'نطاق ${type.nameAr}',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حدد كم كيلومتر يظهر فيها الطلب لسائقي هذه الوسيلة حول موقع الاستلام.',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: adminInputDecoration('نطاق التغطية (كم)'),
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final km = int.tryParse(controller.text.trim());
    if (km == null || km < 1 || km > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل نطاقاً بين 1 و 500 كم')),
      );
      return;
    }

    setState(() => _savingId = type.id);
    final result = await _repo.updateVehicleType(
      type.copyWith(coverageRangeKm: km),
    );
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _savingId = null);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.message)));
      },
      (updated) {
        setState(() {
          _savingId = null;
          _items = _items
              .map((e) => e.id == updated.id ? updated : e)
              .toList(growable: false);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم ضبط نطاق ${updated.nameAr} إلى ${updated.coverageRangeKm} كم',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggle(AdminVehicleType type) async {
    setState(() => _savingId = type.id);
    final result = await _repo.toggleVehicleType(type.id);
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _savingId = null);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.message)));
      },
      (updated) => setState(() {
        _savingId = null;
        _items = _items
            .map((e) => e.id == updated.id ? updated : e)
            .toList(growable: false);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminSectionCard(
            title: 'نطاق وسائل النقل',
            child: const Text(
              'مثال: موتوسيكل بنطاق 7 كم — يظهر الطلب فقط للسائقين المتاحين داخل 7 كم من موقع الاستلام.',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AuthTheme.textMuted,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text(_message!,
                    style: const TextStyle(fontFamily: 'Cairo')),
              ),
            )
          else if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Text('لا توجد مركبات بعد',
                    style: TextStyle(fontFamily: 'Cairo')),
              ),
            )
          else
            ..._items.map((type) {
              final busy = _savingId == type.id;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    type.nameAr,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'المفتاح: ${type.key}\nالنطاق: ${type.coverageRangeKm} كم',
                    style: const TextStyle(fontFamily: 'Cairo', height: 1.4),
                  ),
                  isThreeLine: true,
                  trailing: busy
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'تعديل النطاق',
                              onPressed: () => _editCoverage(type),
                              icon: const Icon(Icons.radar_outlined),
                            ),
                            Switch(
                              value: type.isActive,
                              onChanged: (_) => _toggle(type),
                            ),
                          ],
                        ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
