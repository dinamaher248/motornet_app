

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:motorent/models/brand_model.dart';
import 'package:motorent/models/car_model.dart';
import 'package:motorent/models/category_model.dart';
import 'package:motorent/models/driver_model.dart';
import 'package:motorent/models/home_response.dart';
import 'package:motorent/models/message_model.dart';
import 'package:motorent/models/ride_model.dart';
import 'package:motorent/models/user_model.dart';
import 'package:flutter/cupertino.dart';

import '../data/remote/ApiService.dart';
import '../models/api_response.dart';
import '../models/location_models.dart';
import '../models/ride_book_dto.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Car> cars = [];
  ApiResponse<Driver>? driver;
  ApiResponse<List<Ride>>? rides;
  ApiResponse<Ride>? ride;
  ApiResponse<List<MessageModel>>? messages;
  ApiResponse<List<Driver>>? drivers;
  ApiResponse<List<RideBookDto>>? rideBookDto;

  int egpAmountp = 0;

  // late User userdata;
  List<Car> myCars = [];


  HomeResponse? homeData;

  // ---- locations state ----
  bool isLoadingLocations = false;
  String locationsError = '';
  List<GovernorateModel> governorates = [];
  GovernorateModel? selectedGov;
  AreaModel? selectedCity;

  // اختيار الرول لو حابب تستخدمه من هنا
  String get role =>
      homeData?.role ?? homeData?.profile?.title ?? 'user';

  bool isLoading = true;
  String errorMessage = '';

  String _formatLoadError(Object e) {
    if (e is DioException) {
      if (e.error is SocketException ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'تعذر الاتصال بالسيرفر. تحقق من الإنترنت';
      }
      final status = e.response?.statusCode;
      if (status == 401) {
        return 'انتهت الجلسة. سجّل الدخول مرة أخرى.';
      }
      if (status != null && status >= 500) {
        return 'خطأ في السيرفر. تأكد من إعداد قاعدة البيانات ثم حاول مرة أخرى';
      }
      if (e.message != null && e.message!.isNotEmpty) {
        return e.message!;
      }
    }
    return 'تعذر تحميل البيانات. حاول مرة أخرى';
  }

  /*Future<void> loadHomeData({Map<String, dynamic>? filters}) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      // call /home مرة واحدة
      homeData = await _apiService.fetchHome();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = _formatLoadError(e);
      notifyListeners();
    }
  }*/


  /// تحديث صامت بدون شيمر الصفحة الكاملة (للطلبات الجارية على الرئيسية).
  Future<void> refreshHomeSilent({Map<String, dynamic>? extraFilters}) async {
    try {
      final filters = <String, dynamic>{};
      if (selectedGov != null) {
        filters['governorate'] = selectedGov!.name;
      }
      if (selectedCity != null) {
        filters['area'] = selectedCity!.name;
      }
      if (extraFilters != null) {
        filters.addAll(extraFilters);
      }
      homeData = await _apiService.fetchHome(
        filters: filters.isEmpty ? null : filters,
      );
      notifyListeners();
    } catch (_) {
      // تجاهل أخطاء التحديث الصامت
    }
  }

  // تحميل الـ home + (تحميل المحافظات أول مرة)
  Future<void> loadHomeData({Map<String, dynamic>? extraFilters}) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      // لو لسه مجبناش المحافظات – هنجِبها الأول
      if (governorates.isEmpty) {
        await loadLocations();
      }

      final bool isFirstLoad = (homeData == null);

      // نبني الفلاتر من الـ selectedGov/selectedCity
      final filters = <String, dynamic>{};

      if (selectedGov != null) {
        filters['governorate'] = selectedGov!.name; // زي اللي راجع من /locations
      }

      if (selectedCity != null) {
        filters['area'] = selectedCity!.name;
      }

      // لو عايز تضيف فلاتر إضافية من بره
      if (extraFilters != null) {
        filters.addAll(extraFilters);
      }

      homeData = await _apiService.fetchHome(
        filters: filters.isEmpty ? null : filters,
      );

      // أول مرة فقط: حاول اضبط الاختيار على بيانات البروفايل
      if (isFirstLoad && homeData?.profile != null) {
        final profGov = homeData!.profile!.governorate;
        final profArea = homeData!.profile!.area;

        if (profGov != null && selectedGov == null) {
          try {
            selectedGov = governorates.firstWhere(
                  (g) => g.name == profGov,
            );
          } catch (_) {}
        }

        if (profArea != null &&
            selectedGov != null &&
            selectedCity == null) {
          try {
            selectedCity = selectedGov!.areas.firstWhere(
                  (a) => a.name == profArea,
            );
          } catch (_) {}
        }
      }

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = _formatLoadError(e);
      print('loadHomeData error: $e');
      notifyListeners();
    }
  }

  String _normalizeLocationQuery(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .toLowerCase();
  }

  Future<List<LocationMatch>> searchLocations(String query) async {
    if (governorates.isEmpty) {
      await loadLocations();
    }

    final normalizedQuery = _normalizeLocationQuery(query);
    if (normalizedQuery.isEmpty) {
      return [];
    }

    final results = <LocationMatch>[];

    for (final governorate in governorates) {
      final govName = _normalizeLocationQuery(governorate.name);
      if (govName.contains(normalizedQuery)) {
        results.add(
          LocationMatch(
            governorate: governorate,
            displayName: governorate.name,
          ),
        );
      }

      for (final area in governorate.areas) {
        final areaName = _normalizeLocationQuery(area.name);
        if (areaName.contains(normalizedQuery)) {
          results.add(
            LocationMatch(
              governorate: governorate,
              area: area,
              displayName: '${area.name} - ${governorate.name}',
            ),
          );
        }
      }
    }

    return results;
  }

  void applyLocationMatch(LocationMatch match) {
    selectedGov = match.governorate;
    selectedCity = match.area;
    loadHomeData();
  }

  // تحميل المحافظات والـ areas من /locations
  Future<void> loadLocations() async {
    try {
      isLoadingLocations = true;
      locationsError = '';
      notifyListeners();

      governorates = await _apiService.fetchLocations();

      isLoadingLocations = false;
      notifyListeners();
    } catch (e) {
      isLoadingLocations = false;
      locationsError = 'فشل تحميل المحافظات والمدن';
      notifyListeners();
    }
  }

  // تغيير المحافظة
  void setGovernorate(GovernorateModel? gov) {
    selectedGov = gov;
    selectedCity = null; // نرجّع المدينة فاضية
    // نعيد تحميل /home مع الفلتر الجديد
    loadHomeData();
  }

  // تغيير المدينة
  void setCity(AreaModel? city) {
    selectedCity = city;
    loadHomeData();
  }

  // مسح الفلاتر
  void clearFilters() {
    selectedGov = null;
    selectedCity = null;
    loadHomeData();
  }


  Future<void> loadHomeDataX({Map<String, dynamic>? filters}) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      driver = await _apiService.fetchProfile();
      rides = await _apiService.fetchRides();
      drivers = await _apiService.fetchDrivers();
      rideBookDto = await _apiService.fetchBookRequests();
      print('--nmnmnPPPPPPmnmnm--> ${rideBookDto?.message.length}');
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = _formatLoadError(e);
      notifyListeners();
    }
  }

  Future<void> loadMyCars() async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      myCars = await _apiService.fetchMyCars();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = _formatLoadError(e);
      notifyListeners();
    }
  }


  Future<void> loadProfileData({bool silent = false}) async {
    try {
      if (!silent) {
        isLoading = true;
        errorMessage = '';
        notifyListeners();
      }

      driver = await _apiService.fetchProfile();

      if (!silent) {
        isLoading = false;
      }
      notifyListeners();
    } catch (e) {
      if (!silent) {
        isLoading = false;
        errorMessage = _formatLoadError(e);
      }
      print('loadProfileData error: $e');
      notifyListeners();
    }
  }

  /// تحميل بيانات البروفايل (مثل الصورة) بدون إظهار شاشة التحميل.
  Future<void> ensureProfileLoaded() async {
    if (driver != null) return;
    try {
      driver = await _apiService.fetchProfile();
      notifyListeners();
    } catch (e) {
      print('ensureProfileLoaded error: $e');
    }
  }

  Future<void> loadBookMidDataData(int rideId) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      driver = await _apiService.fetchProfile();
      ride = await _apiService.fetchRide(rideId);


      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = _formatLoadError(e);
      notifyListeners();
    }
  }



  Future<void> loadPostCarInitData() async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = _formatLoadError(e);
      notifyListeners();
    }
  }
  Future<void> loadPostRideInitData() async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      myCars = await _apiService.fetchMyCars();

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = _formatLoadError(e);
      notifyListeners();
    }
  }

  Future<void> loadMessagesInitData(int ride_id, int receiverId) async {
    try {
      isLoading = true;
      errorMessage = '';
      notifyListeners();

      messages = await _apiService.fetchMessages(ride_id, receiverId);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = _formatLoadError(e);
      notifyListeners();
    }
  }
}