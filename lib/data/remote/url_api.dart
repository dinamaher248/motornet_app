/// غيّر إلى `false` بعد رفع مجلد `sonic` على السيرفر (twseela / 46.101.106.163).
const bool useLocalSonicBackend = false;

/// Android Emulator → 10.0.2.2 | جهاز حقيقي على نفس الشبكة → IP الجهاز | Windows → 127.0.0.1
const String _localApiHost = 'http://10.0.2.2:8000';
const String _prodApiHost = 'https://api.tawseelapro.shop';

const String BASE_URL =
    useLocalSonicBackend ? '$_localApiHost/api' : '$_prodApiHost/api';
const String IMG_URL = useLocalSonicBackend
    ? '$_localApiHost/storage/'
    : '$_prodApiHost/storage/';

/// يبني رابط الصورة من مسار التخزين أو رابط كامل.
String resolveStorageImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.trim().isEmpty) {
    return '';
  }

  var path = imagePath.trim();
  if (path.startsWith('http://') || path.startsWith('https://')) {
    path = path.replaceAll('/storage/app/public/', '/storage/');
    return path;
  }

  var normalized = path.startsWith('/') ? path.substring(1) : path;
  if (normalized.startsWith('app/public/')) {
    normalized = normalized.substring('app/public/'.length);
  }
  if (normalized.startsWith('storage/')) {
    normalized = normalized.substring('storage/'.length);
  }

  return '$IMG_URL$normalized';
}

const String accountRento = '$BASE_URL/account';
const String accountRentoPut = '$BASE_URL/profile';
const String updateProfileEP = '$BASE_URL/profile';
const String profileGetEP = '$BASE_URL/profile';
const String profileUpdateEP = '$BASE_URL/profile/update';

const String getCars = '$BASE_URL/cars';
const String postACar = '$BASE_URL/car';
const String getMyCars = '$BASE_URL/cars/mycars';
const String rentalsRento = '$BASE_URL/rentals';
const String myCars = '$BASE_URL/my_cars';

const String getVehicleTypesEP = '$BASE_URL/vehicle-types';

const String registerRento = '$BASE_URL/register';
const String sendOtpEP = '$BASE_URL/send-otp';
const String verifyOtpEP = '$BASE_URL/verify-otp';
const String forgotPasswordEP = '$BASE_URL/forgot-password';
const String resetPasswordEP = '$BASE_URL/reset-password';
const String loginRento = '$BASE_URL/login';
const String getDriver = '$BASE_URL/me';

const String getBookRequests = '$BASE_URL/get_booking_equests';
const String getRides = '$BASE_URL/rides';
const String getDrivers = '$BASE_URL/drivers';
const String setTripFinished = '$BASE_URL/trip_finished';
const String addRide = '$BASE_URL/ride';
const String rideBook = '$BASE_URL/ridebook';

const String withdrawEP = '$BASE_URL/withdraw';

const String getChatMessages = '$BASE_URL/chat';
const String getLastChatMessages = '$BASE_URL/last_chat';
const String sendChatMessage = '$BASE_URL/chat/send';
const String chatNotifyPartnerEP = '$BASE_URL/chat/notify';

const String setFcmToken = '$BASE_URL/set_fcm_token';

const String ratingsEP = '$BASE_URL/ratings';
const String notificationsEP = '$BASE_URL/notifications';
String notificationMarkReadEP(int id) => '$BASE_URL/notifications/$id/mark-read';
const String notificationsMarkAllReadEP = '$BASE_URL/notifications/mark-all-read';

const String locationsEP = '$BASE_URL/locations';

const String homeApi = '$BASE_URL/home';

const String getPlansEP = '$BASE_URL/get_plans';
const String getKoshyAppEP = '$BASE_URL/get_koshy_app';
const String welcomeScreenEP = '$BASE_URL/welcome-screen';

