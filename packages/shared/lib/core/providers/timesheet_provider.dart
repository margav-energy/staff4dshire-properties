import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/timesheet_export_service.dart';

enum ApprovalStatus { pending, approved, rejected }

class TimeEntry {
  final String id;
  final DateTime signInTime;
  final DateTime? signOutTime;
  final String projectId;
  final String projectName;
  final String location;
  final double? latitude;
  final double? longitude;
  final ApprovalStatus approvalStatus;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String staffId;
  final String staffName;
  final String? beforePhoto; // File path for before photo
  final String? afterPhoto; // File path for after photo
  final bool? isFitToWork; // Fit-to-work declaration status
  final String? fitToWorkNotes; // Fit-to-work declaration notes
  final DateTime? fitToWorkDeclaredAt; // When fit-to-work was declared

  TimeEntry({
    required this.id,
    required this.signInTime,
    this.signOutTime,
    required this.projectId,
    required this.projectName,
    required this.location,
    this.latitude,
    this.longitude,
    this.approvalStatus = ApprovalStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.staffId = 'staff1',
    this.staffName = 'Staff Member',
    this.beforePhoto,
    this.afterPhoto,
    this.isFitToWork,
    this.fitToWorkNotes,
    this.fitToWorkDeclaredAt,
  });

  Duration get duration {
    if (signOutTime == null) return Duration.zero;
    return signOutTime!.difference(signInTime);
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'signInTime': signInTime.toIso8601String(),
      'signOutTime': signOutTime?.toIso8601String(),
      'projectId': projectId,
      'projectName': projectName,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'approvalStatus': approvalStatus.toString().split('.').last,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'staffId': staffId,
      'staffName': staffName,
      'beforePhoto': beforePhoto,
      'afterPhoto': afterPhoto,
      'isFitToWork': isFitToWork,
      'fitToWorkNotes': fitToWorkNotes,
      'fitToWorkDeclaredAt': fitToWorkDeclaredAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    ApprovalStatus status = ApprovalStatus.pending;
    if (json['approvalStatus'] != null) {
      final statusStr = json['approvalStatus'] as String;
      status = ApprovalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusStr,
        orElse: () => ApprovalStatus.pending,
      );
    }
    
    return TimeEntry(
      id: json['id'] as String,
      signInTime: DateTime.parse(json['signInTime'] as String),
      signOutTime: json['signOutTime'] != null
          ? DateTime.parse(json['signOutTime'] as String)
          : null,
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      location: json['location'] as String,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      approvalStatus: status,
      approvedBy: json['approvedBy'] as String?,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt'] as String) : null,
      staffId: json['staffId'] as String? ?? json['id'] as String? ?? 'staff1',
      staffName: json['staffName'] as String? ?? 'Staff Member',
      beforePhoto: json['beforePhoto'] as String?,
      afterPhoto: json['afterPhoto'] as String?,
      isFitToWork: json['isFitToWork'] as bool?,
      fitToWorkNotes: json['fitToWorkNotes'] as String?,
      fitToWorkDeclaredAt: json['fitToWorkDeclaredAt'] != null
          ? DateTime.parse(json['fitToWorkDeclaredAt'] as String)
          : null,
    );
  }
  
  // Create a copy with updated fields
  TimeEntry copyWith({
    DateTime? signInTime,
    DateTime? signOutTime,
    String? projectId,
    String? projectName,
    ApprovalStatus? approvalStatus,
    String? approvedBy,
    DateTime? approvedAt,
    String? beforePhoto,
    String? afterPhoto,
  }) {
    return TimeEntry(
      id: id,
      signInTime: signInTime ?? this.signInTime,
      signOutTime: signOutTime ?? this.signOutTime,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      location: location,
      latitude: latitude,
      longitude: longitude,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      staffId: staffId,
      staffName: staffName,
      beforePhoto: beforePhoto ?? this.beforePhoto,
      afterPhoto: afterPhoto ?? this.afterPhoto,
    );
  }
}

class TimesheetProvider extends ChangeNotifier {
  List<TimeEntry> _entries = [];
  bool _isLoading = false;
  static const String _storageKey = 'timesheet_entries';
  bool _initialized = false;

  TimesheetProvider() {
    // Initialize and load from storage on creation
    _initialize();
  }

  List<TimeEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  TimeEntry? get activeEntry {
    if (_entries.isEmpty) return null;
    // Find the most recent entry without sign-out time
    for (var entry in _entries.reversed) {
      if (entry.signOutTime == null) {
        return entry;
      }
    }
    return null;
  }

