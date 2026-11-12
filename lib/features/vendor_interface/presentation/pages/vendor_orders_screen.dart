import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/bidding_system/presentation/pages/bidding_home_page.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_entities.dart';
import 'package:motorent/features/vendor_interface/presentation/bloc/vendor_orders_bloc.dart';
import 'package:motorent/features/vendor_interface/presentation/pages/vendor_dispatch_page.dart';
import 'package:motorent/features/vendor_interface/presentation/widgets/send_custom_offer_sheet.dart';
import 'package:motorent/features/vendor_interface/vendor_interface_injection.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/rating_stars.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorOrdersScreen extends StatelessWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorInterfaceInjection.createOrdersBloc()
        ..add(const FetchVendorOrdersEvent()),
      child: const _VendorOrdersView(),
    );
  }
}

class _VendorOrdersView extends StatelessWidget {
  const _VendorOrdersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'الطلبات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'وسائل النقل',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text(
                        'وسائل النقل',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      centerTitle: true,
                    ),
                    body: Container(
                      decoration: AuthTheme.screenBackground(),
                      child: const SafeArea(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                          child: BiddingHomePage(embedInParent: true),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.two_wheeler_outlined),
          ),
        ],
      ),
      body: BlocConsumer<VendorOrdersBloc, VendorOrdersState>(
        listener: (context, state) {
          if (state.message != null && state.message!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == VendorOrdersStatus.loading ||
              state.status == VendorOrdersStatus.initial) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<VendorOrdersBloc>()
                  .add(const FetchVendorOrdersEvent());
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
            child: state.orders.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'لا توجد طلبات حالياً',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: AuthTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: state.orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = state.orders[index];
                      final busy = state.handlingOrderId == order.id;
                      return _OrderCard(
                        order: order,
                        busy: busy,
                        onAccept: () {
                          final action = order.canConfirmPayment
                              ? 'confirm_payment'
                              : 'accept';
                          context.read<VendorOrdersBloc>().add(
                                HandleVendorOrderEvent(
                                  orderId: order.id,
                                  action: action,
                                  orderType: order.orderType,
                                ),
                              );
                        },
                        onReject: () {
                          final action = order.canRejectPayment
                              ? 'reject_payment'
                              : 'reject';
                          context.read<VendorOrdersBloc>().add(
                                HandleVendorOrderEvent(
                                  orderId: order.id,
                                  action: action,
                                  orderType: order.orderType,
                                ),
                              );
                        },
                        onSendOffer: () => showSendCustomOfferSheet(
                          context,
                          order: order,
                        ),
                        onMarkCompleted: () {
                          context.read<VendorOrdersBloc>().add(
                                HandleVendorOrderEvent(
                                  orderId: order.id,
                                  action: 'complete',
                                  orderType: order.orderType,
                                ),
                              );
                        },
                        onDispatch: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  VendorDispatchPage(order: order),
                            ),
                          ).then((_) {
                            context
                                .read<VendorOrdersBloc>()
                                .add(const FetchVendorOrdersEvent());
                          });
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final VendorOrder order;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onSendOffer;
  final VoidCallback onMarkCompleted;
  final VoidCallback onDispatch;

  const _OrderCard({
    required this.order,
    required this.busy,
    required this.onAccept,
    required this.onReject,
    required this.onSendOffer,
    required this.onMarkCompleted,
    required this.onDispatch,
  });

  String _formatAddress(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '—';
    if (text.contains(' — ')) {
      final detail = text.split(' — ').last.trim();
      if (detail.isNotEmpty && !detail.contains('موقعي الحالي')) {
        return detail;
      }
    }
    final cleaned = text
        .replaceAll(RegExp(r'موقعي الحالي\s*\([^)]+\)\s*-?\s*'), '')
        .trim();
    return cleaned.isEmpty ? text : cleaned;
  }

  Future<void> _call(String? phone) async {
    final raw = (phone ?? '').trim();
    if (raw.isEmpty) return;
    var normalized = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (normalized.startsWith('00')) {
      normalized = '+${normalized.substring(2)}';
    }
    final uri = Uri.parse('tel:$normalized');
    try {
      var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }

  void _chat(String? phone) {
    if (phone == null || phone.isEmpty) return;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    launchUrl(
      Uri.parse('https://wa.me/$digits'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final proofUrl = resolveStorageImageUrl(order.paymentProof);
    final customImageUrl = resolveStorageImageUrl(order.customRequestImage);
    final showCashActions =
        !order.isCustom && (order.canAccept || order.canReject);
    final showWalletActions =
        !order.isCustom && (order.canConfirmPayment || order.canRejectPayment);
    final canContact = (order.customerPhone ?? '').trim().isNotEmpty &&
        !order.isPendingCustomPricing;
    final addressText = _formatAddress(order.deliveryAddress);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: order.isCustom
              ? AuthTheme.primary.withValues(alpha: 0.35)
              : AuthTheme.fieldBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (order.isCustom)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AuthTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'طلب مخصص',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AuthTheme.primaryDark,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  order.displayTitle,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'تقييم العميل: ',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AuthTheme.textMuted,
                ),
              ),
              RatingStars(
                rating: order.customerRating,
                count: order.customerRatingsCount,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (order.isCustom) ...[
            if ((order.customRequestText ?? '').trim().isNotEmpty)
              _row('الوصف', order.customRequestText!),
            if (customImageUrl.isNotEmpty) ...[
              const SizedBox(height: 4),
              const Text(
                'صورة الطلب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  customImageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            if (order.offerPrice != null)
              _row('السعر', '${order.offerPrice!.toStringAsFixed(0)} ج.م'),
            if (order.showCustomerIdentity) ...[
              _row('العميل', order.customerName),
              if ((order.customerPhone ?? '').isNotEmpty)
                _row('الهاتف', order.customerPhone!),
            ] else if (order.isPendingCustomPricing) ...[
              const Text(
                'بيانات التواصل تظهر بعد قبول العميل لعرض السعر',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AuthTheme.textMuted,
                ),
              ),
            ],
            _row('العنوان', addressText),
            _row('طريقة الاستلام', order.fulfillmentLabel),
            _row('الدفع', order.paymentMethodLabel),
            if ((order.notes ?? '').isNotEmpty) _row('ملاحظات', order.notes!),
          ] else ...[
            _row('السعر', '${order.totalPrice.toStringAsFixed(0)} ج.م'),
            if (order.showCustomerIdentity) ...[
              _row('العميل', order.customerName),
              if ((order.customerPhone ?? '').isNotEmpty)
                _row('الهاتف', order.customerPhone!),
            ] else ...[
              const Text(
                'بيانات التواصل تظهر بعد قبول الطلب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AuthTheme.textMuted,
                ),
              ),
            ],
            _row('العنوان', addressText),
            _row('طريقة الاستلام', order.fulfillmentLabel),
            _row(
              'الدفع',
              order.paymentMethodLabel.isNotEmpty
                  ? order.paymentMethodLabel
                  : order.paymentMethod,
            ),
            if ((order.notes ?? '').isNotEmpty) _row('ملاحظات', order.notes!),
          ],
          _row('الحالة', order.statusLabel),
          if ((order.vendorHint ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Text(
                order.vendorHint!,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: Color(0xFF8D6E00),
                ),
              ),
            ),
          ],
          if (canContact) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _call(order.customerPhone),
                    icon: const Icon(Icons.phone, size: 18),
                    label: const Text(
                      'اتصال',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C9F6A),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _chat(order.customerPhone),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text(
                      'محادثة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (order.isWallet && proofUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'صورة التحويل',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                proofUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Text(
                  'تعذر عرض صورة التحويل',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
                ),
              ),
            ),
          ],
          if (order.canSendOffer) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : onSendOffer,
                icon: const Icon(Icons.local_offer_outlined),
                label: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'إرسال عرض السعر',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          if (showCashActions || showWalletActions) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: busy ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C9F6A),
                      foregroundColor: Colors.white,
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            showWalletActions
                                ? 'تأكيد استلام الدفع'
                                : 'قبول الطلب',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: Text(
                      showWalletActions ? 'لم يتم الدفع' : 'رفض الطلب',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (order.canPrepareDispatch || order.canViewDeliveryOffers) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : onDispatch,
                icon: const Icon(Icons.local_shipping_outlined),
                label: Text(
                  order.canViewDeliveryOffers
                      ? 'عروض وسيلة النقل'
                      : 'طلب وسيلة نقل',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          if (order.canMarkCompleted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : onMarkCompleted,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  order.isPickup ? 'تم الاستلام من الفرع' : 'تم التسليم للعميل',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AuthTheme.textDark,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AuthTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