const String tripRequestsEP = '$BASE_URL/trip-requests';
const String tripRequestsMineEP = '$BASE_URL/trip-requests/mine';
const String tripRequestsDriverEP = '$BASE_URL/trip-requests/driver';
String tripRequestEP(int id) => '$BASE_URL/trip-requests/$id';
String tripRequestOffersEP(int id) => '$BASE_URL/trip-requests/$id/offers';
String tripRequestSubmitOfferEP(int id) => '$BASE_URL/trip-requests/$id/offers';
String tripRequestAcceptOfferEP(int tripId, int offerId) =>
    '$BASE_URL/trip-requests/$tripId/offers/$offerId/accept';
String tripRequestCancelEP(int id) => '$BASE_URL/trip-requests/$id/cancel';

const String biddingTripsCreateEP = '$BASE_URL/bidding-trips/create';
const String biddingMyTripsEP = '$BASE_URL/bidding-trips/my-trips';
String biddingTripOffersEP(int id) => '$BASE_URL/bidding-trips/$id/offers';
String biddingOfferAcceptEP(int id) => '$BASE_URL/bidding-offers/$id/accept';
String biddingTripDetailEP(int id) => '$BASE_URL/bidding-trips/$id';
String biddingTripDetailsEP(int id) => '$BASE_URL/bidding-trips/$id/details';
String biddingTripCancelEP(int id) => '$BASE_URL/bidding-trips/$id/cancel';

const String merchantProfileEP = '$BASE_URL/merchant/profile';
const String merchantPaymentMethodsEP = '$BASE_URL/merchant/payment-methods';
const String merchantProductsEP = '$BASE_URL/merchant/products';
String merchantProductEP(int id) => '$BASE_URL/merchant/products/$id';
const String merchantOrdersEP = '$BASE_URL/merchant/orders';
String merchantOrderEP(int id) => '$BASE_URL/merchant/orders/$id';
String merchantOrderAcceptEP(int id) => '$BASE_URL/merchant/orders/$id/accept';
String merchantOrderRejectEP(int id) => '$BASE_URL/merchant/orders/$id/reject';
String merchantOrderConfirmPaymentEP(int id) =>
    '$BASE_URL/merchant/orders/$id/confirm-payment';
String merchantOrderRejectPaymentEP(int id) =>
    '$BASE_URL/merchant/orders/$id/reject-payment';
String merchantOrderSendOfferEP(int id) =>
    '$BASE_URL/merchant/orders/$id/send-offer';
String merchantOrderDriversEP(int id) =>
    '$BASE_URL/merchant/orders/$id/drivers';
String merchantOrderAssignDriverEP(int id) =>
    '$BASE_URL/merchant/orders/$id/assign-driver';
const String merchantDuesEP = '$BASE_URL/merchant/dues';
const String merchantSettlementEP = '$BASE_URL/merchant/settlement-requests';

/// Vendor Interface (أصحاب النشاط) endpoints
const String vendorStoreUpdateEP = '$BASE_URL/vendor/store/update';
const String vendorStoreProfileEP = '$BASE_URL/vendor/store';
const String vendorProductsEP = '$BASE_URL/vendor/products';
String vendorProductToggleEP(int id) => '$BASE_URL/vendor/products/$id/toggle';
String vendorProductEP(int id) => '$BASE_URL/vendor/products/$id';
String vendorProductDeleteEP(int id) => '$BASE_URL/vendor/products/$id/delete';
const String vendorOrdersEP = '$BASE_URL/vendor/orders';
String vendorOrderHandleEP(int id) => '$BASE_URL/vendor/orders/$id/handle';
String vendorOrderDispatchEP(int id) =>
    '$BASE_URL/vendor/orders/$id/dispatch-driver';
String vendorOrderDeliveryOffersEP(int id) =>
    '$BASE_URL/vendor/orders/$id/delivery-offers';
String vendorOrderAcceptDeliveryOfferEP(int id) =>
    '$BASE_URL/vendor/orders/$id/accept-delivery-offer';
