import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/api_response.dart';
import 'package:motorent/models/brand_model.dart';
import 'package:motorent/models/car_model.dart';
import 'package:motorent/models/category_model.dart';
import 'package:dio/dio.dart';
import 'package:motorent/models/driver_model.dart';
import 'package:motorent/models/home_response.dart';
import 'package:motorent/models/location_models.dart';
import 'package:motorent/models/message_model.dart';
import 'package:motorent/models/ride_book_dto.dart';
import 'package:motorent/models/ride_model.dart';
import 'package:motorent/models/vehicle_type_model.dart';

import '../../models/user_model.dart';
import '../local/cache_helper.dart';

class ApiService {
  final Dio _dio = Dio();

  Future<List<Car>> fetchCars(Map<String, dynamic>? filters) async {
    try {
      // Creating query parameters dynamically
      // Map<String, dynamic> queryParams = {};

      // if (search != null) queryParams['search'] = search;
      // if (transmission != null) queryParams['transmission'] = transmission;
      // if (color != null) queryParams['color'] = color;

      final response = await _dio.get(
        getCars,
        queryParameters: filters, // Sending only non-null parameters
      );

      return (response.data as List).map((e) => Car.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching cars: $e");
      return [];
    }
  }

  Future<List<Car>> fetchMyCars() async {
    try {
      final response = await _dio.get(
        myCars,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          },
        ), // Sending only non-null parameters
      );

      return (response.data as List).map((e) => Car.fromJson(e)).toList();
    } catch (e) {
      print("Error fetching cars: $e");
      return [];
    }
  }

  Future<ApiResponse<List<MessageModel>>?> fetchMessages(
    int ride_id,
    int receiverId,
  ) async {
    try {
      final response = await _dio.get(
        '$getChatMessages/$ride_id/$receiverId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          },
        ), // Sending only non-null parameters
      );

      return ApiResponse<List<MessageModel>>.fromJson(
        response.data,
        (data) =>
            List<MessageModel>.from(data.map((x) => MessageModel.fromJson(x))),
      );
    } catch (e) {
      print("Error fetching cars: $e");
      return null;
    }
  }

  Future<ApiResponse<List<Ride>>?> fetchRides() async {
    try {
      final response = await _dio.get(
        getRides,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          },
        ), // Sending only non-null parameters
      );

      ApiResponse<List<Ride>> rr = ApiResponse<List<Ride>>.fromJson(
        response.data,
        (data) => List<Ride>.from(data.map((x) => Ride.fromJson(x))),
      );
      return rr;
      print('zzzzzzzzx : ${rr.message.first.seats}');

      // return ApiResponse<List<Ride>>.fromJson(response.data, (data) => List<Ride>.from(data.map((x) => Ride.fromJson(x))));
    } catch (e) {
      print("Error fetching rides: ${e}");
      return null;
    }
  }

  Future<ApiResponse<List<RideBookDto>>?> fetchBookRequests() async {
    try {
      final response = await _dio.get(
        getBookRequests,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          },
        ), // Sending only non-null parameters
      );

      ApiResponse<List<RideBookDto>> rr =
          ApiResponse<List<RideBookDto>>.fromJson(
            response.data,
            (data) => List<RideBookDto>.from(
              data.map((x) => RideBookDto.fromJson(x)),
            ),
          );
      return rr;
      // print('zzzzzzzzx : ${rr.message.first.seats}');

      // return ApiResponse<List<Ride>>.fromJson(response.data, (data) => List<Ride>.from(data.map((x) => Ride.fromJson(x))));
    } catch (e) {
      print("Error fetching rides: ${e}");
      return null;
    }
  }

  Future<ApiResponse<List<Driver>>?> fetchDrivers() async {
    try {
      final response = await _dio.get(
        getDrivers,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          },
        ), // Sending only non-null parameters
      );

      print('--nmnmnmnmnm--> ${response.data}');
      ApiResponse<List<Driver>> rr = ApiResponse<List<Driver>>.fromJson(
        response.data,
        (data) => List<Driver>.from(data.map((x) => Driver.fromJson(x))),
      );
      return rr;

      // return ApiResponse<List<Ride>>.fromJson(response.data, (data) => List<Ride>.from(data.map((x) => Ride.fromJson(x))));
    } catch (e) {
      print("Error fetching rides: ${e}");
      return null;
    }
  }

  Future<ApiResponse<Ride>?> fetchRide(int rideId) async {
    try {
      final response = await _dio.get(
        'getRides/$rideId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          },
        ), // Sending only non-null parameters
      );

      return ApiResponse<Ride>.fromJson(
        response.data,
        (data) => Ride.fromJson(data),
      );
    } catch (e) {
      print("Error fetching rides: ${e}");
      return null;
    }
  }

  Future<ApiResponse<Driver>> fetchProfile() async {
    final token = CacheHelper.getData(key: 'token');
    final response = await _dio.get(
      getDriver,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (status) => status != null && status < 600,
      ),
    );

    if (response.statusCode == 401) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: 'انتهت الجلسة. سجّل الدخول مرة أخرى.',
      );
    }

    if (response.statusCode != 200 || response.data is! Map) {
      final data = response.data;
      final serverMsg = data is Map ? data['message']?.toString() : null;
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: serverMsg ?? 'تعذر تحميل بيانات الحساب',
      );
    }

    return ApiResponse<Driver>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => Driver.fromJson(data as Map<String, dynamic>),
    );
  }

  /*  Future<HomeResponse?> fetchHome() async {
    try {
      final response = await _dio.get(
        homeApi,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          },
        ),
      );

      // response.data هو الـ JSON اللي أرسلته في السؤال
      return HomeResponse.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print("Error fetching home data: $e");
      return null;
    }
  }*/

  Future<HomeResponse> fetchHome({Map<String, dynamic>? filters}) async {
    final token = CacheHelper.getData(key: 'token');

    final qp = <String, dynamic>{};
    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          qp[key] = value;
        }
      });
    }

    final res = await _dio.get(
      homeApi,
      queryParameters: qp.isEmpty ? null : qp,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (status) => status != null && status < 600,
      ),
    );

    if (res.statusCode == 401) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        message: 'انتهت الجلسة. سجّل الدخول مرة أخرى.',
      );
    }

    if (res.statusCode != 200 || res.data is! Map) {
      final data = res.data;
      final serverMsg = data is Map ? data['message']?.toString() : null;
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        type: DioExceptionType.badResponse,
        message: serverMsg ?? 'خطأ في السيرفر (${res.statusCode})',
      );
    }

    return HomeResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<GovernorateModel>> fetchLocations() async {
    final token = CacheHelper.getData(key: 'token');

    final res = await _dio.get(
      locationsEP,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    return LocationsParser.parse(res.data as Map<String, dynamic>);
  }

  Future<List<GovernorateModel>> fetchGovernorates() async {
    final res = await _dio.get(
      locationsEP,
      queryParameters: {'lang': 'ar'},
      options: Options(
        headers: {'Accept': 'application/json'},
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (status) => status != null && status < 600,
      ),
    );

    if (res.statusCode != 200) {
      throw Exception('locations_api_${res.statusCode}');
    }

    if (res.data is! Map<String, dynamic>) {
      throw Exception('locations_invalid_response');
    }

    return LocationsParser.parse(res.data as Map<String, dynamic>);
  }

  Future<List<VehicleTypeModel>> fetchVehicleTypes({String? category}) async {
    final dio = Dio();
    final res = await dio.get(
      getVehicleTypesEP,
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
      },
      options: Options(
        headers: {'Accept': 'application/json'},
        receiveTimeout: const Duration(seconds: 20),
        validateStatus: (status) => status != null && status < 600,
      ),
    );

    if (res.statusCode == 200) {
      // الاحتمال الأول: لو لارافيل مرجع البيانات جوه Map (فيها status_code و data)
      if (res.data is Map &&
          (res.data['status_code'] == 200 || res.data['status'] == 'success')) {
        final List list = (res.data['data'] as List?) ?? [];
        return list
            .map((e) => VehicleTypeModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }
      // الاحتمال التاني: لو لارافيل مرجع البيانات بشكل مباشر كـ List
      else if (res.data is List) {
        final List list = res.data as List;
        return list
            .map((e) => VehicleTypeModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList();
      }
    }

    throw Exception('Failed to load vehicle types');
  }
}
