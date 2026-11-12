import 'package:equatable/equatable.dart';

// ─── Stats ───────────────────────────────────────────────────────────────────

class AdminStats extends Equatable {
  final int clientsCount;
  final int driversCount;
  final int vendorsCount;
  final double totalRevenue;
  final int activeOrders;
  final double totalProfit;
  final double collectedProfit;
  final double outstandingDues;
  final double subscriptionProfit;

  const AdminStats({
    this.clientsCount = 0,
    this.driversCount = 0,
    this.vendorsCount = 0,
    this.totalRevenue = 0,
    this.activeOrders = 0,
    this.totalProfit = 0,
    this.collectedProfit = 0,
    this.outstandingDues = 0,
    this.subscriptionProfit = 0,
  });

  @override
  List<Object?> get props => [
        clientsCount,
        driversCount,
        vendorsCount,
        totalRevenue,
        activeOrders,
        totalProfit,
        collectedProfit,
        outstandingDues,
        subscriptionProfit,
      ];
}

// ─── Users ───────────────────────────────────────────────────────────────────

enum AdminUserRole { client, driver, vendor }

enum AdminDriverSegment { newUsers, currentUsers }

class AdminUser extends Equatable {
  final int id;
  final String name;
  final String phone;
  final AdminUserRole role;
  final bool isActive;
  final bool isApproved;
  final String statusLabel;
  final List<AdminUserDocument> documents;
  final double dueAmount;
  final int productsCount;

  const AdminUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.isActive = true,
    this.isApproved = false,
    this.statusLabel = '',
    this.documents = const [],
    this.dueAmount = 0,
    this.productsCount = 0,
  });

  AdminUser copyWith({
    bool? isActive,
    bool? isApproved,
    String? statusLabel,
    List<AdminUserDocument>? documents,
    double? dueAmount,
    int? productsCount,
  }) =>
      AdminUser(
        id: id,
        name: name,
        phone: phone,
        role: role,
        isActive: isActive ?? this.isActive,
        isApproved: isApproved ?? this.isApproved,
        statusLabel: statusLabel ?? this.statusLabel,
        documents: documents ?? this.documents,
        dueAmount: dueAmount ?? this.dueAmount,
        productsCount: productsCount ?? this.productsCount,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        role,
        isActive,
        isApproved,
        documents,
        dueAmount,
        productsCount,
      ];
}

class AdminUserDocument extends Equatable {
  final String label;
  final String? url;

  const AdminUserDocument({required this.label, this.url});

  @override
  List<Object?> get props => [label, url];
}

// ─── Categories ──────────────────────────────────────────────────────────────

class AdminCategory extends Equatable {
  final int id;
  final String name;
  final String? slug;
  /// orders | bookings | services | transport
  final String hubSection;
  final int sortOrder;
  final bool isActive;
  final int imagesCount;

  const AdminCategory({
    required this.id,
    required this.name,
    this.slug,
    this.hubSection = 'orders',
    this.sortOrder = 0,
    this.isActive = true,
    this.imagesCount = 0,
  });

  AdminCategory copyWith({
    String? name,
    String? slug,
    String? hubSection,
    int? sortOrder,
    bool? isActive,
    int? imagesCount,
  }) =>
      AdminCategory(
        id: id,
        name: name ?? this.name,
        slug: slug ?? this.slug,
        hubSection: hubSection ?? this.hubSection,
        sortOrder: sortOrder ?? this.sortOrder,
        isActive: isActive ?? this.isActive,
        imagesCount: imagesCount ?? this.imagesCount,
      );

  @override
  List<Object?> get props =>
      [id, name, slug, hubSection, sortOrder, isActive, imagesCount];
}

// ─── Products ────────────────────────────────────────────────────────────────

class AdminProduct extends Equatable {
  final int id;
  final String name;
  final double price;
  final String? image;
  final String vendorName;
  final bool isVisible;

  const AdminProduct({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    required this.vendorName,
    this.isVisible = true,
  });

  AdminProduct copyWith({bool? isVisible}) => AdminProduct(
        id: id,
        name: name,
        price: price,
        image: image,
        vendorName: vendorName,
        isVisible: isVisible ?? this.isVisible,
      );

  @override
  List<Object?> get props => [id, name, price, image, vendorName, isVisible];
}

// ─── Commissions & Settlements ───────────────────────────────────────────────

class AdminCommissionSettings extends Equatable {
  final bool commissionEnabled;
  final double driverCommissionPercent;
  final double vendorCommissionPercent;
  final double debtLimit;
  final bool vendorOrdersCommissionEnabled;
  final double vendorOrdersCommissionPercent;
  final bool vendorOrdersFixedFeeEnabled;
  final double vendorOrdersFixedFeeAmount;

