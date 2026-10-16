import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_state.dart';
import '../../personal_details/presentation/personal_details_state.dart';
import '../../documents/presentation/documents_state.dart';
import '../../selfie/presentation/selfie_state.dart';
import '../../submission/presentation/submission_state.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(personalDetailsStateProvider.notifier).loadPersonalDetails();
      ref.read(documentsStateProvider.notifier).loadDocuments();
      ref.read(selfieStateProvider.notifier).loadSelfie();
      ref.read(submissionStateProvider.notifier).loadSubmission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final personalDetailsState = ref.watch(personalDetailsStateProvider);
    final documentsState = ref.watch(documentsStateProvider);
    final selfieState = ref.watch(selfieStateProvider);
    final submissionState = ref.watch(submissionStateProvider);
    final user = authState.user;

    // Check for rejection errors in each section
    final rejectionDetails = submissionState.submission?.rejectionDetails;
    final hasPersonalDetailsError =
        rejectionDetails?.hasPersonalDetailsErrors ?? false;
    final hasDocumentError = rejectionDetails?.hasDocumentErrors ?? false;
    final hasSelfieError = rejectionDetails?.hasSelfieErrors ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Onboarding'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authNotifier = ref.read(authStateProvider.notifier);
              await authNotifier.logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 100, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              'Welcome, ${user?.fullName ?? 'User'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            const Text(
              'KYC Verification Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => context.go('/personal-details'),
                      child: _buildStatusRow(
                        'Personal Details',
                        personalDetailsState.isSaved,
                        Icons.person,
                        hasError: hasPersonalDetailsError,
                      ),
                    ),
                    const Divider(height: 32),
                    InkWell(
                      onTap: () => context.go('/document-upload'),
                      child: _buildStatusRow(
                        'Document Upload',
                        documentsState.isUploaded,
                        Icons.description,
                        hasError: hasDocumentError,
                      ),
                    ),
                    const Divider(height: 32),
                    InkWell(
                      onTap: () => context.go('/selfie-capture'),
                      child: _buildStatusRow(
                        'Selfie Capture',
                        selfieState.isUploaded,
                        Icons.camera_alt,
                        hasError: hasSelfieError,
                      ),
                    ),
                    const Divider(height: 32),
                    InkWell(
                      onTap: () => context.go('/review-submit'),
                      child: _buildStatusRow(
                        'Verification',
                        submissionState.isSubmitted,
                        Icons.verified,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/review-submit');
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Review & Submit'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    String label,
    bool completed,
    IconData icon, {
    bool hasError = false,
  }) {
    final color = hasError
        ? Colors.red
        : (completed ? Colors.green : Colors.grey);
    final statusIcon = hasError
        ? Icons.error
        : (completed ? Icons.check_circle : Icons.radio_button_unchecked);

    return Row(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: hasError
                  ? Colors.red
                  : (completed ? Colors.green : Colors.black87),
            ),
          ),
        ),
        Icon(statusIcon, color: color),
      ],
    );
  }
}
