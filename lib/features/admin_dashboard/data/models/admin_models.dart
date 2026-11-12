import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';

int _asInt(dynamic v) {
  if (v is int) return v;
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0;
}

bool _asBool(dynamic v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v == 1 || v == '1' || v == 'true') return true;
  if (v == 0 || v == '0' || v == 'false') return false;
  return fallback;
}

class AdminStatsModel extends AdminStats {
  const AdminStatsModel({
    super.clientsCount,
    super.driversCount,
    super.vendorsCount,
    super.totalRevenue,
    super.activeOrders,
    super.totalProfit,
    super.collectedProfit,
    super.outstandingDues,
    super.subscriptionProfit,
  });

  factory AdminStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatsModel(
      clientsCount: _asInt(json['clients_count'] ?? json['clients']),
      driversCount: _asInt(json['drivers_count'] ?? json['drivers']),
      vendorsCount: _asInt(json['vendors_count'] ?? json['vendors']),
      totalRevenue: _asDouble(json['total_revenue'] ?? json['revenue']),
      activeOrders: _asInt(json['active_orders']),
      totalProfit: _asDouble(
          json['total_profit'] ?? json['profits'] ?? json['profit']),
      collectedProfit: _asDouble(json['collected_profit']),
      outstandingDues: _asDouble(
          json['outstanding_dues'] ?? json['due_amount_total']),
      subscriptionProfit: _asDouble(json['subscription_profit']),
    );
  }
}

class AdminUserModel extends AdminUser {
  const AdminUserModel({
    required super.id,
    required super.name,
    required super.phone,
    required super.role,
    super.isActive,
    super.isApproved,
    super.statusLabel,
    super.documents,
    super.dueAmount,
    super.productsCount,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final roleRaw =
        (json['role'] ?? json['title'] ?? json['type'] ?? 'user').toString();
    final role = switch (roleRaw) {
      'driver' => AdminUserRole.driver,
      'merchant' || 'vendor' => AdminUserRole.vendor,
      _ => AdminUserRole.client,
    };
    final docsRaw = json['documents'] as List? ?? [];

    // Backend uses is_suspended (web admin). Prefer that over is_active.
    final suspended = json['is_suspended'] == true ||
        json['is_suspended'] == 1 ||
        json['is_suspended'] == '1';
    final hasExplicitActive = json.containsKey('is_active') ||
        json.containsKey('active');
    final isActive = suspended
        ? false
        : (hasExplicitActive
            ? _asBool(json['is_active'] ?? json['active'], fallback: true)
            : true);
    final isApproved = _asBool(json['is_approved'] ?? json['approved'],
        fallback: false);

    return AdminUserModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: role,
      isActive: isActive,
      isApproved: isApproved,
      statusLabel: (json['status_label'] ?? (isActive ? 'مفعل' : 'موقوف'))
          .toString(),
      dueAmount: _asDouble(json['due_amount']),
      productsCount: _asInt(json['products_count']),
      documents: docsRaw
          .whereType<Map>()
          .map((e) => AdminUserDocument(
                label: (e['label'] ?? e['name'] ?? '').toString(),
                url: e['url']?.toString() ?? e['image']?.toString(),
              ))
          .toList(),
    );
  }
}

class AdminCategoryModel extends AdminCategory {
  const AdminCategoryModel({
    required super.id,
    required super.name,
    super.slug,
    super.hubSection,
    super.sortOrder,
    super.isActive,
    super.imagesCount,
  });

  factory AdminCategoryModel.fromJson(Map<String, dynamic> json) {
    final section = (json['hub_section'] ?? 'orders').toString();
    return AdminCategoryModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      slug: json['slug']?.toString(),
      hubSection: (section == 'bookings' ||
              section == 'services' ||
              section == 'transport')
          ? section
          : 'orders',
      sortOrder: _asInt(json['sort_order'] ?? json['order']),
      isActive: _asBool(json['is_active'], fallback: true),
      imagesCount: _asInt(json['images_count'] ?? json['photos_count']),
    );
  }
}

class AdminProductModel extends AdminProduct {
  const AdminProductModel({
    required super.id,
    required super.name,
    required super.price,
    super.image,
    required super.vendorName,
    super.isVisible,
  });

  factory AdminProductModel.fromJson(Map<String, dynamic> json) {
    return AdminProductModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      price: _asDouble(json['price']),
      image: json['image']?.toString(),
      vendorName: (json['vendor_name'] ??
              json['merchant_name'] ??
              json['store_name'] ??
              '')
          .toString(),
      isVisible: _asBool(
        json['is_visible'] ?? json['is_active'] ?? json['is_available'],
        fallback: true,
      ),
    );
  }
}