  const AdminCommissionSettings({
    this.commissionEnabled = false,
    this.driverCommissionPercent = 0,
    this.vendorCommissionPercent = 0,
    this.debtLimit = 0,
    this.vendorOrdersCommissionEnabled = true,
    this.vendorOrdersCommissionPercent = 5,
    this.vendorOrdersFixedFeeEnabled = true,
    this.vendorOrdersFixedFeeAmount = 10,
  });

  AdminCommissionSettings copyWith({
    bool? commissionEnabled,
    double? driverCommissionPercent,
    double? vendorCommissionPercent,
    double? debtLimit,
    bool? vendorOrdersCommissionEnabled,
    double? vendorOrdersCommissionPercent,
    bool? vendorOrdersFixedFeeEnabled,
    double? vendorOrdersFixedFeeAmount,
  }) =>
      AdminCommissionSettings(
        commissionEnabled: commissionEnabled ?? this.commissionEnabled,
        driverCommissionPercent:
            driverCommissionPercent ?? this.driverCommissionPercent,
        vendorCommissionPercent:
            vendorCommissionPercent ?? this.vendorCommissionPercent,
        debtLimit: debtLimit ?? this.debtLimit,
        vendorOrdersCommissionEnabled: vendorOrdersCommissionEnabled ??
            this.vendorOrdersCommissionEnabled,
        vendorOrdersCommissionPercent: vendorOrdersCommissionPercent ??
            this.vendorOrdersCommissionPercent,
        vendorOrdersFixedFeeEnabled:
            vendorOrdersFixedFeeEnabled ?? this.vendorOrdersFixedFeeEnabled,
        vendorOrdersFixedFeeAmount:
            vendorOrdersFixedFeeAmount ?? this.vendorOrdersFixedFeeAmount,
      );

  @override
  List<Object?> get props => [
        commissionEnabled,
        driverCommissionPercent,
        vendorCommissionPercent,
        debtLimit,
        vendorOrdersCommissionEnabled,
        vendorOrdersCommissionPercent,
        vendorOrdersFixedFeeEnabled,
        vendorOrdersFixedFeeAmount,
      ];
}

class AdminSettlementRequest extends Equatable {
  final int id;
  final String userName;
  final String userRole;
  final double amount;
  final String? receiptImage;
  final String status;
  final String statusLabel;
  final String? createdAt;
  final bool isSuspended;
  final int? receiptRequestId;
  final bool atLimit;
  final bool earlyPayment;
  final String reasonLabel;
  final String billingModeLabel;

  const AdminSettlementRequest({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.amount,
    this.receiptImage,
    required this.status,
    this.statusLabel = '',
    this.createdAt,
    this.isSuspended = false,
    this.receiptRequestId,
    this.atLimit = false,
    this.earlyPayment = false,
    this.reasonLabel = '',
    this.billingModeLabel = '',
  });

  bool get isPending => status == 'pending';

  @override
  List<Object?> get props => [
        id,
        userName,
        amount,
        status,
        receiptImage,
        isSuspended,
        atLimit,
        earlyPayment,
      ];
}

// ─── Payment Methods ─────────────────────────────────────────────────────────

class AdminPaymentSettings extends Equatable {
  final String vodafoneCashNumber;
  final String instapayHandle;
  final bool vodafoneEnabled;
  final bool instapayEnabled;
  final bool cashEnabled;

  const AdminPaymentSettings({
    this.vodafoneCashNumber = '',
    this.instapayHandle = '',
    this.vodafoneEnabled = true,
    this.instapayEnabled = true,
    this.cashEnabled = true,
  });

  AdminPaymentSettings copyWith({
    String? vodafoneCashNumber,
    String? instapayHandle,
    bool? vodafoneEnabled,
    bool? instapayEnabled,
    bool? cashEnabled,
  }) =>
      AdminPaymentSettings(
        vodafoneCashNumber: vodafoneCashNumber ?? this.vodafoneCashNumber,
        instapayHandle: instapayHandle ?? this.instapayHandle,
        vodafoneEnabled: vodafoneEnabled ?? this.vodafoneEnabled,
        instapayEnabled: instapayEnabled ?? this.instapayEnabled,
        cashEnabled: cashEnabled ?? this.cashEnabled,
      );

  @override
  List<Object?> get props => [
        vodafoneCashNumber,
        instapayHandle,
        vodafoneEnabled,
        instapayEnabled,
        cashEnabled,
      ];
}

// ─── Notifications ───────────────────────────────────────────────────────────

enum AdminNotificationTarget {
  all,
  clients,
  drivers,
  vendors,
  withDues,
  specific,
}

