enum IncidentSeverity {
  low,
  medium,
  high,
  critical,
}

enum IncidentStatus {
  reported,
  attending,
  fixing,
  tracking,
  resolved,
}

class Incident {
  final String id;
  final String reporterId;
  final String reporterName;
  final String? projectId;
  final String? projectName;
  final String description;
  final String? photoPath; // File path or URL for the photo
  final IncidentSeverity severity;
  final DateTime reportedAt;
  final String? location; // Optional location description
  final double? latitude;
  final double? longitude;
  final IncidentStatus status; // Status of the incident
  final String? assignedTo; // Supervisor or admin assigned to handle
  final String? assignedToName; // Name of the person assigned
  final String? notes; // Additional notes from supervisors/admins
  final DateTime? statusUpdatedAt; // When status was last updated
  final String? statusUpdatedBy; // Who updated the status

  Incident({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    this.projectId,
    this.projectName,
    required this.description,
    this.photoPath,
    this.severity = IncidentSeverity.medium,
    DateTime? reportedAt,
    this.location,
    this.latitude,
    this.longitude,
    this.status = IncidentStatus.reported,
    this.assignedTo,
    this.assignedToName,
    this.notes,
    this.statusUpdatedAt,
    this.statusUpdatedBy,
  }) : reportedAt = reportedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'projectId': projectId,
      'projectName': projectName,
      'description': description,
      'photoPath': photoPath,
      'severity': severity.toString().split('.').last,
      'reportedAt': reportedAt.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'status': status.toString().split('.').last,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'notes': notes,
      'statusUpdatedAt': statusUpdatedAt?.toIso8601String(),
      'statusUpdatedBy': statusUpdatedBy,
    };
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    IncidentSeverity severity = IncidentSeverity.medium;
    if (json['severity'] != null) {
      final severityStr = json['severity'] as String;
      severity = IncidentSeverity.values.firstWhere(
        (s) => s.toString().split('.').last == severityStr,
        orElse: () => IncidentSeverity.medium,
      );
    }

    IncidentStatus status = IncidentStatus.reported;
    if (json['status'] != null) {
      final statusStr = json['status'] as String;
      status = IncidentStatus.values.firstWhere(
        (s) => s.toString().split('.').last == statusStr,
        orElse: () => IncidentStatus.reported,
      );
    }

    return Incident(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      reporterName: json['reporterName'] as String,
      projectId: json['projectId'] as String?,
      projectName: json['projectName'] as String?,
      description: json['description'] as String,
      photoPath: json['photoPath'] as String?,
      severity: severity,
      reportedAt: json['reportedAt'] != null
          ? DateTime.parse(json['reportedAt'] as String)
          : DateTime.now(),
      location: json['location'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      status: status,
      assignedTo: json['assignedTo'] as String?,
      assignedToName: json['assignedToName'] as String?,
      notes: json['notes'] as String?,
      statusUpdatedAt: json['statusUpdatedAt'] != null
          ? DateTime.parse(json['statusUpdatedAt'] as String)
          : null,
      statusUpdatedBy: json['statusUpdatedBy'] as String?,
    );
  }

  Incident copyWith({
    String? id,
    String? reporterId,
    String? reporterName,
    String? projectId,
    String? projectName,
    String? description,
    String? photoPath,
    IncidentSeverity? severity,
    DateTime? reportedAt,
    String? location,
    double? latitude,
    double? longitude,
    IncidentStatus? status,
    String? assignedTo,
    String? assignedToName,
    String? notes,
    DateTime? statusUpdatedAt,
    String? statusUpdatedBy,
  }) {
    return Incident(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      severity: severity ?? this.severity,
      reportedAt: reportedAt ?? this.reportedAt,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      notes: notes ?? this.notes,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      statusUpdatedBy: statusUpdatedBy ?? this.statusUpdatedBy,
    );
  }
}

