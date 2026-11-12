import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/admin_dashboard_injection.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_plans_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class AdminPlansScreen extends StatelessWidget {
  const AdminPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardInjection.createPlansBloc()
        ..add(const LoadAdminPlansEvent()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  Future<void> _planDialog(BuildContext context, {AdminPlan? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final price = TextEditingController(
        text: existing == null ? '' : existing.price.toString());
    final days = TextEditingController(
        text: existing == null ? '30' : existing.durationDays.toString());
    final desc = TextEditingController(text: existing?.description ?? '');
    var audience = existing?.audience ?? AdminPlanAudience.driver;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'إضافة خطة' : 'تعديل خطة',
              style: const TextStyle(fontFamily: 'Cairo')),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: name,
                    decoration: adminInputDecoration('اسم الخطة')),
                const SizedBox(height: 8),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: adminInputDecoration('السعر (ج.م)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: days,
                  keyboardType: TextInputType.number,
                  decoration: adminInputDecoration('المدة بالأيام'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<AdminPlanAudience>(
                  value: audience,
                  decoration: adminInputDecoration('موجهة إلى'),
                  items: const [
                    DropdownMenuItem(
                        value: AdminPlanAudience.driver,
                        child: Text('السائقين')),
                    DropdownMenuItem(
                        value: AdminPlanAudience.vendor,
                        child: Text('أصحاب النشاط')),
                  ],
                  onChanged: (v) {
                    if (v != null) setLocal(() => audience = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: desc,
                  maxLines: 2,
                  decoration: adminInputDecoration('الوصف'),
                ),
              ],
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
    final plan = AdminPlan(
      id: existing?.id ?? 0,
      name: name.text.trim(),
      price: double.tryParse(price.text.trim()) ?? 0,
      durationDays: int.tryParse(days.text.trim()) ?? 30,
      audience: audience,
      description: desc.text.trim().isEmpty ? null : desc.text.trim(),
      isActive: existing?.isActive ?? true,
    );
    if (plan.name.isEmpty) return;
    if (existing == null) {
      context.read<AdminPlansBloc>().add(CreateAdminPlanEvent(plan));
    } else {
      context.read<AdminPlansBloc>().add(UpdateAdminPlanEvent(plan));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminPlansBloc, AdminPlansState>(
      listener: (context, state) {
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state.status == AdminPlansStatus.loading) {
          return const AdminTableLoader();
        }
        final settings = state.settings;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminSectionCard(
              title: 'تفعيل نظام الاشتراكات',
              actions: [
                ElevatedButton(
                  onPressed: state.savingSettings
                      ? null
                      : () => context
                          .read<AdminPlansBloc>()
                          .add(const SavePlansSettingsEvent()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: state.savingSettings
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('حفظ الإعدادات',
                          style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
              child: Column(
                children: [
                  AdminMasterSwitch(
                    title: 'تفعيل الخطط للسائقين',
                    value: settings.driversPlansEnabled,
                    onChanged: (v) => context.read<AdminPlansBloc>().add(
                          UpdatePlansMasterSwitchesEvent(driversEnabled: v),
                        ),
                  ),
                  AdminMasterSwitch(
                    title: 'تفعيل الخطط لأصحاب النشاط',
                    value: settings.vendorsPlansEnabled,
                    onChanged: (v) => context.read<AdminPlansBloc>().add(
                          UpdatePlansMasterSwitchesEvent(vendorsEnabled: v),
                        ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => _planDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('إضافة خطة',
                    style: TextStyle(fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AdminSectionCard(
              title: 'الخطط المتاحة',
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('الاسم')),
                    DataColumn(label: Text('السعر')),
                    DataColumn(label: Text('المدة')),
                    DataColumn(label: Text('الجمهور')),
                    DataColumn(label: Text('إجراءات')),
                  ],
                  rows: state.plans
                      .map(
                        (p) => DataRow(cells: [
                          DataCell(Text(p.name,
                              style: const TextStyle(fontFamily: 'Cairo'))),
                          DataCell(Text('${p.price.toStringAsFixed(0)} ج.م')),
                          DataCell(Text('${p.durationDays} يوم')),
                          DataCell(Text(
                            p.audience == AdminPlanAudience.driver
                                ? 'سائقين'
                                : 'أنشطة',
                            style: const TextStyle(fontFamily: 'Cairo'),
                          )),
                          DataCell(Row(children: [
                            IconButton(
                              onPressed: () =>
                                  _planDialog(context, existing: p),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              onPressed: () => context
                                  .read<AdminPlansBloc>()
                                  .add(DeleteAdminPlanEvent(p.id)),
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
