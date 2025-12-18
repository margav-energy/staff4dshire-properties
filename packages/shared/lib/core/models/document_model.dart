enum DocumentType {
  driverLicense,
  compliance,
  accreditation,
  cscs,
  healthSafety,
  insurance,
  cpp,
  rams,
  other,
}

class Document {
  final String id;
  final String name;
  final DocumentType type;
  final DateTime uploadDate;
  final DateTime? expiryDate;
  final String fileUrl;
  final bool isVerified;

  Document({
    required this.id,
    required this.name,
    required this.type,
    required this.uploadDate,
    this.expiryDate,
    required this.fileUrl,
    this.isVerified = false,
  });

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }
}

