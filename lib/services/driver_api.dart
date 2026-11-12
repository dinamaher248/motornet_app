import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/driver_models.dart';

class DriverApi {
  final Dio _dio = Dio();

  Options get _authOptions => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 600,
      );

  Future<List<DriverOrderItem>> fetchAvailableOrders() async {
    final response =
        await _dio.get(driverAvailableOrdersEP, options: _authOptions);
    if (response.statusCode != 200) throw Exception(_msg(response));
    return (response.data['data'] as List)
        .map((e) => DriverOrderItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DriverCompletedOrder>> fetchMyCompletedOrders() async {
    final response = await _dio.get(driverMyOrdersEP, options: _authOptions);
    if (response.statusCode != 200) throw Exception(_msg(response));
    return (response.data['data'] as List)
        .map((e) => DriverCompletedOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> completeOrder(String type, int id) async {
    final url = driverCompleteOrderEP(type, id);
    var response = await _dio.post(
      url,
      data: const {'action': 'complete'},
      options: _authOptions,
    );
    if (response.statusCode == 405) {
      response = await _dio.get(url, options: _authOptions);
    }
    if (response.statusCode != 200) throw Exception(_msg(response));
  }

  Future<DriverDuesSummary> fetchDuesSummary() async {
    final response = await _dio.get(driverDuesEP, options: _authOptions);
    if (response.statusCode != 200) throw Exception(_msg(response));
    return DriverDuesSummary.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> submitSettlement(String proofPath) async {
    final response = await _dio.post(
      driverSettlementEP,
      data: FormData.fromMap({
        'payment_proof': await MultipartFile.fromFile(proofPath),
      }),
      options: _authOptions.copyWith(contentType: 'multipart/form-data'),
    );
    if (response.statusCode != 201) throw Exception(_msg(response));
  }

  Future<void> acceptServiceInvitation(int orderId) async {
    final response = await _dio.post(
      driverAcceptServiceInviteEP(orderId),
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_msg(response));
  }

  Future<void> setOnlineStatus(bool online) async {
    final response = await _dio.post(
      toggleOnlineEP,
      data: {'is_online': online ? 1 : 0},
      options: _authOptions,
    );
    if (response.statusCode != 200) throw Exception(_msg(response));
  }

  String _msg(Response response) {
    final data = response.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    return 'حدث خطأ';
  }
}
