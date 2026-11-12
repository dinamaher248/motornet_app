import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/admin_dashboard_injection.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_categories_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardInjection.createCategoriesBloc()
        ..add(const FetchAdminCategoriesEvent()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  String _sectionLabel(String section) {
    return switch (section) {
      'transport' => 'وسائل المواصلات',
      'bookings' => 'الحجوزات',
      'services' => 'خدمات أخرى',
      _ => 'الطلبات',
    };
  }

  Future<void> _editDialog(
    BuildContext context, {
    AdminCategory? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final slugCtrl = TextEditingController(text: existing?.slug ?? '');
    var hubSection = existing?.hubSection ?? 'orders';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'إضافة قسم' : 'تعديل قسم',
            style: const TextStyle(fontFamily: 'Cairo')),
        content: StatefulBuilder(
          builder: (context, setLocal) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: adminInputDecoration('اسم القسم'),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: slugCtrl,
                  decoration:
                      adminInputDecoration('المعرّف (slug)', hint: 'اختياري'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: hubSection,
                  decoration: adminInputDecoration('نوع الإضافة'),
                  items: const [
                    DropdownMenuItem(value: 'orders', child: Text('الطلبات')),
                    DropdownMenuItem(
                        value: 'transport',
                        child: Text('وسائل المواصلات')),
                    DropdownMenuItem(
                        value: 'bookings', child: Text('الحجوزات')),
                    DropdownMenuItem(
                        value: 'services', child: Text('خدمات أخرى')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setLocal(() => hubSection = v);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    if (existing == null) {
      context.read<AdminCategoriesBloc>().add(
            CreateAdminCategoryEvent(
              name: name,
              slug: slugCtrl.text.trim().isEmpty ? null : slugCtrl.text.trim(),
              hubSection: hubSection,
            ),
          );
    } else {
      context.read<AdminCategoriesBloc>().add(
            UpdateAdminCategoryEvent(
              existing.copyWith(
                name: name,
                slug: slugCtrl.text.trim().isEmpty
                    ? existing.slug
                    : slugCtrl.text.trim(),
                hubSection: hubSection,
              ),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminCategoriesBloc, AdminCategoriesState>(
      listener: (context, state) {
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state.status == AdminCategoriesStatus.loading) {
          return const AdminTableLoader();
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => _editDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('إضافة قسم',
                    style: TextStyle(fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AdminSectionCard(
              title: 'الأقسام (اسحب لإعادة الترتيب)',
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.categories.length,
                onReorder: (oldIndex, newIndex) {
                  context
                      .read<AdminCategoriesBloc>()
                      .add(ReorderAdminCategoriesEvent(oldIndex, newIndex));
                },
                itemBuilder: (context, index) {
                  final c = state.categories[index];
                  return ListTile(
                    key: ValueKey(c.id),
                    leading: const Icon(Icons.drag_indicator),
                    title: Text(c.name,
                        style: const TextStyle(
                            fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${c.isActive ? 'مفعّل' : 'معطّل'} · ${_sectionLabel(c.hubSection)} · الصور المضافة: ${c.imagesCount}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: c.isActive
                            ? AdminColors.success
                            : AdminColors.danger,
                      ),
                    ),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: 'تفعيل / تعطيل',
                          onPressed: () => context
                              .read<AdminCategoriesBloc>()
                              .add(ToggleAdminCategoryEvent(c.id)),
                          icon: Icon(
                            c.isActive
                                ? Icons.toggle_on
                                : Icons.toggle_off_outlined,
                            color: c.isActive
                                ? AdminColors.success
                                : AuthTheme.textMuted,
                            size: 32,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _editDialog(context, existing: c),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => context
                              .read<AdminCategoriesBloc>()
                              .add(DeleteAdminCategoryEvent(c.id)),
                          icon: const Icon(Icons.delete_outline,
                              color: AdminColors.danger),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
