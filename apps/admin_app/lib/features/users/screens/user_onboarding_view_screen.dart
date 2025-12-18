import 'package:flutter/material.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:intl/intl.dart';
import 'package:staff4dshire_shared/shared.dart';
class UserOnboardingViewScreen extends StatefulWidget {
  final UserModel user;

  const UserOnboardingViewScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserOnboardingViewScreen> createState() => _UserOnboardingViewScreenState();
}

class _UserOnboardingViewScreenState extends State<UserOnboardingViewScreen> {
  bool _isLoading = true;
  OnboardingNewStarterDetails? _newStarterDetails;
  CisOnboarding? _cisOnboarding;
  OnboardingProgress? _progress;
  Map<String, dynamic>? _qualifications;
  Map<String, dynamic>? _policies;

  @override
  void initState() {
    super.initState();
    _loadOnboardingData();
  }

  Future<void> _loadOnboardingData() async {
    setState(() => _isLoading = true);
    
    final onboardingProvider = Provider.of<OnboardingProvider>(context, listen: false);
    
    try {
      // Try loading regular onboarding first
      await onboardingProvider.loadProgress(widget.user.id);
      _progress = onboardingProvider.progress;
      
      if (_progress != null && _progress!.step1Completed) {
        await onboardingProvider.loadNewStarterDetails(widget.user.id);
        _newStarterDetails = onboardingProvider.newStarterDetails;
      }
      
      // Also try loading CIS onboarding
      await onboardingProvider.loadCisOnboarding(widget.user.id);
      _cisOnboarding = onboardingProvider.cisOnboarding;
      
      // Load qualifications and policies if employee onboarding
      if (_progress != null && _progress!.step1Completed) {
        await onboardingProvider.loadQualifications(widget.user.id);
        await onboardingProvider.loadPolicies(widget.user.id);
        _qualifications = onboardingProvider.qualifications;
        _policies = onboardingProvider.policies;
      }
    } catch (e) {
      debugPrint('Error loading onboarding data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Onboarding: ${widget.user.fullName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Show onboarding status
                  _buildStatusCard(theme),
                  
                  const SizedBox(height: 24),
                  
                  // Show appropriate onboarding form data
                  if (_cisOnboarding != null && _cisOnboarding!.isComplete)
                    _buildCisOnboardingView(theme)
                  else if (_newStarterDetails != null)
                    _buildEmployeeOnboardingView(theme, _qualifications, _policies)
                  else
                    _buildNoOnboardingView(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final hasCisData = _cisOnboarding != null && _cisOnboarding!.isComplete;
    final hasEmployeeData = _newStarterDetails != null;
    
    return Card(
      color: hasCisData || hasEmployeeData
          ? Colors.green.shade50
          : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              hasCisData || hasEmployeeData
                  ? Icons.check_circle
                  : Icons.pending,
              color: hasCisData || hasEmployeeData
                  ? Colors.green
                  : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasCisData || hasEmployeeData
                        ? 'Onboarding Complete'
                        : 'Onboarding Pending',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasCisData
                        ? 'CIS Subcontractor Form'
                        : hasEmployeeData
                            ? 'Employee Onboarding Form'
                            : 'No onboarding data submitted yet',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOnboardingView(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Onboarding Data',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This user has not completed onboarding yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCisOnboardingView(ThemeData theme) {
    final cis = _cisOnboarding!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CIS Subcontractor Onboarding Details',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Basic Details
        _buildSection(
          theme,
          '1. Basic Details',
          [
            _buildInfoRow('Name', cis.name),
            _buildInfoRow('Known As', cis.knownAs),
            _buildInfoRow('Trade', cis.trade),
            _buildInfoRow('Site', cis.site),
            _buildInfoRow('Start Date', cis.startDate != null ? DateFormat('dd/MM/yyyy').format(cis.startDate!) : null),
            _buildInfoRow('Supervisor', cis.supervisor),
            _buildInfoRow('Mobile', cis.mobile),
            _buildInfoRow('Email', cis.email),
          ],
        ),
        
        // CIS/Company Details
        _buildSection(
          theme,
          '2. CIS / Company Details',
          [
            _buildInfoRow('Company Status', cis.companyStatus),
            _buildInfoRow('UTR', cis.utr),
            _buildInfoRow('CIS Status', cis.cisStatus),
            if (cis.companyStatus == 'ltd_company') ...[
              _buildInfoRow('Company Name', cis.grossCompanyName),
              _buildInfoRow('Company Number', cis.companyNumber),
            ],
            _buildInfoRow('Bank', cis.bankName),
            _buildInfoRow('Sort Code', cis.sortCode),
            _buildInfoRow('Account Number', cis.accountNumber),
          ],
        ),
        
        // Right to Work & CSCS
        _buildSection(
          theme,
          '3. Right to Work & CSCS',
          [
            _buildInfoRow('Nationality', cis.nationality),
            _buildInfoRow('Right to Work in UK', cis.rightToWorkUk != null ? (cis.rightToWorkUk! ? 'Yes' : 'No') : null),
            _buildInfoRow('ID Documents Seen', cis.idSeen?.join(', ')),
            if (cis.idOther != null) _buildInfoRow('ID Other', cis.idOther),
            _buildInfoRow('CSCS Type', cis.cscsType),
            _buildInfoRow('CSCS Card Number', cis.cscsCardNumber),
            _buildInfoRow('CSCS Expiry', cis.cscsExpiry != null ? DateFormat('dd/MM/yyyy').format(cis.cscsExpiry!) : null),
          ],
        ),
        
        // Key Tickets
        _buildSection(
          theme,
          '4. Key Tickets',
          [
            _buildInfoRow('CPCS/NPORS Plant', cis.cpcsNporsPlant),
            _buildInfoRow('CPCS/NPORS Expiry', cis.cpcsNporsExpiry != null ? DateFormat('dd/MM/yyyy').format(cis.cpcsNporsExpiry!) : null),
            _buildInfoRow('Working at Height', cis.workingAtHeight ? 'Yes' : 'No'),
            _buildInfoRow('PASMA', cis.pasma ? 'Yes' : 'No'),
            _buildInfoRow('Asbestos Awareness', cis.asbestosAwareness ? 'Yes' : 'No'),
            _buildInfoRow('First Aid', cis.firstAid ? 'Yes' : 'No'),
            _buildInfoRow('Manual Handling', cis.manualHandling ? 'Yes' : 'No'),
            if (cis.otherTickets != null) _buildInfoRow('Other Tickets', cis.otherTickets),
          ],
        ),
        
        // Emergency Contact
        _buildSection(
          theme,
          '5. Emergency Contact',
          [
            _buildInfoRow('Name', cis.emergencyContactName),
            _buildInfoRow('Relationship', cis.emergencyContactRelationship),
            _buildInfoRow('Mobile', cis.emergencyContactMobile),
            _buildInfoRow('Type', cis.emergencyContactType),
          ],
        ),
        
        // Medical
        _buildSection(
          theme,
          '6. Medical',
          [
            _buildInfoRow('Fit to Work', cis.fitToWork != null ? (cis.fitToWork! ? 'Yes' : 'No') : null),
            if (cis.medicalNotes != null) _buildInfoRow('Medical Notes', cis.medicalNotes),
          ],
        ),
        
        // Site Induction
        if (cis.siteRulesExplained || cis.signInOutExplained || cis.firePointsExplained)
          _buildSection(
            theme,
            '7. Quick Site Induction',
            [
              _buildInfoRow('Site Rules Explained', cis.siteRulesExplained ? 'Yes' : 'No'),
              _buildInfoRow('Sign In/Out Explained', cis.signInOutExplained ? 'Yes' : 'No'),
              _buildInfoRow('Fire Points Explained', cis.firePointsExplained ? 'Yes' : 'No'),
              _buildInfoRow('First Aid Explained', cis.firstAidExplained ? 'Yes' : 'No'),
              _buildInfoRow('RAMS Explained', cis.ramsExplained ? 'Yes' : 'No'),
              _buildInfoRow('PPE Checked', cis.ppeChecked ? 'Yes' : 'No'),
              if (cis.extraPpeNotes != null) _buildInfoRow('Extra PPE Notes', cis.extraPpeNotes),
            ],
          ),
        
        // Declaration
        if (cis.subcontractorNamePrint != null)
          _buildSection(
            theme,
            '9. Declaration',
            [
              _buildInfoRow('Subcontractor Name', cis.subcontractorNamePrint),
              _buildInfoRow('Subcontractor Signed Date', cis.subcontractorSignedDate != null ? DateFormat('dd/MM/yyyy').format(cis.subcontractorSignedDate!) : null),
              if (cis.siteManagerNamePrint != null) _buildInfoRow('Site Manager Name', cis.siteManagerNamePrint),
              if (cis.siteManagerSignedDate != null) _buildInfoRow('Site Manager Signed Date', DateFormat('dd/MM/yyyy').format(cis.siteManagerSignedDate!)),
            ],
          ),
      ],
    );
  }

  Widget _buildEmployeeOnboardingView(ThemeData theme, Map<String, dynamic>? qualifications, Map<String, dynamic>? policies) {
    final details = _newStarterDetails!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Employee Onboarding Details',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // New Starter Details
        _buildSection(
          theme,
          '1. New Starter Details',
          [
            _buildInfoRow('Position', details.position),
            _buildInfoRow('Site/Office', details.siteOffice),
            _buildInfoRow('Start Date', details.startDate != null ? DateFormat('dd/MM/yyyy').format(details.startDate!) : null),
            _buildInfoRow('Employment Type', details.employmentType),
            _buildInfoRow('Known As', details.knownAs),
            _buildInfoRow('Date of Birth', details.dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(details.dateOfBirth!) : null),
            _buildInfoRow('NI Number', details.niNumber),
            _buildInfoRow('Address', details.address),
            _buildInfoRow('Postcode', details.postcode),
            _buildInfoRow('Mobile', details.mobile),
            _buildInfoRow('Email', details.email),
          ],
        ),
        
        // Emergency Contact
        _buildSection(
          theme,
          'Emergency Contact',
          [
            _buildInfoRow('Primary Contact Name', details.emergencyContactName),
            _buildInfoRow('Relationship', details.emergencyContactRelationship),
            _buildInfoRow('Mobile', details.emergencyContactMobile),
            _buildInfoRow('Type', details.emergencyContactType),
            if (details.secondaryContactName != null) _buildInfoRow('Secondary Contact Name', details.secondaryContactName),
            if (details.secondaryContactMobile != null) _buildInfoRow('Secondary Contact Mobile', details.secondaryContactMobile),
          ],
        ),
        
        // Right to Work
        _buildSection(
          theme,
          'Right to Work (UK)',
          [
            _buildInfoRow('Nationality', details.nationality),
            _buildInfoRow('Right to Work in UK', details.rightToWorkUk != null ? (details.rightToWorkUk! ? 'Yes' : 'No') : null),
            _buildInfoRow('ID Documents Seen', details.rightToWorkDocsSeen?.join(', ')),
            if (details.rightToWorkOther != null) _buildInfoRow('ID Other', details.rightToWorkOther),
            if (details.rightToWorkCheckedBy != null) _buildInfoRow('Checked By', details.rightToWorkCheckedBy),
            if (details.rightToWorkCheckedDate != null) _buildInfoRow('Checked Date', DateFormat('dd/MM/yyyy').format(details.rightToWorkCheckedDate!)),
          ],
        ),
        
        // Payroll & Tax (if employee)
        if (details.employmentType == 'employee')
          _buildSection(
            theme,
            'Payroll & Tax',
            [
              _buildInfoRow('Bank', details.bankName),
              _buildInfoRow('Sort Code', details.sortCode),
              _buildInfoRow('Account Number', details.accountNumber),
              _buildInfoRow('Payroll Number', details.payrollNumber),
              _buildInfoRow('Worked This Tax Year', details.workedThisTaxYear != null ? (details.workedThisTaxYear! ? 'Yes' : 'No') : null),
              _buildInfoRow('P45 Provided', details.p45Provided != null ? (details.p45Provided! ? 'Yes' : 'No') : null),
            ],
          ),
        
        // CIS Details (if subcontractor)
        if (details.employmentType == 'subcontractor_cis')
          _buildSection(
            theme,
            'CIS Subcontractor Details',
            [
              _buildInfoRow('UTR', details.utr),
              _buildInfoRow('CIS Status', details.cisStatus),
              _buildInfoRow('Company Name', details.grossCompanyName),
              _buildInfoRow('Company Number', details.companyNumber),
            ],
          ),
        
        // Medical / Fitness
        _buildSection(
          theme,
          'Medical / Fitness for Work',
          [
            _buildInfoRow('Fit to Carry Out Role Safely', details.fitForRole != null ? (details.fitForRole! ? 'Yes' : 'No') : null),
            if (details.medicalConditions != null) _buildInfoRow('Medical Conditions', details.medicalConditions),
            if (details.medicationDetails != null) _buildInfoRow('Medication Details', details.medicationDetails),
          ],
        ),
        
        // Qualifications
        if (qualifications != null)
          _buildSection(
            theme,
            '2. Qualifications, Tickets & Competencies',
            [
              if (qualifications['cscs_type'] != null) _buildInfoRow('CSCS Type', qualifications['cscs_type']),
              if (qualifications['cscs_expiry'] != null) _buildInfoRow('CSCS Expiry', qualifications['cscs_expiry']),
              if (qualifications['cpcs_npors_types'] != null) _buildInfoRow('CPCS/NPORS Types', qualifications['cpcs_npors_types']),
              if (qualifications['cpcs_npors_expiry'] != null) _buildInfoRow('CPCS/NPORS Expiry', qualifications['cpcs_npors_expiry']),
              if (qualifications['sssts_expiry'] != null) _buildInfoRow('SSSTS Expiry', qualifications['sssts_expiry']),
              if (qualifications['smsts_expiry'] != null) _buildInfoRow('SMSTS Expiry', qualifications['smsts_expiry']),
              _buildInfoRow('First Aid at Work', qualifications['first_aid_work'] == true ? 'Yes' : 'No'),
              if (qualifications['first_aid_emergency_expiry'] != null) _buildInfoRow('Emergency First Aid Expiry', qualifications['first_aid_emergency_expiry']),
              _buildInfoRow('Asbestos Awareness', qualifications['asbestos_awareness'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Working at Height', qualifications['working_at_height'] == true ? 'Yes' : 'No'),
              _buildInfoRow('PASMA', qualifications['pasma'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Confined Spaces', qualifications['confined_spaces'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Manual Handling', qualifications['manual_handling'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Fire Marshall', qualifications['fire_marshall'] == true ? 'Yes' : 'No'),
              if (qualifications['other_qualifications'] != null) _buildInfoRow('Other', qualifications['other_qualifications']),
            ],
          ),
        
        // Policies
        if (policies != null)
          _buildSection(
            theme,
            '5. Policies Acknowledged',
            [
              _buildInfoRow('Health & Safety Policy', policies['health_safety_policy'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Drugs & Alcohol Policy', policies['drugs_alcohol_policy'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Environmental Policy', policies['environmental_policy'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Equality & Diversity', policies['equality_diversity'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Disciplinary & Grievance', policies['disciplinary_grievance'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Quality Policy', policies['quality_policy'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Anti-Bullying & Harassment', policies['anti_bullying_harassment'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Data Protection & Confidentiality', policies['data_protection_confidentiality'] == true ? 'Yes' : 'No'),
              _buildInfoRow('Vehicle/Fuel Card Policy', policies['vehicle_fuel_card_policy'] == true ? 'Yes' : 'No'),
              _buildInfoRow('IT/Email/Social Media Policy', policies['it_email_social_media_policy'] == true ? 'Yes' : 'No'),
              if (policies['acknowledged_name'] != null) _buildInfoRow('Acknowledged By', policies['acknowledged_name']),
              if (policies['acknowledged_date'] != null) _buildInfoRow('Acknowledged Date', policies['acknowledged_date']),
            ],
          ),
        
        // Progress Status
        if (_progress != null)
          _buildSection(
            theme,
            'Onboarding Progress',
            [
              _buildInfoRow('Step 1 Completed', _progress!.step1Completed ? 'Yes' : 'No'),
              _buildInfoRow('Step 2 Completed', _progress!.step2Completed ? 'Yes' : 'No'),
              _buildInfoRow('Step 5 Completed', _progress!.step5Completed ? 'Yes' : 'No'),
              _buildInfoRow('Current Step', _progress!.currentStep.toString()),
              _buildInfoRow('Complete', _progress!.isComplete ? 'Yes' : 'No'),
            ],
          ),
      ],
    );
  }

  Widget _buildSection(ThemeData theme, String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

