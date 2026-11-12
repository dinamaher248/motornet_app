import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/admin_dashboard/admin_dashboard_injection.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_users_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/pages/admin_products_screen.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardInjection.createUsersBloc()
        ..add(const FetchAdminUsersEvent(AdminUserRole.client)),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _fetch(
    BuildContext context,
    AdminUsersState state, {
    AdminUserRole? role,
    AdminDriverSegment? driverSegment,
    String? search,
    bool clearSearch = false,
  }) {
    if (clearSearch) {
      _searchCtrl.clear();
    }
    final query = clearSearch ? '' : (search ?? _searchCtrl.text.trim());
    final selectedRole = role ?? state.selectedRole;
    context.read<AdminUsersBloc>().add(
          FetchAdminUsersEvent(
            selectedRole,
            driverSegment: selectedRole == AdminUserRole.driver
                ? (driverSegment ?? state.selectedDriverSegment)
                : null,
            search: query,
          ),
        );
  }

  void _openVendorProducts(BuildContext context, AdminUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductsScreen(
          vendorId: user.id,
          vendorName: user.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminUsersBloc, AdminUsersState>(
      listener: (context, state) {
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message!)));
        }
        if (state.reviewedUser != null) {
          final user = state.reviewedUser!;
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('مراجعة: ${user.name}',
                  style: const TextStyle(fontFamily: 'Cairo')),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الهاتف: ${user.phone}',
                        style: const TextStyle(fontFamily: 'Cairo')),
                    Text('الحالة: ${user.statusLabel}',
                        style: const TextStyle(fontFamily: 'Cairo')),
                    const SizedBox(height: 12),
                    const Text('المستندات',
                        style: TextStyle(
                            fontFamily: 'Cairo', fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (user.documents.isEmpty)
                      const Text('لا توجد مستندات',
                          style: TextStyle(fontFamily: 'Cairo'))
                    else
                      ...user.documents.map((d) {
                        final url = resolveStorageImageUrl(d.url);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(d.label,
                              style: const TextStyle(fontFamily: 'Cairo')),
                          trailing: url.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: InteractiveViewer(
                                          child: Image.network(url),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        );
                      }),
                  ],
                ),
              ),
              actions: [
                if (user.role == AdminUserRole.driver && !user.isApproved)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.read<AdminUsersBloc>().add(
                            ApproveAdminUserDocumentsEvent(user.id),
                          );
                    },
                    child: const Text('اعتماد المستندات',
                        style: TextStyle(
                            fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SegmentedButton<AdminUserRole>(
                segments: const [
                  ButtonSegment(
                      value: AdminUserRole.client, label: Text('العملاء')),
                  ButtonSegment(
                      value: AdminUserRole.driver, label: Text('السائقين')),
                  ButtonSegment(
                      value: AdminUserRole.vendor,
                      label: Text('أصحاب النشاط')),
                ],
                selected: {state.selectedRole},
                onSelectionChanged: (s) {
                  _fetch(context, state, role: s.first);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      textDirection: TextDirection.rtl,
                      decoration: adminInputDecoration(
                        'بحث بالاسم أو الهاتف أو البريد أو رقم المستخدم',
                      ).copyWith(
                        prefixIcon: const Icon(Icons.search),
                      ),
                      style: const TextStyle(fontFamily: 'Cairo'),
                      onSubmitted: (_) => _fetch(context, state),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _fetch(context, state),
                    child: const Text('بحث',
                        style: TextStyle(fontFamily: 'Cairo')),
                  ),
                  if (state.searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _fetch(context, state, clearSearch: true),
                      child: const Text('مسح',
                          style: TextStyle(fontFamily: 'Cairo')),
                    ),
                  ],
                ],
              ),
            ),
            if (state.selectedRole == AdminUserRole.driver)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SegmentedButton<AdminDriverSegment>(
                  segments: const [
                    ButtonSegment(
                      value: AdminDriverSegment.currentUsers,
                      label: Text('سائقين حاليين'),
                    ),
                    ButtonSegment(
                      value: AdminDriverSegment.newUsers,
                      label: Text('بانتظار المراجعة'),
                    ),
                  ],
                  selected: {state.selectedDriverSegment},
                  onSelectionChanged: (s) {
                    _fetch(
                      context,
                      state,
                      role: AdminUserRole.driver,
                      driverSegment: s.first,
                    );
                  },
                ),
              ),
            Expanded(
              child: state.status == AdminUsersStatus.loading
                  ? const AdminTableLoader()
                  : state.status == AdminUsersStatus.failure
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  state.message ?? 'تعذر تحميل المستخدمين',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AdminColors.danger,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => _fetch(context, state),
                                  child: const Text('إعادة المحاولة',
                                      style: TextStyle(fontFamily: 'Cairo')),
                                ),
                              ],
                            ),
                          ),
                        )
                      : state.users.isEmpty
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  state.selectedRole == AdminUserRole.driver &&
                                          state.selectedDriverSegment ==
                                              AdminDriverSegment.newUsers
                                      ? 'لا يوجد سائقون بانتظار المراجعة'
                                      : state.searchQuery.isNotEmpty
                                          ? 'لا توجد نتائج مطابقة لـ «${state.searchQuery}»'
                                          : 'لا يوجد مستخدمون في هذا القسم حالياً',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    color: AuthTheme.textMuted,
                                  ),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: AdminSectionCard(
                        title: state.selectedRole == AdminUserRole.driver &&
                                state.selectedDriverSegment ==
                                    AdminDriverSegment.newUsers
                            ? 'سائقون بانتظار المراجعة (${state.users.length})'
                            : state.selectedRole == AdminUserRole.vendor
                                ? 'أصحاب النشاط (${state.users.length}) — اضغط على الاسم لعرض المنتجات'
                                : 'قائمة المستخدمين (${state.users.length})',
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              const DataColumn(label: Text('الاسم')),
                              const DataColumn(label: Text('الهاتف')),
                              if (state.selectedRole == AdminUserRole.vendor) ...[
                                const DataColumn(label: Text('المستحقات')),
                                const DataColumn(label: Text('المنتجات')),
                              ],
                              const DataColumn(label: Text('الحالة')),
                              const DataColumn(label: Text('إجراءات')),
                            ],
                            rows: state.users.map((u) {
                              final busy = state.actingUserId == u.id;
                              return DataRow(cells: [
                                DataCell(
                                  state.selectedRole == AdminUserRole.vendor
                                      ? InkWell(
                                          onTap: () =>
                                              _openVendorProducts(context, u),
                                          child: Text(
                                            u.name,
                                            style: const TextStyle(
                                              fontFamily: 'Cairo',
                                              color: AuthTheme.primaryDark,
                                              fontWeight: FontWeight.w700,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          u.name,
                                          style: const TextStyle(
                                              fontFamily: 'Cairo'),
                                        ),
                                ),
                                DataCell(Text(u.phone,
                                    textDirection: TextDirection.ltr)),
                                if (state.selectedRole == AdminUserRole.vendor) ...[
                                  DataCell(Text(
                                      '${u.dueAmount.toStringAsFixed(2)} ج.م')),
                                  DataCell(
                                    TextButton(
                                      onPressed: () =>
                                          _openVendorProducts(context, u),
                                      child: Text(
                                        '${u.productsCount} منتج',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                DataCell(Chip(
                                  label: Text(
                                    u.isActive ? 'مفعل' : 'موقوف',
                                    style: const TextStyle(
                                        fontFamily: 'Cairo', fontSize: 11),
                                  ),
                                  backgroundColor: u.isActive
                                      ? AdminColors.success
                                          .withValues(alpha: 0.12)
                                      : AdminColors.danger
                                          .withValues(alpha: 0.12),
                                )),
                                DataCell(Row(
                                  children: [
                                    if (state.selectedRole ==
                                            AdminUserRole.driver &&
                                        state.selectedDriverSegment ==
                                            AdminDriverSegment.newUsers) ...[
                                      TextButton(
                                        onPressed: busy
                                            ? null
                                            : () => context
                                                .read<AdminUsersBloc>()
                                                .add(ReviewAdminUserEvent(
                                                    u.id)),
                                        child: const Text(
                                          'مراجعة البطاقة والرخص',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            color: AuthTheme.primaryDark,
                                          ),
                                        ),
                                      ),
                                      if (!u.isApproved)
                                        TextButton(
                                          onPressed: busy
                                              ? null
                                              : () => context
                                                  .read<AdminUsersBloc>()
                                                  .add(
                                                    ApproveAdminUserDocumentsEvent(
                                                        u.id),
                                                  ),
                                          child: const Text(
                                            'اعتماد وتفعيل',
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              color: AdminColors.success,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                    ] else ...[
                                    TextButton(
                                      onPressed: busy
                                          ? null
                                          : () => context
                                              .read<AdminUsersBloc>()
                                              .add(ToggleAdminUserEvent(u.id)),
                                      child: Text(
                                        u.isActive
                                            ? 'إيقاف مؤقت'
                                            : 'تفعيل',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: u.isActive
                                              ? AdminColors.danger
                                              : AdminColors.success,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: busy
                                          ? null
                                          : () => context
                                              .read<AdminUsersBloc>()
                                              .add(ReviewAdminUserEvent(u.id)),
                                      child: const Text(
                                        'مراجعة البيانات',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: AuthTheme.primaryDark,
                                        ),
                                      ),
                                    ),
                                    ],
                                    TextButton(
                                      onPressed: busy
                                          ? null
                                          : () async {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: const Text(
                                                    'حذف الحساب؟',
                                                    style: TextStyle(
                                                      fontFamily: 'Cairo',
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  content: Text(
                                                    'سيتم حذف حساب ${u.name} نهائياً.',
                                                    style: const TextStyle(
                                                        fontFamily: 'Cairo'),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, false),
                                                      child: const Text(
                                                        'إلغاء',
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'Cairo'),
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, true),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                      child: const Text(
                                                        'حذف',
                                                        style: TextStyle(
                                                            fontFamily:
                                                                'Cairo'),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (ok == true && context.mounted) {
                                                context
                                                    .read<AdminUsersBloc>()
                                                    .add(DeleteAdminUserEvent(
                                                        u.id));
                                              }
                                            },
                                      child: const Text(
                                        'حذف',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
