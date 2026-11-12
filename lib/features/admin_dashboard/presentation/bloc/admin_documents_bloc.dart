import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/admin_dashboard/domain/entities/admin_entities.dart';
import 'package:motorent/features/admin_dashboard/domain/repositories/admin_repository.dart';

part 'admin_documents_event.dart';
part 'admin_documents_state.dart';

class AdminDocumentsBloc
    extends Bloc<AdminDocumentsEvent, AdminDocumentsState> {
  final AdminRepository repository;

  AdminDocumentsBloc({required this.repository})
      : super(const AdminDocumentsState()) {
    on<FetchAdminDocumentsEvent>(_onFetch);
    on<CreateAdminDocumentEvent>(_onCreate);
    on<DeleteAdminDocumentEvent>(_onDelete);
  }

  Future<void> _onFetch(
    FetchAdminDocumentsEvent event,
    Emitter<AdminDocumentsState> emit,
  ) async {
    emit(state.copyWith(
        status: AdminDocumentsStatus.loading, clearMessage: true));
    final result = await repository.fetchRegistrationDocs();
    result.fold(
      (f) => emit(state.copyWith(
          status: AdminDocumentsStatus.failure, message: f.message)),
      (list) => emit(state.copyWith(
          status: AdminDocumentsStatus.loaded, documents: list)),
    );
  }

  Future<void> _onCreate(
    CreateAdminDocumentEvent event,
    Emitter<AdminDocumentsState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result = await repository.createRegistrationDoc(
      name: event.name,
      audience: event.audience,
      vehicleTypeKeys: event.vehicleTypeKeys,
    );
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (doc) => emit(state.copyWith(
        busy: false,
        documents: [...state.documents, doc],
        message: 'تمت إضافة المستند',
      )),
    );
  }

  Future<void> _onDelete(
    DeleteAdminDocumentEvent event,
    Emitter<AdminDocumentsState> emit,
  ) async {
    emit(state.copyWith(busy: true, clearMessage: true));
    final result = await repository.deleteRegistrationDoc(event.id);
    result.fold(
      (f) => emit(state.copyWith(busy: false, message: f.message)),
      (_) => emit(state.copyWith(
        busy: false,
        documents: state.documents.where((e) => e.id != event.id).toList(),
        message: 'تم حذف المستند',
      )),
    );
  }
}
