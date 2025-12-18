enum JobCompletionStatus {
  pending,    // Waiting for supervisor approval
  approved,    // Supervisor approved
  rejected,    // Supervisor rejected
  invoiced,    // Invoice has been generated
}

class JobCompletion {
  final String id;
  final String timeEntryId;
  final String projectId;
  final String userId;
  final bool isCompleted;
  final String? completionReason; // Required if isCompleted = false
  final String? completionImageUrl; // For callout jobs
  final JobCompletionStatus status;
  final String? approvedBy; // Supervisor ID
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  JobCompletion({
    required this.id,
    required this.timeEntryId,
    required this.projectId,
    required this.userId,
    required this.isCompleted,
    this.completionReason,
    this.completionImageUrl,
    this.status = JobCompletionStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory JobCompletion.fromJson(Map<String, dynamic> json) {
    JobCompletionStatus status = JobCompletionStatus.pending;
    final statusStr = (json['status'] as String? ?? 'pending').toLowerCase();
    switch (statusStr) {
      case 'approved':
        status = JobCompletionStatus.approved;
        break;
      case 'rejected':
        status = JobCompletionStatus.rejected;
        break;
      case 'invoiced':
        status = JobCompletionStatus.invoiced;
        break;
      default:
        status = JobCompletionStatus.pending;
    }

    return JobCompletion(
      id: json['id'] as String,
      timeEntryId: json['time_entry_id'] as String? ?? json['timeEntryId'] as String,
      projectId: json['project_id'] as String? ?? json['projectId'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      isCompleted: json['is_completed'] as bool? ?? json['isCompleted'] as bool,
      completionReason: json['completion_reason'] as String? ?? json['completionReason'] as String?,
      completionImageUrl: json['completion_image_url'] as String? ?? json['completionImageUrl'] as String?,
      status: status,
      approvedBy: json['approved_by'] as String? ?? json['approvedBy'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : (json['approvedAt'] != null ? DateTime.parse(json['approvedAt'] as String) : null),
      rejectionReason: json['rejection_reason'] as String? ?? json['rejectionReason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : (json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    String statusStr = 'pending';
    switch (status) {
      case JobCompletionStatus.approved:
        statusStr = 'approved';
        break;
      case JobCompletionStatus.rejected:
        statusStr = 'rejected';
        break;
      case JobCompletionStatus.invoiced:
        statusStr = 'invoiced';
        break;
      default:
        statusStr = 'pending';
    }

    return {
      'id': id,
      'time_entry_id': timeEntryId,
      'project_id': projectId,
      'user_id': userId,
      'is_completed': isCompleted,
      'completion_reason': completionReason,
      'completion_image_url': completionImageUrl,
      'status': statusStr,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  JobCompletion copyWith({
    String? id,
    String? timeEntryId,
    String? projectId,
    String? userId,
    bool? isCompleted,
    String? completionReason,
    String? completionImageUrl,
    JobCompletionStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobCompletion(
      id: id ?? this.id,
      timeEntryId: timeEntryId ?? this.timeEntryId,
      projectId: projectId ?? this.projectId,
      userId: userId ?? this.userId,
      isCompleted: isCompleted ?? this.isCompleted,
      completionReason: completionReason ?? this.completionReason,
      completionImageUrl: completionImageUrl ?? this.completionImageUrl,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


