part of 'admin_documents_bloc.dart';

enum AdminDocumentsStatus { initial, loading, loaded, failure }

class AdminDocumentsState extends Equatable {
  final AdminDocumentsStatus status;
  final List<AdminRegistrationDoc> documents;
  final bool busy;
  final String? message;

  const AdminDocumentsState({
    this.status = AdminDocumentsStatus.initial,
    this.documents = const [],
    this.busy = false,
    this.message,
  });

  AdminDocumentsState copyWith({
    AdminDocumentsStatus? status,
    List<AdminRegistrationDoc>? documents,
    bool? busy,
    String? message,
    bool clearMessage = false,
  }) =>
      AdminDocumentsState(
        status: status ?? this.status,
        documents: documents ?? this.documents,
        busy: busy ?? this.busy,
        message: clearMessage ? null : (message ?? this.message),
      );

  @override
  List<Object?> get props => [status, documents, busy, message];
}
