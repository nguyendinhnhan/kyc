import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_state.dart';
import '../../personal_details/presentation/personal_details_state.dart';
import '../../documents/presentation/documents_state.dart';
import '../../selfie/presentation/selfie_state.dart';
import 'submission_state.dart';

class ReviewSubmitScreen extends ConsumerStatefulWidget {
  const ReviewSubmitScreen({super.key});

  @override
  ConsumerState<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends ConsumerState<ReviewSubmitScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(submissionStateProvider.notifier).loadSubmission();
    });
  }

  Future<void> _handleSubmit() async {
    final notifier = ref.read(submissionStateProvider.notifier);
    final success = await notifier.submitKYC();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KYC submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    } else {
      final errorMessage = ref.read(submissionStateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Failed to submit KYC'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit KYC'),
        content: const Text(
          'Are you sure you want to submit your KYC application? '
          'Please ensure all information is accurate and complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleSubmit();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final personalDetailsState = ref.watch(personalDetailsStateProvider);
    final documentsState = ref.watch(documentsStateProvider);
    final selfieState = ref.watch(selfieStateProvider);
    final submissionState = ref.watch(submissionStateProvider);
    final user = authState.user;

    final allRequirementsMet = personalDetailsState.isSaved &&
        documentsState.isUploaded &&
        selfieState.isUploaded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Submit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: submissionState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : submissionState.isSubmitted
              ? _buildAlreadySubmittedView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfoCard(user),
                      const SizedBox(height: 16),
                      _buildPersonalDetailsCard(personalDetailsState),
                      const SizedBox(height: 16),
                      _buildDocumentsCard(documentsState),
                      const SizedBox(height: 16),
                      _buildSelfieCard(selfieState),
                      const SizedBox(height: 24),
                      if (!allRequirementsMet)
                        Card(
                          color: Colors.orange[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange[700]),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Please complete all requirements before submitting.',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: allRequirementsMet && !submissionState.isLoading
                            ? _showConfirmationDialog
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          textStyle: const TextStyle(fontSize: 16),
                          backgroundColor: Colors.green,
                        ),
                        child: submissionState.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit KYC Application'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAlreadySubmittedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 100,
            color: Colors.green[400],
          ),
          const SizedBox(height: 24),
          const Text(
            'KYC Submitted',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your KYC application has been submitted\nand is being reviewed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Full Name', user?.fullName ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow('Email', user?.email ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalDetailsCard(PersonalDetailsState personalDetailsState) {
    final details = personalDetailsState.details;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Personal Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  personalDetailsState.isSaved
                      ? Icons.check_circle
                      : Icons.error,
                  color: personalDetailsState.isSaved
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (details != null) ...[
              _buildInfoRow(
                'Date of Birth',
                details.dateOfBirth,
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Nationality', details.nationality),
              const SizedBox(height: 8),
              _buildInfoRow('Phone', details.phone),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Address',
                '${details.address.street}, ${details.address.city}, ${details.address.state} ${details.address.postalCode}',
              ),
            ] else
              const Text(
                'No personal details provided',
                style: TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/personal-details'),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard(DocumentsState documentsState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  documentsState.isUploaded
                      ? Icons.check_circle
                      : Icons.error,
                  color: documentsState.isUploaded
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (documentsState.documents.isNotEmpty) ...[
              for (final doc in documentsState.documents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildInfoRow(
                    doc.type.replaceAll('_', ' ').toUpperCase(),
                    doc.documentNumber,
                  ),
                ),
            ] else
              const Text(
                'No documents uploaded',
                style: TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/document-upload'),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfieCard(SelfieState selfieState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Selfie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  selfieState.isUploaded
                      ? Icons.check_circle
                      : Icons.error,
                  color: selfieState.isUploaded
                      ? Colors.green
                      : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selfieState.isUploaded)
              const Text('Selfie captured successfully')
            else
              const Text(
                'No selfie captured',
                style: TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/selfie-capture'),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
