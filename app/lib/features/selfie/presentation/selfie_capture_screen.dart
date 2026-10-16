import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/widgets/authenticated_image.dart';
import '../../submission/presentation/submission_state.dart';
import '../../submission/domain/submission.dart';
import 'selfie_state.dart';

class SelfieCaptureScreen extends ConsumerStatefulWidget {
  const SelfieCaptureScreen({super.key});

  @override
  ConsumerState<SelfieCaptureScreen> createState() =>
      _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends ConsumerState<SelfieCaptureScreen> {
  File? _selectedImage;
  final _picker = ImagePicker();
  // Track which fields the user has actually edited
  final Set<String> _changedFields = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selfieStateProvider.notifier).loadSelfie();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
        preferredCameraDevice:
            CameraDevice.front, // Use front camera for selfie
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _changedFields.add('imageQuality');
          _changedFields.add('faceMatch');
        });
        _clearSelfieFieldRejection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Capture Selfie',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Selfie'),
              subtitle: const Text('Use front camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpload() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture or select a selfie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final notifier = ref.read(selfieStateProvider.notifier);
    final success = await notifier.uploadSelfie(file: _selectedImage!);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selfie uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final errorMessage = ref.read(selfieStateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Failed to upload selfie'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearSelfieFieldRejection() {
    final submissionState = ref.read(submissionStateProvider);
    final currentSubmission = submissionState.submission;

    if (currentSubmission?.rejectionDetails?.selfie == null) return;

    // When user captures a new selfie, clear all selfie rejection errors locally.
    // The backend will handle clearing rejection details and resetting submission
    // status when the selfie is uploaded (via clearRejectionField).
    final otherRejections = currentSubmission!.rejectionDetails!;
    final updatedRejectionDetails = RejectionDetails(
      personalDetails: otherRejections.personalDetails,
      documents: otherRejections.documents,
      selfie: null, // Clear all selfie errors
      generalNotes: otherRejections.generalNotes,
    );

    final hasAnyErrors =
        updatedRejectionDetails.hasPersonalDetailsErrors ||
        updatedRejectionDetails.hasDocumentErrors ||
        updatedRejectionDetails.hasSelfieErrors;

    final submissionNotifier = ref.read(submissionStateProvider.notifier);

    final updatedSubmission = Submission(
      id: currentSubmission.id,
      userId: currentSubmission.userId,
      status: currentSubmission.status,
      submittedAt: currentSubmission.submittedAt,
      reviewedAt: currentSubmission.reviewedAt,
      notes: currentSubmission.notes,
      rejectionDetails: hasAnyErrors ? updatedRejectionDetails : null,
    );
    submissionNotifier.updateSubmission(updatedSubmission);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(selfieStateProvider);
    final submissionState = ref.watch(submissionStateProvider);
    final rejectionDetails =
        submissionState.submission?.rejectionDetails?.selfie;

    // Check if submission is locked (submitted, under_review, or approved)
    final isEditable =
        submissionState.submission == null ||
        submissionState.submission!.isEditable;

    // Check if there are any remaining field-level rejection errors
    final hasRejectionErrors =
        rejectionDetails != null &&
        ((rejectionDetails.imageQuality != null &&
                !_changedFields.contains('imageQuality')) ||
            (rejectionDetails.faceMatch != null &&
                !_changedFields.contains('faceMatch')));

    // Disable upload button when there are still visible errors or submission is locked
    final isUploadDisabled =
        state.isLoading || hasRejectionErrors || !isEditable;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Selfie'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Instructions',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text('• Use good lighting'),
                          Text('• Face the camera directly'),
                          Text('• Remove glasses or masks'),
                          Text('• Ensure face is clearly visible'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your Selfie',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: isEditable ? _showImageSourceDialog : null,
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              ((rejectionDetails?.imageQuality != null &&
                                      !_changedFields.contains(
                                        'imageQuality',
                                      )) ||
                                  (rejectionDetails?.faceMatch != null &&
                                      !_changedFields.contains('faceMatch')))
                              ? Colors.red
                              : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: _selectedImage == null
                          ? (state.selfie != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: const AuthenticatedImage(
                                      path: '/user/selfie/image',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.face,
                                        size: 80,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Tap to capture selfie',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Front camera recommended',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                  if (rejectionDetails?.imageQuality != null &&
                      !_changedFields.contains('imageQuality')) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Image Quality: ${rejectionDetails!.imageQuality}',
                              style: TextStyle(color: Colors.red[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (rejectionDetails?.faceMatch != null &&
                      !_changedFields.contains('faceMatch')) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Face Match: ${rejectionDetails!.faceMatch}',
                              style: TextStyle(color: Colors.red[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: state.isLoading || !isEditable
                        ? null
                        : _showImageSourceDialog,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Selfie'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (hasRejectionErrors) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Please capture a new selfie to fix the errors above',
                              style: TextStyle(color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  ElevatedButton(
                    onPressed: isUploadDisabled ? null : _handleUpload,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Upload Selfie'),
                  ),
                ],
              ),
            ),
    );
  }
}
