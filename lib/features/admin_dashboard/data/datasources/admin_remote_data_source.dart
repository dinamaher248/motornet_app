import 'package:dio/dio.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/admin_dashboard/core/error/exceptions.dart';
import 'package:motorent/features/admin_dashboard/data/models/admin_models.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';

abstract class AdminRemoteDataSource {
  Future<AdminStats> fetchStats();
  Future<List<AdminUser>> fetchUsers({
    AdminUserRole? role,
    AdminDriverSegment? driverSegment,
    String? search,
  });
  Future<AdminUser> toggleUser(int userId);
  Future<void> deleteUser(int userId);
  Future<AdminUser> reviewUser(int userId);
  Future<AdminUser> approveUserDocuments(int userId);

  Future<List<AdminCategory>> fetchCategories();
  Future<AdminCategory> createCategory({
    required String name,
    String? slug,
    String hubSection = 'orders',
  });
  Future<AdminCategory> updateCategory(AdminCategory category);
  Future<void> deleteCategory(int id);
  Future<AdminCategory> toggleCategory(int id);
  Future<void> reorderCategories(List<int> orderedIds);

  Future<List<AdminProduct>> fetchProducts({int? vendorId});
  Future<AdminProduct> toggleProduct(int id);
  Future<void> deleteProduct(int id);

  Future<AdminCommissionSettings> fetchCommissionSettings();
  Future<AdminCommissionSettings> saveCommissionSettings(
    AdminCommissionSettings settings,
  );
  Future<List<AdminSettlementRequest>> fetchSettlements();
  Future<AdminSettlementRequest> handleSettlement({
    required int id,
    required String action,
  });

  Future<AdminPaymentSettings> fetchPaymentSettings();
  Future<AdminPaymentSettings> savePaymentSettings(
    AdminPaymentSettings settings,
  );

  Future<void> sendNotification(SendAdminNotificationParams params);

  Future<List<AdminModerator>> fetchModerators();
  Future<AdminModerator> createModerator({
    required String name,
    required String phone,
    String email,
    String password,
    List<String> permissions,
  });
  Future<AdminModerator> updateModerator(AdminModerator moderator);
  Future<AdminModerator> toggleModerator(int id);
  Future<void> deleteModerator(int id);

  Future<List<AdminRegistrationDoc>> fetchRegistrationDocs();
  Future<AdminRegistrationDoc> createRegistrationDoc({
    required String name,
    required AdminDocAudience audience,
    List<String> vehicleTypeKeys = const [],
  });
  Future<void> deleteRegistrationDoc(int id);

  Future<AdminPlansSettings> fetchPlansSettings();
  Future<AdminPlansSettings> savePlansSettings(AdminPlansSettings settings);
  Future<List<AdminPlan>> fetchPlans();
  Future<AdminPlan> createPlan(AdminPlan plan);
  Future<AdminPlan> updatePlan(AdminPlan plan);
  Future<void> deletePlan(int id);

  Future<List<AdminVehicleType>> fetchVehicleTypes();
  Future<AdminVehicleType> updateVehicleType(AdminVehicleType type);
  Future<AdminVehicleType> toggleVehicleType(int id);
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final Dio dio;

  AdminRemoteDataSourceImpl({Dio? dio}) : dio = dio ?? Dio();

  Options get _auth => Options(
        headers: {
          'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (s) => s != null && s < 600,
      );

  // ── helpers ──────────────────────────────────────────────────────────────

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map) {
      final m = Map<String, dynamic>.from(data);
      final nested = m['data'] ?? m['settings'] ?? m['stats'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return m;
    }
    throw const ServerException('استجابة غير متوقعة من السيرفر');
  }

