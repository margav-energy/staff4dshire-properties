enum ProjectType { regular, callout }

class ProjectDrawing {
  final String id;
  final String fileName;
  final String filePath; // File path or URL
  final String fileType; // 'pdf', 'docx', 'png', 'jpeg'
  final int fileSize; // File size in bytes
  final DateTime uploadedAt;

  ProjectDrawing({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    DateTime? uploadedAt,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  factory ProjectDrawing.fromJson(Map<String, dynamic> json) {
    return ProjectDrawing(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileType: json['fileType'] as String,
      fileSize: json['fileSize'] as int,
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class Project {
  final String id;
  final String name;
  final String? address;
  final double? latitude; // Project location latitude
  final double? longitude; // Project location longitude
  final String? description;
  final bool isActive;
  final bool isCompleted;
  final String? beforePhoto; // File path or URL for before photo
  final String? afterPhoto; // File path or URL for after photo
  final DateTime? completedAt;
  final ProjectType type; // Regular or callout project
  final String? category; // Category for regular projects (e.g., "Construction", "Maintenance", "Renovation")
  final List<String> assignedStaffIds; // Staff IDs assigned to this project (admin-assigned)
  final List<String> assignedSupervisorIds; // Supervisor IDs assigned to this project (admin-assigned)
  final List<String> photos; // Minimum 3 photos required
  final List<ProjectDrawing> drawings; // Drawings/files (PDF, DOCX, PNG, JPEG)
  final DateTime? startDate; // Start date - project becomes active when set and in past
  final String? companyId; // Company/organization ID

  Project({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.description,
    this.isActive = false, // Default to inactive
    this.isCompleted = false,
    this.beforePhoto,
    this.afterPhoto,
    this.completedAt,
    this.type = ProjectType.regular,
    this.category,
    List<String>? assignedStaffIds,
    List<String>? assignedSupervisorIds,
    List<String>? photos,
    List<ProjectDrawing>? drawings,
    this.startDate,
    this.companyId,
  }) : assignedStaffIds = assignedStaffIds ?? [],
       assignedSupervisorIds = assignedSupervisorIds ?? [],
       photos = photos ?? [],
       drawings = drawings ?? [];

  factory Project.fromJson(Map<String, dynamic> json) {
    ProjectType projectType = ProjectType.regular;
    if (json['type'] != null) {
      final typeStr = json['type'] as String;
      projectType = typeStr == 'callout' ? ProjectType.callout : ProjectType.regular;
    }
    
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      latitude: json['latitude'] != null 
          ? (json['latitude'] is String 
              ? double.tryParse(json['latitude'] as String) 
              : (json['latitude'] as num).toDouble())
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] is String 
              ? double.tryParse(json['longitude'] as String)
              : (json['longitude'] as num).toDouble())
          : null,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      beforePhoto: json['beforePhoto'] as String?,
      afterPhoto: json['afterPhoto'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      type: projectType,
      category: json['category'] as String?,
      assignedStaffIds: json['assignedStaffIds'] != null
          ? List<String>.from(json['assignedStaffIds'] as List)
          : null,
      assignedSupervisorIds: json['assignedSupervisorIds'] != null
          ? List<String>.from(json['assignedSupervisorIds'] as List)
          : null,
      photos: json['photos'] != null
          ? List<String>.from(json['photos'] as List)
          : null,
      drawings: json['drawings'] != null
          ? (json['drawings'] as List).map((d) => ProjectDrawing.fromJson(d as Map<String, dynamic>)).toList()
          : null,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      companyId: json['company_id'] as String? ?? json['companyId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'isActive': isActive,
      'isCompleted': isCompleted,
      'beforePhoto': beforePhoto,
      'afterPhoto': afterPhoto,
      'completedAt': completedAt?.toIso8601String(),
      'type': type == ProjectType.callout ? 'callout' : 'regular',
      'category': category,
      'assignedStaffIds': assignedStaffIds,
      'assignedSupervisorIds': assignedSupervisorIds,
      'photos': photos,
      'drawings': drawings.map((d) => d.toJson()).toList(),
      'startDate': startDate?.toIso8601String(),
      'company_id': companyId,
    };
  }

  Project copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
    bool? isActive,
    bool? isCompleted,
    String? beforePhoto,
    String? afterPhoto,
    DateTime? completedAt,
    ProjectType? type,
    String? category,
    List<String>? assignedStaffIds,
    List<String>? assignedSupervisorIds,
    List<String>? photos,
    List<ProjectDrawing>? drawings,
    DateTime? startDate,
    String? companyId,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isCompleted: isCompleted ?? this.isCompleted,
      beforePhoto: beforePhoto ?? this.beforePhoto,
      afterPhoto: afterPhoto ?? this.afterPhoto,
      completedAt: completedAt ?? this.completedAt,
      type: type ?? this.type,
      category: category ?? this.category,
      assignedStaffIds: assignedStaffIds ?? this.assignedStaffIds,
      assignedSupervisorIds: assignedSupervisorIds ?? this.assignedSupervisorIds,
      photos: photos ?? this.photos,
      drawings: drawings ?? this.drawings,
      startDate: startDate ?? this.startDate,
      companyId: companyId ?? this.companyId,
    );
  }
}

