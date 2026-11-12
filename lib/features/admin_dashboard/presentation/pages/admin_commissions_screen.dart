import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/admin_dashboard/admin_dashboard_injection.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_commissions_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class AdminCommissionsScreen extends StatelessWidget {
  const AdminCommissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardInjection.createCommissionsBloc()
        ..add(const LoadAdminCommissionsEvent()),
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
  late final TextEditingController _driver;
  late final TextEditingController _vendor;
  late final TextEditingController _debt;
  late final TextEditingController _orderCommission;
  late final TextEditingController _orderFixedFee;
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    _driver = TextEditingController();
    _vendor = TextEditingController();
    _debt = TextEditingController();
    _orderCommission = TextEditingController();
    _orderFixedFee = TextEditingController();
  }

  @override
  void dispose() {
    _driver.dispose();
    _vendor.dispose();
    _debt.dispose();
    _orderCommission.dispose();
    _orderFixedFee.dispose();
    super.dispose();
  }

  void _syncFields(AdminCommissionsState state) {
    if (_synced || state.status != AdminCommissionsStatus.loaded) return;
    _driver.text = state.settings.driverCommissionPercent.toString();
    _vendor.text = state.settings.vendorCommissionPercent.toString();
    _debt.text = state.settings.debtLimit.toString();
    _orderCommission.text =
        state.settings.vendorOrdersCommissionPercent.toString();
    _orderFixedFee.text =
        state.settings.vendorOrdersFixedFeeAmount.toString();
    _synced = true;
  }

  void _saveAll(BuildContext context) {
    context.read<AdminCommissionsBloc>().add(
          UpdateCommissionFieldsEvent(
            driverPercent: double.tryParse(_driver.text.trim()),
            vendorPercent: double.tryParse(_vendor.text.trim()),
            debtLimit: double.tryParse(_debt.text.trim()),
            vendorOrdersCommissionPercent:
                double.tryParse(_orderCommission.text.trim()),
            vendorOrdersFixedFeeAmount:
                double.tryParse(_orderFixedFee.text.trim()),
          ),
        );
    context.read<AdminCommissionsBloc>().add(const SaveCommissionSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminCommissionsBloc, AdminCommissionsState>(
      listener: (context, state) {
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        _syncFields(state);
        if (state.status == AdminCommissionsStatus.loading) {
          return const AdminTableLoader();
        }
        final enabled = state.settings.commissionEnabled;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminSectionCard(
              title: 'إعدادات نظام العمولة',
              actions: [
                ElevatedButton(
                  onPressed: state.saving ? null : () => _saveAll(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: state.saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('حفظ',
                          style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
              child: Column(
                children: [
                  AdminMasterSwitch(
                    title: 'تفعيل نظام العمولة',
                    subtitle:
                        'عند التعطيل لن تُحسب عمولات على الطلبات والرحلات',
                    value: enabled,
                    onChanged: (v) => context
                        .read<AdminCommissionsBloc>()
                        .add(UpdateCommissionEnabledEvent(v)),
                  ),
                  const Divider(),
                  Opacity(
                    opacity: enabled ? 1 : 0.45,
                    child: IgnorePointer(
                      ignoring: !enabled,
                      child: Column(
                        children: [
                          TextField(
                            controller: _driver,
                            keyboardType: TextInputType.number,
                            decoration: adminInputDecoration(
                                'عمولة السائق %'),
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _vendor,
                            keyboardType: TextInputType.number,
                            decoration: adminInputDecoration(
                                'عمولة صاحب النشاط %'),
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _debt,
                            keyboardType: TextInputType.number,
                            decoration:
                                adminInputDecoration('حد المديونية (ج.م)'),
                            style: const TextStyle(fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AdminSectionCard(
              title: 'أصحاب النشاط — الطلبات',
              actions: [
                ElevatedButton(
                  onPressed: state.saving ? null : () => _saveAll(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AuthTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: state.saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('حفظ',
                          style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'لو فعّلت الخيارين يظهران لصاحب نشاط الطلبات ليختار. لو وقّفت خياراً لا يظهر ولا يُحسب. أي تعديل في النسبة أو المبلغ يظهر فوراً في حسابه.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AuthTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AdminMasterSwitch(
                    title: 'تفعيل خيار العمولة',
                    subtitle: 'يظهر لصاحب نشاط الطلبات كخيار عمولة من قيمة الطلب',
                    value: state.settings.vendorOrdersCommissionEnabled,
                    onChanged: (v) => context
                        .read<AdminCommissionsBloc>()
                        .add(UpdateVendorOrdersCommissionEnabledEvent(v)),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity:
                        state.settings.vendorOrdersCommissionEnabled ? 1 : 0.45,
                    child: IgnorePointer(
                      ignoring: !state.settings.vendorOrdersCommissionEnabled,
                      child: TextField(
                        controller: _orderCommission,
                        keyboardType: TextInputType.number,
                        decoration: adminInputDecoration(
                            'نسبة عمولة الطلبات %'),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                  const Divider(height: 28),
                  AdminMasterSwitch(
                    title: 'تفعيل الاشتراك الثابت لكل طلب',
                    subtitle: 'مبلغ ثابت يُخصم من صاحب النشاط على كل طلب في قسم الطلبات',
                    value: state.settings.vendorOrdersFixedFeeEnabled,
                    onChanged: (v) => context
                        .read<AdminCommissionsBloc>()
                        .add(UpdateVendorOrdersFixedFeeEnabledEvent(v)),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: state.settings.vendorOrdersFixedFeeEnabled
                        ? 1
                        : 0.45,
                    child: IgnorePointer(
                      ignoring: !state.settings.vendorOrdersFixedFeeEnabled,
                      child: TextField(
                        controller: _orderFixedFee,
                        keyboardType: TextInputType.number,
                        decoration: adminInputDecoration(
                            'قيمة الاشتراك لكل طلب (ج.م)'),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AdminSectionCard(
              title: 'المديونيات (الحد + تسديد بدري)',
              actions: [
                TextButton(
                  onPressed: state.actingSettlementId != null
                      ? null
                      : () => context.read<AdminCommissionsBloc>().add(
                            const HandleSettlementEvent(
                                id: 0, action: 'notify_all'),
                          ),
                  child: const Text('إشعار الكل',
                      style: TextStyle(fontFamily: 'Cairo')),
                ),
                TextButton(
                  onPressed: state.actingSettlementId != null
                      ? null
                      : () => context.read<AdminCommissionsBloc>().add(
                            const HandleSettlementEvent(
                                id: 0, action: 'suspend_all'),
                          ),
                  child: const Text('إيقاف الكل',
                      style: TextStyle(
                          fontFamily: 'Cairo', color: AdminColors.danger)),
                ),
                TextButton(
                  onPressed: state.actingSettlementId != null
                      ? null
                      : () => context.read<AdminCommissionsBloc>().add(
                            const HandleSettlementEvent(
                                id: 0, action: 'activate_all'),
                          ),
                  child: const Text('تشغيل الكل',
                      style: TextStyle(
                          fontFamily: 'Cairo', color: AdminColors.success)),
                ),
              ],
              child: state.settlements.isEmpty
                  ? const Text('لا يوجد مستخدمين وصلوا للحد أو طلبوا تسديد بدري',
                      style: TextStyle(fontFamily: 'Cairo'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('المستخدم')),
                          DataColumn(label: Text('المستحق')),
                          DataColumn(label: Text('الفوترة')),
                          DataColumn(label: Text('السبب')),
                          DataColumn(label: Text('الإيصال')),
                          DataColumn(label: Text('الحساب')),
                          DataColumn(label: Text('إجراءات')),
                        ],
                        rows: state.settlements.map((s) {
                          final busy = state.actingSettlementId == s.id;
                          final url = resolveStorageImageUrl(s.receiptImage);
                          return DataRow(cells: [
                            DataCell(Text(s.userName,
                                style: const TextStyle(fontFamily: 'Cairo'))),
                            DataCell(Text(
                                '${s.amount.toStringAsFixed(0)} ج.م')),
                            DataCell(Text(
                              s.billingModeLabel.isNotEmpty
                                  ? s.billingModeLabel
                                  : '-',
                              style: const TextStyle(fontFamily: 'Cairo'),
                            )),
                            DataCell(Text(
                              s.reasonLabel.isNotEmpty
                                  ? s.reasonLabel
                                  : (s.earlyPayment
                                      ? 'طلب تسديد بدري'
                                      : (s.atLimit ? 'وصل للحد' : '-')),
                              style: const TextStyle(fontFamily: 'Cairo'),
                            )),
                            DataCell(
                              url.isEmpty
                                  ? const Text('-')
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton(
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
                                          child: const Text('عرض',
                                              style: TextStyle(
                                                  fontFamily: 'Cairo')),
                                        ),
                                        if (s.receiptRequestId != null)
                                          TextButton(
                                            onPressed: busy
                                                ? null
                                                : () => context
                                                    .read<
                                                        AdminCommissionsBloc>()
                                                    .add(HandleSettlementEvent(
                                                      id: s.receiptRequestId!,
                                                      action: 'approve_receipt',
                                                    )),
                                            child: const Text('قبول',
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  color: AdminColors.success,
                                                )),
                                          ),
                                      ],
                                    ),
                            ),
                            DataCell(Text(
                              s.isSuspended ? 'موقوف' : 'يعمل',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: s.isSuspended
                                    ? AdminColors.danger
                                    : AdminColors.success,
                              ),
                            )),
                            DataCell(
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: busy
                                        ? null
                                        : () => context
                                            .read<AdminCommissionsBloc>()
                                            .add(HandleSettlementEvent(
                                              id: s.id,
                                              action: 'mark_paid',
                                            )),
                                    child: const Text('تم السداد',
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          color: AdminColors.success,
                                        )),
                                  ),
                                  TextButton(
                                    onPressed: busy
                                        ? null
                                        : () => context
                                            .read<AdminCommissionsBloc>()
                                            .add(HandleSettlementEvent(
                                              id: s.id,
                                              action: 'toggle',
                                            )),
                                    child: Text(
                                      s.isSuspended ? 'تشغيل' : 'إيقاف',
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        color: s.isSuspended
                                            ? AdminColors.success
                                            : AdminColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
