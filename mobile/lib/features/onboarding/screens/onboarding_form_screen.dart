import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/models/onboarding_model.dart';
import '../../../core/utils/uk_data.dart';
import '../../../core/providers/auth_provider.dart' show UserRole;

class OnboardingFormScreen extends StatefulWidget {
  const OnboardingFormScreen({super.key});

  @override
  State<OnboardingFormScreen> createState() => _OnboardingFormScreenState();
}

class _OnboardingFormScreenState extends State<OnboardingFormScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  // Step 1: New Starter Details
  String? _selectedPosition;
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _siteOfficeController = TextEditingController();
  final TextEditingController _knownAsController = TextEditingController();
  final TextEditingController _niNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactRelationshipController = TextEditingController();
  final TextEditingController _emergencyContactMobileController = TextEditingController();
  final TextEditingController _secondaryContactNameController = TextEditingController();
  final TextEditingController _secondaryContactMobileController = TextEditingController();
  String? _selectedNationality;
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _sortCodeController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  DateTime? _startDate;
  DateTime? _dateOfBirth;
  String? _employmentType;
  String? _emergencyContactType;
  bool? _rightToWorkUk;
  List<String> _rightToWorkDocs = [];
  bool? _workedThisTaxYear;
  bool? _p45Provided;
  bool? _fitForRole;
  String? _medicalConditions;
  String? _medicationDetails;

  // Step 2: Qualifications
  final Map<String, TextEditingController> _qualificationControllers = {};
  final Map<String, DateTime?> _qualificationExpiries = {};
  final Map<String, bool> _qualificationFlags = {};

  // Step 3: Policies
  final Map<String, bool> _policyAcknowledged = {};

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _initializeQualificationControllers();
  }

  void _initializeQualificationControllers() {
    _qualificationControllers['cscs_type'] = TextEditingController();
    _qualificationControllers['cpcs_npors_types'] = TextEditingController();
  }

  Future<void> _loadExistingData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      // Initialize and load progress
      await onboardingProvider.loadProgress(user.id);
      
      if (onboardingProvider.newStarterDetails != null) {
        final details = onboardingProvider.newStarterDetails!;
        _selectedPosition = details.position;
        _positionController.text = details.position ?? '';
        _siteOfficeController.text = details.siteOffice ?? '';
        _knownAsController.text = details.knownAs ?? '';
        _niNumberController.text = details.niNumber ?? '';
        _addressController.text = details.address ?? '';
        _postcodeController.text = details.postcode ?? '';
        _mobileController.text = details.mobile ?? '';
        _emergencyContactNameController.text = details.emergencyContactName ?? '';
        _emergencyContactRelationshipController.text = details.emergencyContactRelationship ?? '';
        _emergencyContactMobileController.text = details.emergencyContactMobile ?? '';
        _secondaryContactNameController.text = details.secondaryContactName ?? '';
        _secondaryContactMobileController.text = details.secondaryContactMobile ?? '';
        _selectedNationality = details.nationality;
        _nationalityController.text = details.nationality ?? '';
        _bankNameController.text = details.bankName ?? '';
        _sortCodeController.text = details.sortCode ?? '';
        _accountNumberController.text = details.accountNumber ?? '';
        _startDate = details.startDate;
        _dateOfBirth = details.dateOfBirth;
        _employmentType = details.employmentType;
        _emergencyContactType = details.emergencyContactType;
        _rightToWorkUk = details.rightToWorkUk;
        _rightToWorkDocs = details.rightToWorkDocsSeen ?? [];
        _workedThisTaxYear = details.workedThisTaxYear;
        _p45Provided = details.p45Provided;
        _fitForRole = details.fitForRole;
        _medicalConditions = details.medicalConditions;
        _medicationDetails = details.medicationDetails;
      }
      
      setState(() {
        _currentStep = onboardingProvider.currentStep - 1;
        if (_currentStep < 0) _currentStep = 0;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _positionController.dispose();
    _siteOfficeController.dispose();
    _knownAsController.dispose();
    _niNumberController.dispose();
    _addressController.dispose();
    _postcodeController.dispose();
    _mobileController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactRelationshipController.dispose();
    _emergencyContactMobileController.dispose();
    _secondaryContactNameController.dispose();
    _secondaryContactMobileController.dispose();
    _nationalityController.dispose();
    _bankNameController.dispose();
    _sortCodeController.dispose();
    _accountNumberController.dispose();
    _qualificationControllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _nextStep() async {
    if (!_formKeys[_currentStep].currentState!.validate()) {
      return;
    }

    if (_currentStep == 0) {
      await _saveStep1();
    } else if (_currentStep == 1) {
      await _saveStep2();
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      await _saveStep3();
      await _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveStep1() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    final details = OnboardingNewStarterDetails(
      userId: user.id,
      position: _selectedPosition ?? _positionController.text.trim(),
      siteOffice: _siteOfficeController.text.trim(),
      startDate: _startDate,
      employmentType: _employmentType,
      knownAs: _knownAsController.text.trim(),
      dateOfBirth: _dateOfBirth,
      niNumber: _niNumberController.text.trim(),
      address: _addressController.text.trim(),
      postcode: UKData.formatUKPostcode(_postcodeController.text.trim()),
      mobile: _mobileController.text.trim(),
      email: user.email,
      emergencyContactName: _emergencyContactNameController.text.trim(),
      emergencyContactRelationship: _emergencyContactRelationshipController.text.trim(),
      emergencyContactMobile: _emergencyContactMobileController.text.trim(),
      emergencyContactType: _emergencyContactType,
      secondaryContactName: _secondaryContactNameController.text.trim(),
      secondaryContactMobile: _secondaryContactMobileController.text.trim(),
      nationality: _selectedNationality ?? _nationalityController.text.trim(),
      rightToWorkUk: _rightToWorkUk,
      rightToWorkDocsSeen: _rightToWorkDocs,
      bankName: _bankNameController.text.trim(),
      sortCode: _sortCodeController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      workedThisTaxYear: _workedThisTaxYear,
      p45Provided: _p45Provided,
      fitForRole: _fitForRole,
      medicalConditions: _medicalConditions,
      medicationDetails: _medicationDetails,
    );

    final success = await onboardingProvider.saveNewStarterDetails(details);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveStep2() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    final qualifications = {
      'user_id': user.id,
      'cscs_type': _qualificationControllers['cscs_type']?.text.trim(),
      'cscs_expiry': _qualificationExpiries['cscs']?.toIso8601String().split('T')[0],
      'cpcs_npors_types': _qualificationControllers['cpcs_npors_types']?.text.trim(),
      'cpcs_npors_expiry': _qualificationExpiries['cpcs']?.toIso8601String().split('T')[0],
      'sssts_expiry': _qualificationExpiries['sssts']?.toIso8601String().split('T')[0],
      'smsts_expiry': _qualificationExpiries['smsts']?.toIso8601String().split('T')[0],
      'first_aid_work': _qualificationFlags['first_aid_work'] ?? false,
      'first_aid_emergency_expiry': _qualificationExpiries['first_aid']?.toIso8601String().split('T')[0],
      'asbestos_awareness': _qualificationFlags['asbestos'] ?? false,
      'working_at_height': _qualificationFlags['working_at_height'] ?? false,
      'pasma': _qualificationFlags['pasma'] ?? false,
      'confined_spaces': _qualificationFlags['confined_spaces'] ?? false,
      'manual_handling': _qualificationFlags['manual_handling'] ?? false,
      'fire_marshall': _qualificationFlags['fire_marshall'] ?? false,
    };

    final success = await onboardingProvider.saveQualifications(qualifications);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save qualifications. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveStep3() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    final policies = {
      'user_id': user.id,
      'health_safety_policy': _policyAcknowledged['health_safety'] ?? false,
      'drugs_alcohol_policy': _policyAcknowledged['drugs_alcohol'] ?? false,
      'environmental_policy': _policyAcknowledged['environmental'] ?? false,
      'equality_diversity': _policyAcknowledged['equality_diversity'] ?? false,
      'disciplinary_grievance': _policyAcknowledged['disciplinary'] ?? false,
      'quality_policy': _policyAcknowledged['quality'] ?? false,
      'anti_bullying_harassment': _policyAcknowledged['anti_bullying'] ?? false,
      'data_protection_confidentiality': _policyAcknowledged['data_protection'] ?? false,
      'vehicle_fuel_card_policy': _policyAcknowledged['vehicle'] ?? false,
      'it_email_social_media_policy': _policyAcknowledged['it_social'] ?? false,
      'acknowledged_name': '${user.firstName} ${user.lastName}',
      'acknowledged_date': DateTime.now().toIso8601String().split('T')[0],
    };

    final success = await onboardingProvider.savePolicies(policies);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save policies. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (mounted && user != null) {
      // Get role from selected position
      final selectedPosition = _selectedPosition ?? _positionController.text.trim();
      if (selectedPosition.isNotEmpty) {
        final roleString = UKData.getRoleFromPosition(selectedPosition);
        
        // Convert role string to UserRole enum
        UserRole newRole = UserRole.staff;
        switch (roleString.toLowerCase()) {
          case 'supervisor':
            newRole = UserRole.supervisor;
            break;
          case 'admin':
            newRole = UserRole.admin;
            break;
          default:
            newRole = UserRole.staff;
        }
        
        // Update user role in database
        try {
          await userProvider.updateUserRole(user.id, newRole);
          
          // Refresh auth provider to get updated role
          await authProvider.refreshCurrentUser(userProvider: userProvider);
        } catch (e) {
          debugPrint('Error updating user role: $e');
          // Continue anyway - role update is not critical
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onboarding completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (mounted && context.mounted) {
        // Use the role from position or fall back to current user role
        final selectedPosition = _selectedPosition ?? _positionController.text.trim();
        final roleString = selectedPosition.isNotEmpty
            ? UKData.getRoleFromPosition(selectedPosition)
            : (authProvider.currentUser?.role.toString().split('.').last ?? 'staff');
        
        debugPrint('Navigating to dashboard with role: $roleString (from position: $selectedPosition)');
        
        // Use a post-frame callback to ensure navigation happens after build completes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            context.go('/dashboard?role=$roleString');
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Starter Onboarding'),
        automaticallyImplyLeading: _currentStep > 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? theme.colorScheme.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Step ${_currentStep + 1} of 3',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Form content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(theme),
                _buildStep2(theme),
                _buildStep3(theme),
              ],
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    child: Text(_currentStep == 2 ? 'Complete' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return Form(
      key: _formKeys[0],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New Starter Details',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Position - Dropdown (categorized)
            // Note: Management positions (Site Manager, Project Manager, Site Supervisor, Foreman, Health & Safety Officer) 
            // will show the Supervisor dashboard. All other positions show the Staff dashboard.
            DropdownButtonFormField<String>(
              value: _selectedPosition,
              decoration: InputDecoration(
                labelText: 'Position',
                border: const OutlineInputBorder(),
                helperText: _selectedPosition != null
                    ? 'Dashboard: ${UKData.getRoleFromPosition(_selectedPosition!) == 'supervisor' ? 'Supervisor' : 'Staff'}'
                    : 'Select your position to determine dashboard access',
                helperMaxLines: 2,
              ),
              items: UKData.positions.map((position) {
                final role = UKData.getRoleFromPosition(position);
                final isSupervisor = role == 'supervisor';
                
                return DropdownMenuItem(
                  value: position,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSupervisor)
                        Icon(
                          Icons.verified_user,
                          size: 16,
                          color: Colors.blue,
                        )
                      else
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.green,
                        ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          position,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSupervisor ? 'Supervisor' : 'Staff',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSupervisor ? Colors.blue : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPosition = value;
                  if (value != null) {
                    _positionController.text = value;
                  }
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a position';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Site/Office
            TextFormField(
              controller: _siteOfficeController,
              decoration: const InputDecoration(
                labelText: 'Site / Office',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Start Date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _startDate = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(_startDate != null
                    ? DateFormat('dd/MM/yyyy').format(_startDate!)
                    : 'Select start date'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Employment Type
            DropdownButtonFormField<String>(
              value: _employmentType,
              decoration: const InputDecoration(
                labelText: 'Employment Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'employee', child: Text('Employee')),
                DropdownMenuItem(value: 'subcontractor_cis', child: Text('Subcontractor (CIS)')),
                DropdownMenuItem(value: 'consultant', child: Text('Consultant')),
              ],
              onChanged: (value) => setState(() => _employmentType = value),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Personal Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Known As
            TextFormField(
              controller: _knownAsController,
              decoration: const InputDecoration(
                labelText: 'Known As',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Date of Birth
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateOfBirth ?? DateTime(1990),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _dateOfBirth = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(),
                ),
                child: Text(_dateOfBirth != null
                    ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!)
                    : 'Select date of birth'),
              ),
            ),
            const SizedBox(height: 16),
            
            // NI Number
            TextFormField(
              controller: _niNumberController,
              decoration: const InputDecoration(
                labelText: 'NI Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            
            // Postcode - Format UK postcode
            TextFormField(
              controller: _postcodeController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Postcode',
                border: OutlineInputBorder(),
                hintText: 'SW1A 1AA',
              ),
              onChanged: (value) {
                // Auto-format on change
                final formatted = UKData.formatUKPostcode(value);
                if (formatted != value && value.isNotEmpty) {
                  _postcodeController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Mobile
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Emergency Contact',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emergencyContactNameController,
              decoration: const InputDecoration(
                labelText: 'Primary Contact Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emergencyContactRelationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emergencyContactMobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _emergencyContactType,
              decoration: const InputDecoration(
                labelText: 'Contact Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'home', child: Text('Home')),
                DropdownMenuItem(value: 'work', child: Text('Work')),
              ],
              onChanged: (value) => setState(() => _emergencyContactType = value),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Right to Work (UK)',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Nationality - Dropdown
            DropdownButtonFormField<String>(
              value: _selectedNationality,
              decoration: const InputDecoration(
                labelText: 'Nationality',
                border: OutlineInputBorder(),
              ),
              items: UKData.nationalities.map((nationality) {
                return DropdownMenuItem(
                  value: nationality,
                  child: Text(nationality),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedNationality = value;
                  if (value != null) {
                    _nationalityController.text = value;
                  }
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a nationality';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Flexible(
                  child: const Text('Right to work in UK?'),
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _rightToWorkUk,
                      onChanged: (value) => setState(() => _rightToWorkUk = value),
                    ),
                    const Text('Yes'),
                    Radio<bool>(
                      value: false,
                      groupValue: _rightToWorkUk,
                      onChanged: (value) => setState(() => _rightToWorkUk = value),
                    ),
                    const Text('No'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Bank Details (shown for all employment types)
            Text(
              'Bank Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _bankNameController,
              readOnly: true, // Auto-populated from sort code
              decoration: const InputDecoration(
                labelText: 'Bank',
                border: OutlineInputBorder(),
                hintText: 'Will be filled from sort code',
                filled: true,
                fillColor: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _sortCodeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
                _SortCodeFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Sort Code (XX-XX-XX)',
                border: OutlineInputBorder(),
                hintText: '12-34-56',
              ),
              onChanged: (value) {
                // Auto-populate bank name from sort code
                final formatted = UKData.formatSortCode(value);
                final bankName = UKData.getBankFromSortCode(value);
                if (bankName != null) {
                  setState(() {
                    _bankNameController.text = bankName;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter sort code';
                }
                final formatted = UKData.formatSortCode(value);
                if (formatted == null || formatted.length != 8) {
                  return 'Sort code must be 6 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(
                labelText: 'Account Number (8 digits)',
                border: OutlineInputBorder(),
                hintText: '12345678',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account number';
                }
                if (!UKData.isValidAccountNumber(value)) {
                  return 'Account number must be 8 digits';
                }
                return null;
              },
            ),
            
            // Payroll & Tax fields (only for employees)
            if (_employmentType == 'employee') ...[
              const SizedBox(height: 16),
              Text(
                'Payroll & Tax',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Flexible(
                    child: const Text('Worked this tax year?'),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _workedThisTaxYear,
                        onChanged: (value) => setState(() => _workedThisTaxYear = value),
                      ),
                      const Text('Yes'),
                      Radio<bool>(
                        value: false,
                        groupValue: _workedThisTaxYear,
                        onChanged: (value) => setState(() => _workedThisTaxYear = value),
                      ),
                      const Text('No'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Flexible(
                    child: const Text('P45 Provided?'),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _p45Provided,
                        onChanged: (value) => setState(() => _p45Provided = value),
                      ),
                      const Text('Yes'),
                      Radio<bool>(
                        value: false,
                        groupValue: _p45Provided,
                        onChanged: (value) => setState(() => _p45Provided = value),
                      ),
                      const Text('No'),
                    ],
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 24),
            
            Text(
              'Medical / Fitness for Work',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Flexible(
                  child: const Text('Fit to carry out role safely?'),
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _fitForRole,
                      onChanged: (value) => setState(() => _fitForRole = value),
                    ),
                    const Text('Yes'),
                    Radio<bool>(
                      value: false,
                      groupValue: _fitForRole,
                      onChanged: (value) => setState(() => _fitForRole = value),
                    ),
                    const Text('No'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Form(
      key: _formKeys[1],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Qualifications, Tickets & Competencies',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // CSCS Card Type - Dropdown
            DropdownButtonFormField<String>(
              value: _qualificationControllers['cscs_type']?.text.isEmpty ?? true
                  ? null
                  : _qualificationControllers['cscs_type']?.text,
              decoration: const InputDecoration(
                labelText: 'CSCS Card - Type',
                border: OutlineInputBorder(),
              ),
              items: UKData.cscsCardTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _qualificationControllers['cscs_type']?.text = value ?? '';
                });
              },
            ),
            const SizedBox(height: 16),
            
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _qualificationExpiries['cscs'] ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() => _qualificationExpiries['cscs'] = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'CSCS Expiry',
                  border: OutlineInputBorder(),
                ),
                child: Text(_qualificationExpiries['cscs'] != null
                    ? DateFormat('dd/MM/yyyy').format(_qualificationExpiries['cscs']!)
                    : 'Select expiry date'),
              ),
            ),
            const SizedBox(height: 24),
            
            // Other qualifications checkboxes
            CheckboxListTile(
              title: const Text('First Aid at Work'),
              value: _qualificationFlags['first_aid_work'] ?? false,
              onChanged: (value) => setState(() => _qualificationFlags['first_aid_work'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Asbestos Awareness'),
              value: _qualificationFlags['asbestos'] ?? false,
              onChanged: (value) => setState(() => _qualificationFlags['asbestos'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Working at Height / Harness'),
              value: _qualificationFlags['working_at_height'] ?? false,
              onChanged: (value) => setState(() => _qualificationFlags['working_at_height'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('PASMA'),
              value: _qualificationFlags['pasma'] ?? false,
              onChanged: (value) => setState(() => _qualificationFlags['pasma'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Confined Spaces'),
              value: _qualificationFlags['confined_spaces'] ?? false,
              onChanged: (value) => setState(() => _qualificationFlags['confined_spaces'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Manual Handling'),
              value: _qualificationFlags['manual_handling'] ?? false,
              onChanged: (value) => setState(() => _qualificationFlags['manual_handling'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Fire Marshall'),
              value: _qualificationFlags['fire_marshall'] ?? false,
              onChanged: (value) => setState(() => _qualificationFlags['fire_marshall'] = value ?? false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return Form(
      key: _formKeys[2],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Policies Issued & Acknowledged',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Please acknowledge that you have received, read and understood the following policies:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            CheckboxListTile(
              title: const Text('Health & Safety Policy'),
              value: _policyAcknowledged['health_safety'] ?? false,
              onChanged: (value) => setState(() => _policyAcknowledged['health_safety'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Drugs & Alcohol Policy'),
              value: _policyAcknowledged['drugs_alcohol'] ?? false,
              onChanged: (value) => setState(() => _policyAcknowledged['drugs_alcohol'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Environmental Policy'),
              value: _policyAcknowledged['environmental'] ?? false,
              onChanged: (value) => setState(() => _policyAcknowledged['environmental'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Equality & Diversity'),
              value: _policyAcknowledged['equality_diversity'] ?? false,
              onChanged: (value) => setState(() => _policyAcknowledged['equality_diversity'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Disciplinary & Grievance'),
              value: _policyAcknowledged['disciplinary'] ?? false,
              onChanged: (value) => setState(() => _policyAcknowledged['disciplinary'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Quality Policy'),
              value: _policyAcknowledged['quality'] ?? false,
              onChanged: (value) => setState(() => _policyAcknowledged['quality'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Anti-Bullying & Harassment'),
              value: _policyAcknowledged['anti_bullying'] ?? false,
              onChanged: (value) => setState(() => _policyAcknowledged['anti_bullying'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Data Protection & Confidentiality'),
              value: _policyAcknowledged['data_protection'] ?? false,
              onChanged: (value) => setState(() => _policyAcknowledged['data_protection'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('Company Vehicle / Fuel Card Policy'),
              value: _policyAcknowledged['vehicle'] ?? false,
              onChanged: (value) => setState(() => _policyAcknowledged['vehicle'] = value ?? false),
            ),
            
            CheckboxListTile(
              title: const Text('IT / Email / Social Media Policy'),
              value: _policyAcknowledged['it_social'] ?? false,
              onChanged: (value) => setState(() => _policyAcknowledged['it_social'] = value ?? false),
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                'I confirm I have received, read and understood the above policies and agree to comply with them while working for / with Staff4dshire Properties Ltd.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom TextInputFormatter for sort code (XX-XX-XX)
class _SortCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    if (text.length <= 2) {
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } else if (text.length <= 4) {
      return TextEditingValue(
        text: '${text.substring(0, 2)}-${text.substring(2)}',
        selection: TextSelection.collapsed(offset: text.length + 1),
      );
    } else {
      return TextEditingValue(
        text: '${text.substring(0, 2)}-${text.substring(2, 4)}-${text.substring(4, text.length > 6 ? 6 : text.length)}',
        selection: TextSelection.collapsed(offset: text.length + 2 > 8 ? 8 : text.length + 2),
      );
    }
  }
}

