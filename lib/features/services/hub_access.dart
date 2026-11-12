/// صلاحية تبويبات الصفحة الرئيسية.
/// الحجوزات مجانية في الفترة الأولى — فعّل الاشتراك لاحقاً من هنا.
class HubAccess {
  static const bool bookingsRequireSubscription = false;

  static bool get canUseBookings => !bookingsRequireSubscription;
}