const String vendorWalletEP = '$BASE_URL/vendor/wallet';
const String vendorWalletBillingModeEP = '$BASE_URL/vendor/wallet/billing-mode';
const String vendorWalletSettleEP = '$BASE_URL/vendor/wallet/settle';

const String localServiceCategoriesEP = '$BASE_URL/local-services/categories';
String localServiceMerchantsEP(String slug) =>
    '$BASE_URL/local-services/categories/$slug/merchants';
String localServiceMerchantEP(int id) => '$BASE_URL/local-services/merchants/$id';
const String localServiceOrdersEP = '$BASE_URL/local-services/orders';
const String localServiceCustomOrdersEP = '$BASE_URL/local-services/custom-orders';
const String localServiceMyOrdersEP = '$BASE_URL/local-services/orders/mine';
String localServiceOrderEP(int id) => '$BASE_URL/local-services/orders/$id';
String localServiceOrderFulfillmentEP(int id) =>
    '$BASE_URL/local-services/orders/$id/fulfillment';
String servicesOrderFulfillmentEP(int id) =>
    '$BASE_URL/services/orders/$id/fulfillment';
String localServiceAcceptOfferEP(int id) =>
    '$BASE_URL/local-services/orders/$id/accept-offer';
String localServiceRejectOfferEP(int id) =>
    '$BASE_URL/local-services/orders/$id/reject-offer';
const String localServiceDriverOrdersEP = '$BASE_URL/local-services/orders/driver';
String localServiceDeliveryOfferEP(int orderId) =>
    '$BASE_URL/local-services/orders/$orderId/delivery-offers';

const String servicesCategoriesEP = '$BASE_URL/services/categories';
const String servicesStoresEP = '$BASE_URL/services/stores';
const String servicesPlacesEP = '$BASE_URL/services/places';
const String servicesProfessionsEP = '$BASE_URL/services/professions';
const String servicesBookingsEP = '$BASE_URL/services/bookings';
const String servicesBookingsCountEP = '$BASE_URL/services/bookings/count';
String servicesStoreDetailEP(int id) => '$BASE_URL/services/stores/$id';
const String servicesCheckoutEP = '$BASE_URL/services/orders/checkout';
const String servicesCustomOrdersSubmitEP =
    '$BASE_URL/services/custom-orders/submit';
String servicesCustomOrderRespondEP(int id) =>
    '$BASE_URL/services/custom-orders/$id/respond';
String vendorCustomOrderOfferEP(int id) =>
    '$BASE_URL/vendor/custom-orders/$id/offer';

const String driverAvailableOrdersEP = '$BASE_URL/driver/available-orders';
const String driverMyOrdersEP = '$BASE_URL/driver/my-orders';
String driverCompleteOrderEP(String type, int id) =>
    '$BASE_URL/driver/orders/$type/$id/complete';
String driverProgressOrderEP(String type, int id) =>
    '$BASE_URL/driver/orders/$type/$id/progress';

String orderTrackingEP(String type, int id) =>
    '$BASE_URL/order-tracking/$type/$id';
String orderHandToDriverEP(String type, int id) =>
    '$BASE_URL/order-tracking/$type/$id/hand-to-driver';
String orderTrackingCancelEP(String type, int id) =>
    '$BASE_URL/order-tracking/$type/$id/cancel';
const String ratingsPendingEP = '$BASE_URL/ratings/pending';
const String driverDuesEP = '$BASE_URL/driver/dues';
const String driverSettlementEP = '$BASE_URL/driver/settlement-requests';
String driverAcceptServiceInviteEP(int id) =>
    '$BASE_URL/driver/orders/service_order/$id/accept-invite';

/// Driver Interface (Super App) endpoints
const String driverAvailableBidsEP = '$BASE_URL/driver/available-bids';
String driverMakeOfferEP(int id) => '$BASE_URL/driver/trips/$id/make-offer';
String driverDeclineTripEP(int id) => '$BASE_URL/driver/trips/$id/decline';
const String driverMyTripsEP = '$BASE_URL/driver/my-trips';
const String driverWalletEP = '$BASE_URL/driver/wallet';
const String driverWalletSettleEP = '$BASE_URL/driver/wallet/settle';
const String driverWalletBillingModeEP = '$BASE_URL/driver/wallet/billing-mode';

