import 'package:motorent/features/admin_dashboard/core/error/failures.dart';
import 'package:motorent/features/admin_dashboard/core/utils/either.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';

abstract class AdminRepository {
  // Stats
  Future<Either<Failure, AdminStats>> fetchStats();

  // Users
  Future<Either<Failure, List<AdminUser>>> fetchUsers({
    AdminUserRole? role,
    AdminDriverSegment? driverSegment,
    String? search,
  });
  Future<Either<Failure, AdminUser>> toggleUser(int userId);
  Future<Either<Failure, Unit>> deleteUser(int userId);
  Future<Either<Failure, AdminUser>> reviewUser(int userId);
  Future<Either<Failure, AdminUser>> approveUserDocuments(int userId);

  // Categories
  Future<Either<Failure, List<AdminCategory>>> fetchCategories();
  Future<Either<Failure, AdminCategory>> createCategory({
    required String name,
    String? slug,
    String hubSection = 'orders',
  });
  Future<Either<Failure, AdminCategory>> updateCategory(AdminCategory category);
  Future<Either<Failure, Unit>> deleteCategory(int id);
  Future<Either<Failure, AdminCategory>> toggleCategory(int id);
  Future<Either<Failure, Unit>> reorderCategories(List<int> orderedIds);

  // Products
  Future<Either<Failure, List<AdminProduct>>> fetchProducts({int? vendorId});
  Future<Either<Failure, AdminProduct>> toggleProduct(int id);
  Future<Either<Failure, Unit>> deleteProduct(int id);

  // Commissions
  Future<Either<Failure, AdminCommissionSettings>> fetchCommissionSettings();
  Future<Either<Failure, AdminCommissionSettings>> saveCommissionSettings(
    AdminCommissionSettings settings,
  );
  Future<Either<Failure, List<AdminSettlementRequest>>> fetchSettlements();
  Future<Either<Failure, AdminSettlementRequest>> handleSettlement({
    required int id,
    required String action, // approve | reject
  });

  // Payment methods
  Future<Either<Failure, AdminPaymentSettings>> fetchPaymentSettings();
  Future<Either<Failure, AdminPaymentSettings>> savePaymentSettings(
    AdminPaymentSettings settings,
  );

  // Notifications
  Future<Either<Failure, Unit>> sendNotification(
    SendAdminNotificationParams params,
  );

  // Moderators
  Future<Either<Failure, List<AdminModerator>>> fetchModerators();
  Future<Either<Failure, AdminModerator>> createModerator({
    required String name,
    required String phone,
    String email,
    String password,
    List<String> permissions,
  });
  Future<Either<Failure, AdminModerator>> updateModerator(
    AdminModerator moderator,
  );
  Future<Either<Failure, AdminModerator>> toggleModerator(int id);
  Future<Either<Failure, Unit>> deleteModerator(int id);

  // Registration docs
  Future<Either<Failure, List<AdminRegistrationDoc>>> fetchRegistrationDocs();
  Future<Either<Failure, AdminRegistrationDoc>> createRegistrationDoc({
    required String name,
    required AdminDocAudience audience,
    List<String> vehicleTypeKeys = const [],
  });
  Future<Either<Failure, Unit>> deleteRegistrationDoc(int id);

  // Plans
  Future<Either<Failure, AdminPlansSettings>> fetchPlansSettings();
  Future<Either<Failure, AdminPlansSettings>> savePlansSettings(
    AdminPlansSettings settings,
  );
  Future<Either<Failure, List<AdminPlan>>> fetchPlans();
  Future<Either<Failure, AdminPlan>> createPlan(AdminPlan plan);
  Future<Either<Failure, AdminPlan>> updatePlan(AdminPlan plan);
  Future<Either<Failure, Unit>> deletePlan(int id);

  Future<Either<Failure, List<AdminVehicleType>>> fetchVehicleTypes();
  Future<Either<Failure, AdminVehicleType>> updateVehicleType(
    AdminVehicleType type,
  );
  Future<Either<Failure, AdminVehicleType>> toggleVehicleType(int id);
}
