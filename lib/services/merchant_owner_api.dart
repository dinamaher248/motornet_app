import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/driver_models.dart';
import 'package:motorent/models/merchant_owner_models.dart';

class MerchantOwnerApi {
  final Dio _dio = Dio();

  Options get _authOptions => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 600,
      );

  Future<MerchantProfilePayload> fetchProfile() async {
    final response = await _dio.get(merchantProfileEP, options: _authOptions);
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantProfilePayload.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<MerchantBusinessProfile> saveProfile({
    required int categoryId,
    required String name,
    required String address,
    required String phone,
    required double lat,
    required double lng,
    required List<WorkingDayHours> workingHours,
    String? imagePath,
  }) async {
    final formData = FormData.fromMap({
      'category_id': categoryId,
      'name': name,
      'address': address,
      'phone': phone,
      'lat': lat,
      'lng': lng,
      'working_hours': jsonEncode(workingHours.map((e) => e.toJson()).toList()),
      if (imagePath != null)
        'image': await MultipartFile.fromFile(imagePath),
    });

    final response = await _dio.post(
      merchantProfileEP,
      data: formData,
      options: _authOptions.copyWith(contentType: 'multipart/form-data'),
    );

    if (response.statusCode != 200) throw Exception(_msg(response));

    return MerchantBusinessProfile.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<MerchantPaymentSettings> fetchPaymentMethods() async {
    final response =
        await _dio.get(merchantPaymentMethodsEP, options: _authOptions);
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantPaymentSettings.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<MerchantPaymentSettings> savePaymentMethods({
    required bool payOnDelivery,
    required bool payWallet,
    String? walletNumber,
    String? walletOwnerName,
    String? walletType,
  }) async {
    final response = await _dio.post(
      merchantPaymentMethodsEP,
      data: {
        'pay_on_delivery': payOnDelivery ? 1 : 0,
        'pay_wallet': payWallet ? 1 : 0,
        if (walletNumber != null) 'wallet_number': walletNumber,
        if (walletOwnerName != null) 'wallet_owner_name': walletOwnerName,
        if (walletType != null && walletType.isNotEmpty) 'wallet_type': walletType,
      },
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantPaymentSettings.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<MerchantProductsPayload> fetchProducts() async {
    final response = await _dio.get(merchantProductsEP, options: _authOptions);
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantProductsPayload.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<MerchantProductItem> createProduct({
    required String name,
    required double price,
    required String imagePath,
    String? description,
    required bool isActive,
  }) async {
    final response = await _dio.post(
      merchantProductsEP,
      data: FormData.fromMap({
        'name': name,
        'price': price,
        if (description != null && description.isNotEmpty)
          'description': description,
        'is_active': isActive ? 1 : 0,
        'image': await MultipartFile.fromFile(imagePath),
      }),
      options: _authOptions.copyWith(contentType: 'multipart/form-data'),
    );
    if (response.statusCode != 201) throw Exception(_msg(response));
    return MerchantProductItem.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<MerchantProductItem> updateProduct({
    required int productId,
    required String name,
    required double price,
    String? description,
    required bool isActive,
    String? imagePath,
  }) async {
    final response = await _dio.post(
      merchantProductEP(productId),
      data: FormData.fromMap({
        'name': name,
        'price': price,
        if (description != null) 'description': description,
        'is_active': isActive ? 1 : 0,
        if (imagePath != null)
          'image': await MultipartFile.fromFile(imagePath),
      }),
      options: _authOptions.copyWith(contentType: 'multipart/form-data'),
    );
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantProductItem.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteProduct(int productId) async {
    final response = await _dio.delete(
      merchantProductEP(productId),
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_msg(response));
  }

  Future<MerchantOrdersPayload> fetchOrders() async {
    final response = await _dio.get(merchantOrdersEP, options: _authOptions);
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantOrdersPayload.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<MerchantServiceOrder> fetchOrder(int orderId) async {
    final response =
        await _dio.get(merchantOrderEP(orderId), options: _authOptions);
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantServiceOrder.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<MerchantServiceOrder> acceptOrder(int orderId) async {
    final response = await _dio.post(
      merchantOrderAcceptEP(orderId),
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantServiceOrder.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<MerchantServiceOrder> rejectOrder(int orderId) async {
    final response = await _dio.post(
      merchantOrderRejectEP(orderId),
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantServiceOrder.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<MerchantServiceOrder> confirmPayment(int orderId) async {
    final response = await _dio.post(
      merchantOrderConfirmPaymentEP(orderId),
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantServiceOrder.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<MerchantServiceOrder> rejectPayment(int orderId) async {
    final response = await _dio.post(
      merchantOrderRejectPaymentEP(orderId),
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantServiceOrder.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<MerchantServiceOrder> sendCustomOffer({
    required int orderId,
    double? merchantOfferPrice,
    String? merchantOfferNotes,
  }) async {
    final response = await _dio.post(
      merchantOrderSendOfferEP(orderId),
      data: {
        if (merchantOfferPrice != null) 'merchant_offer_price': merchantOfferPrice,
        if (merchantOfferNotes != null && merchantOfferNotes.isNotEmpty)
          'merchant_offer_notes': merchantOfferNotes,
      },
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantServiceOrder.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<MerchantAvailableDriver>> fetchAvailableDrivers(int orderId) async {
    final response =
        await _dio.get(merchantOrderDriversEP(orderId), options: _authOptions);
    if (response.statusCode != 200) throw Exception(_msg(response));
    return (response.data['data'] as List)
        .map((e) => MerchantAvailableDriver.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MerchantServiceOrder> assignDriver({
    required int orderId,
    required int driverId,
  }) async {
    final response = await _dio.post(
      merchantOrderAssignDriverEP(orderId),
      data: {'driver_id': driverId},
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_msg(response));
    return MerchantServiceOrder.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<DriverDuesSummary> fetchDuesSummary() async {
    final response = await _dio.get(merchantDuesEP, options: _authOptions);
    if (response.statusCode != 200) throw Exception(_msg(response));
    return DriverDuesSummary.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> submitSettlement(String proofPath) async {
    final response = await _dio.post(
      merchantSettlementEP,
      data: FormData.fromMap({
        'payment_proof': await MultipartFile.fromFile(proofPath),
      }),
      options: _authOptions.copyWith(contentType: 'multipart/form-data'),
    );
    if (response.statusCode != 201) throw Exception(_msg(response));
  }

  String _msg(Response response) {
    final data = response.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    return 'حدث خطأ';
  }
}
