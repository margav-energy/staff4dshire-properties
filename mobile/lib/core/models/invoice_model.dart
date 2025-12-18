enum InvoiceStatus {
  pending,   // Invoice created but not sent
  sent,      // Invoice sent to client
  paid,      // Invoice paid
  cancelled, // Invoice cancelled
}

class Invoice {
  final String id;
  final String invoiceNumber; // Auto-generated (e.g., INV-2024-001)
  final String projectId;
  final String? timeEntryId;
  final String? jobCompletionId;
  final String staffId;
  final String? supervisorId; // Supervisor who approved
  final double amount;
  final double? hoursWorked;
  final double? hourlyRate;
  final String? description;
  final InvoiceStatus status;
  final bool isPaid;
  final DateTime? paidAt;
  final String? paidBy; // Admin ID who marked as paid
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  String get formattedAmount => '£${amount.toStringAsFixed(2)}';
  String get statusLabel {
    switch (status) {
      case InvoiceStatus.pending:
        return 'Pending';
      case InvoiceStatus.sent:
        return 'Sent';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.projectId,
    this.timeEntryId,
    this.jobCompletionId,
    required this.staffId,
    this.supervisorId,
    required this.amount,
    this.hoursWorked,
    this.hourlyRate,
    this.description,
    this.status = InvoiceStatus.pending,
    this.isPaid = false,
    this.paidAt,
    this.paidBy,
    this.dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Invoice.fromJson(Map<String, dynamic> json) {
    InvoiceStatus status = InvoiceStatus.pending;
    final statusStr = (json['status'] as String? ?? 'pending').toLowerCase();
    switch (statusStr) {
      case 'sent':
        status = InvoiceStatus.sent;
        break;
      case 'paid':
        status = InvoiceStatus.paid;
        break;
      case 'cancelled':
        status = InvoiceStatus.cancelled;
        break;
      default:
        status = InvoiceStatus.pending;
    }

    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String? ?? json['invoiceNumber'] as String,
      projectId: json['project_id'] as String? ?? json['projectId'] as String,
      timeEntryId: json['time_entry_id'] as String? ?? json['timeEntryId'] as String?,
      jobCompletionId: json['job_completion_id'] as String? ?? json['jobCompletionId'] as String?,
      staffId: json['staff_id'] as String? ?? json['staffId'] as String,
      supervisorId: json['supervisor_id'] as String? ?? json['supervisorId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      hoursWorked: json['hours_worked'] != null ? (json['hours_worked'] as num).toDouble() : null,
      hourlyRate: json['hourly_rate'] != null ? (json['hourly_rate'] as num).toDouble() : null,
      description: json['description'] as String?,
      status: status,
      isPaid: json['is_paid'] as bool? ?? json['isPaid'] as bool? ?? false,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : (json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null),
      paidBy: json['paid_by'] as String? ?? json['paidBy'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : (json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null),
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
      case InvoiceStatus.sent:
        statusStr = 'sent';
        break;
      case InvoiceStatus.paid:
        statusStr = 'paid';
        break;
      case InvoiceStatus.cancelled:
        statusStr = 'cancelled';
        break;
      default:
        statusStr = 'pending';
    }

    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'project_id': projectId,
      'time_entry_id': timeEntryId,
      'job_completion_id': jobCompletionId,
      'staff_id': staffId,
      'supervisor_id': supervisorId,
      'amount': amount,
      'hours_worked': hoursWorked,
      'hourly_rate': hourlyRate,
      'description': description,
      'status': statusStr,
      'is_paid': isPaid,
      'paid_at': paidAt?.toIso8601String(),
      'paid_by': paidBy,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? projectId,
    String? timeEntryId,
    String? jobCompletionId,
    String? staffId,
    String? supervisorId,
    double? amount,
    double? hoursWorked,
    double? hourlyRate,
    String? description,
    InvoiceStatus? status,
    bool? isPaid,
    DateTime? paidAt,
    String? paidBy,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      projectId: projectId ?? this.projectId,
      timeEntryId: timeEntryId ?? this.timeEntryId,
      jobCompletionId: jobCompletionId ?? this.jobCompletionId,
      staffId: staffId ?? this.staffId,
      supervisorId: supervisorId ?? this.supervisorId,
      amount: amount ?? this.amount,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      description: description ?? this.description,
      status: status ?? this.status,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      paidBy: paidBy ?? this.paidBy,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}


