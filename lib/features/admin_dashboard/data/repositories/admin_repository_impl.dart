import 'package:motorent/features/admin_dashboard/core/error/exceptions.dart';
import 'package:motorent/features/admin_dashboard/core/error/failures.dart';
import 'package:motorent/features/admin_dashboard/core/utils/either.dart';
import 'package:motorent/features/admin_dashboard/data/datasources/admin_remote_data_source.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  const AdminRepositoryImpl({required this.remoteDataSource});

  Future<Either<Failure, T>> _catch<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<Either<Failure, Unit>> _catchUnit(Future<void> Function() run) async {
    try {
      await run();
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AdminStats>> fetchStats() =>
      _catch(() => remoteDataSource.fetchStats());

  @override
  Future<Either<Failure, List<AdminUser>>> fetchUsers({
    AdminUserRole? role,
    AdminDriverSegment? driverSegment,
    String? search,
  }) =>
      _catch(() => remoteDataSource.fetchUsers(
            role: role,
            driverSegment: driverSegment,
            search: search,
          ));

  @override
  Future<Either<Failure, AdminUser>> toggleUser(int userId) =>
      _catch(() => remoteDataSource.toggleUser(userId));

  @override
  Future<Either<Failure, Unit>> deleteUser(int userId) =>
      _catchUnit(() => remoteDataSource.deleteUser(userId));

  @override
  Future<Either<Failure, AdminUser>> reviewUser(int userId) =>
      _catch(() => remoteDataSource.reviewUser(userId));

  @override
  Future<Either<Failure, AdminUser>> approveUserDocuments(int userId) =>
      _catch(() => remoteDataSource.approveUserDocuments(userId));

  @override
  Future<Either<Failure, List<AdminCategory>>> fetchCategories() =>
      _catch(() => remoteDataSource.fetchCategories());

  @override
  Future<Either<Failure, AdminCategory>> createCategory({
    required String name,
    String? slug,
    String hubSection = 'orders',
  }) =>
      _catch(() => remoteDataSource.createCategory(
            name: name,
            slug: slug,
            hubSection: hubSection,
          ));

  @override
  Future<Either<Failure, AdminCategory>> updateCategory(
          AdminCategory category) =>
      _catch(() => remoteDataSource.updateCategory(category));

  @override
  Future<Either<Failure, Unit>> deleteCategory(int id) =>
      _catchUnit(() => remoteDataSource.deleteCategory(id));

  @override
  Future<Either<Failure, AdminCategory>> toggleCategory(int id) =>
      _catch(() => remoteDataSource.toggleCategory(id));

  @override
  Future<Either<Failure, Unit>> reorderCategories(List<int> orderedIds) =>
      _catchUnit(() => remoteDataSource.reorderCategories(orderedIds));

  @override
  Future<Either<Failure, List<AdminProduct>>> fetchProducts({int? vendorId}) =>
      _catch(() => remoteDataSource.fetchProducts(vendorId: vendorId));

  @override
  Future<Either<Failure, AdminProduct>> toggleProduct(int id) =>
      _catch(() => remoteDataSource.toggleProduct(id));

  @override
  Future<Either<Failure, Unit>> deleteProduct(int id) =>
      _catchUnit(() => remoteDataSource.deleteProduct(id));

  @override
  Future<Either<Failure, AdminCommissionSettings>>
      fetchCommissionSettings() =>
          _catch(() => remoteDataSource.fetchCommissionSettings());

  @override
  Future<Either<Failure, AdminCommissionSettings>> saveCommissionSettings(
    AdminCommissionSettings settings,
  ) =>
      _catch(() => remoteDataSource.saveCommissionSettings(settings));

  @override
  Future<Either<Failure, List<AdminSettlementRequest>>> fetchSettlements() =>
      _catch(() => remoteDataSource.fetchSettlements());

  @override
  Future<Either<Failure, AdminSettlementRequest>> handleSettlement({
    required int id,
    required String action,
  }) =>
      _catch(
        () => remoteDataSource.handleSettlement(id: id, action: action),
      );

  @override
  Future<Either<Failure, AdminPaymentSettings>> fetchPaymentSettings() =>
      _catch(() => remoteDataSource.fetchPaymentSettings());

  @override
  Future<Either<Failure, AdminPaymentSettings>> savePaymentSettings(
    AdminPaymentSettings settings,
  ) =>
      _catch(() => remoteDataSource.savePaymentSettings(settings));

  @override
  Future<Either<Failure, Unit>> sendNotification(
    SendAdminNotificationParams params,
  ) =>
      _catchUnit(() => remoteDataSource.sendNotification(params));

  @override
  Future<Either<Failure, List<AdminModerator>>> fetchModerators() =>
      _catch(() => remoteDataSource.fetchModerators());

  @override
  Future<Either<Failure, AdminModerator>> createModerator({
    required String name,
    required String phone,
    String email = '',
    String password = '',
    List<String> permissions = const [],
  }) =>
      _catch(() => remoteDataSource.createModerator(
            name: name,
            phone: phone,
            email: email,
            password: password,
            permissions: permissions,
          ));

  @override
  Future<Either<Failure, AdminModerator>> updateModerator(
    AdminModerator moderator,
  ) =>
      _catch(() => remoteDataSource.updateModerator(moderator));

  @override
  Future<Either<Failure, AdminModerator>> toggleModerator(int id) =>
      _catch(() => remoteDataSource.toggleModerator(id));

  @override
  Future<Either<Failure, Unit>> deleteModerator(int id) =>
      _catchUnit(() => remoteDataSource.deleteModerator(id));

  @override
  Future<Either<Failure, List<AdminRegistrationDoc>>>
      fetchRegistrationDocs() =>
          _catch(() => remoteDataSource.fetchRegistrationDocs());

  @override
  Future<Either<Failure, AdminRegistrationDoc>> createRegistrationDoc({
    required String name,
    required AdminDocAudience audience,
    List<String> vehicleTypeKeys = const [],
  }) =>
      _catch(() => remoteDataSource.createRegistrationDoc(
            name: name,
            audience: audience,
            vehicleTypeKeys: vehicleTypeKeys,
          ));

  @override
  Future<Either<Failure, Unit>> deleteRegistrationDoc(int id) =>
      _catchUnit(() => remoteDataSource.deleteRegistrationDoc(id));

  @override
  Future<Either<Failure, AdminPlansSettings>> fetchPlansSettings() =>
      _catch(() => remoteDataSource.fetchPlansSettings());

  @override
  Future<Either<Failure, AdminPlansSettings>> savePlansSettings(
    AdminPlansSettings settings,
  ) =>
      _catch(() => remoteDataSource.savePlansSettings(settings));

  @override
  Future<Either<Failure, List<AdminPlan>>> fetchPlans() =>
      _catch(() => remoteDataSource.fetchPlans());

  @override
  Future<Either<Failure, AdminPlan>> createPlan(AdminPlan plan) =>
      _catch(() => remoteDataSource.createPlan(plan));

  @override
  Future<Either<Failure, AdminPlan>> updatePlan(AdminPlan plan) =>
      _catch(() => remoteDataSource.updatePlan(plan));

  @override
  Future<Either<Failure, Unit>> deletePlan(int id) =>
      _catchUnit(() => remoteDataSource.deletePlan(id));

  @override
  Future<Either<Failure, List<AdminVehicleType>>> fetchVehicleTypes() =>
      _catch(() => remoteDataSource.fetchVehicleTypes());

  @override
  Future<Either<Failure, AdminVehicleType>> updateVehicleType(
    AdminVehicleType type,
  ) =>
      _catch(() => remoteDataSource.updateVehicleType(type));

  @override
  Future<Either<Failure, AdminVehicleType>> toggleVehicleType(int id) =>
      _catch(() => remoteDataSource.toggleVehicleType(id));
}
