import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/authenticated_image.dart';
import '../../auth/presentation/auth_state.dart';
import '../../personal_details/presentation/personal_details_state.dart';
import '../../documents/presentation/documents_state.dart';
import '../../selfie/presentation/selfie_state.dart';
import '../domain/submission.dart';
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

    final allRequirementsMet =
        personalDetailsState.isSaved &&
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
          : submissionState.submission != null &&
                submissionState.submission!.status != 'draft'
          ? _buildStatusView(submissionState)
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

  Widget _buildStatusView(SubmissionState submissionState) {
    final submission = submissionState.submission!;

    // Check if there are any field-level errors (excluding generalNotes)
    final hasFieldErrors =
        submission.rejectionDetails != null &&
        (submission.rejectionDetails!.hasPersonalDetailsErrors ||
            submission.rejectionDetails!.hasDocumentErrors ||
            submission.rejectionDetails!.hasSelfieErrors);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusIcon(submission.status),
            const SizedBox(height: 24),
            _buildStatusTitle(submission.status),
            const SizedBox(height: 12),
            _buildStatusDescription(submission),
            const SizedBox(height: 32),
            _buildStatusDetailsCard(submission),
            const SizedBox(height: 32),
            if (submission.isRejected) ...[
              if (hasFieldErrors)
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
                            'Please fix all errors above before resubmitting your application.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Card(
                  color: Colors.green,
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All errors have been fixed. You can now resubmit your application.',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: hasFieldErrors
                    ? null
                    : () async {
                        final notifier = ref.read(
                          submissionStateProvider.notifier,
                        );
                        await notifier.resetSubmission();

                        if (mounted) {
                          final state = ref.read(submissionStateProvider);
                          if (state.errorMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.errorMessage!),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('KYC resubmitted successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            context.go('/home');
                          }
                        }
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('Resubmit Application'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ] else
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'submitted':
        icon = Icons.schedule;
        color = Colors.blue;
        break;
      case 'under_review':
        icon = Icons.rate_review;
        color = Colors.orange;
        break;
      case 'approved':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }

    return Icon(icon, size: 100, color: color);
  }

  Widget _buildStatusTitle(String status) {
    String title;

    switch (status) {
      case 'submitted':
        title = 'Application Submitted';
        break;
      case 'under_review':
        title = 'Under Review';
        break;
      case 'approved':
        title = 'Approved';
        break;
      case 'rejected':
        title = 'Application Rejected';
        break;
      default:
        title = 'Unknown Status';
    }

    return Text(
      title,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatusDescription(Submission submission) {
    String description;

    switch (submission.status) {
      case 'submitted':
        description =
            'Your KYC application has been submitted\nand is awaiting review.';
        break;
      case 'under_review':
        description =
            'Your application is currently being reviewed\nby our team.';
        break;
      case 'approved':
        description =
            'Congratulations! Your KYC application\nhas been approved.';
        break;
      case 'rejected':
        description =
            'Your application has been rejected.\nPlease review the reason below.';
        break;
      default:
        description = '';
    }

    return Text(
      description,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, color: Colors.grey),
    );
  }

  Widget _buildStatusDetailsCard(Submission submission) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Status',
              submission.status.replaceAll('_', ' ').toUpperCase(),
              _getStatusColor(submission.status),
            ),
            if (submission.submittedAt != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                'Submitted',
                _formatDate(submission.submittedAt!),
                Colors.black87,
              ),
            ],
            if (submission.reviewedAt != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                'Reviewed',
                _formatDate(submission.reviewedAt!),
                Colors.black87,
              ),
            ],
            if (submission.rejectionDetails != null) ...[
              const Divider(height: 24),
              _buildRejectionDetails(submission.rejectionDetails!),
            ],
            if (submission.notes != null && submission.notes!.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'General Notes',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: submission.isRejected
                      ? Colors.red[50]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: submission.isRejected
                        ? Colors.red[200]!
                        : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                  submission.notes!,
                  style: TextStyle(
                    color: submission.isRejected
                        ? Colors.red[900]
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRejectionDetails(RejectionDetails details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rejection Reasons',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.red,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        if (details.hasPersonalDetailsErrors) ...[
          _buildRejectionSection(
            'Personal Details',
            Icons.person,
            _getPersonalDetailsErrors(details.personalDetails!),
          ),
          const SizedBox(height: 12),
        ],
        if (details.hasDocumentErrors) ...[
          _buildRejectionSection(
            'Documents',
            Icons.description,
            _getDocumentErrors(details.documents!),
          ),
          const SizedBox(height: 12),
        ],
        if (details.hasSelfieErrors) ...[
          _buildRejectionSection(
            'Selfie',
            Icons.camera_alt,
            _getSelfieErrors(details.selfie!),
          ),
        ],
        if (details.generalNotes != null &&
            details.generalNotes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    details.generalNotes!,
                    style: TextStyle(color: Colors.red[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRejectionSection(
    String title,
    IconData icon,
    List<String> errors,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.map(
            (error) => Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: Colors.red[700])),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(color: Colors.red[900]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getPersonalDetailsErrors(PersonalDetailsRejection details) {
    final errors = <String>[];
    if (details.dateOfBirth != null)
      errors.add('Date of Birth: ${details.dateOfBirth}');
    if (details.nationality != null)
      errors.add('Nationality: ${details.nationality}');
    if (details.phone != null) errors.add('Phone: ${details.phone}');
    if (details.address != null) errors.add('Address: ${details.address}');
    return errors;
  }

  List<String> _getDocumentErrors(DocumentRejection details) {
    final errors = <String>[];
    if (details.imageQuality != null)
      errors.add('Image Quality: ${details.imageQuality}');
    if (details.documentNumber != null)
      errors.add('Document Number: ${details.documentNumber}');
    if (details.expirationDate != null)
      errors.add('Expiration Date: ${details.expirationDate}');
    return errors;
  }

  List<String> _getSelfieErrors(SelfieRejection details) {
    final errors = <String>[];
    if (details.imageQuality != null)
      errors.add('Image Quality: ${details.imageQuality}');
    if (details.faceMatch != null)
      errors.add('Face Match: ${details.faceMatch}');
    return errors;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.blue;
      case 'under_review':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
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
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              _buildInfoRow('Date of Birth', details.dateOfBirth),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(
                  documentsState.isUploaded ? Icons.check_circle : Icons.error,
                  color: documentsState.isUploaded ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (documentsState.documents.isNotEmpty) ...[
              for (final doc in documentsState.documents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        doc.type.replaceAll('_', ' ').toUpperCase(),
                        doc.documentNumber,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AuthenticatedImage(
                          path: '/user/documents/${doc.id}/image',
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity,
                        ),
                      ),
                    ],
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Icon(
                  selfieState.isUploaded ? Icons.check_circle : Icons.error,
                  color: selfieState.isUploaded ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selfieState.isUploaded)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const AuthenticatedImage(
                  path: '/user/selfie/image',
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                ),
              )
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