class AdminCommissionSettingsModel extends AdminCommissionSettings {
  const AdminCommissionSettingsModel({
    super.commissionEnabled,
    super.driverCommissionPercent,
    super.vendorCommissionPercent,
    super.debtLimit,
    super.vendorOrdersCommissionEnabled,
    super.vendorOrdersCommissionPercent,
    super.vendorOrdersFixedFeeEnabled,
    super.vendorOrdersFixedFeeAmount,
  });

  factory AdminCommissionSettingsModel.fromJson(Map<String, dynamic> json) {
    return AdminCommissionSettingsModel(
      commissionEnabled: _asBool(json['commission_enabled'] ?? json['enabled']),
      driverCommissionPercent: _asDouble(
        json['driver_commission_percent'] ?? json['driver_commission'],
      ),
      vendorCommissionPercent: _asDouble(
        json['vendor_commission_percent'] ?? json['vendor_commission'],
      ),
      debtLimit: _asDouble(json['debt_limit']),
      vendorOrdersCommissionEnabled: _asBool(
        json['vendor_orders_commission_enabled'],
        fallback: true,
      ),
      vendorOrdersCommissionPercent: _asDouble(
        json['vendor_orders_commission_percent'] ??
            json['vendor_commission_percent'],
      ),
      vendorOrdersFixedFeeEnabled: _asBool(
        json['vendor_orders_fixed_fee_enabled'],
        fallback: true,
      ),
      vendorOrdersFixedFeeAmount:
          _asDouble(json['vendor_orders_fixed_fee_amount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'commission_enabled': commissionEnabled,
        'driver_commission_percent': driverCommissionPercent,
        'vendor_commission_percent': vendorCommissionPercent,
        'debt_limit': debtLimit,
        'vendor_orders_commission_enabled': vendorOrdersCommissionEnabled,
        'vendor_orders_commission_percent': vendorOrdersCommissionPercent,
        'vendor_orders_fixed_fee_enabled': vendorOrdersFixedFeeEnabled,
        'vendor_orders_fixed_fee_amount': vendorOrdersFixedFeeAmount,
      };
}

class AdminSettlementModel extends AdminSettlementRequest {
  const AdminSettlementModel({
    required super.id,
    required super.userName,
    required super.userRole,
    required super.amount,
    super.receiptImage,
    required super.status,
    super.statusLabel,
    super.createdAt,
    super.isSuspended,
    super.receiptRequestId,
    super.atLimit,
    super.earlyPayment,
    super.reasonLabel,
    super.billingModeLabel,
  });

  factory AdminSettlementModel.fromJson(Map<String, dynamic> json) {
    return AdminSettlementModel(
      id: _asInt(json['id'] ?? json['user_id']),
      userName: (json['user_name'] ?? json['name'] ?? '').toString(),
      userRole: (json['user_role'] ?? json['role'] ?? '').toString(),
      amount: _asDouble(json['amount'] ?? json['due_amount']),
      receiptImage: json['receipt_image']?.toString() ??
          json['receipt']?.toString() ??
          json['image']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      statusLabel: (json['status_label'] ?? json['status'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
      isSuspended: _asBool(json['is_suspended']) ||
          (json['status']?.toString() == 'suspended'),
      receiptRequestId: json['receipt_request_id'] == null
          ? null
          : _asInt(json['receipt_request_id']),
      atLimit: _asBool(json['at_limit']),
      earlyPayment: _asBool(json['early_payment']),
      reasonLabel: (json['reason_label'] ?? '').toString(),
      billingModeLabel: (json['billing_mode_label'] ?? '').toString(),
    );
  }
}

class AdminPaymentSettingsModel extends AdminPaymentSettings {
  const AdminPaymentSettingsModel({
    super.vodafoneCashNumber,
    super.instapayHandle,
    super.vodafoneEnabled,
    super.instapayEnabled,
    super.cashEnabled,
  });

  factory AdminPaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    return AdminPaymentSettingsModel(
      vodafoneCashNumber:
          (json['vodafone_cash_number'] ?? json['vodafone_number'] ?? '')
              .toString(),
      instapayHandle:
          (json['instapay_handle'] ?? json['instapay_number'] ?? '').toString(),
      vodafoneEnabled: _asBool(json['vodafone_enabled'], fallback: true),
      instapayEnabled: _asBool(json['instapay_enabled'], fallback: true),
      cashEnabled: _asBool(json['cash_enabled'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'vodafone_cash_number': vodafoneCashNumber,
        'instapay_handle': instapayHandle,
        'vodafone_enabled': vodafoneEnabled,
        'instapay_enabled': instapayEnabled,
        'cash_enabled': cashEnabled,
      };
}

class AdminModeratorModel extends AdminModerator {
  const AdminModeratorModel({
    required super.id,
    required super.name,
    required super.phone,
    super.email,
    super.isActive,
    super.isSuperAdmin,
    super.permissions,
  });

  factory AdminModeratorModel.fromJson(Map<String, dynamic> json) {
    final perms = json['permission_keys'] ?? json['permissions'];
    final isSuper = _asBool(json['is_super_admin']) ||
        (perms is List && perms.map((e) => e.toString()).contains('*'));
    return AdminModeratorModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      isActive: _asBool(json['is_active'], fallback: true),
      isSuperAdmin: isSuper,
      permissions: perms is List
          ? perms.map((e) => e.toString()).where((e) => e != '*').toList()
          : const [],
    );
  }
}

class AdminRegistrationDocModel extends AdminRegistrationDoc {
  const AdminRegistrationDocModel({
    required super.id,
    required super.name,
    super.audience,
    super.isRequired,
    super.vehicleTypeKeys,
  });

  factory AdminRegistrationDocModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['audience'] ?? json['for'] ?? 'both').toString();
    final audience = switch (raw) {
      'driver' => AdminDocAudience.driver,
      'vendor' || 'merchant' => AdminDocAudience.vendor,
      _ => AdminDocAudience.both,
    };
    final keysRaw = json['vehicle_type_keys'] ?? json['vehicle_types'];
    final keys = keysRaw is List
        ? keysRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const <String>[];
    return AdminRegistrationDocModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? json['label'] ?? '').toString(),
      audience: audience,
      isRequired: _asBool(json['is_required'], fallback: true),
      vehicleTypeKeys: keys,
    );
  }
}

class AdminPlansSettingsModel extends AdminPlansSettings {
  const AdminPlansSettingsModel({
    super.driversPlansEnabled,
    super.vendorsPlansEnabled,
  });

  factory AdminPlansSettingsModel.fromJson(Map<String, dynamic> json) {
    return AdminPlansSettingsModel(
      driversPlansEnabled: _asBool(
        json['drivers_plans_enabled'] ?? json['enable_driver_plans'],
      ),
      vendorsPlansEnabled: _asBool(
        json['vendors_plans_enabled'] ?? json['enable_vendor_plans'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'drivers_plans_enabled': driversPlansEnabled,
        'vendors_plans_enabled': vendorsPlansEnabled,
      };
}

class AdminPlanModel extends AdminPlan {
  const AdminPlanModel({
    required super.id,
    required super.name,
    required super.price,
    required super.durationDays,
    required super.audience,
    super.description,
    super.isActive,
  });

  factory AdminPlanModel.fromJson(Map<String, dynamic> json) {
    final raw = (json['audience'] ?? json['for'] ?? 'driver').toString();
    return AdminPlanModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      price: _asDouble(json['price']),
      durationDays: _asInt(json['duration_days'] ?? json['days']),
      audience: raw == 'vendor' || raw == 'merchant'
          ? AdminPlanAudience.vendor
          : AdminPlanAudience.driver,
      description: json['description']?.toString(),
      isActive: _asBool(json['is_active'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'duration_days': durationDays,
        'audience': audience == AdminPlanAudience.vendor ? 'vendor' : 'driver',
        if (description != null) 'description': description,
        'is_active': isActive,
      };
}

class AdminVehicleTypeModel extends AdminVehicleType {
  const AdminVehicleTypeModel({
    required super.id,
    required super.key,
    required super.nameAr,
    super.nameEn,
    super.coverageRangeKm,
    super.isActive,
    super.category,
  });

  factory AdminVehicleTypeModel.fromJson(Map<String, dynamic> json) {
    return AdminVehicleTypeModel(
      id: _asInt(json['id']),
      key: (json['key'] ?? '').toString(),
      nameAr: (json['name_ar'] ?? json['name'] ?? '').toString(),
      nameEn: json['name_en']?.toString(),
      coverageRangeKm: _asInt(
        json['coverage_range_km'] ?? json['service_radius_km'] ?? 10,
      ),
      isActive: _asBool(json['is_active'], fallback: true),
      category: json['category']?.toString(),
    );
  }
}
