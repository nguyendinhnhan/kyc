import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

/// A widget that loads and displays an image from an authenticated API endpoint.
/// Uses Dio (with auth token interceptor) to fetch image bytes and displays via Image.memory.
class AuthenticatedImage extends ConsumerWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? loadingPlaceholder;
  final Widget? errorPlaceholder;

  const AuthenticatedImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.loadingPlaceholder,
    this.errorPlaceholder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);

    return FutureBuilder<Response<List<int>>>(
      future: apiClient.dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingPlaceholder ??
              Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final bytes = snapshot.data?.data;
        if (snapshot.hasError || bytes == null || bytes.isEmpty) {
          return errorPlaceholder ??
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              );
        }

        return Image.memory(
          Uint8List.fromList(bytes),
          fit: fit,
          width: width,
          height: height,
        );
      },
    );
  }
}
