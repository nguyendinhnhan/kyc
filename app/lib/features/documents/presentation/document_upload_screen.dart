import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/widgets/authenticated_image.dart';
import '../../submission/presentation/submission_state.dart';
import '../../submission/domain/submission.dart';
import 'documents_state.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();
  String _selectedType = 'passport';
  File? _selectedImage;
  final _picker = ImagePicker();
  bool _hasPrefilled = false;
  // Track which fields the user has actually edited
  final Set<String> _changedFields = {};
  bool _isPopulating = false;

  final _documentTypes = [
    {'value': 'passport', 'label': 'Passport', 'icon': Icons.book},
    {'value': 'id_card', 'label': 'ID Card', 'icon': Icons.badge},
    {
      'value': 'drivers_license',
      'label': "Driver's License",
      'icon': Icons.drive_eta,
    },
    {
      'value': 'residence_permit',
      'label': 'Residence Permit',
      'icon': Icons.home,
    },
  ];

  @override
  void initState() {
    super.initState();
    _documentNumberController.addListener(() {
      if (!_isPopulating) {
        setState(() {
          _changedFields.add('documentNumber');
        });
        _clearDocumentFieldRejection('documentNumber');
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentsStateProvider.notifier).loadDocuments();
    });
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _changedFields.add('imageQuality');
        });
        _clearDocumentFieldRejection('imageQuality');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
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
                'Select Image Source',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final notifier = ref.read(documentsStateProvider.notifier);
    final success = await notifier.uploadDocument(
      type: _selectedType,
      documentNumber: _documentNumberController.text.trim(),
      file: _selectedImage!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final errorMessage = ref.read(documentsStateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Failed to upload document'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _populateFieldsForType(String type, DocumentsState state) {
    _isPopulating = true;
    final existingDoc = state.documents.where((d) => d.type == type);
    if (existingDoc.isNotEmpty) {
      _documentNumberController.text = existingDoc.first.documentNumber;
    } else {
      _documentNumberController.clear();
    }
    _isPopulating = false;
  }

  void _clearDocumentFieldRejection(String fieldName) {
    final submissionState = ref.read(submissionStateProvider);
    final currentSubmission = submissionState.submission;

    if (currentSubmission?.rejectionDetails?.documents == null) return;

    final currentRejection = currentSubmission!.rejectionDetails!.documents!;

    final updatedDocRejection = DocumentRejection(
      imageQuality: fieldName == 'imageQuality'
          ? null
          : currentRejection.imageQuality,
      documentNumber: fieldName == 'documentNumber'
          ? null
          : currentRejection.documentNumber,
      expirationDate: currentRejection.expirationDate,
    );

    final hasDocErrors =
        updatedDocRejection.imageQuality != null ||
        updatedDocRejection.documentNumber != null ||
        updatedDocRejection.expirationDate != null;

    final otherRejections = currentSubmission.rejectionDetails!;
    final updatedRejectionDetails = RejectionDetails(
      personalDetails: otherRejections.personalDetails,
      documents: hasDocErrors ? updatedDocRejection : null,
      selfie: otherRejections.selfie,
      generalNotes: otherRejections.generalNotes,
    );

    final hasAnyErrors =
        updatedRejectionDetails.hasPersonalDetailsErrors ||
        updatedRejectionDetails.hasDocumentErrors ||
        updatedRejectionDetails.hasSelfieErrors;

    final submissionNotifier = ref.read(submissionStateProvider.notifier);

    // Update local state only — the backend handles clearing rejection details
    // and resetting submission status when the document is uploaded.
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

  Widget _buildExistingDocumentImage(DocumentsState state) {
    final existingDoc = state.documents.where((d) => d.type == _selectedType);
    if (existingDoc.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AuthenticatedImage(
          path: '/user/documents/${existingDoc.first.id}/image',
          fit: BoxFit.cover,
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Tap to select image',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentsStateProvider);
    final submissionState = ref.watch(submissionStateProvider);
    final rejectionDetails =
        submissionState.submission?.rejectionDetails?.documents;

    // Check if there are any remaining field-level rejection errors
    final hasRejectionErrors =
        rejectionDetails != null &&
        ((rejectionDetails.documentNumber != null &&
                !_changedFields.contains('documentNumber')) ||
            (rejectionDetails.imageQuality != null &&
                !_changedFields.contains('imageQuality')));

    // Disable button when there are still visible errors
    final isButtonDisabled = state.isLoading || hasRejectionErrors;

    // Pre-fill document number when documents are loaded
    if (!state.isLoading && state.documents.isNotEmpty && !_hasPrefilled) {
      _hasPrefilled = true;
      _populateFieldsForType(_selectedType, state);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Document Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioGroup<String>(
                      groupValue: _selectedType,
                      onChanged: (value) {
                        final state = ref.read(documentsStateProvider);
                        setState(() {
                          _selectedType = value!;
                        });
                        _populateFieldsForType(value!, state);
                      },
                      child: Column(
                        children: _documentTypes.map((type) {
                          return RadioListTile<String>(
                            title: Row(
                              children: [
                                Icon(type['icon'] as IconData),
                                const SizedBox(width: 12),
                                Text(type['label'] as String),
                              ],
                            ),
                            value: type['value'] as String,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _documentNumberController,
                      decoration: InputDecoration(
                        labelText: 'Document Number',
                        hintText: 'Enter document number',
                        prefixIcon: const Icon(Icons.numbers),
                        border: const OutlineInputBorder(),
                        errorText: _changedFields.contains('documentNumber')
                            ? null
                            : rejectionDetails?.documentNumber,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter document number';
                        }
                        if (value.length < 3) {
                          return 'Document number must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Document Image',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                (rejectionDetails?.imageQuality != null &&
                                    !_changedFields.contains('imageQuality'))
                                ? Colors.red
                                : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[100],
                        ),
                        child: _selectedImage == null
                            ? _buildExistingDocumentImage(state)
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
                                rejectionDetails!.imageQuality!,
                                style: TextStyle(color: Colors.red[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
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
                                'Please fix the errors above before uploading',
                                style: TextStyle(color: Colors.orange[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      onPressed: isButtonDisabled ? null : _handleUpload,
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
                          : const Text('Upload Document'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
