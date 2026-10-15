import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../data/documents_repository.dart';
import '../domain/document.dart';

final documentsStateProvider = StateNotifierProvider<DocumentsNotifier, DocumentsState>((ref) {
  final repository = ref.watch(documentsRepositoryProvider);
  return DocumentsNotifier(repository);
});

class DocumentsState {
  final bool isLoading;
  final List<Document> documents;
  final String? errorMessage;
  final bool isUploaded;

  DocumentsState({
    this.isLoading = false,
    this.documents = const [],
    this.errorMessage,
    this.isUploaded = false,
  });

  DocumentsState copyWith({
    bool? isLoading,
    List<Document>? documents,
    String? errorMessage,
    bool? isUploaded,
    bool clearError = false,
  }) {
    return DocumentsState(
      isLoading: isLoading ?? this.isLoading,
      documents: documents ?? this.documents,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }
}

class DocumentsNotifier extends StateNotifier<DocumentsState> {
  final DocumentsRepository _repository;

  DocumentsNotifier(this._repository) : super(DocumentsState());

  Future<void> loadDocuments() async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getDocuments();

    if (result.isSuccess && result.documents != null) {
      state = state.copyWith(
        isLoading: false,
        documents: result.documents!,
        isUploaded: result.documents!.isNotEmpty,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        isUploaded: false,
      );
    }
  }

  Future<bool> uploadDocument({
    required String type,
    required String documentNumber,
    required File file,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _repository.uploadDocument(
      type: type,
      documentNumber: documentNumber,
      file: file,
    );

    if (result.isSuccess && result.document != null) {
      // Reload documents to get the updated list
      await loadDocuments();
      return true;
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.message,
      );
      return false;
    }
  }

  bool hasDocumentOfType(String type) {
    return state.documents.any((doc) => doc.type == type);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = DocumentsState();
  }
}
