import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/data/local/auth_prefs.dart';
import 'package:motorent/features/my_account/presentation/pages/profile_screen.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';
import 'package:motorent/features/vendor_interface/presentation/bloc/vendor_wallet_bloc.dart';
import 'package:motorent/features/vendor_interface/presentation/widgets/vendor_settlement_sheet.dart';
import 'package:motorent/features/vendor_interface/vendor_interface_injection.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:shimmer/shimmer.dart';

class VendorAccountScreen extends StatelessWidget {
  final int refreshToken;

  const VendorAccountScreen({super.key, this.refreshToken = 0});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('vendor_wallet_$refreshToken'),
      create: (_) => VendorInterfaceInjection.createWalletBloc()
        ..add(const FetchVendorWalletEvent()),
      child: _Body(refreshToken: refreshToken),
    );
  }
}

class _Body extends StatefulWidget {
  final int refreshToken;
  const _Body({required this.refreshToken});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with WidgetsBindingObserver {
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
      context.read<VendorWalletBloc>().add(const FetchVendorWalletEvent());
    }
  }

  @override
  void didUpdateWidget(covariant _Body oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      context.read<VendorWalletBloc>().add(const FetchVendorWalletEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      refreshToken: widget.refreshToken,
      topSection: BlocConsumer<VendorWalletBloc, VendorWalletState>(
        listener: (context, state) {
          if (state.message != null &&
              state.message!.isNotEmpty &&
              state.status == VendorWalletStatus.loaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if ((state.status == VendorWalletStatus.loading ||
                  state.status == VendorWalletStatus.initial) &&
              state.wallet == null) {
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }

          final wallet = state.wallet;
          if (wallet == null) return const SizedBox.shrink();

          if (AuthPrefs.isVendorServicesMode) {
            return const SizedBox.shrink();
          }

          return _OrdersBillingCard(
            wallet: wallet,
            updating: state.status == VendorWalletStatus.loading,
            isBookings: AuthPrefs.isVendorBookingsMode,
          );
        },
      ),
    );
  }
}

class _OrdersBillingCard extends StatelessWidget {
  final VendorWallet wallet;
  final bool updating;
  final bool isBookings;

  const _OrdersBillingCard({
    required this.wallet,
    this.updating = false,
    this.isBookings = false,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<VendorWalletBloc>();
    final showCommission = wallet.commissionOptionEnabled;
    final showFixed = wallet.fixedFeeOptionEnabled;
    final billingOff = !showCommission && !showFixed;

    if (billingOff && wallet.dueAmount <= 0 && !isBookings) {
      return const SizedBox.shrink();
    }

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
          if (wallet.debtLimit > 0 &&
              wallet.dueAmount >= wallet.debtLimit)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'وصلت لحد المديونية (${wallet.debtLimit.toStringAsFixed(0)} ج.م). سدد المستحقات حتى يُعاد تفعيل الحساب.',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Color(0xFFB42318),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
              _BillingOptionTile(
                selected: wallet.billingMode == 'commission' || !showFixed,
                enabled: !updating && showFixed,
                title:
                    'عمولة ${wallet.orderCommissionPercent.toStringAsFixed(0)}%',
                subtitle: isBookings
                    ? 'نسبة من قيمة كل حجز'
                    : 'نسبة من قيمة كل طلب',
                onTap: showFixed
                    ? () => bloc.add(
                          const UpdateVendorBillingModeEvent('commission'),
                        )
                    : null,
              ),
              const SizedBox(height: 8),
            ],
            if (showFixed) ...[
              _BillingOptionTile(
                selected: wallet.billingMode == 'fixed_fee' || !showCommission,
                enabled: !updating && showCommission,
                title:
                    '${wallet.orderFixedFee.toStringAsFixed(0)} ج.م لكل ${isBookings ? 'حجز' : 'طلب'}',
                subtitle: 'اشتراك ثابت',
                onTap: showCommission
                    ? () => bloc.add(
                          const UpdateVendorBillingModeEvent('fixed_fee'),
                        )
                    : null,
              ),
              const SizedBox(height: 12),
            ],
          ],
          if (!billingOff || wallet.dueAmount > 0) ...[
          _stat(
            'الرصيد المستحق',
            '${wallet.dueAmount.toStringAsFixed(0)} ج.م',
          ),
          if (!billingOff)
          _stat(
            wallet.isFixedFeeMode ? 'السعر لكل طلب' : 'نسبة العمولة',
            wallet.rateLabel,
          ),
          ],
          if (isBookings)
            _stat('عدد الحجوزات', '${wallet.bookingsCount}')
          else
          _stat(
            'الطلبات المكتملة',
            '${wallet.completedOrdersCount}',
          ),
          if (wallet.debtLimit > 0)
            _stat(
              'حد المديونية',
              '${wallet.debtLimit.toStringAsFixed(0)} ج.م',
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: wallet.dueAmount <= 0
                  ? null
                  : () => showVendorSettlementSheet(
                        context: context,
                        wallet: wallet,
                        bloc: bloc,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AuthTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'سداد مستحقات التطبيق',
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

class _BillingOptionTile extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _BillingOptionTile({
    required this.selected,
    required this.enabled,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}
