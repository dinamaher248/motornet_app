import 'package:flutter/material.dart';
import 'package:motorent/features/bidding_system/presentation/pages/dynamic_vehicle_select_page.dart';
import 'package:motorent/features/bidding_system/presentation/pages/my_trips_screen.dart';
import 'package:motorent/features/bidding_system/presentation/widgets/service_type_card.dart';
import 'package:motorent/features/vendor_interface/domain/entities/vendor_order_dispatch_prefill.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/customer/customer_active_orders_section.dart';

/// Home entry for the bidding system (InDrive-style).
class BiddingHomePage extends StatelessWidget {
  final bool embedInParent;
  final VendorOrderDispatchPrefill? vendorDispatch;

  const BiddingHomePage({
    super.key,
    this.embedInParent = false,
    this.vendorDispatch,
  });

  @override
  Widget build(BuildContext context) {
    final content = _BiddingHomeBody(vendorDispatch: vendorDispatch);

    if (embedInParent) {
      return content;
    }

    return Scaffold(
      body: Container(
        decoration: AuthTheme.screenBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _BiddingHomeBody extends StatelessWidget {
  final VendorOrderDispatchPrefill? vendorDispatch;

  const _BiddingHomeBody({this.vendorDispatch});

  @override
  Widget build(BuildContext context) {
    final forVendor = vendorDispatch != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (forVendor) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Text(
              'موقع التسليم: ${vendorDispatch!.dropoffAddress}',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
                height: 1.45,
                color: Color(0xFF8D6E00),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          forVendor ? 'اختر نوع وسيلة النقل' : 'مرحباً بك في توصيلة برو',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AuthTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          forVendor
              ? 'اختر مشواراً سريعاً أو نقل بضائع — سيُملأ عنوان العميل تلقائياً'
              : 'كل اللي محتاجه في مكان واحد مع توصيلة',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            color: AuthTheme.textMuted,
          ),
        ),
        const SizedBox(height: 18),
        ServiceTypeCard(
          title: 'مشوار سريع',
          description:
              'لمشوار شخصي أو توصيل خفيف — موتوسيكل أو سكوتر بسهولة.',
          icon: Icons.two_wheeler,
          color: AuthTheme.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DynamicVehicleSelectPage(
                  category: 'quick_trip',
                  pageTitle: 'اختر وسيلة النقل',
                  serviceTitle: 'مشوار سريع',
                  descriptionLabel: 'وصف الطلب',
                  accentColor: AuthTheme.primary,
                  vendorDispatch: vendorDispatch,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        ServiceTypeCard(
          title: 'نقل بضائع',
          description:
              'لطلب تروسيكل أو ربع نقل أو نصف نقل حسب حجم البضاعة.',
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFF0C9F6A),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DynamicVehicleSelectPage(
                  category: 'goods',
                  pageTitle: 'اختر نوع المركبة',
                  serviceTitle: 'نقل بضائع',
                  accentColor: Color(0xFF0C9F6A),
                  descriptionLabel: 'وصف البضاعة',
                  vendorDispatch: vendorDispatch,
                ),
              ),
            );
          },
        ),
        if (!forVendor) ...[
          const SizedBox(height: 22),
          const CustomerActiveOrdersSection(),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyTripsScreen()),
                );
              },
              icon: const Icon(Icons.list_alt_outlined, size: 18),
              label: const Text(
                'عرض كل الطلبات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
