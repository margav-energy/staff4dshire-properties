class OnboardingNewStarterDetails {
  final String? id;
  final String userId;
  final String? position;
  final String? siteOffice;
  final DateTime? startDate;
  final String? employmentType; // 'employee', 'subcontractor_cis', 'consultant'
  final String? knownAs;
  final DateTime? dateOfBirth;
  final String? niNumber;
  final String? address;
  final String? postcode;
  final String? mobile;
  final String? email;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactMobile;
  final String? emergencyContactType; // 'home' or 'work'
  final String? secondaryContactName;
  final String? secondaryContactMobile;
  final String? nationality;
  final bool? rightToWorkUk;
  final List<String>? rightToWorkDocsSeen;
  final String? rightToWorkOther;
  final String? rightToWorkCheckedBy;
  final DateTime? rightToWorkCheckedDate;
  // Payroll & Tax (Employees)
  final String? bankName;
  final String? sortCode;
  final String? accountNumber;
  final String? payrollNumber;
  final bool? workedThisTaxYear;
  final bool? p45Provided;
  // CIS Subcontractors
  final String? utr;
  final String? cisStatus; // 'registered' or 'unregistered'
  final String? grossCompanyName;
  final String? companyNumber;
  // Medical / Fitness
  final bool? fitForRole;
  final String? medicalConditions;
  final String? medicationDetails;

  OnboardingNewStarterDetails({
    this.id,
    required this.userId,
    this.position,
    this.siteOffice,
    this.startDate,
    this.employmentType,
    this.knownAs,
    this.dateOfBirth,
    this.niNumber,
    this.address,
    this.postcode,
    this.mobile,
    this.email,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactMobile,
    this.emergencyContactType,
    this.secondaryContactName,
    this.secondaryContactMobile,
    this.nationality,
    this.rightToWorkUk,
    this.rightToWorkDocsSeen,
    this.rightToWorkOther,
    this.rightToWorkCheckedBy,
    this.rightToWorkCheckedDate,
    this.bankName,
    this.sortCode,
    this.accountNumber,
    this.payrollNumber,
    this.workedThisTaxYear,
    this.p45Provided,
    this.utr,
    this.cisStatus,
    this.grossCompanyName,
    this.companyNumber,
    this.fitForRole,
    this.medicalConditions,
    this.medicationDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (position != null) 'position': position,
      if (siteOffice != null) 'site_office': siteOffice,
      if (startDate != null) 'start_date': startDate?.toIso8601String().split('T')[0],
      if (employmentType != null) 'employment_type': employmentType,
      if (knownAs != null) 'known_as': knownAs,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      if (niNumber != null) 'ni_number': niNumber,
      if (address != null) 'address': address,
      if (postcode != null) 'postcode': postcode,
      if (mobile != null) 'mobile': mobile,
      if (email != null) 'email': email,
      if (emergencyContactName != null) 'emergency_contact_name': emergencyContactName,
      if (emergencyContactRelationship != null) 'emergency_contact_relationship': emergencyContactRelationship,
      if (emergencyContactMobile != null) 'emergency_contact_mobile': emergencyContactMobile,
      if (emergencyContactType != null) 'emergency_contact_type': emergencyContactType,
      if (secondaryContactName != null) 'secondary_contact_name': secondaryContactName,
      if (secondaryContactMobile != null) 'secondary_contact_mobile': secondaryContactMobile,
      if (nationality != null) 'nationality': nationality,
      if (rightToWorkUk != null) 'right_to_work_uk': rightToWorkUk,
      if (rightToWorkDocsSeen != null) 'right_to_work_docs_seen': rightToWorkDocsSeen,
      if (rightToWorkOther != null) 'right_to_work_other': rightToWorkOther,
      if (rightToWorkCheckedBy != null) 'right_to_work_checked_by': rightToWorkCheckedBy,
      if (rightToWorkCheckedDate != null) 'right_to_work_checked_date': rightToWorkCheckedDate?.toIso8601String().split('T')[0],
      if (bankName != null) 'bank_name': bankName,
      if (sortCode != null) 'sort_code': sortCode,
      if (accountNumber != null) 'account_number': accountNumber,
      if (payrollNumber != null) 'payroll_number': payrollNumber,
      if (workedThisTaxYear != null) 'worked_this_tax_year': workedThisTaxYear,
      if (p45Provided != null) 'p45_provided': p45Provided,
      if (utr != null) 'utr': utr,
      if (cisStatus != null) 'cis_status': cisStatus,
      if (grossCompanyName != null) 'gross_company_name': grossCompanyName,
      if (companyNumber != null) 'company_number': companyNumber,
      if (fitForRole != null) 'fit_for_role': fitForRole,
      if (medicalConditions != null) 'medical_conditions': medicalConditions,
      if (medicationDetails != null) 'medication_details': medicationDetails,
    };
  }

  factory OnboardingNewStarterDetails.fromJson(Map<String, dynamic> json) {
    return OnboardingNewStarterDetails(
      id: json['id'],
      userId: json['user_id'],
      position: json['position'],
      siteOffice: json['site_office'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      employmentType: json['employment_type'],
      knownAs: json['known_as'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      niNumber: json['ni_number'],
      address: json['address'],
      postcode: json['postcode'],
      mobile: json['mobile'],
      email: json['email'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactRelationship: json['emergency_contact_relationship'],
      emergencyContactMobile: json['emergency_contact_mobile'],
      emergencyContactType: json['emergency_contact_type'],
      secondaryContactName: json['secondary_contact_name'],
      secondaryContactMobile: json['secondary_contact_mobile'],
      nationality: json['nationality'],
      rightToWorkUk: json['right_to_work_uk'],
      rightToWorkDocsSeen: json['right_to_work_docs_seen'] != null
          ? (json['right_to_work_docs_seen'] is List
              ? List<String>.from(json['right_to_work_docs_seen'])
              : json['right_to_work_docs_seen'] is Map
                  ? [json['right_to_work_docs_seen'].toString()]
                  : [])
          : null,
      rightToWorkOther: json['right_to_work_other'],
      rightToWorkCheckedBy: json['right_to_work_checked_by'],
      rightToWorkCheckedDate: json['right_to_work_checked_date'] != null 
          ? DateTime.parse(json['right_to_work_checked_date']) 
          : null,
      bankName: json['bank_name'],
      sortCode: json['sort_code'],
      accountNumber: json['account_number'],
      payrollNumber: json['payroll_number'],
      workedThisTaxYear: json['worked_this_tax_year'],
      p45Provided: json['p45_provided'],
      utr: json['utr'],
      cisStatus: json['cis_status'],
      grossCompanyName: json['gross_company_name'],
      companyNumber: json['company_number'],
      fitForRole: json['fit_for_role'],
      medicalConditions: json['medical_conditions'],
      medicationDetails: json['medication_details'],
    );
  }
}

class OnboardingProgress {
  final String? id;
  final String userId;
  final bool step1Completed;
  final bool step2Completed;
  final bool step3Completed;
  final bool step4Completed;
  final bool step5Completed;
  final bool step6Completed;
  final int currentStep;
  final bool isComplete;

  OnboardingProgress({
    this.id,
    required this.userId,
    this.step1Completed = false,
    this.step2Completed = false,
    this.step3Completed = false,
    this.step4Completed = false,
    this.step5Completed = false,
    this.step6Completed = false,
    this.currentStep = 1,
    this.isComplete = false,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'step_1_completed': step1Completed,
      'step_2_completed': step2Completed,
      'step_3_completed': step3Completed,
      'step_4_completed': step4Completed,
      'step_5_completed': step5Completed,
      'step_6_completed': step6Completed,
      'current_step': currentStep,
      'is_complete': isComplete,
    };
  }

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    return OnboardingProgress(
      id: json['id'],
      userId: json['user_id'],
      step1Completed: json['step_1_completed'] ?? false,
      step2Completed: json['step_2_completed'] ?? false,
      step3Completed: json['step_3_completed'] ?? false,
      step4Completed: json['step_4_completed'] ?? false,
      step5Completed: json['step_5_completed'] ?? false,
      step6Completed: json['step_6_completed'] ?? false,
      currentStep: json['current_step'] ?? 1,
      isComplete: json['is_complete'] ?? false,
    );
  }
}

