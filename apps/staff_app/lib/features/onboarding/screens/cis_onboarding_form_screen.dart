import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:staff4dshire_shared/shared.dart';
class CisOnboardingFormScreen extends StatefulWidget {
  const CisOnboardingFormScreen({super.key});

  @override
  State<CisOnboardingFormScreen> createState() => _CisOnboardingFormScreenState();
}

class _CisOnboardingFormScreenState extends State<CisOnboardingFormScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _knownAsController = TextEditingController();
  final TextEditingController _tradeController = TextEditingController();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _supervisorController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _utrController = TextEditingController();
  final TextEditingController _grossCompanyNameController = TextEditingController();
  final TextEditingController _companyNumberController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _sortCodeController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _nationalityController = TextEditingController();
  final TextEditingController _idOtherController = TextEditingController();
  final TextEditingController _cscsTypeController = TextEditingController();
  final TextEditingController _cscsCardNumberController = TextEditingController();
  final TextEditingController _cpcsNporsPlantController = TextEditingController();
  final TextEditingController _otherTicketsController = TextEditingController();
  final TextEditingController _emergencyContactNameController = TextEditingController();
  final TextEditingController _emergencyContactRelationshipController = TextEditingController();
  final TextEditingController _emergencyContactMobileController = TextEditingController();
  final TextEditingController _medicalNotesController = TextEditingController();
  final TextEditingController _subcontractorNamePrintController = TextEditingController();
  final TextEditingController _siteManagerNamePrintController = TextEditingController();

  DateTime? _startDate;
  DateTime? _cscsExpiry;
  DateTime? _cpcsNporsExpiry;
  DateTime? _subcontractorSignedDate;
  DateTime? _siteManagerSignedDate;

  String? _companyStatus;
  String? _cisStatus;
  bool? _rightToWorkUk;
  List<String> _idSeen = [];
  bool _workingAtHeight = false;
  bool _pasma = false;
  bool _asbestosAwareness = false;
  bool _firstAid = false;
  bool _manualHandling = false;
  String? _emergencyContactType;
  bool? _fitToWork;
  bool _siteRulesExplained = false;
  bool _signInOutExplained = false;
  bool _firePointsExplained = false;
  bool _firstAidExplained = false;
  bool _ramsExplained = false;
  bool _ppeChecked = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      await onboardingProvider.loadCisOnboarding(user.id);
      
      if (onboardingProvider.cisOnboarding != null) {
        final cis = onboardingProvider.cisOnboarding!;
        _nameController.text = cis.name ?? '';
        _knownAsController.text = cis.knownAs ?? '';
        _tradeController.text = cis.trade ?? '';
        _siteController.text = cis.site ?? '';
        _supervisorController.text = cis.supervisor ?? '';
        _mobileController.text = cis.mobile ?? '';
        _emailController.text = cis.email ?? '';
        _utrController.text = cis.utr ?? '';
        _grossCompanyNameController.text = cis.grossCompanyName ?? '';
        _companyNumberController.text = cis.companyNumber ?? '';
        _bankNameController.text = cis.bankName ?? '';
        _sortCodeController.text = cis.sortCode ?? '';
        _accountNumberController.text = cis.accountNumber ?? '';
        _nationalityController.text = cis.nationality ?? '';
        _idOtherController.text = cis.idOther ?? '';
        _cscsTypeController.text = cis.cscsType ?? '';
        _cscsCardNumberController.text = cis.cscsCardNumber ?? '';
        _cpcsNporsPlantController.text = cis.cpcsNporsPlant ?? '';
        _otherTicketsController.text = cis.otherTickets ?? '';
        _emergencyContactNameController.text = cis.emergencyContactName ?? '';
        _emergencyContactRelationshipController.text = cis.emergencyContactRelationship ?? '';
        _emergencyContactMobileController.text = cis.emergencyContactMobile ?? '';
        _medicalNotesController.text = cis.medicalNotes ?? '';
        _subcontractorNamePrintController.text = cis.subcontractorNamePrint ?? '';
        _siteManagerNamePrintController.text = cis.siteManagerNamePrint ?? '';
        
        _startDate = cis.startDate;
        _cscsExpiry = cis.cscsExpiry;
        _cpcsNporsExpiry = cis.cpcsNporsExpiry;
        _subcontractorSignedDate = cis.subcontractorSignedDate;
        _siteManagerSignedDate = cis.siteManagerSignedDate;
        _companyStatus = cis.companyStatus;
        _cisStatus = cis.cisStatus;
        _rightToWorkUk = cis.rightToWorkUk;
        _idSeen = cis.idSeen ?? [];
        _workingAtHeight = cis.workingAtHeight;
        _pasma = cis.pasma;
        _asbestosAwareness = cis.asbestosAwareness;
        _firstAid = cis.firstAid;
        _manualHandling = cis.manualHandling;
        _emergencyContactType = cis.emergencyContactType;
        _fitToWork = cis.fitToWork;
        _siteRulesExplained = cis.siteRulesExplained;
        _signInOutExplained = cis.signInOutExplained;
        _firePointsExplained = cis.firePointsExplained;
        _firstAidExplained = cis.firstAidExplained;
        _ramsExplained = cis.ramsExplained;
        _ppeChecked = cis.ppeChecked;
      } else {
        // Pre-fill email from user account
        _emailController.text = user.email;
        _nameController.text = '${user.firstName} ${user.lastName}';
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _knownAsController.dispose();
    _tradeController.dispose();
    _siteController.dispose();
    _supervisorController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _utrController.dispose();
    _grossCompanyNameController.dispose();
    _companyNumberController.dispose();
    _bankNameController.dispose();
    _sortCodeController.dispose();
    _accountNumberController.dispose();
    _nationalityController.dispose();
    _idOtherController.dispose();
    _cscsTypeController.dispose();
    _cscsCardNumberController.dispose();
    _cpcsNporsPlantController.dispose();
    _otherTicketsController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactRelationshipController.dispose();
    _emergencyContactMobileController.dispose();
    _medicalNotesController.dispose();
    _subcontractorNamePrintController.dispose();
    _siteManagerNamePrintController.dispose();
    super.dispose();
  }

  Future<void> _saveAndComplete() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user == null) return;

    final cisOnboarding = CisOnboarding(
      userId: user.id,
      name: _nameController.text.trim(),
      knownAs: _knownAsController.text.trim(),
      trade: _tradeController.text.trim(),
      site: _siteController.text.trim(),
      startDate: _startDate,
      supervisor: _supervisorController.text.trim(),
      mobile: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      companyStatus: _companyStatus,
      utr: _utrController.text.trim(),
      cisStatus: _cisStatus,
      grossCompanyName: _grossCompanyNameController.text.trim(),
      companyNumber: _companyNumberController.text.trim(),
      bankName: _bankNameController.text.trim(),
      sortCode: _sortCodeController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      nationality: _nationalityController.text.trim(),
      rightToWorkUk: _rightToWorkUk,
      idSeen: _idSeen,
      idOther: _idOtherController.text.trim(),
      cscsType: _cscsTypeController.text.trim(),
      cscsCardNumber: _cscsCardNumberController.text.trim(),
      cscsExpiry: _cscsExpiry,
      cpcsNporsPlant: _cpcsNporsPlantController.text.trim(),
      cpcsNporsExpiry: _cpcsNporsExpiry,
      workingAtHeight: _workingAtHeight,
      pasma: _pasma,
      asbestosAwareness: _asbestosAwareness,
      firstAid: _firstAid,
      manualHandling: _manualHandling,
      otherTickets: _otherTicketsController.text.trim(),
      emergencyContactName: _emergencyContactNameController.text.trim(),
      emergencyContactRelationship: _emergencyContactRelationshipController.text.trim(),
      emergencyContactMobile: _emergencyContactMobileController.text.trim(),
      emergencyContactType: _emergencyContactType,
      fitToWork: _fitToWork,
      medicalNotes: _medicalNotesController.text.trim(),
      siteRulesExplained: _siteRulesExplained,
      signInOutExplained: _signInOutExplained,
      firePointsExplained: _firePointsExplained,
      firstAidExplained: _firstAidExplained,
      ramsExplained: _ramsExplained,
      ppeChecked: _ppeChecked,
      subcontractorNamePrint: _subcontractorNamePrintController.text.trim(),
      siteManagerNamePrint: _siteManagerNamePrintController.text.trim(),
      subcontractorSignedDate: _subcontractorSignedDate,
      siteManagerSignedDate: _siteManagerSignedDate,
      isComplete: true,
    );

    final success = await onboardingProvider.saveCisOnboarding(cisOnboarding);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onboarding completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        final role = user.role.toString().split('.').last;
        context.go('/dashboard?role=$role');
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('CIS Subcontractor Onboarding'),
        automaticallyImplyLeading: _currentStep > 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
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
            
            Text(
              'Step ${_currentStep + 1} of 3',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentStep--;
                          });
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _currentStep < 2
                          ? () {
                              if (_formKey.currentState!.validate()) {
                                setState(() {
                                  _currentStep++;
                                });
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            }
                          : _saveAndComplete,
                      child: Text(_currentStep == 2 ? 'Complete' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '1. Basic Details',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name *',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _knownAsController,
            decoration: const InputDecoration(
              labelText: 'Known As',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _tradeController,
            decoration: const InputDecoration(
              labelText: 'Trade *',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _siteController,
            decoration: const InputDecoration(
              labelText: 'Site *',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          
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
                labelText: 'Start Date *',
                border: OutlineInputBorder(),
              ),
              child: Text(_startDate != null
                  ? DateFormat('dd/MM/yyyy').format(_startDate!)
                  : 'Select start date'),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _supervisorController,
            decoration: const InputDecoration(
              labelText: 'Supervisor',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _mobileController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile *',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email *',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
          ),
          
          const SizedBox(height: 32),
          
          Text(
            '2. CIS / Company Details',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _companyStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'sole_trader', child: Text('Sole Trader')),
              DropdownMenuItem(value: 'ltd_company', child: Text('LTD Company')),
              DropdownMenuItem(value: 'partnership', child: Text('Partnership')),
            ],
            onChanged: (value) => setState(() => _companyStatus = value),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _utrController,
            decoration: const InputDecoration(
              labelText: 'UTR',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _cisStatus,
            decoration: const InputDecoration(
              labelText: 'CIS',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'registered', child: Text('Registered')),
              DropdownMenuItem(value: 'gross', child: Text('Gross')),
            ],
            onChanged: (value) => setState(() => _cisStatus = value),
          ),
          const SizedBox(height: 16),
          
          if (_companyStatus == 'ltd_company') ...[
            TextFormField(
              controller: _grossCompanyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _companyNumberController,
              decoration: const InputDecoration(
                labelText: 'Company No',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          TextFormField(
            controller: _bankNameController,
            decoration: const InputDecoration(
              labelText: 'Bank',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _sortCodeController,
            decoration: const InputDecoration(
              labelText: 'Sort Code',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _accountNumberController,
            decoration: const InputDecoration(
              labelText: 'Account No',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '3. Right to Work & CSCS',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _nationalityController,
            decoration: const InputDecoration(
              labelText: 'Nationality',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              const Text('Right to work in UK?'),
              const SizedBox(width: 16),
              Row(
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
          const SizedBox(height: 16),
          
          const Text('ID Seen:'),
          CheckboxListTile(
            title: const Text('Passport'),
            value: _idSeen.contains('passport'),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _idSeen.add('passport');
                } else {
                  _idSeen.remove('passport');
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text('BRP'),
            value: _idSeen.contains('brp'),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _idSeen.add('brp');
                } else {
                  _idSeen.remove('brp');
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Share Code'),
            value: _idSeen.contains('share_code'),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _idSeen.add('share_code');
                } else {
                  _idSeen.remove('share_code');
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Birth Cert+NI'),
            value: _idSeen.contains('birth_cert_ni'),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _idSeen.add('birth_cert_ni');
                } else {
                  _idSeen.remove('birth_cert_ni');
                }
              });
            },
          ),
          
          TextFormField(
            controller: _idOtherController,
            decoration: const InputDecoration(
              labelText: 'Other',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _cscsTypeController,
            decoration: const InputDecoration(
              labelText: 'CSCS Type',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _cscsCardNumberController,
            decoration: const InputDecoration(
              labelText: 'CSCS Card No',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _cscsExpiry ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              );
              if (date != null) {
                setState(() => _cscsExpiry = date);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'CSCS Expiry',
                border: OutlineInputBorder(),
              ),
              child: Text(_cscsExpiry != null
                  ? DateFormat('dd/MM/yyyy').format(_cscsExpiry!)
                  : 'Select expiry date'),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            '4. Key Tickets',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _cpcsNporsPlantController,
            decoration: const InputDecoration(
              labelText: 'CPCS / NPORS Plant',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _cpcsNporsExpiry ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
              );
              if (date != null) {
                setState(() => _cpcsNporsExpiry = date);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'CPCS/NPORS Expiry',
                border: OutlineInputBorder(),
              ),
              child: Text(_cpcsNporsExpiry != null
                  ? DateFormat('dd/MM/yyyy').format(_cpcsNporsExpiry!)
                  : 'Select expiry date'),
            ),
          ),
          const SizedBox(height: 16),
          
          CheckboxListTile(
            title: const Text('Working at Height / Harness'),
            value: _workingAtHeight,
            onChanged: (value) => setState(() => _workingAtHeight = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('PASMA'),
            value: _pasma,
            onChanged: (value) => setState(() => _pasma = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('Asbestos Awareness'),
            value: _asbestosAwareness,
            onChanged: (value) => setState(() => _asbestosAwareness = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('First Aid'),
            value: _firstAid,
            onChanged: (value) => setState(() => _firstAid = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('Manual Handling'),
            value: _manualHandling,
            onChanged: (value) => setState(() => _manualHandling = value ?? false),
          ),
          
          TextFormField(
            controller: _otherTicketsController,
            decoration: const InputDecoration(
              labelText: 'Other',
              border: OutlineInputBorder(),
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            '5. Emergency Contact',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _emergencyContactNameController,
            decoration: const InputDecoration(
              labelText: 'Name',
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
              labelText: 'Home/Work',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'home', child: Text('Home')),
              DropdownMenuItem(value: 'work', child: Text('Work')),
            ],
            onChanged: (value) => setState(() => _emergencyContactType = value),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            '6. Medical (Basic)',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              const Text('Fit to work in this role?'),
              const SizedBox(width: 16),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _fitToWork,
                    onChanged: (value) => setState(() => _fitToWork = value),
                  ),
                  const Text('Yes'),
                  Radio<bool>(
                    value: false,
                    groupValue: _fitToWork,
                    onChanged: (value) => setState(() => _fitToWork = value),
                  ),
                  const Text('No'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _medicalNotesController,
            decoration: const InputDecoration(
              labelText: 'Anything we should know for safety / emergencies (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '7. Quick Site Induction',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manager to tick when done',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          
          CheckboxListTile(
            title: const Text('Site rules, start / finish times and breaks explained'),
            value: _siteRulesExplained,
            onChanged: (value) => setState(() => _siteRulesExplained = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('Sign-in / out and visitor rules'),
            value: _signInOutExplained,
            onChanged: (value) => setState(() => _signInOutExplained = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('Fire points, alarms and muster point'),
            value: _firePointsExplained,
            onChanged: (value) => setState(() => _firePointsExplained = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('First aiders and accident reporting'),
            value: _firstAidExplained,
            onChanged: (value) => setState(() => _firstAidExplained = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('RAMS / method statements for your tasks'),
            value: _ramsExplained,
            onChanged: (value) => setState(() => _ramsExplained = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('PPE checked: hard hat, hi-vis, boots, gloves, eye protection'),
            value: _ppeChecked,
            onChanged: (value) => setState(() => _ppeChecked = value ?? false),
          ),
          
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '8. Behaviour & Pay Basics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text('• Respect neighbours, client property and other trades on site.'),
                const Text('• Zero tolerance for drugs, alcohol, abuse or harassment.'),
                const Text('• Timesheets / hours are to be submitted using the agreed system by the deadline each week.'),
                const Text('• Agreed day rate / price work will be confirmed in writing (text/email) before starting.'),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          Text(
            '9. Declaration',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'I confirm that the information I have given is accurate to the best of my knowledge. '
              'I understand Staff4dshire\'s basic site rules and safety expectations and agree to work in line with them. '
              'I will report any accidents, near misses or unsafe conditions immediately.',
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _subcontractorNamePrintController,
            decoration: const InputDecoration(
              labelText: 'Name (Print)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _subcontractorSignedDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _subcontractorSignedDate = date);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              child: Text(_subcontractorSignedDate != null
                  ? DateFormat('dd/MM/yyyy').format(_subcontractorSignedDate!)
                  : 'Select date'),
            ),
          ),
        ],
      ),
    );
  }
}

