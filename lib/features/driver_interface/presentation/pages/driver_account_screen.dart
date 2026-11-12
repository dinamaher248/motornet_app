import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/driver_interface/driver_interface_injection.dart';
import 'package:motorent/features/driver_interface/presentation/bloc/driver_wallet_bloc.dart';
import 'package:motorent/features/driver_interface/presentation/widgets/driver_settlement_sheet.dart';
import 'package:motorent/features/driver_interface/presentation/widgets/driver_shimmer.dart';
import 'package:motorent/features/my_account/presentation/pages/profile_screen.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

/// Profile screen extended with driver dues (مستحقات التطبيق).
class DriverAccountScreen extends StatelessWidget {
  final int refreshToken;

  const DriverAccountScreen({super.key, this.refreshToken = 0});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('driver_wallet_$refreshToken'),
      create: (_) => DriverInterfaceInjection.createWalletBloc()
        ..add(const FetchWalletStats()),
      child: _DriverAccountBody(refreshToken: refreshToken),
    );
  }
}

class _DriverAccountBody extends StatefulWidget {
  final int refreshToken;

  const _DriverAccountBody({required this.refreshToken});

  @override
  State<_DriverAccountBody> createState() => _DriverAccountBodyState();
}

class _DriverAccountBodyState extends State<_DriverAccountBody>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<DriverWalletBloc>().add(const FetchWalletStats());
    }
  }

  @override
  void didUpdateWidget(covariant _DriverAccountBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      context.read<DriverWalletBloc>().add(const FetchWalletStats());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      refreshToken: widget.refreshToken,
      topSection: BlocBuilder<DriverWalletBloc, DriverWalletState>(
        builder: (context, state) {
          if ((state.status == DriverWalletStatus.loading ||
                  state.status == DriverWalletStatus.initial) &&
              state.wallet == null) {
            return const DriverWalletShimmer();
          }

          final wallet = state.wallet;
          if (wallet == null) {
            return const SizedBox.shrink();
          }

          final showCommission = wallet.commissionOptionEnabled;
          final showFixed = wallet.fixedFeeOptionEnabled;
          final billingOff = !showCommission && !showFixed;
          if (billingOff && wallet.dueAmount <= 0) {
            return const SizedBox.shrink();
          }
          final updating = state.status == DriverWalletStatus.loading;
          final bloc = context.read<DriverWalletBloc>();

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  AuthTheme.primary.withValues(alpha: 0.16),
                  const Color(0xFF0C9F6A).withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(color: AuthTheme.fieldBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مستحقات التطبيق',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (billingOff)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'لا توجد فوترة مفعّلة حالياً من الإدارة.',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AuthTheme.textMuted,
                      ),
                    ),
                  )
                else ...[
                  if (showCommission && showFixed) ...[
                    const Text(
                      'اختر طريقة الفوترة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AuthTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (showCommission) ...[
                    _option(
                      selected:
                          wallet.billingMode == 'commission' || !showFixed,
                      enabled: !updating && showFixed,
                      title:
                          'عمولة ${wallet.commissionRate.toStringAsFixed(0)}%',
                      subtitle: 'نسبة من قيمة كل طلب',
                      onTap: showFixed
                          ? () => bloc.add(
                                const UpdateDriverBillingModeEvent(
                                  'commission',
                                ),
                              )
                          : null,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (showFixed) ...[
                    _option(
                      selected:
                          wallet.billingMode == 'fixed_fee' || !showCommission,
                      enabled: !updating && showCommission,
                      title:
                          '${wallet.orderFixedFee.toStringAsFixed(0)} ج.م لكل طلب',
                      subtitle: 'اشتراك ثابت لكل طلب',
                      onTap: showCommission
                          ? () => bloc.add(
                                const UpdateDriverBillingModeEvent(
                                  'fixed_fee',
                                ),
                              )
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                if (!billingOff || wallet.dueAmount > 0)
                  _stat(
                    'الرصيد المستحق',
                    '${wallet.dueAmount.toStringAsFixed(0)} ج.م',
                  ),
                if (!billingOff)
                  _stat(
                    wallet.isFixedFeeMode ? 'السعر لكل طلب' : 'نسبة العمولة',
                    wallet.rateLabel,
                  ),
                _stat(
                  'عدد الطلبات المكتملة',
                  '${wallet.completedTripsCount}',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: wallet.dueAmount <= 0
                        ? null
                        : () => showDriverSettlementSheet(
                              context: context,
                              wallet: wallet,
                              bloc: context.read<DriverWalletBloc>(),
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AuthTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'سداد المستحقات',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _option({
    required bool selected,
    required bool enabled,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: selected
          ? AuthTheme.primary.withValues(alpha: 0.1)
          : Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AuthTheme.primary : AuthTheme.fieldBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? AuthTheme.primary : AuthTheme.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? AuthTheme.primaryDark
                            : AuthTheme.textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AuthTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                color: AuthTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
