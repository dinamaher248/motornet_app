import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/admin_dashboard_injection.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_notifications_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardInjection.createNotificationsBloc(),
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
  AdminNotificationTarget _target = AdminNotificationTarget.all;
  final _phone = TextEditingController();
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminNotificationsBloc, AdminNotificationsState>(
      listener: (context, state) {
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message!)));
          if (state.status == AdminNotificationsStatus.success) {
            _title.clear();
            _body.clear();
            _phone.clear();
          }
        }
      },
      builder: (context, state) {
        final sending = state.status == AdminNotificationsStatus.sending;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminSectionCard(
              title: 'إرسال إشعار',
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'يُحفظ داخل التطبيق للمستهدفين، ويُرسل Push عند توفر توكنات FCM أو لموضوع الكل.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ),
                  DropdownButtonFormField<AdminNotificationTarget>(
                    value: _target,
                    decoration: adminInputDecoration('الجمهور المستهدف'),
                    items: const [
                      DropdownMenuItem(
                          value: AdminNotificationTarget.all,
                          child: Text('الكل')),
                      DropdownMenuItem(
                          value: AdminNotificationTarget.clients,
                          child: Text('العملاء فقط')),
                      DropdownMenuItem(
                          value: AdminNotificationTarget.drivers,
                          child: Text('السائقين فقط')),
                      DropdownMenuItem(
                          value: AdminNotificationTarget.vendors,
                          child: Text('أصحاب النشاط فقط')),
                      DropdownMenuItem(
                          value: AdminNotificationTarget.withDues,
                          child: Text('من عليهم مستحقات')),
                      DropdownMenuItem(
                          value: AdminNotificationTarget.specific,
                          child: Text('مستخدم محدد (برقم الهاتف)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _target = v);
                    },
                  ),
                  if (_target == AdminNotificationTarget.specific) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: adminInputDecoration('رقم هاتف المستخدم'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _title,
                    decoration: adminInputDecoration('عنوان الإشعار'),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _body,
                    maxLines: 4,
                    decoration: adminInputDecoration('نص الإشعار'),
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: sending
                          ? null
                          : () {
                              if (_title.text.trim().isEmpty ||
                                  _body.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('أدخل العنوان والنص')),
                                );
                                return;
                              }
                              if (_target ==
                                      AdminNotificationTarget.specific &&
                                  _phone.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('أدخل رقم الهاتف')),
                                );
                                return;
                              }
                              context.read<AdminNotificationsBloc>().add(
                                    SendAdminPushEvent(
                                      SendAdminNotificationParams(
                                        target: _target,
                                        specificPhone: _phone.text.trim(),
                                        title: _title.text.trim(),
                                        body: _body.text.trim(),
                                      ),
                                    ),
                                  );
                            },
                      icon: sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send),
                      label: const Text('إرسال',
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AuthTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
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
