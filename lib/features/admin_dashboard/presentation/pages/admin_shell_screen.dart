import 'package:flutter/material.dart';
import 'package:motorent/data/local/auth_prefs.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/features/admin_dashboard/presentation/pages/admin_categories_screen.dart';
import 'package:motorent/features/admin_dashboard/presentation/pages/admin_commissions_screen.dart';
import 'package:motorent/features/admin_dashboard/presentation/pages/admin_documents_screen.dart';
import 'package:motorent/features/admin_dashboard/presentation/pages/admin_moderators_screen.dart';
import 'package:motorent/features/admin_dashboard/presentation/pages/admin_notifications_screen.dart';
import 'package:motorent/features/admin_dashboard/presentation/pages/admin_payment_screen.dart';
import 'package:motorent/features/admin_dashboard/presentation/pages/admin_stats_screen.dart';
import 'package:motorent/features/admin_dashboard/presentation/pages/admin_users_screen.dart';
import 'package:motorent/features/admin_dashboard/presentation/pages/admin_vehicle_types_screen.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';
import 'package:motorent/features/my_account/presentation/pages/profile_screen.dart';
import 'package:motorent/pages/splash_page.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

enum AdminNavItem {
  stats,
  users,
  categories,
  vehicleTypes,
  commissions,
  payments,
  notifications,
  moderators,
  documents,
  account,
}

extension AdminNavItemX on AdminNavItem {
  String get label => switch (this) {
        AdminNavItem.stats => 'الرئيسية / الإحصائيات',
        AdminNavItem.users => 'إدارة المستخدمين',
        AdminNavItem.categories => 'إدارة الأقسام',
        AdminNavItem.vehicleTypes => 'المركبات والنطاق',
        AdminNavItem.commissions => 'العمولة والمستحقات',
        AdminNavItem.payments => 'طرق الدفع',
        AdminNavItem.notifications => 'الإشعارات',
        AdminNavItem.moderators => 'إدارة المشرفين',
        AdminNavItem.documents => 'المستندات المطلوبة',
        AdminNavItem.account => 'حسابي / الإعدادات',
      };

  IconData get icon => switch (this) {
        AdminNavItem.stats => Icons.dashboard_outlined,
        AdminNavItem.users => Icons.people_outline,
        AdminNavItem.categories => Icons.category_outlined,
        AdminNavItem.vehicleTypes => Icons.two_wheeler_outlined,
        AdminNavItem.commissions => Icons.account_balance_wallet_outlined,
        AdminNavItem.payments => Icons.payment_outlined,
        AdminNavItem.notifications => Icons.notifications_outlined,
        AdminNavItem.moderators => Icons.admin_panel_settings_outlined,
        AdminNavItem.documents => Icons.folder_shared_outlined,
        AdminNavItem.account => Icons.manage_accounts_outlined,
      };

  String? get permissionKey => switch (this) {
        AdminNavItem.stats => null,
        AdminNavItem.users => 'users',
        AdminNavItem.categories => 'categories',
        AdminNavItem.vehicleTypes => 'vehicle_types',
        AdminNavItem.commissions => 'settlements',
        AdminNavItem.payments => 'settings',
        AdminNavItem.notifications => 'notifications',
        AdminNavItem.moderators => 'moderators',
        AdminNavItem.documents => 'documents',
        AdminNavItem.account => null,
      };
}

bool _canAdmin(String? key) {
  if (key == null) return true;
  final raw = CacheHelper.getData(key: 'admin_permissions')?.toString() ?? '';
  if (raw.isEmpty || raw == '*' || raw == 'all') return true;
  final have = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
  if (have.contains('*') || have.contains('all')) return true;
  const aliases = {
    'settlements': ['settlements', 'commissions'],
    'settings': ['settings', 'payments'],
    'vehicle_types': ['vehicle_types', 'vehicles'],
  };
  final need = aliases[key] ?? [key];
  return have.any(need.contains);
}

/// Responsive Admin shell: NavigationRail (wide) / Drawer (narrow).
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  AdminNavItem _selected = AdminNavItem.stats;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget get _content => switch (_selected) {
        AdminNavItem.stats => const AdminStatsScreen(),
        AdminNavItem.users => const AdminUsersScreen(),
        AdminNavItem.categories => const AdminCategoriesScreen(),
        AdminNavItem.vehicleTypes => const AdminVehicleTypesScreen(),
        AdminNavItem.commissions => const AdminCommissionsScreen(),
        AdminNavItem.payments => const AdminPaymentScreen(),
        AdminNavItem.notifications => const AdminNotificationsScreen(),
        AdminNavItem.moderators => const AdminModeratorsScreen(),
        AdminNavItem.documents => const AdminDocumentsScreen(),
        AdminNavItem.account => const ProfileScreen(showAppBar: false),
      };

  void _select(AdminNavItem item) {
    setState(() => _selected = item);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'تسجيل الخروج',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'هل تريد تسجيل الخروج من لوحة الإدارة؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await CacheHelper.removeData(key: 'token');
    await CacheHelper.removeData(key: 'id');
    await CacheHelper.removeData(key: 'title');
    await CacheHelper.removeData(key: 'status');
    await AuthPrefs.clearAccountScopedData();
    await CacheHelper.removeData(key: 'is_admin');
    await CacheHelper.removeData(key: 'admin_permissions');
    await CacheHelper.removeData(key: 'is_super_admin');
    await CacheHelper.putBoolean(
      key: AuthPrefs.registrationCompletedKey,
      value: true,
    );
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashPage()),
      (_) => false,
    );
  }

  Widget _navList({required bool dark}) {
    final fg = dark ? Colors.white70 : AuthTheme.textDark;
    final selectedFg = dark ? Colors.white : AuthTheme.primaryDark;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Text(
                  'لوحة الإدارة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: dark ? Colors.white : AuthTheme.textDark,
                  ),
                ),
              ),
              ...AdminNavItem.values.where((item) => _canAdmin(item.permissionKey)).map((item) {
                final selected = item == _selected;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: selected ? selectedFg : fg,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                      color: selected ? selectedFg : fg,
                    ),
                  ),
                  selected: selected,
                  selectedTileColor: dark
                      ? AdminColors.sidebarSelected.withValues(alpha: 0.25)
                      : AuthTheme.primary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onTap: () => _select(item),
                );
              }),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white24),
        ListTile(
          leading: Icon(
            Icons.logout_rounded,
            color: dark ? Colors.red.shade200 : AdminColors.danger,
          ),
          title: Text(
            'تسجيل الخروج',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: dark ? Colors.red.shade200 : AdminColors.danger,
            ),
          ),
          onTap: _logout,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 900;

    if (useRail) {
      return Scaffold(
        backgroundColor: AdminColors.contentBg,
        body: Row(
          children: [
            Container(
              width: 260,
              color: AdminColors.sidebar,
              child: SafeArea(child: _navList(dark: true)),
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(title: _selected.label),
                  Expanded(child: _content),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminColors.contentBg,
      appBar: AppBar(
        title: Text(
          _selected.label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        backgroundColor: AdminColors.sidebar,
        child: SafeArea(child: _navList(dark: true)),
      ),
      body: _content,
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AuthTheme.fieldBorder)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const Spacer(),
          const Text(
            'مشرف النظام',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: AuthTheme.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: AuthTheme.primary.withValues(alpha: 0.15),
            child: const Icon(Icons.person, size: 18, color: AuthTheme.primary),
          ),
        ],
      ),
    );
  }
}
