import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../submission/presentation/submission_state.dart';
import '../../submission/domain/submission.dart';
import '../domain/personal_details.dart';
import 'personal_details_state.dart';

class PersonalDetailsScreen extends ConsumerStatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  ConsumerState<PersonalDetailsScreen> createState() =>
      _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends ConsumerState<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateOfBirthController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isPopulating = false;
  // Track which fields the user has actually edited
  final Set<String> _changedFields = {};

  @override
  void initState() {
    super.initState();
    // Listen for changes - only mark if not during population
    void onFieldChange(String fieldName) {
      if (!_isPopulating) {
        setState(() {
          _changedFields.add(fieldName);
        });
        // Clear this field's rejection error immediately
        _clearFieldRejection(fieldName);
      }
    }

    _dateOfBirthController.addListener(() => onFieldChange('dateOfBirth'));
    _nationalityController.addListener(() => onFieldChange('nationality'));
    _phoneController.addListener(() => onFieldChange('phone'));
    _streetController.addListener(() => onFieldChange('address'));
    _cityController.addListener(() => onFieldChange('address'));
    _stateController.addListener(() => onFieldChange('address'));
    _postalCodeController.addListener(() => onFieldChange('address'));
    _countryController.addListener(() => onFieldChange('address'));

    // Load existing personal details if any
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(personalDetailsStateProvider.notifier).loadPersonalDetails();
    });
  }

  @override
  void dispose() {
    _dateOfBirthController.dispose();
    _nationalityController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _populateFields(PersonalDetails details) {
    _isPopulating = true;
    _dateOfBirthController.text = details.dateOfBirth.split('T')[0];
    _nationalityController.text = details.nationality;
    _phoneController.text = details.phone;
    _streetController.text = details.address.street;
    _cityController.text = details.address.city;
    _stateController.text = details.address.state;
    _postalCodeController.text = details.address.postalCode;
    _countryController.text = details.address.country;
    _isPopulating = false;
  }

  void _clearFieldRejection(String fieldName) {
    final submissionState = ref.read(submissionStateProvider);
    final currentSubmission = submissionState.submission;

    if (currentSubmission?.rejectionDetails?.personalDetails == null) return;

    final currentRejection =
        currentSubmission!.rejectionDetails!.personalDetails!;

    // Build updated personal details rejection without the changed field
    final updatedPersonalRejection = PersonalDetailsRejection(
      dateOfBirth: fieldName == 'dateOfBirth'
          ? null
          : currentRejection.dateOfBirth,
      nationality: fieldName == 'nationality'
          ? null
          : currentRejection.nationality,
      phone: fieldName == 'phone' ? null : currentRejection.phone,
      address: fieldName == 'address' ? null : currentRejection.address,
    );

    // Check if any personal details errors remain
    final hasPersonalErrors =
        updatedPersonalRejection.dateOfBirth != null ||
        updatedPersonalRejection.nationality != null ||
        updatedPersonalRejection.phone != null ||
        updatedPersonalRejection.address != null;

    final otherRejections = currentSubmission.rejectionDetails!;
    final updatedRejectionDetails = RejectionDetails(
      personalDetails: hasPersonalErrors ? updatedPersonalRejection : null,
      documents: otherRejections.documents,
      selfie: otherRejections.selfie,
      generalNotes: otherRejections.generalNotes,
    );

    final hasAnyErrors =
        updatedRejectionDetails.hasPersonalDetailsErrors ||
        updatedRejectionDetails.hasDocumentErrors ||
        updatedRejectionDetails.hasSelfieErrors;

    final submissionNotifier = ref.read(submissionStateProvider.notifier);

    // Update local state only — the backend handles clearing rejection details
    // and resetting submission status when personal details are saved.
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dateOfBirthController.text = picked.toIso8601String().split('T')[0];
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final address = Address(
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      country: _countryController.text.trim(),
    );

    final notifier = ref.read(personalDetailsStateProvider.notifier);
    final success = await notifier.savePersonalDetails(
      dateOfBirth: _dateOfBirthController.text,
      nationality: _nationalityController.text.trim(),
      phone: _phoneController.text.trim(),
      address: address,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal details saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/home');
    } else {
      final errorMessage = ref.read(personalDetailsStateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? 'Failed to save personal details'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalDetailsStateProvider);
    final submissionState = ref.watch(submissionStateProvider);
    final rejectionDetails =
        submissionState.submission?.rejectionDetails?.personalDetails;

    // Check if there are any remaining field-level rejection errors
    // (excluding fields the user has already changed)
    final hasRejectionErrors =
        rejectionDetails != null &&
        ((rejectionDetails.dateOfBirth != null &&
                !_changedFields.contains('dateOfBirth')) ||
            (rejectionDetails.nationality != null &&
                !_changedFields.contains('nationality')) ||
            (rejectionDetails.phone != null &&
                !_changedFields.contains('phone')) ||
            (rejectionDetails.address != null &&
                !_changedFields.contains('address')));

    // Disable button when there are still visible errors
    final isButtonDisabled = state.isLoading || hasRejectionErrors;

    // Populate fields when details are loaded
    if (state.details != null && _dateOfBirthController.text.isEmpty) {
      _populateFields(state.details!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Details'),
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
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateOfBirthController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth',
                        hintText: 'YYYY-MM-DD',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: const OutlineInputBorder(),
                        errorText: _changedFields.contains('dateOfBirth')
                            ? null
                            : rejectionDetails?.dateOfBirth,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your date of birth';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nationalityController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nationality',
                        prefixIcon: const Icon(Icons.flag),
                        border: const OutlineInputBorder(),
                        errorText: _changedFields.contains('nationality')
                            ? null
                            : rejectionDetails?.nationality,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your nationality';
                        }
                        if (value.length < 2) {
                          return 'Nationality must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+1234567890',
                        prefixIcon: const Icon(Icons.phone),
                        border: const OutlineInputBorder(),
                        errorText: _changedFields.contains('phone')
                            ? null
                            : rejectionDetails?.phone,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
                        if (!phoneRegex.hasMatch(value)) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _streetController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Street Address',
                        prefixIcon: const Icon(Icons.home),
                        border: const OutlineInputBorder(),
                        errorText: _changedFields.contains('address')
                            ? null
                            : rejectionDetails?.address,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your street address';
                        }
                        if (value.length < 2) {
                          return 'Street address must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (value.length < 2) {
                                return 'Too short';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'State/Province',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (value.length < 2) {
                                return 'Too short';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (value.length < 3) {
                                return 'Too short';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _countryController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Country',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (value.length < 2) {
                                return 'Too short';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
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
                                'Please fix the errors above before updating',
                                style: TextStyle(color: Colors.orange[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      onPressed: isButtonDisabled ? null : _handleSave,
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
                          : Text(state.isSaved ? 'Update' : 'Save'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