class SendAdminNotificationParams extends Equatable {
  final AdminNotificationTarget target;
  final String? specificPhone;
  final String title;
  final String body;

  const SendAdminNotificationParams({
    required this.target,
    this.specificPhone,
    required this.title,
    required this.body,
  });

  String get targetApiValue => switch (target) {
        AdminNotificationTarget.all => 'all',
        AdminNotificationTarget.clients => 'clients',
        AdminNotificationTarget.drivers => 'drivers',
        AdminNotificationTarget.vendors => 'vendors',
        AdminNotificationTarget.withDues => 'with_dues',
        AdminNotificationTarget.specific => 'specific',
      };

  @override
  List<Object?> get props => [target, specificPhone, title, body];
}

// ─── Moderators ──────────────────────────────────────────────────────────────

class AdminModerator extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String email;
  final bool isActive;
  final bool isSuperAdmin;
  final List<String> permissions;

  const AdminModerator({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.isActive = true,
    this.isSuperAdmin = false,
    this.permissions = const [],
  });

  AdminModerator copyWith({
    String? name,
    String? phone,
    String? email,
    bool? isActive,
    bool? isSuperAdmin,
    List<String>? permissions,
  }) =>
      AdminModerator(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        isActive: isActive ?? this.isActive,
        isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
        permissions: permissions ?? this.permissions,
      );

  @override
  List<Object?> get props =>
      [id, name, phone, email, isActive, isSuperAdmin, permissions];
}

// ─── Registration Documents ──────────────────────────────────────────────────

enum AdminDocAudience { driver, vendor, both }

class AdminRegistrationDoc extends Equatable {
  final int id;
  final String name;
  final AdminDocAudience audience;
  final bool isRequired;
  final List<String> vehicleTypeKeys;

  const AdminRegistrationDoc({
    required this.id,
    required this.name,
    this.audience = AdminDocAudience.both,
    this.isRequired = true,
    this.vehicleTypeKeys = const [],
  });

  @override
  List<Object?> get props => [id, name, audience, isRequired, vehicleTypeKeys];
}

// ─── Subscription Plans ──────────────────────────────────────────────────────

class AdminPlansSettings extends Equatable {
  final bool driversPlansEnabled;
  final bool vendorsPlansEnabled;

  const AdminPlansSettings({
    this.driversPlansEnabled = false,
    this.vendorsPlansEnabled = false,
  });

  AdminPlansSettings copyWith({
    bool? driversPlansEnabled,
    bool? vendorsPlansEnabled,
  }) =>
      AdminPlansSettings(
        driversPlansEnabled: driversPlansEnabled ?? this.driversPlansEnabled,
        vendorsPlansEnabled: vendorsPlansEnabled ?? this.vendorsPlansEnabled,
      );

  @override
  List<Object?> get props => [driversPlansEnabled, vendorsPlansEnabled];
}

enum AdminPlanAudience { driver, vendor }

class AdminPlan extends Equatable {
  final int id;
  final String name;
  final double price;
  final int durationDays;
  final AdminPlanAudience audience;
  final String? description;
  final bool isActive;

  const AdminPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.audience,
    this.description,
    this.isActive = true,
  });

  AdminPlan copyWith({
    String? name,
    double? price,
    int? durationDays,
    AdminPlanAudience? audience,
    String? description,
    bool? isActive,
  }) =>
      AdminPlan(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        durationDays: durationDays ?? this.durationDays,
        audience: audience ?? this.audience,
        description: description ?? this.description,
        isActive: isActive ?? this.isActive,
      );

  @override
  List<Object?> get props =>
      [id, name, price, durationDays, audience, description, isActive];
}

// ─── Vehicle types (نطاق التغطية) ───────────────────────────────────────────

class AdminVehicleType extends Equatable {
  final int id;
  final String key;
  final String nameAr;
  final String? nameEn;
  final int coverageRangeKm;
  final bool isActive;
  final String? category;

  const AdminVehicleType({
    required this.id,
    required this.key,
    required this.nameAr,
    this.nameEn,
    this.coverageRangeKm = 10,
    this.isActive = true,
    this.category,
  });

  AdminVehicleType copyWith({
    String? nameAr,
    int? coverageRangeKm,
    bool? isActive,
  }) =>
      AdminVehicleType(
        id: id,
        key: key,
        nameAr: nameAr ?? this.nameAr,
        nameEn: nameEn,
        coverageRangeKm: coverageRangeKm ?? this.coverageRangeKm,
        isActive: isActive ?? this.isActive,
        category: category,
      );

  @override
  List<Object?> get props =>
      [id, key, nameAr, coverageRangeKm, isActive, category];
}
