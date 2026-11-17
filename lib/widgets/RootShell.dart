import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motorent/data/local/auth_prefs.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/features/admin_dashboard/presentation/pages/admin_shell_screen.dart';
import 'package:motorent/features/driver_interface/presentation/pages/driver_account_screen.dart';
import 'package:motorent/features/driver_interface/presentation/pages/driver_home_screen.dart';
import 'package:motorent/features/driver_interface/presentation/pages/driver_my_trips_screen.dart';
import 'package:motorent/features/services/presentation/pages/customer_hub_page.dart';
import 'package:motorent/features/vendor_interface/presentation/pages/vendor_account_screen.dart';
import 'package:motorent/features/vendor_interface/presentation/pages/vendor_orders_screen.dart';
import 'package:motorent/features/vendor_interface/presentation/pages/vendor_products_screen.dart';
import 'package:motorent/features/vendor_interface/presentation/pages/vendor_reservations_screen.dart';
import 'package:motorent/features/vendor_interface/presentation/pages/vendor_store_screen.dart';
import 'package:motorent/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:motorent/pages/HistoryPage.dart';
import 'package:motorent/pages/NotificationPage.dart';
import 'package:motorent/pages/home_page.dart';
import 'package:motorent/pages/profile_page.dart';
import 'package:motorent/services/notification_store.dart';
import 'package:motorent/services/pending_rating_service.dart';
import 'bottom_nav_bar.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  int _notificationRefreshToken = 0;
  int _profileRefreshToken = 0;
  int _historyRefreshToken = 0;
  int _servicesRefreshToken = 0;
  int _unreadNotifications = 0;
  StreamSubscription<void>? _notificationSub;
  late final bool _isAdmin;
  late final bool _isDriver;
  late final bool _isMerchant;
  late final bool _isMerchantServices;
  late final bool _isMerchantBookings;

  late List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    final title = CacheHelper.getData(key: 'title')?.toString() ?? '';
    final isAdminCache = CacheHelper.getData(key: 'is_admin');
    _isAdmin = title == 'admin' ||
        isAdminCache == true ||
        isAdminCache == 1 ||
        isAdminCache == '1';
    _isDriver = !_isAdmin && title == 'driver';
    // Backend may store merchant or vendor — both use the vendor shell
    _isMerchant = !_isAdmin && (title == 'merchant' || title == 'vendor');
    _isMerchantServices =
        _isMerchant && AuthPrefs.isVendorServicesMode;
    _isMerchantBookings =
        _isMerchant && AuthPrefs.isVendorBookingsMode;
    _buildTabs();
    _loadUnreadCount();
    _notificationSub =
        NotificationStore.instance.changes.listen((_) => _loadUnreadCount());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isAdmin) {
        unawaited(PendingRatingService.promptIfNeeded(context));
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    var count = 0;
    try {
      final remote = await NotificationRemoteDataSourceImpl().getNotifications();
      count = remote.unreadCount;
      // Keep local cache aligned so the notifications tab shows the same items.
      await NotificationStore.instance.syncFromServer(
        remote.notifications,
        notify: false,
      );
    } catch (_) {
      count = await NotificationStore.instance.unreadCount();
    }
    if (!mounted) return;
    setState(() => _unreadNotifications = count);
  }

  void _buildTabs() {
    if (_isAdmin) {
      _tabs = const [AdminShellScreen()];
      return;
    }
    if (_isDriver) {
      _tabs = [
        const _KeepAlive(child: DriverHomeScreen()),
        const _KeepAlive(child: DriverMyTripsScreen()),
        _KeepAlive(
          child: NotificationsPage(refreshToken: _notificationRefreshToken),
        ),
        _KeepAlive(
          key: ValueKey('driver_account_$_profileRefreshToken'),
          child: DriverAccountScreen(
            refreshToken: _profileRefreshToken,
          ),
        ),
      ];
    } else if (_isMerchant) {
      if (_isMerchantServices) {
        _tabs = [
          const _KeepAlive(child: VendorStoreScreen()),
          _KeepAlive(
            child: NotificationsPage(
              refreshToken: _notificationRefreshToken,
              isMerchant: true,
            ),
          ),
          _KeepAlive(
            key: ValueKey('vendor_account_$_profileRefreshToken'),
            child: VendorAccountScreen(
              refreshToken: _profileRefreshToken,
            ),
          ),
        ];
      } else if (_isMerchantBookings) {
        _tabs = [
          const _KeepAlive(child: VendorStoreScreen()),
          const _KeepAlive(child: VendorProductsScreen()),
          // استفسارات الحجز: عرض سعر / غير متوفر / المؤكدة
          const _KeepAlive(child: VendorReservationsScreen()),
          _KeepAlive(
            child: NotificationsPage(
              refreshToken: _notificationRefreshToken,
              isMerchant: true,
            ),
          ),
          _KeepAlive(
            key: ValueKey('vendor_account_$_profileRefreshToken'),
            child: VendorAccountScreen(
              refreshToken: _profileRefreshToken,
            ),
          ),
        ];
      } else {
        _tabs = [
          const _KeepAlive(child: VendorStoreScreen()),
          const _KeepAlive(child: VendorProductsScreen()),
          const _KeepAlive(child: VendorOrdersScreen()),
          _KeepAlive(
            child: NotificationsPage(
              refreshToken: _notificationRefreshToken,
              isMerchant: true,
            ),
          ),
          _KeepAlive(
            key: ValueKey('vendor_account_$_profileRefreshToken'),
            child: VendorAccountScreen(
              refreshToken: _profileRefreshToken,
            ),
          ),
        ];
      }
    } else {
      _tabs = [
        const _KeepAlive(child: HomePage()),
        _KeepAlive(
          child: NotificationsPage(refreshToken: _notificationRefreshToken),
        ),
        const _KeepAlive(child: CustomerHubPage()),
        _KeepAlive(
          child: HistoryPage(refreshToken: _historyRefreshToken),
        ),
        _KeepAlive(
          child: ProfilePage(refreshToken: _profileRefreshToken),
        ),
      ];
    }
  }

  int get _notificationsTabIndex {
    if (_isDriver) return 2;
    if (_isMerchant) {
      if (_isMerchantServices) return 1;
      return 3;
    }
    return 1;
  }

  int get _profileTabIndex {
    if (_isDriver) return 3;
    if (_isMerchant) {
      if (_isMerchantServices) return 2;
      return 4;
    }
    return 4;
  }

  int get _historyTabIndex {
    if (_isDriver || _isMerchant) return -1;
    return 3;
  }

  int get _servicesTabIndex {
    if (_isDriver || _isMerchant) return -1;
    return 2;
  }

  void _onItemTapped(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentIndex = index;
      if (index == _notificationsTabIndex) {
        _notificationRefreshToken++;
        _buildTabs();
      } else if (index == _profileTabIndex) {
        _profileRefreshToken++;
        _buildTabs();
      } else if (index == _historyTabIndex) {
        _historyRefreshToken++;
        _buildTabs();
      } else if (index == _servicesTabIndex) {
        _servicesRefreshToken++;
        _buildTabs();
      }
    });
    _pageController.jumpToPage(index);
    if (index == _notificationsTabIndex) {
      unawaited(_loadUnreadCount());
    }
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin) {
      return const AdminShellScreen();
    }

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: BuildBottomNavBar(
        currIndex: _currentIndex,
        notificationBadgeCount: _unreadNotifications,
        isDriver: _isDriver,
        isMerchant: _isMerchant,
        isMerchantServices: _isMerchantServices,
        isMerchantBookings: _isMerchantBookings,
        onTap: (i) {
          _onItemTapped(i);
        },
        onCenterTap: () {
          if (_isDriver) {
            _onItemTapped(1);
          } else if (_isMerchant &&
              !_isMerchantServices &&
              !_isMerchantBookings) {
            _onItemTapped(1);
          } else if (_isMerchant && _isMerchantBookings) {
            _onItemTapped(1);
          } else {
            _onItemTapped(2);
          }
        },
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _tabs,
      ),
    );
  }
}

class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({super.key, required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
