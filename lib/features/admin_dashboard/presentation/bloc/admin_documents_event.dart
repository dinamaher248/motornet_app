part of 'admin_documents_bloc.dart';

abstract class AdminDocumentsEvent extends Equatable {
  const AdminDocumentsEvent();
  @override
  List<Object?> get props => [];
}

class FetchAdminDocumentsEvent extends AdminDocumentsEvent {
  const FetchAdminDocumentsEvent();
}

class CreateAdminDocumentEvent extends AdminDocumentsEvent {
  final String name;
  final AdminDocAudience audience;
  final List<String> vehicleTypeKeys;
  const CreateAdminDocumentEvent({
    required this.name,
    this.audience = AdminDocAudience.both,
    this.vehicleTypeKeys = const [],
  });
  @override
  List<Object?> get props => [name, audience, vehicleTypeKeys];
}

class DeleteAdminDocumentEvent extends AdminDocumentsEvent {
  final int id;
  const DeleteAdminDocumentEvent(this.id);
  @override
  List<Object?> get props => [id];
}