  List<dynamic> _list(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final nested = data['data'] ??
          data['users'] ??
          data['items'] ??
          data['categories'] ??
          data['products'] ??
          data['settlements'] ??
          data['moderators'] ??
          data['documents'] ??
          data['plans'] ??
          data['vehicle_types'];
      if (nested is List) return nested;
    }
    return const [];
  }

  String _msg(dynamic data, String fallback) {
    if (data is Map) {
      final m = data['message'];
      if (m is String && m.trim().isNotEmpty) return m;
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
        return first.toString();
      }
    }
    return fallback;
  }

  Exception _mapDio(DioException e, String fallback) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    if (e.response != null) {
      return ServerException(
        _msg(e.response?.data, fallback),
        statusCode: e.response?.statusCode,
      );
    }
    return NetworkException(e.message ?? fallback);
  }

  Future<Response> _get(String url, {Map<String, dynamic>? query}) =>
      dio.get(url, queryParameters: query, options: _auth);

  Future<Response> _post(String url, {Object? data}) =>
      dio.post(url, data: data, options: _auth);

  Future<Response> _put(String url, {Object? data}) =>
      dio.put(url, data: data, options: _auth);

  Future<Response> _delete(String url) => dio.delete(url, options: _auth);

  // ── Stats ────────────────────────────────────────────────────────────────

  @override
  Future<AdminStats> fetchStats() async {
    try {
      final res = await _get(adminStatsEP);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل الإحصائيات'),
            statusCode: res.statusCode);
      }
      return AdminStatsModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل الإحصائيات');
    }
  }

  // ── Users ────────────────────────────────────────────────────────────────

  @override
  Future<List<AdminUser>> fetchUsers({
    AdminUserRole? role,
    AdminDriverSegment? driverSegment,
    String? search,
  }) async {
    try {
      // Backend filters by title: user / driver / merchant
      final roleParam = switch (role) {
        AdminUserRole.client => 'user',
        AdminUserRole.driver => 'driver',
        AdminUserRole.vendor => 'merchant',
        null => 'user',
      };
      final query = <String, dynamic>{
        'role': roleParam,
        'type': roleParam,
        'title': roleParam,
      };
      if (role == AdminUserRole.driver) {
        query['segment'] = driverSegment == AdminDriverSegment.newUsers
            ? 'new'
            : 'current';
      }
      final trimmedSearch = search?.trim();
      if (trimmedSearch != null && trimmedSearch.isNotEmpty) {
        query['search'] = trimmedSearch;
      }
      final res = await _get(
        adminUsersEP,
        query: query,
      );
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل المستخدمين'),
            statusCode: res.statusCode);
      }
      return _list(res.data)
          .whereType<Map>()
          .map((e) => AdminUserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل المستخدمين');
    }
  }

  @override
  Future<AdminUser> toggleUser(int userId) async {
    try {
      final res = await _post(adminUserToggleEP(userId));
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحديث حالة المستخدم'),
            statusCode: res.statusCode);
      }
      return AdminUserModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحديث حالة المستخدم');
    }
  }

  @override
  Future<void> deleteUser(int userId) async {
    try {
      final res = await dio.delete(
        adminUserDeleteEP(userId),
        options: _auth,
      );
      if (res.statusCode == 404 || res.statusCode == 405) {
        final fallback = await _post(adminUserDeleteEP(userId));
        if (fallback.statusCode != 200) {
          throw ServerException(_msg(fallback.data, 'تعذر حذف المستخدم'),
              statusCode: fallback.statusCode);
        }
        return;
      }
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر حذف المستخدم'),
            statusCode: res.statusCode);
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر حذف المستخدم');
    }
  }

  @override
  Future<AdminUser> reviewUser(int userId) async {
    try {
      final res = await _get(adminUserReviewEP(userId));
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل بيانات المستخدم'),
            statusCode: res.statusCode);
      }
      return AdminUserModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل بيانات المستخدم');
    }
  }

  @override
  Future<AdminUser> approveUserDocuments(int userId) async {
    try {
      final res = await _post(adminUserApproveDocumentsEP(userId));
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw ServerException(_msg(res.data, 'تعذر اعتماد المستندات'),
            statusCode: res.statusCode);
      }
      return AdminUserModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر اعتماد المستندات');
    }
  }

  // ── Categories ───────────────────────────────────────────────────────────

  @override
  Future<List<AdminCategory>> fetchCategories() async {
    try {
      final res = await _get(adminCategoriesEP);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل الأقسام'),
            statusCode: res.statusCode);
      }
      final list = _list(res.data)
          .whereType<Map>()
          .map((e) => AdminCategoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return list;
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل الأقسام');
    }
  }

  @override
  Future<AdminCategory> createCategory({
    required String name,
    String? slug,
    String hubSection = 'orders',
  }) async {
    try {
      final res = await _post(adminCategoriesEP, data: {
        'name': name,
        if (slug != null && slug.isNotEmpty) 'slug': slug,
        'hub_section': hubSection,
      });
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw ServerException(_msg(res.data, 'تعذر إضافة القسم'),
            statusCode: res.statusCode);
      }
      return AdminCategoryModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إضافة القسم');
    }
  }

  @override
  Future<AdminCategory> updateCategory(AdminCategory category) async {
    try {
      final res = await _put(adminCategoryEP(category.id), data: {
        'name': category.name,
        if (category.slug != null) 'slug': category.slug,
        'hub_section': category.hubSection,
        'is_active': category.isActive,
        'sort_order': category.sortOrder,
      });
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تعديل القسم'),
            statusCode: res.statusCode);
      }
      return AdminCategoryModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تعديل القسم');
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    try {
      final res = await _delete(adminCategoryEP(id));
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw ServerException(_msg(res.data, 'تعذر حذف القسم'),
            statusCode: res.statusCode);
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر حذف القسم');
    }
  }

  @override
  Future<AdminCategory> toggleCategory(int id) async {
    try {
      final res = await _post(adminCategoryToggleEP(id));
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحديث حالة القسم'),
            statusCode: res.statusCode);
      }
      return AdminCategoryModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحديث حالة القسم');
    }
  }

  @override
  Future<void> reorderCategories(List<int> orderedIds) async {
    try {
      final res = await _post(adminCategoriesReorderEP, data: {
        'order': orderedIds,
      });
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر إعادة ترتيب الأقسام'),
            statusCode: res.statusCode);
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إعادة ترتيب الأقسام');
    }
  }

  // ── Products ─────────────────────────────────────────────────────────────

  @override
  Future<List<AdminProduct>> fetchProducts({int? vendorId}) async {
    try {
      final res = await _get(
        vendorId != null ? adminUserProductsEP(vendorId) : adminProductsEP,
      );
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل المنتجات'),
            statusCode: res.statusCode);
      }
      return _list(res.data)
          .whereType<Map>()
          .map((e) => AdminProductModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل المنتجات');
    }
  }

  @override
  Future<AdminProduct> toggleProduct(int id) async {
    try {
      final res = await _post(adminProductToggleEP(id));
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحديث ظهور المنتج'),
            statusCode: res.statusCode);
      }
      return AdminProductModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحديث ظهور المنتج');
    }
  }

  @override
  Future<void> deleteProduct(int id) async {
    try {
      final res = await _delete(adminProductDeleteEP(id));
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw ServerException(_msg(res.data, 'تعذر حذف المنتج'),
            statusCode: res.statusCode);
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر حذف المنتج');
    }
  }

  // ── Commissions ──────────────────────────────────────────────────────────

  @override
  Future<AdminCommissionSettings> fetchCommissionSettings() async {
    try {
      final res = await _get(adminCommissionSettingsEP);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل إعدادات العمولة'),
            statusCode: res.statusCode);
      }
      return AdminCommissionSettingsModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل إعدادات العمولة');
    }
  }

  @override
  Future<AdminCommissionSettings> saveCommissionSettings(
    AdminCommissionSettings settings,
  ) async {
    try {
      final payload = AdminCommissionSettingsModel(
        commissionEnabled: settings.commissionEnabled,
        driverCommissionPercent: settings.driverCommissionPercent,
        vendorCommissionPercent: settings.vendorCommissionPercent,
        debtLimit: settings.debtLimit,
      ).toJson();
      final res = await _post(adminCommissionSettingsEP, data: payload);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر حفظ إعدادات العمولة'),
            statusCode: res.statusCode);
      }
      return AdminCommissionSettingsModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر حفظ إعدادات العمولة');
    }
  }

  @override
  Future<List<AdminSettlementRequest>> fetchSettlements() async {
    try {
      final res = await _get(adminSettlementsEP);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل طلبات السداد'),
            statusCode: res.statusCode);
      }
      return _list(res.data)
          .whereType<Map>()
          .map((e) =>
              AdminSettlementModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل طلبات السداد');
    }
  }

  @override
  Future<AdminSettlementRequest> handleSettlement({
    required int id,
    required String action,
  }) async {
    try {
      final res = await _post(
        adminSettlementHandleEP(id),
        data: {'action': action},
      );
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر معالجة طلب السداد'),
            statusCode: res.statusCode);
      }
      final raw = res.data;
      Map<String, dynamic> map = {};
      if (raw is Map) {
        final data = raw['data'];
        if (data is Map) {
          map = Map<String, dynamic>.from(data);
        } else {
          map = Map<String, dynamic>.from(raw);
        }
      }
      if (map.isEmpty || (map['id'] == null && map['user_id'] == null)) {
        return AdminSettlementModel(
          id: id,
          userName: '',
          userRole: 'driver',
          amount: 0,
          status: action,
          statusLabel: _msg(res.data, 'تم'),
        );
      }
      return AdminSettlementModel.fromJson(map);
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر معالجة طلب السداد');
    }
  }

  // ── Payment ──────────────────────────────────────────────────────────────

  @override
  Future<AdminPaymentSettings> fetchPaymentSettings() async {
    try {
      final res = await _get(adminPaymentMethodsEP);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل طرق الدفع'),
            statusCode: res.statusCode);
      }
      return AdminPaymentSettingsModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل طرق الدفع');
    }
  }

  @override
  Future<AdminPaymentSettings> savePaymentSettings(
    AdminPaymentSettings settings,
  ) async {
    try {
      final payload = AdminPaymentSettingsModel(
        vodafoneCashNumber: settings.vodafoneCashNumber,
        instapayHandle: settings.instapayHandle,
        vodafoneEnabled: settings.vodafoneEnabled,
        instapayEnabled: settings.instapayEnabled,
        cashEnabled: settings.cashEnabled,
      ).toJson();
      final res = await _post(adminPaymentMethodsEP, data: payload);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر حفظ طرق الدفع'),
            statusCode: res.statusCode);
      }
      return AdminPaymentSettingsModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر حفظ طرق الدفع');
    }
  }

  // ── Notifications ────────────────────────────────────────────────────────

  @override
  Future<void> sendNotification(SendAdminNotificationParams params) async {
    try {
      final res = await _post(adminNotificationsSendEP, data: {
        'target': params.targetApiValue,
        if (params.specificPhone != null && params.specificPhone!.isNotEmpty)
          'phone': params.specificPhone,
        'title': params.title,
        'body': params.body,
      });
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw ServerException(_msg(res.data, 'تعذر إرسال الإشعار'),
            statusCode: res.statusCode);
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إرسال الإشعار');
    }
  }

  // ── Moderators ───────────────────────────────────────────────────────────

  @override
  Future<List<AdminModerator>> fetchModerators() async {
    try {
      final res = await _get(adminModeratorsEP);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل المشرفين'),
            statusCode: res.statusCode);
      }
      return _list(res.data)
          .whereType<Map>()
          .map(
              (e) => AdminModeratorModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل المشرفين');
    }
  }

  @override
  Future<AdminModerator> createModerator({
    required String name,
    required String phone,
    String email = '',
    String password = '',
    List<String> permissions = const [],
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name,
        'phone': phone,
        'permissions': permissions,
      };
      if (email.trim().isNotEmpty) {
        payload['email'] = email.trim();
      }
      if (password.trim().isNotEmpty) {
        payload['password'] = password.trim();
      }
      final res = await _post(adminModeratorsEP, data: payload);
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw ServerException(_msg(res.data, 'تعذر إضافة المشرف'),
            statusCode: res.statusCode);
      }
      return AdminModeratorModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إضافة المشرف');
    }
  }

  @override
  Future<AdminModerator> updateModerator(AdminModerator moderator) async {
    try {
      final res = await _put(adminModeratorEP(moderator.id), data: {
        'name': moderator.name,
        'phone': moderator.phone,
        'email': moderator.email,
        'permissions': moderator.permissions,
        'is_active': moderator.isActive,
      });
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تعديل المشرف'),
            statusCode: res.statusCode);
      }
      return AdminModeratorModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تعديل المشرف');
    }
  }

  @override
  Future<AdminModerator> toggleModerator(int id) async {
    try {
      final res = await _post(adminModeratorToggleEP(id));
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحديث حالة المشرف'),
            statusCode: res.statusCode);
      }
      return AdminModeratorModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحديث حالة المشرف');
    }
  }

  @override
  Future<void> deleteModerator(int id) async {
    try {
      final res = await _delete(adminModeratorEP(id));
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw ServerException(_msg(res.data, 'تعذر حذف المشرف'),
            statusCode: res.statusCode);
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر حذف المشرف');
    }
  }

  // ── Registration docs ────────────────────────────────────────────────────

  @override
  Future<List<AdminRegistrationDoc>> fetchRegistrationDocs() async {
    try {
      final res = await _get(adminRegistrationDocsEP);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل المستندات'),
            statusCode: res.statusCode);
      }
      return _list(res.data)
          .whereType<Map>()
          .map((e) =>
              AdminRegistrationDocModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل المستندات');
    }
  }

  @override
  Future<AdminRegistrationDoc> createRegistrationDoc({
    required String name,
    required AdminDocAudience audience,
    List<String> vehicleTypeKeys = const [],
  }) async {
    try {
      final audienceValue = switch (audience) {
        AdminDocAudience.driver => 'driver',
        AdminDocAudience.vendor => 'vendor',
        AdminDocAudience.both => 'both',
      };
      final payload = <String, dynamic>{
        'name': name,
        'audience': audienceValue,
      };
      if (audience == AdminDocAudience.driver && vehicleTypeKeys.isNotEmpty) {
        payload['vehicle_type_keys'] = vehicleTypeKeys;
      }
      final res = await _post(adminRegistrationDocsEP, data: payload);
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw ServerException(_msg(res.data, 'تعذر إضافة المستند'),
            statusCode: res.statusCode);
      }
      return AdminRegistrationDocModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إضافة المستند');
    }
  }

  @override
  Future<void> deleteRegistrationDoc(int id) async {
    try {
      final res = await _delete(adminRegistrationDocEP(id));
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw ServerException(_msg(res.data, 'تعذر حذف المستند'),
            statusCode: res.statusCode);
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر حذف المستند');
    }
  }

  // ── Plans ────────────────────────────────────────────────────────────────

  @override
  Future<AdminPlansSettings> fetchPlansSettings() async {
    try {
      final res = await _get(adminPlansSettingsEP);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل إعدادات الخطط'),
            statusCode: res.statusCode);
      }
      return AdminPlansSettingsModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل إعدادات الخطط');
    }
  }

  @override
  Future<AdminPlansSettings> savePlansSettings(
    AdminPlansSettings settings,
  ) async {
    try {
      final payload = AdminPlansSettingsModel(
        driversPlansEnabled: settings.driversPlansEnabled,
        vendorsPlansEnabled: settings.vendorsPlansEnabled,
      ).toJson();
      final res = await _post(adminPlansSettingsEP, data: payload);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر حفظ إعدادات الخطط'),
            statusCode: res.statusCode);
      }
      return AdminPlansSettingsModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر حفظ إعدادات الخطط');
    }
  }

  @override
  Future<List<AdminPlan>> fetchPlans() async {
    try {
      final res = await _get(adminPlansEP);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل الخطط'),
            statusCode: res.statusCode);
      }
      return _list(res.data)
          .whereType<Map>()
          .map((e) => AdminPlanModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل الخطط');
    }
  }

  @override
  Future<AdminPlan> createPlan(AdminPlan plan) async {
    try {
      final res = await _post(
        adminPlansEP,
        data: AdminPlanModel(
          id: 0,
          name: plan.name,
          price: plan.price,
          durationDays: plan.durationDays,
          audience: plan.audience,
          description: plan.description,
          isActive: plan.isActive,
        ).toJson(),
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw ServerException(_msg(res.data, 'تعذر إضافة الخطة'),
            statusCode: res.statusCode);
      }
      return AdminPlanModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر إضافة الخطة');
    }
  }

  @override
  Future<AdminPlan> updatePlan(AdminPlan plan) async {
    try {
      final res = await _put(
        adminPlanEP(plan.id),
        data: AdminPlanModel(
          id: plan.id,
          name: plan.name,
          price: plan.price,
          durationDays: plan.durationDays,
          audience: plan.audience,
          description: plan.description,
          isActive: plan.isActive,
        ).toJson(),
      );
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تعديل الخطة'),
            statusCode: res.statusCode);
      }
      return AdminPlanModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تعديل الخطة');
    }
  }

  @override
  Future<void> deletePlan(int id) async {
    try {
      final res = await _delete(adminPlanEP(id));
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw ServerException(_msg(res.data, 'تعذر حذف الخطة'),
            statusCode: res.statusCode);
      }
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر حذف الخطة');
    }
  }

  @override
  Future<List<AdminVehicleType>> fetchVehicleTypes() async {
    try {
      final res = await _get(adminVehicleTypesEP);
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحميل المركبات'),
            statusCode: res.statusCode);
      }
      return _list(res.data)
          .whereType<Map>()
          .map((e) =>
              AdminVehicleTypeModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحميل المركبات');
    }
  }

  @override
  Future<AdminVehicleType> updateVehicleType(AdminVehicleType type) async {
    try {
      final res = await _put(adminVehicleTypeEP(type.id), data: {
        'name_ar': type.nameAr,
        if (type.nameEn != null) 'name_en': type.nameEn,
        'coverage_range_km': type.coverageRangeKm,
        'is_active': type.isActive,
      });
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تحديث المركبة'),
            statusCode: res.statusCode);
      }
      return AdminVehicleTypeModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تحديث المركبة');
    }
  }

  @override
  Future<AdminVehicleType> toggleVehicleType(int id) async {
    try {
      final res = await _post(adminVehicleTypeToggleEP(id));
      if (res.statusCode != 200) {
        throw ServerException(_msg(res.data, 'تعذر تغيير حالة المركبة'),
            statusCode: res.statusCode);
      }
      return AdminVehicleTypeModel.fromJson(_map(res.data));
    } on DioException catch (e) {
      throw _mapDio(e, 'تعذر تغيير حالة المركبة');
    }
  }
}