  bool get hasActiveSignIn => activeEntry != null;

  // Get pending approvals (entries that are completed but not approved)
  List<TimeEntry> getPendingApprovals() {
    return _entries.where((entry) {
      return entry.signOutTime != null && 
             entry.approvalStatus == ApprovalStatus.pending;
    }).toList();
  }

  // Get approved entries
  List<TimeEntry> getApprovedEntries() {
    return _entries.where((entry) {
      return entry.approvalStatus == ApprovalStatus.approved;
    }).toList();
  }

  // Get entries by staff member
  List<TimeEntry> getEntriesByStaff(String staffId) {
    return _entries.where((entry) => entry.staffId == staffId).toList();
  }

  // Approve a timesheet entry
  // Only admin and supervisor roles can approve timesheets
  // Staff cannot approve their own timesheets
  Future<void> approveEntry(
    String entryId, 
    String approvedBy, {
    String? approverId,
    String? approverRole,
  }) async {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index == -1) {
      throw Exception('Timesheet entry not found');
    }
    
    final entry = _entries[index];
    
    // Check if approver is trying to approve their own timesheet
    if (approverId != null && entry.staffId == approverId) {
      throw Exception('You cannot approve your own timesheet entry');
    }
    
    // Check if approver has permission (admin or supervisor only)
    if (approverRole != null) {
      final role = approverRole.toLowerCase();
      if (role != 'admin' && role != 'supervisor' && role != 'superadmin') {
        throw Exception('Only administrators and supervisors can approve timesheet entries');
      }
    }
    
    _entries[index] = _entries[index].copyWith(
      approvalStatus: ApprovalStatus.approved,
      approvedBy: approvedBy,
      approvedAt: DateTime.now(),
    );
    notifyListeners();
    await saveToStorage();
  }

  // Reject a timesheet entry
  Future<void> rejectEntry(String entryId, String rejectedBy) async {
    final index = _entries.indexWhere((e) => e.id == entryId);
    if (index != -1) {
      _entries[index] = _entries[index].copyWith(
        approvalStatus: ApprovalStatus.rejected,
        approvedBy: rejectedBy,
        approvedAt: DateTime.now(),
      );
      notifyListeners();
      await saveToStorage();
    }
  }

  // Initialize and load from storage
  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;
    await loadFromStorage();
  }

  // Public method to re-initialize if needed
  Future<void> initialize() async {
    await _initialize();
  }

  List<TimeEntry> getCurrentWeekEntries() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return _entries.where((entry) {
      return entry.signInTime.isAfter(startOfWeek) &&
          entry.signInTime.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  Duration getTotalHoursForWeek() {
    final weekEntries = getCurrentWeekEntries();
    Duration total = Duration.zero;
    
    for (var entry in weekEntries) {
      total += entry.duration;
    }
    
    return total;
  }

  Future<void> addEntry(TimeEntry entry) async {
    _entries.add(entry);
    notifyListeners();
    await saveToStorage();
  }

  Future<void> updateEntry(String id, TimeEntry updatedEntry) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      _entries[index] = updatedEntry;
      notifyListeners();
      await saveToStorage();
    }
  }

  // Save entries to SharedPreferences
  Future<void> saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = _entries.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(entriesJson));
    } catch (e) {
      debugPrint('Error saving timesheet entries: $e');
    }
  }

  // Load entries from SharedPreferences
  Future<void> loadFromStorage() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final entriesJsonString = prefs.getString(_storageKey);

      if (entriesJsonString != null && entriesJsonString.isNotEmpty) {
        final List<dynamic> entriesJson = jsonDecode(entriesJsonString);
        _entries = entriesJson
            .map((json) => TimeEntry.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading timesheet entries: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear all entries (for testing/logout)
  Future<void> clearAll() async {
    _entries.clear();
    notifyListeners();
    await saveToStorage();
  }

  Future<void> loadTimesheet() async {
    _isLoading = true;
    notifyListeners();

    // Load from storage first
    await loadFromStorage();

    // In a real app, this would also sync with the API
    // For now, we just load from storage

    _isLoading = false;
    notifyListeners();
  }

  Future<void> exportTimesheet(String format, {BuildContext? context}) async {
    try {
      // Get all entries
      if (_entries.isEmpty) {
        throw Exception('No timesheet entries to export');
      }
      
      await TimesheetExportService.exportTimesheet(
        List<TimeEntry>.from(_entries),
        format,
        context,
      );
    } catch (e) {
      debugPrint('Error exporting timesheet: $e');
      rethrow;
    }
  }
}

