import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../data/documents_repository.dart';
import '../domain/document.dart';
import '../../submission/presentation/submission_state.dart';
import '../../submission/domain/submission.dart';

final documentsStateProvider =
    StateNotifierProvider<DocumentsNotifier, DocumentsState>((ref) {
      final repository = ref.watch(documentsRepositoryProvider);
      return DocumentsNotifier(repository, ref);
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
  final Ref _ref;

  DocumentsNotifier(this._repository, this._ref) : super(DocumentsState());

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
      state = state.copyWith(isLoading: false, isUploaded: false);
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

      // Clear document rejection from submission state
      _clearDocumentRejection();

      return true;
    } else {
      state = state.copyWith(isLoading: false, errorMessage: result.message);
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

  void _clearDocumentRejection() async {
    final submissionNotifier = _ref.read(submissionStateProvider.notifier);
    final currentSubmission = submissionNotifier.state.submission;

    if (currentSubmission?.rejectionDetails != null) {
      final rejectionDetails = currentSubmission!.rejectionDetails!;

      // Create new rejection details without documents
      final updatedRejection = RejectionDetails(
        personalDetails: rejectionDetails.personalDetails,
        selfie: rejectionDetails.selfie,
        generalNotes: rejectionDetails.generalNotes,
      );

      // Check if all rejections are now cleared
      final hasAnyErrors =
          updatedRejection.hasPersonalDetailsErrors ||
          updatedRejection.hasDocumentErrors ||
          updatedRejection.hasSelfieErrors;

      // If all errors are cleared, call backend to reset submission
      if (!hasAnyErrors && currentSubmission.isRejected) {
        await submissionNotifier.resetSubmission();
      } else {
        // Create updated submission with remaining errors
        final updatedSubmission = Submission(
          id: currentSubmission.id,
          userId: currentSubmission.userId,
          status: currentSubmission.status,
          submittedAt: currentSubmission.submittedAt,
          reviewedAt: currentSubmission.reviewedAt,
          notes: currentSubmission.notes,
          rejectionDetails: updatedRejection,
        );

        // Update submission state
        submissionNotifier.state = submissionNotifier.state.copyWith(
          submission: updatedSubmission,
        );
      }
    }
  }
}
