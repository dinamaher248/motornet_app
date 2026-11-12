import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/local_service_models.dart';

class LocalServiceApi {
  final Dio _dio = Dio();

  Options get _authOptions => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 25),
        validateStatus: (status) => status != null && status < 600,
      );

  Future<List<ServiceCategoryItem>> fetchCategories() async {
    final response = await _dio.get(localServiceCategoriesEP, options: _authOptions);
    if (response.statusCode != 200) {
      throw Exception(_message(response));
    }
    return (response.data['data'] as List)
        .map((e) => ServiceCategoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({String title, List<MerchantListItem> merchants})> fetchMerchants(
    String slug, {
    double? lat,
    double? lng,
  }) async {
    final response = await _dio.get(
      localServiceMerchantsEP(slug),
      queryParameters: {
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
      options: _authOptions,
    );
    if (response.statusCode != 200) {
      throw Exception(_message(response));
    }
    final category = response.data['category'] as Map<String, dynamic>? ?? {};
    final merchants = (response.data['data'] as List)
        .map((e) => MerchantListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return (
      title: category['title_nearby']?.toString() ?? '',
      merchants: merchants,
    );
  }

  Future<MerchantDetail> fetchMerchant(int id) async {
    final response =
        await _dio.get(localServiceMerchantEP(id), options: _authOptions);
    if (response.statusCode != 200) {
      throw Exception(_message(response));
    }
    return MerchantDetail.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ServiceOrderItem> placeOrder({
    required int merchantId,
    required int productId,
    required int quantity,
    required String deliveryAddress,
    String? deliveryDetails,
    double? deliveryLat,
    double? deliveryLng,
    required String paymentMethod,
    String? notes,
    String? paymentProofPath,
    double? productTotal,
  }) async {
    final map = <String, dynamic>{
      'merchant_id': merchantId,
      'store_id': merchantId,
      'product_id': productId,
      'quantity': quantity,
      'delivery_address': deliveryAddress,
      'payment_method': paymentMethod,
      if (productTotal != null) 'product_total': productTotal,
      if (deliveryDetails != null && deliveryDetails.isNotEmpty)
        'delivery_details': deliveryDetails,
      if (deliveryLat != null) 'delivery_lat': deliveryLat,
      if (deliveryLng != null) 'delivery_lng': deliveryLng,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    if (paymentProofPath != null && paymentProofPath.isNotEmpty) {
      map['payment_proof'] = await MultipartFile.fromFile(paymentProofPath);
    }

    final response = await _dio.post(
      localServiceOrdersEP,
      data: FormData.fromMap(map),
      options: _authOptions.copyWith(contentType: 'multipart/form-data'),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_message(response));
    }

    return ServiceOrderItem.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }

  Future<ServiceOrderItem> placeCustomOrder({
    required int merchantId,
    String? customRequestText,
    String? customRequestImagePath,
    required String customerContactPhone,
    required String deliveryAddress,
    String? deliveryDetails,
    double? deliveryLat,
    double? deliveryLng,
    String? notes,
  }) async {
    final map = <String, dynamic>{
      'merchant_id': merchantId,
      'customer_contact_phone': customerContactPhone,
      'delivery_address': deliveryAddress,
      if (customRequestText != null && customRequestText.isNotEmpty)
        'custom_request_text': customRequestText,
      if (deliveryDetails != null && deliveryDetails.isNotEmpty)
        'delivery_details': deliveryDetails,
      if (deliveryLat != null) 'delivery_lat': deliveryLat,
      if (deliveryLng != null) 'delivery_lng': deliveryLng,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    if (customRequestImagePath != null && customRequestImagePath.isNotEmpty) {
      map['custom_request_image'] =
          await MultipartFile.fromFile(customRequestImagePath);
    }

    final response = await _dio.post(
      localServiceCustomOrdersEP,
      data: FormData.fromMap(map),
      options: _authOptions.copyWith(contentType: 'multipart/form-data'),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_message(response));
    }

    return ServiceOrderItem.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }

  Future<ServiceOrderItem> fetchOrder(int orderId) async {
    final response =
        await _dio.get(localServiceOrderEP(orderId), options: _authOptions);
    if (response.statusCode != 200) throw Exception(_message(response));
    return ServiceOrderItem.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ServiceOrderItem> chooseFulfillment({
    required int orderId,
    required String fulfillmentType,
  }) async {
    var response = await _dio.post(
      localServiceOrderFulfillmentEP(orderId),
      data: {'fulfillment_type': fulfillmentType},
      options: _authOptions,
    );
    if (response.statusCode == 404) {
      response = await _dio.post(
        servicesOrderFulfillmentEP(orderId),
        data: {'fulfillment_type': fulfillmentType},
        options: _authOptions,
      );
    }
    if (response.statusCode != 200) throw Exception(_message(response));
    return ServiceOrderItem.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }

  Future<ServiceOrderItem> acceptCustomOffer(int orderId) async {
    final response = await _dio.post(
      localServiceAcceptOfferEP(orderId),
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_message(response));
    return ServiceOrderItem.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ServiceOrderItem> rejectCustomOffer(int orderId) async {
    final response = await _dio.post(
      localServiceRejectOfferEP(orderId),
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_message(response));
    return ServiceOrderItem.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<ServiceOrderItem>> fetchMyOrders() async {
    final response = await _dio.get(localServiceMyOrdersEP, options: _authOptions);
    if (response.statusCode != 200) throw Exception(_message(response));
    return (response.data['data'] as List)
        .map((e) => ServiceOrderItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DriverServiceOrderItem>> fetchDriverOrders() async {
    final response =
        await _dio.get(localServiceDriverOrdersEP, options: _authOptions);
    if (response.statusCode != 200) throw Exception(_message(response));
    return (response.data['data'] as List)
        .map((e) => DriverServiceOrderItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitDeliveryOffer(int orderId, double amount) async {
    final response = await _dio.post(
      localServiceDeliveryOfferEP(orderId),
      data: {'amount': amount},
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_message(response));
  }

  String _message(Response response) {
    final data = response.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    return 'حدث خطأ، حاول مرة أخرى';
  }
}
