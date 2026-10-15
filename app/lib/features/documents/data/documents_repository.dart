import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../../core/api/api_client.dart';
import '../domain/document.dart';

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DocumentsRepository(apiClient);
});

class DocumentsRepository {
  final ApiClient _apiClient;

  DocumentsRepository(this._apiClient);

  Future<DocumentResult> uploadDocument({
    required String type,
    required String documentNumber,
    required File file,
  }) async {
    try {
      // Create multipart form data
      final formData = FormData.fromMap({
        'type': type,
        'documentNumber': documentNumber,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _apiClient.dio.post(
        '/user/documents',
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final document = Document.fromJson(
          response.data['document'],
        );
        return DocumentResult.success(
          message: response.data['message'] ?? 'Document uploaded successfully',
          document: document,
        );
      }

      return DocumentResult.error(
        message: response.data['error'] ?? 'Failed to upload document',
      );
    } on DioException catch (e) {
      return DocumentResult.error(
        message: e.response?.data['error'] ?? 'Failed to upload document',
      );
    } catch (e) {
      return DocumentResult.error(
        message: 'An unexpected error occurred',
      );
    }
  }

  Future<DocumentResult> getDocuments() async {
    try {
      final response = await _apiClient.dio.get('/user/documents');

      if (response.statusCode == 200) {
        final documentsList = (response.data['documents'] as List)
            .map((doc) => Document.fromJson(doc))
            .toList();
        return DocumentResult.success(
          message: 'Documents retrieved successfully',
          documents: documentsList,
        );
      }

      return DocumentResult.error(
        message: response.data['error'] ?? 'Failed to retrieve documents',
      );
    } on DioException catch (e) {
      return DocumentResult.error(
        message: e.response?.data['error'] ?? 'Failed to retrieve documents',
      );
    } catch (e) {
      return DocumentResult.error(
        message: 'An unexpected error occurred',
      );
    }
  }
}

class DocumentResult {
  final bool isSuccess;
  final String message;
  final Document? document;
  final List<Document>? documents;

  DocumentResult._({
    required this.isSuccess,
    required this.message,
    this.document,
    this.documents,
  });

  factory DocumentResult.success({
    required String message,
    Document? document,
    List<Document>? documents,
  }) {
    return DocumentResult._(
      isSuccess: true,
      message: message,
      document: document,
      documents: documents,
    );
  }

  factory DocumentResult.error({required String message}) {
    return DocumentResult._(
      isSuccess: false,
      message: message,
    );
  }
}
