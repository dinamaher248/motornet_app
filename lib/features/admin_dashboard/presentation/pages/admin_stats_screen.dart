import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/admin_dashboard_injection.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_stats_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardInjection.createStatsBloc()
        ..add(const FetchAdminStatsEvent()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminStatsBloc, AdminStatsState>(
      listener: (context, state) {
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        if (state.status == AdminStatsStatus.loading ||
            state.status == AdminStatsStatus.initial) {
          return const AdminTableLoader();
        }
        final s = state.stats;
        final cards = [
          AdminStatCard(
            label: 'إجمالي الأرباح',
            value: '${s.totalProfit.toStringAsFixed(0)} ج.م',
            icon: Icons.trending_up,
            color: const Color(0xFF059669),
          ),
          AdminStatCard(
            label: 'أرباح محصّلة',
            value: '${s.collectedProfit.toStringAsFixed(0)} ج.م',
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFF0C9F6A),
          ),
          AdminStatCard(
            label: 'مستحقات معلقة',
            value: '${s.outstandingDues.toStringAsFixed(0)} ج.م',
            icon: Icons.pending_actions_outlined,
            color: AdminColors.warning,
          ),
          AdminStatCard(
            label: 'العملاء',
            value: '${s.clientsCount}',
            icon: Icons.people_outline,
            color: const Color(0xFF2563EB),
          ),
          AdminStatCard(
            label: 'السائقين',
            value: '${s.driversCount}',
            icon: Icons.two_wheeler,
            color: const Color(0xFF0C9F6A),
          ),
          AdminStatCard(
            label: 'أصحاب النشاط',
            value: '${s.vendorsCount}',
            icon: Icons.storefront_outlined,
            color: const Color(0xFF7C3AED),
          ),
          AdminStatCard(
            label: 'قيمة الطلبات المكتملة',
            value: '${s.totalRevenue.toStringAsFixed(0)} ج.م',
            icon: Icons.payments_outlined,
            color: AdminColors.sidebarSelected,
          ),
          AdminStatCard(
            label: 'الطلبات النشطة',
            value: '${s.activeOrders}',
            icon: Icons.local_shipping_outlined,
            color: AdminColors.warning,
          ),
        ];

        return RefreshIndicator(
          onRefresh: () async {
            context
                .read<AdminStatsBloc>()
                .add(const FetchAdminStatsEvent());
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth > 1100
                      ? 3
                      : constraints.maxWidth > 700
                          ? 2
                          : 1;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: cards
                        .map((c) => SizedBox(
                              width: (constraints.maxWidth - (cols - 1) * 14) /
                                  cols,
                              child: c,
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              AdminSectionCard(
                title: 'توزيع الأرباح',
                child: _SimpleBars(
                  values: {
                    'محصّلة': s.collectedProfit,
                    'معلقة': s.outstandingDues,
                  },
                ),
              ),
              const SizedBox(height: 16),
              AdminSectionCard(
                title: 'توزيع المستخدمين',
                child: _SimpleBars(
                  values: {
                    'عملاء': s.clientsCount.toDouble(),
                    'سائقين': s.driversCount.toDouble(),
                    'أنشطة': s.vendorsCount.toDouble(),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SimpleBars extends StatelessWidget {
  final Map<String, double> values;
  const _SimpleBars({required this.values});

  @override
  Widget build(BuildContext context) {
    final max = values.values.fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = max <= 0 ? 1.0 : max;
    return Column(
      children: values.entries.map((e) {
        final ratio = (e.value / safeMax).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  e.key,
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 14,
                    backgroundColor: const Color(0xFFEEF0F3),
                    color: AdminColors.sidebarSelected,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                e.value.toStringAsFixed(0),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
