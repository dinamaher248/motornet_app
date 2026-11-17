import 'dart:ui';

import 'package:motorent/pages/home_page.dart';
import 'package:motorent/pages/orders_tab_page.dart';
import 'package:motorent/widgets/bottom_nav_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unicons/unicons.dart';

import '../pages/profile_page.dart';
import 'hexbutton.dart';

class BuildBottomNavBar extends StatelessWidget {
  final int currIndex;
  final int notificationBadgeCount;
  final bool isDriver;
  final bool isMerchant;
  final bool isMerchantServices;
  final bool isMerchantBookings;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  const BuildBottomNavBar({
    super.key,
    required this.currIndex,
    this.notificationBadgeCount = 0,
    this.isDriver = false,
    this.isMerchant = false,
    this.isMerchantServices = false,
    this.isMerchantBookings = false,
    required this.onTap,
    required this.onCenterTap,
  });

  // ترجمة بسيطة حسب اتجاه الواجهة
  String _t(BuildContext ctx, String en, String ar) {
    return Directionality.of(ctx) == TextDirection.rtl ? ar : ar;
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String title,
    required BuildContext context,
    int badgeCount = 0,
  }) {
    final theme = Theme.of(context);
    final selected = currIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              child: AnimatedScale(
                scale: selected ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: selected ? 24 : 22,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        top: -4,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 0.1,
              ),
              child: Text(title, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final showServicesCenter = !isDriver && !isMerchant;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: showServicesCenter ? 118 : 88,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // خلفية البار (زجاجي خفيف مع تينت أخضر)
            Positioned(
              left: 16,
              right: 16,
              bottom: 10,
              height: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                          const Color(0xFF053711).withOpacity(0.90),
                          const Color(0xFF084016).withOpacity(0.96),
                        ]
                            : [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.98),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFF106C4A).withOpacity(0.12), // أخضر
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF106C4A)
                              .withOpacity(isDark ? 0.18 : 0.10),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _navItem(
                            index: 0,
                            icon: isDriver
                                ? Icons.home_rounded
                                : isMerchant
                                    ? Icons.storefront
                                    : Icons.home_rounded,
                            title: _t(
                              context,
                              'Home',
                              isDriver
                                  ? 'الرئيسية'
                                  : isMerchant
                                      ? 'بيانات النشاط'
                                      : 'الرئيسية',
                            ),
                            context: context,
                          ),
                        ),
                        if (isDriver)
                          Expanded(
                            child: _navItem(
                              index: 1,
                              icon: Icons.receipt_long,
                              title: _t(context, 'My Trips', 'طلباتي'),
                              context: context,
                            ),
                          )
                        else if (isMerchant && !isMerchantServices)
                          Expanded(
                            child: _navItem(
                              index: 1,
                              icon: Icons.photo_library_outlined,
                              // «المنتجات» فقط لقسم الطلبات، والحجوزات تبقى «صور النشاط»
                              title: _t(
                                context,
                                'Photos',
                                isMerchantBookings
                                    ? 'صور النشاط'
                                    : 'المنتجات',
                              ),
                              context: context,
                            ),
                          )
                        else if (isMerchant && isMerchantServices)
                          Expanded(
                            child: _navItem(
                              index: 1,
                              icon: Icons.notifications_active,
                              title: _t(context, 'Notifications', 'الإشعارات'),
                              context: context,
                              badgeCount: notificationBadgeCount,
                            ),
                          )
                        else
                          Expanded(
                            child: _navItem(
                              index: 1,
                              icon: Icons.notifications_active,
                              title: _t(context, 'Notifications', 'الإشعارات'),
                              context: context,
                              badgeCount: notificationBadgeCount,
                            ),
                          ),
                        if (!isDriver && !isMerchant) const SizedBox(width: 80),
                        if (isDriver)
                          Expanded(
                            child: _navItem(
                              index: 2,
                              icon: Icons.notifications_active,
                              title: _t(context, 'Notifications', 'الإشعارات'),
                              context: context,
                              badgeCount: notificationBadgeCount,
                            ),
                          )
                        else if (isMerchant && !isMerchantServices && !isMerchantBookings)
                          Expanded(
                            child: _navItem(
                              index: 2,
                              icon: Icons.receipt_long,
                              title: _t(context, 'Orders', 'الطلبات'),
                              context: context,
                            ),
                          )
                        else if (isMerchant && isMerchantBookings)
                          Expanded(
                            child: _navItem(
                              index: 2,
                              icon: Icons.event_note_outlined,
                              title: _t(context, 'Reservations', 'الحجوزات'),
                              context: context,
                            ),
                          )
                        else if (!isMerchant)
                          Expanded(
                            child: _navItem(
                              index: 3,
                              icon: Icons.history,
                              title: _t(context, 'History', 'التاريخ'),
                              context: context,
                            ),
                          ),
                        if (isMerchant && !isMerchantServices)
                          Expanded(
                            child: _navItem(
                              index: 3,
                              icon: Icons.notifications_active,
                              title: _t(context, 'Notifications', 'الإشعارات'),
                              context: context,
                              badgeCount: notificationBadgeCount,
                            ),
                          ),
                        Expanded(
                          child: _navItem(
                            index: isDriver
                                ? 3
                                : isMerchant
                                    ? (isMerchantServices ? 2 : 4)
                                    : 4,
                            icon: Icons.person_rounded,
                            title: _t(context, 'Profile', 'حسابي'),
                            context: context,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // زر وسطي للعميل فقط (خدمات) — مرتفع فوق الشريط مع تسمية واضحة
            if (showServicesCenter)
              Positioned(
                bottom: 22,
                child: GestureDetector(
                  onTap: onCenterTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HexagonButton(
                        size: const Size(62, 62),
                        lift: 0,
                        onTap: onCenterTap,
                        child: const Icon(
                          Icons.grid_view_rounded,
                          size: 26,
                          color: Colors.white,
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFCD6B0A),
                            Color(0xFFE3B98B),
                          ],
                        ),
                        highlightGradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x66FFFFFF),
                            Color(0x00FFFFFF),
                          ],
                        ),
                        borderColor: Colors.white.withOpacity(0.22),
                        borderWidth: 1.4,
                        shadowBlur: 16,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t(context, 'Services', 'الخدمات'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Cairo',
                          height: 1.1,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F3D2E),
                          shadows: [
                            Shadow(
                              color: (isDark ? Colors.black : Colors.white)
                                  .withOpacity(0.85),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}





Widget buildBottomNavBar(int currIndex, Size size, ThemeData themeData) {
  return BottomNavigationBar(
    iconSize: size.width * 0.07,
    elevation: 0,
    selectedLabelStyle: const TextStyle(fontSize: 0),
    unselectedLabelStyle: const TextStyle(fontSize: 0),
    currentIndex: currIndex,
    backgroundColor: const Color(0x00ffffff),
    type: BottomNavigationBarType.fixed,
    selectedItemColor: themeData.brightness == Brightness.dark
        ? Color(0xffcc8212)
        : Color(0xffe6910a),
    unselectedItemColor: const Color(0xff191919),
    onTap: (value) {
      if (value != currIndex) {
        if (value == 0) {
          Get.off(const HomePage());
        }else if(value == 1){
          Get.off( OrdersPage());
        }else if(value == 2){
          Get.off(const ProfilePage());
        }
      }
    },
    items: [
      buildBottomNavItem(
        UniconsLine.car,
        themeData,
        size,
      ),
      buildBottomNavItem(
        Icons.access_time_outlined,
        themeData,
        size,
      ),
      buildBottomNavItem(
        UniconsLine.user,
        themeData,
        size,
      ),
    ],
  );
}
