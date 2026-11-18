import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/services/notification_store.dart';

class AuthPrefs {
  static const String registrationCompletedKey = 'registration_completed';
  static const String vendorHubSectionKey = 'vendor_hub_section';
  static const String vendorBusinessTypeChosenKey = 'vendor_business_type_chosen';

  static bool get hasCompletedRegistration {
    final value = CacheHelper.getData(key: registrationCompletedKey);
    return value == true || value == 'true' || value == 1;
  }

  static String? get vendorHubSection {
    final value = CacheHelper.getData(key: vendorHubSectionKey);
    if (value == null) return null;
    final section = value.toString();
    if (section == 'orders' || section == 'bookings' || section == 'services') {
      return section;
    }
    return null;
  }

  static bool get hasChosenVendorBusinessType {
    final value = CacheHelper.getData(key: vendorBusinessTypeChosenKey);
    return value == true || value == 'true' || value == 1;
  }

  /// صاحب نشاط من نوع «خدمات أخرى» — بدون منتجات ولا طلبات.
  static bool get isVendorServicesMode => vendorHubSection == 'services';

  /// صاحب نشاط «حجوزات» — صور للنشاط بدون صفحة طلبات.
  static bool get isVendorBookingsMode => vendorHubSection == 'bookings';

  /// صاحب نشاط «طلبات» — تظهر له تصنيفات الطلبات وطرق الدفع.
  static bool get isVendorOrdersMode =>
      vendorHubSection == null || vendorHubSection == 'orders';

  static bool get hideVendorOrdersTab =>
      isVendorServicesMode || isVendorBookingsMode;

  static Future<void> markRegistrationCompleted() {
    return CacheHelper.putBoolean(
      key: registrationCompletedKey,
      value: true,
    );
  }

  static Future<void> saveVendorHubSection(String section) async {
    await CacheHelper.saveData(key: vendorHubSectionKey, value: section);
    await CacheHelper.putBoolean(
      key: vendorBusinessTypeChosenKey,
      value: true,
    );
  }

  /// يمسح كل ما يخص الحساب السابق (قسم النشاط + إشعارات الجهاز) كي لا يتسرب لحساب آخر.
  static Future<void> clearAccountScopedData() async {
    await CacheHelper.removeData(key: vendorHubSectionKey);
    await CacheHelper.removeData(key: vendorBusinessTypeChosenKey);
    try {
      await NotificationStore.instance.clearAll();
    } catch (_) {}
  }
}