const String subscribeEP = '$BASE_URL/subscribe';
const String checkStatusEP = '$BASE_URL/check_status';
const String toggleOnlineEP = '$BASE_URL/toggle_online';
const String updateDriverLocationEP = '$BASE_URL/driver/location';
const String updateBookingStatusEP = '$BASE_URL/update-booking-status';
const String getAvailableDriversEP = '$BASE_URL/get_available_drivers';

/// Admin Dashboard endpoints
const String adminStatsEP = '$BASE_URL/admin/stats';
const String adminUsersEP = '$BASE_URL/admin/users';
String adminUserToggleEP(int id) => '$BASE_URL/admin/users/$id/toggle';
String adminUserDeleteEP(int id) => '$BASE_URL/admin/users/$id';
String adminUserReviewEP(int id) => '$BASE_URL/admin/users/$id/review';
String adminUserApproveDocumentsEP(int id) =>
    '$BASE_URL/admin/users/$id/approve-documents';
String adminUserProductsEP(int id) => '$BASE_URL/admin/users/$id/products';
const String requiredDocumentsEP = '$BASE_URL/required-documents';
const List<String> requiredDocumentsFallbackEPs = [
  '$BASE_URL/required-documents',
  '$BASE_URL/required_documents',
  '$BASE_URL/registration/documents',
];
const String adminCategoriesEP = '$BASE_URL/admin/categories';
String adminCategoryEP(int id) => '$BASE_URL/admin/categories/$id';
const String adminCategoriesReorderEP = '$BASE_URL/admin/categories/reorder';
String adminCategoryToggleEP(int id) =>
    '$BASE_URL/admin/categories/$id/toggle';
const String adminProductsEP = '$BASE_URL/admin/products';
String adminProductToggleEP(int id) => '$BASE_URL/admin/products/$id/toggle';
String adminProductDeleteEP(int id) => '$BASE_URL/admin/products/$id';
const String adminCommissionSettingsEP = '$BASE_URL/admin/commissions/settings';
const String adminSettlementsEP = '$BASE_URL/admin/settlements';
String adminSettlementHandleEP(int id) =>
    '$BASE_URL/admin/settlements/$id/handle';
const String adminPaymentMethodsEP = '$BASE_URL/admin/payment-methods';
const String adminNotificationsSendEP = '$BASE_URL/admin/notifications/send';
const String adminModeratorsEP = '$BASE_URL/admin/moderators';
String adminModeratorEP(int id) => '$BASE_URL/admin/moderators/$id';
String adminModeratorToggleEP(int id) =>
    '$BASE_URL/admin/moderators/$id/toggle';
const String adminRegistrationDocsEP = '$BASE_URL/admin/registration-docs';
String adminRegistrationDocEP(int id) =>
    '$BASE_URL/admin/registration-docs/$id';
const String adminPlansSettingsEP = '$BASE_URL/admin/plans/settings';
const String adminPlansEP = '$BASE_URL/admin/plans';
String adminPlanEP(int id) => '$BASE_URL/admin/plans/$id';

// Admin — المركبات والأماكن
const String adminVehicleTypesEP = '$BASE_URL/admin/vehicle-types';
String adminVehicleTypeEP(int id) => '$BASE_URL/admin/vehicle-types/$id';
String adminVehicleTypeToggleEP(int id) => '$BASE_URL/admin/vehicle-types/$id/toggle';
const String adminLocationsEP = '$BASE_URL/admin/locations';
String adminLocationEP(int id) => '$BASE_URL/admin/locations/$id';
const String adminSubscriptionsEP = '$BASE_URL/admin/subscriptions';
String adminSubscriptionHandleEP(int id) =>
    '$BASE_URL/admin/subscriptions/$id/handle';
