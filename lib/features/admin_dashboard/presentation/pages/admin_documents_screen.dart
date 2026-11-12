import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/admin_dashboard_injection.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_documents_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class AdminDocumentsScreen extends StatelessWidget {
  const AdminDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardInjection.createDocumentsBloc()
        ..add(const FetchAdminDocumentsEvent()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  String _audienceLabel(AdminDocAudience a) => switch (a) {
        AdminDocAudience.driver => 'سائق',
        AdminDocAudience.vendor => 'صاحب نشاط',
        AdminDocAudience.both => 'كلاهما',
      };

  String _docSubtitle(AdminRegistrationDoc doc) {
    final audience = _audienceLabel(doc.audience);
    if (doc.audience == AdminDocAudience.driver) {
      if (doc.vehicleTypeKeys.isEmpty) {
        return '$audience · كل وسائل النقل';
      }
      return '$audience · ${doc.vehicleTypeKeys.join('، ')}';
    }
    if (doc.audience == AdminDocAudience.both) {
      return '$audience · للجميع';
    }
    return audience;
  }

  Future<void> _add(BuildContext context) async {
    final name = TextEditingController();
    var audience = AdminDocAudience.both;
    final selectedVehicleKeys = <String>{};
    List<AdminVehicleType> vehicleTypes = const [];
    var loadingVehicleTypes = true;

    final repo = AdminDashboardInjection.createRepository();
    final vehicleResult = await repo.fetchVehicleTypes();
    vehicleResult.fold(
      (_) => vehicleTypes = const [],
      (items) => vehicleTypes = items.where((v) => v.isActive).toList(),
    );
    loadingVehicleTypes = false;

    if (!context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('إضافة مستند مطلوب',
              style: TextStyle(fontFamily: 'Cairo')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: name,
                  decoration: adminInputDecoration('اسم المستند'),
                  style: const TextStyle(fontFamily: 'Cairo'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<AdminDocAudience>(
                  value: audience,
                  decoration: adminInputDecoration('مطلوب لـ'),
                  items: const [
                    DropdownMenuItem(
                        value: AdminDocAudience.vendor,
                        child: Text('صاحب نشاط')),
                    DropdownMenuItem(
                        value: AdminDocAudience.both,
                        child: Text('كلاهما (سائق + صاحب نشاط)')),
                    DropdownMenuItem(
                        value: AdminDocAudience.driver,
                        child: Text('سائق')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setLocal(() {
                        audience = v;
                        if (v != AdminDocAudience.driver) {
                          selectedVehicleKeys.clear();
                        }
                      });
                    }
                  },
                ),
                if (audience == AdminDocAudience.driver) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'وسائل النقل',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (loadingVehicleTypes)
                    const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  else if (vehicleTypes.isEmpty)
                    const Text(
                      'لا توجد وسائل نقل مفعّلة في لوحة الإدارة.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AdminColors.danger,
                        fontSize: 12,
                      ),
                    )
                  else
                    ...vehicleTypes.map((vehicle) {
                      final checked = selectedVehicleKeys.contains(vehicle.key);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: checked,
                        title: Text(
                          vehicle.nameAr.isNotEmpty
                              ? vehicle.nameAr
                              : (vehicle.nameEn ?? vehicle.key),
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        onChanged: (v) {
                          setLocal(() {
                            if (v == true) {
                              selectedVehicleKeys.add(vehicle.key);
                            } else {
                              selectedVehicleKeys.remove(vehicle.key);
                            }
                          });
                        },
                      );
                    }),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('إضافة')),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    if (name.text.trim().isEmpty) return;
    if (audience == AdminDocAudience.driver && selectedVehicleKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر وسيلة نقل واحدة على الأقل')),
      );
      return;
    }
    context.read<AdminDocumentsBloc>().add(CreateAdminDocumentEvent(
          name: name.text.trim(),
          audience: audience,
          vehicleTypeKeys: selectedVehicleKeys.toList(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminDocumentsBloc, AdminDocumentsState>(
      listener: (context, state) {
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state.status == AdminDocumentsStatus.loading) {
          return const AdminTableLoader();
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: () => _add(context),
                icon: const Icon(Icons.add),
                label: const Text('إضافة مستند',
                    style: TextStyle(fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            AdminSectionCard(
              title: 'المستندات المطلوبة للتسجيل',
              child: Column(
                children: state.documents
                    .map(
                      (d) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_outlined),
                        title: Text(d.name,
                            style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700)),
                        subtitle: Text(_docSubtitle(d),
                            style: const TextStyle(fontFamily: 'Cairo')),
                        trailing: IconButton(
                          onPressed: () => context
                              .read<AdminDocumentsBloc>()
                              .add(DeleteAdminDocumentEvent(d.id)),
                          icon: const Icon(Icons.delete_outline,
                              color: AdminColors.danger),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
