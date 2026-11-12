import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/admin_dashboard_injection.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_moderators_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

const _permissionOptions = {
  'users': 'المستخدمين',
  'categories': 'إدارة الأقسام',
  'products': 'منتجات المتاجر',
  'vehicle_types': 'المركبات والنطاق',
  'settlements': 'المديونيات',
  'settings': 'إعدادات النظام',
  'notifications': 'الإشعارات',
  'documents': 'المستندات المطلوبة',
  'moderators': 'إدارة المشرفين',
};

class AdminModeratorsScreen extends StatelessWidget {
  const AdminModeratorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardInjection.createModeratorsBloc()
        ..add(const FetchAdminModeratorsEvent()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  Future<void> _dialog(BuildContext context, {AdminModerator? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final password = TextEditingController();
    final selected = <String>{...(existing?.permissions ?? const [])};

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'إضافة مشرف' : 'تعديل مشرف',
              style: const TextStyle(fontFamily: 'Cairo')),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: name,
                      decoration: adminInputDecoration('الاسم')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phone,
                    decoration: adminInputDecoration('الهاتف'),
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                      controller: email,
                      decoration: adminInputDecoration('البريد (اختياري)')),
                  if (existing == null) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: password,
                      obscureText: true,
                      decoration: adminInputDecoration('كلمة المرور (اختياري)'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('الصلاحيات',
                        style: TextStyle(
                            fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
                  ),
                  if (existing?.isSuperAdmin == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'هذا المشرف الأساسي وله كل الصلاحيات.',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    )
                  else
                    ..._permissionOptions.entries.map(
                      (e) => CheckboxListTile(
                        dense: true,
                        title: Text(e.value,
                            style: const TextStyle(fontFamily: 'Cairo')),
                        value: selected.contains(e.key),
                        onChanged: (v) => setLocal(() {
                          if (v == true) {
                            selected.add(e.key);
                          } else {
                            selected.remove(e.key);
                          }
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    if (name.text.trim().isEmpty || phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الاسم ورقم الهاتف مطلوبان')),
      );
      return;
    }

    if (existing == null) {
      context.read<AdminModeratorsBloc>().add(CreateAdminModeratorEvent(
            name: name.text.trim(),
            phone: phone.text.trim(),
            email: email.text.trim(),
            password: password.text.trim(),
            permissions: selected.toList(),
          ));
    } else {
      context.read<AdminModeratorsBloc>().add(UpdateAdminModeratorEvent(
            existing.copyWith(
              name: name.text.trim(),
              phone: phone.text.trim(),
              email: email.text.trim(),
              permissions: selected.toList(),
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminModeratorsBloc, AdminModeratorsState>(
      listener: (context, state) {
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state.status == AdminModeratorsStatus.loading) {
          return const AdminTableLoader();
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => _dialog(context),
                icon: const Icon(Icons.add),
                label: const Text('إضافة مشرف',
                    style: TextStyle(fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AdminSectionCard(
              title: 'المشرفون',
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('الاسم')),
                    DataColumn(label: Text('الهاتف')),
                    DataColumn(label: Text('الحالة')),
                    DataColumn(label: Text('إجراءات')),
                  ],
                  rows: state.moderators
                      .map(
                        (m) => DataRow(cells: [
                          DataCell(Text(m.name,
                              style: const TextStyle(fontFamily: 'Cairo'))),
                          DataCell(Text(m.phone,
                              textDirection: TextDirection.ltr)),
                          DataCell(Text(m.isActive ? 'نشط' : 'موقوف',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: m.isActive
                                    ? AdminColors.success
                                    : AdminColors.danger,
                              ))),
                          DataCell(Row(children: [
                            TextButton(
                              onPressed: () => _dialog(context, existing: m),
                              child: const Text('صلاحيات',
                                  style: TextStyle(fontFamily: 'Cairo')),
                            ),
                            TextButton(
                              onPressed: () => context
                                  .read<AdminModeratorsBloc>()
                                  .add(ToggleAdminModeratorEvent(m.id)),
                              child: Text(
                                m.isActive ? 'إيقاف' : 'تفعيل',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  color: m.isActive
                                      ? AdminColors.danger
                                      : AdminColors.success,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => context
                                  .read<AdminModeratorsBloc>()
                                  .add(DeleteAdminModeratorEvent(m.id)),
                              icon: const Icon(Icons.delete_outline,
                                  color: AdminColors.danger),
                            ),
                          ])),
                        ]),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
