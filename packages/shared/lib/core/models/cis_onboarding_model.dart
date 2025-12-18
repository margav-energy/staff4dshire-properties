class CisOnboarding {
  final String? id;
  final String userId;
  
  // Basic Details
  final String? name;
  final String? knownAs;
  final String? trade;
  final String? site;
  final DateTime? startDate;
  final String? supervisor;
  final String? mobile;
  final String? email;
  
  // CIS / Company Details
  final String? companyStatus; // 'sole_trader', 'ltd_company', 'partnership'
  final String? utr;
  final String? cisStatus; // 'registered' or 'gross'
  final String? grossCompanyName;
  final String? companyNumber;
  final String? bankName;
  final String? sortCode;
  final String? accountNumber;
  
  // Right to Work & CSCS
  final String? nationality;
  final bool? rightToWorkUk;
  final List<String>? idSeen;
  final String? idOther;
  final String? cscsType;
  final String? cscsCardNumber;
  final DateTime? cscsExpiry;
  
  // Key Tickets
  final String? cpcsNporsPlant;
  final DateTime? cpcsNporsExpiry;
  final bool workingAtHeight;
  final bool pasma;
  final bool asbestosAwareness;
  final bool firstAid;
  final bool manualHandling;
  final String? otherTickets;
  
  // Emergency Contact
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactMobile;
  final String? emergencyContactType; // 'home' or 'work'
  
  // Medical
  final bool? fitToWork;
  final String? medicalNotes;
  
  // Quick Site Induction (Manager)
  final bool siteRulesExplained;
  final bool signInOutExplained;
  final bool firePointsExplained;
  final bool firstAidExplained;
  final bool ramsExplained;
  final bool ppeChecked;
  final String? extraPpeNotes;
  
  // Declaration
  final String? subcontractorSignature;
  final DateTime? subcontractorSignedDate;
  final String? subcontractorNamePrint;
  final String? siteManagerSignature;
  final DateTime? siteManagerSignedDate;
  final String? siteManagerNamePrint;
  
  final bool isComplete;

  CisOnboarding({
    this.id,
    required this.userId,
    this.name,
    this.knownAs,
    this.trade,
    this.site,
    this.startDate,
    this.supervisor,
    this.mobile,
    this.email,
    this.companyStatus,
    this.utr,
    this.cisStatus,
    this.grossCompanyName,
    this.companyNumber,
    this.bankName,
    this.sortCode,
    this.accountNumber,
    this.nationality,
    this.rightToWorkUk,
    this.idSeen,
    this.idOther,
    this.cscsType,
    this.cscsCardNumber,
    this.cscsExpiry,
    this.cpcsNporsPlant,
    this.cpcsNporsExpiry,
    this.workingAtHeight = false,
    this.pasma = false,
    this.asbestosAwareness = false,
    this.firstAid = false,
    this.manualHandling = false,
    this.otherTickets,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactMobile,
    this.emergencyContactType,
    this.fitToWork,
    this.medicalNotes,
    this.siteRulesExplained = false,
    this.signInOutExplained = false,
    this.firePointsExplained = false,
    this.firstAidExplained = false,
    this.ramsExplained = false,
    this.ppeChecked = false,
    this.extraPpeNotes,
    this.subcontractorSignature,
    this.subcontractorSignedDate,
    this.subcontractorNamePrint,
    this.siteManagerSignature,
    this.siteManagerSignedDate,
    this.siteManagerNamePrint,
    this.isComplete = false,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (name != null) 'name': name,
      if (knownAs != null) 'known_as': knownAs,
      if (trade != null) 'trade': trade,
      if (site != null) 'site': site,
      if (startDate != null) 'start_date': startDate?.toIso8601String().split('T')[0],
      if (supervisor != null) 'supervisor': supervisor,
      if (mobile != null) 'mobile': mobile,
      if (email != null) 'email': email,
      if (companyStatus != null) 'company_status': companyStatus,
      if (utr != null) 'utr': utr,
      if (cisStatus != null) 'cis_status': cisStatus,
      if (grossCompanyName != null) 'gross_company_name': grossCompanyName,
      if (companyNumber != null) 'company_number': companyNumber,
      if (bankName != null) 'bank_name': bankName,
      if (sortCode != null) 'sort_code': sortCode,
      if (accountNumber != null) 'account_number': accountNumber,
      if (nationality != null) 'nationality': nationality,
      if (rightToWorkUk != null) 'right_to_work_uk': rightToWorkUk,
      if (idSeen != null) 'id_seen': idSeen,
      if (idOther != null) 'id_other': idOther,
      if (cscsType != null) 'cscs_type': cscsType,
      if (cscsCardNumber != null) 'cscs_card_number': cscsCardNumber,
      if (cscsExpiry != null) 'cscs_expiry': cscsExpiry?.toIso8601String().split('T')[0],
      if (cpcsNporsPlant != null) 'cpcs_npors_plant': cpcsNporsPlant,
      if (cpcsNporsExpiry != null) 'cpcs_npors_expiry': cpcsNporsExpiry?.toIso8601String().split('T')[0],
      'working_at_height': workingAtHeight,
      'pasma': pasma,
      'asbestos_awareness': asbestosAwareness,
      'first_aid': firstAid,
      'manual_handling': manualHandling,
      if (otherTickets != null) 'other_tickets': otherTickets,
      if (emergencyContactName != null) 'emergency_contact_name': emergencyContactName,
      if (emergencyContactRelationship != null) 'emergency_contact_relationship': emergencyContactRelationship,
      if (emergencyContactMobile != null) 'emergency_contact_mobile': emergencyContactMobile,
      if (emergencyContactType != null) 'emergency_contact_type': emergencyContactType,
      if (fitToWork != null) 'fit_to_work': fitToWork,
      if (medicalNotes != null) 'medical_notes': medicalNotes,
      'site_rules_explained': siteRulesExplained,
      'sign_in_out_explained': signInOutExplained,
      'fire_points_explained': firePointsExplained,
      'first_aid_explained': firstAidExplained,
      'rams_explained': ramsExplained,
      'ppe_checked': ppeChecked,
      if (extraPpeNotes != null) 'extra_ppe_notes': extraPpeNotes,
      if (subcontractorSignature != null) 'subcontractor_signature': subcontractorSignature,
      if (subcontractorSignedDate != null) 'subcontractor_signed_date': subcontractorSignedDate?.toIso8601String().split('T')[0],
      if (subcontractorNamePrint != null) 'subcontractor_name_print': subcontractorNamePrint,
      if (siteManagerSignature != null) 'site_manager_signature': siteManagerSignature,
      if (siteManagerSignedDate != null) 'site_manager_signed_date': siteManagerSignedDate?.toIso8601String().split('T')[0],
      if (siteManagerNamePrint != null) 'site_manager_name_print': siteManagerNamePrint,
      'is_complete': isComplete,
    };
  }

  factory CisOnboarding.fromJson(Map<String, dynamic> json) {
    return CisOnboarding(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      knownAs: json['known_as'],
      trade: json['trade'],
      site: json['site'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      supervisor: json['supervisor'],
      mobile: json['mobile'],
      email: json['email'],
      companyStatus: json['company_status'],
      utr: json['utr'],
      cisStatus: json['cis_status'],
      grossCompanyName: json['gross_company_name'],
      companyNumber: json['company_number'],
      bankName: json['bank_name'],
      sortCode: json['sort_code'],
      accountNumber: json['account_number'],
      nationality: json['nationality'],
      rightToWorkUk: json['right_to_work_uk'],
      idSeen: json['id_seen'] != null ? List<String>.from(json['id_seen']) : null,
      idOther: json['id_other'],
      cscsType: json['cscs_type'],
      cscsCardNumber: json['cscs_card_number'],
      cscsExpiry: json['cscs_expiry'] != null ? DateTime.parse(json['cscs_expiry']) : null,
      cpcsNporsPlant: json['cpcs_npors_plant'],
      cpcsNporsExpiry: json['cpcs_npors_expiry'] != null ? DateTime.parse(json['cpcs_npors_expiry']) : null,
      workingAtHeight: json['working_at_height'] ?? false,
      pasma: json['pasma'] ?? false,
      asbestosAwareness: json['asbestos_awareness'] ?? false,
      firstAid: json['first_aid'] ?? false,
      manualHandling: json['manual_handling'] ?? false,
      otherTickets: json['other_tickets'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactRelationship: json['emergency_contact_relationship'],
      emergencyContactMobile: json['emergency_contact_mobile'],
      emergencyContactType: json['emergency_contact_type'],
      fitToWork: json['fit_to_work'],
      medicalNotes: json['medical_notes'],
      siteRulesExplained: json['site_rules_explained'] ?? false,
      signInOutExplained: json['sign_in_out_explained'] ?? false,
      firePointsExplained: json['fire_points_explained'] ?? false,
      firstAidExplained: json['first_aid_explained'] ?? false,
      ramsExplained: json['rams_explained'] ?? false,
      ppeChecked: json['ppe_checked'] ?? false,
      extraPpeNotes: json['extra_ppe_notes'],
      subcontractorSignature: json['subcontractor_signature'],
      subcontractorSignedDate: json['subcontractor_signed_date'] != null 
          ? DateTime.parse(json['subcontractor_signed_date']) 
          : null,
      subcontractorNamePrint: json['subcontractor_name_print'],
      siteManagerSignature: json['site_manager_signature'],
      siteManagerSignedDate: json['site_manager_signed_date'] != null 
          ? DateTime.parse(json['site_manager_signed_date']) 
          : null,
      siteManagerNamePrint: json['site_manager_name_print'],
      isComplete: json['is_complete'] ?? false,
    );
  }
}

