/// Shared vehicle type helpers for the bidding system.
class BiddingVehicleTypes {
  static const motorcycle = 'motorcycle';
  static const scooter = 'scooter';
  static const tricycle = 'tricycle';
  static const quarterTruck = 'quarter_truck';
  static const halfTruck = 'half_truck';

  static const quickTripCategory = 'quick_trip';
  static const goodsCategory = 'goods';

  static String labelOf(String key) {
    switch (key) {
      case motorcycle:
        return 'موتوسيكل';
      case scooter:
        return 'سكوتر';
      case tricycle:
        return 'تروسيكل';
      case quarterTruck:
        return 'ربع نقل';
      case halfTruck:
        return 'نصف نقل';
      default:
        return key;
    }
  }
}
