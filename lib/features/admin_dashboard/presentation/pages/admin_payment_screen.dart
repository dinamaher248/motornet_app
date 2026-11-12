import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/admin_dashboard_injection.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_payment_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class AdminPaymentScreen extends StatelessWidget {
  const AdminPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardInjection.createPaymentBloc()
        ..add(const LoadAdminPaymentEvent()),
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
  late final TextEditingController _vodafone;
  late final TextEditingController _instapay;
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    _vodafone = TextEditingController();
    _instapay = TextEditingController();
  }

  @override
  void dispose() {
    _vodafone.dispose();
    _instapay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminPaymentBloc, AdminPaymentState>(
      listener: (context, state) {
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state.status == AdminPaymentStatus.loading) {
          return const AdminTableLoader();
        }
        if (!_synced && state.status == AdminPaymentStatus.loaded) {
          _vodafone.text = state.settings.vodafoneCashNumber;
          _instapay.text = state.settings.instapayHandle;
          _synced = true;
        }
        final s = state.settings;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminSectionCard(
              title: 'طرق الدفع العامة للتطبيق',
              actions: [
                ElevatedButton(
                  onPressed: state.saving
                      ? null
                      : () {
                          context.read<AdminPaymentBloc>().add(
                                UpdatePaymentDraftEvent(
                                  vodafoneCashNumber: _vodafone.text.trim(),
                                  instapayHandle: _instapay.text.trim(),
                                ),
                              );
                          context
                              .read<AdminPaymentBloc>()
                              .add(const SaveAdminPaymentEvent());
                        },
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
                    title: 'تفعيل الدفع كاش',
                    value: s.cashEnabled,
                    onChanged: (v) => context
                        .read<AdminPaymentBloc>()
                        .add(UpdatePaymentDraftEvent(cashEnabled: v)),
                  ),
                  const Divider(),
                  AdminMasterSwitch(
                    title: 'تفعيل Vodafone Cash',
                    value: s.vodafoneEnabled,
                    onChanged: (v) => context
                        .read<AdminPaymentBloc>()
                        .add(UpdatePaymentDraftEvent(vodafoneEnabled: v)),
                  ),
                  TextField(
                    controller: _vodafone,
                    enabled: s.vodafoneEnabled,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration:
                        adminInputDecoration('رقم Vodafone Cash للتطبيق'),
                    onChanged: (v) => context.read<AdminPaymentBloc>().add(
                          UpdatePaymentDraftEvent(vodafoneCashNumber: v),
                        ),
                  ),
                  const SizedBox(height: 14),
                  AdminMasterSwitch(
                    title: 'تفعيل InstaPay',
                    value: s.instapayEnabled,
                    onChanged: (v) => context
                        .read<AdminPaymentBloc>()
                        .add(UpdatePaymentDraftEvent(instapayEnabled: v)),
                  ),
                  TextField(
                    controller: _instapay,
                    enabled: s.instapayEnabled,
                    textDirection: TextDirection.ltr,
                    decoration:
                        adminInputDecoration('معرّف InstaPay للتطبيق'),
                    onChanged: (v) => context.read<AdminPaymentBloc>().add(
                          UpdatePaymentDraftEvent(instapayHandle: v),
                        ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
