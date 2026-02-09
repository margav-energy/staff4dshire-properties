import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/job_completion_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class JobCompletionProvider extends ChangeNotifier {
  static const String _storageKey = 'job_completions_list';
  List<JobCompletion> _completions = [];
  bool _isLoading = false;

  List<JobCompletion> get completions => _completions;
  bool get isLoading => _isLoading;

  // Get completions by status
  List<JobCompletion> getPendingCompletions() {
    return _completions.where((c) => c.status == JobCompletionStatus.pending).toList();
  }

  // Get completions by project
  List<JobCompletion> getCompletionsByProject(String projectId) {
    return _completions.where((c) => c.projectId == projectId).toList();
  }

  // Get completion by time entry
  JobCompletion? getCompletionByTimeEntry(String timeEntryId) {
    try {
      return _completions.firstWhere((c) => c.timeEntryId == timeEntryId);
    } catch (e) {
      return null;
    }
  }

  // Load completions from API or storage
  Future<void> loadCompletions({String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (ApiConfig.isApiEnabled) {
        try {
          // Include userId in query params for company filtering
          final endpoint = userId != null 
              ? '/job-completions?userId=${Uri.encodeComponent(userId)}'
              : '/job-completions';
          final response = await ApiService.get(endpoint);
          if (response is List) {
            _completions = response
                .map((json) => JobCompletion.fromJson(json as Map<String, dynamic>))
                .toList();
            await _saveToStorage();
          }
        } catch (e) {
          debugPrint('Failed to load completions from API: $e');
          await _loadFromStorage();
        }
      } else {
        await _loadFromStorage();
      }
    } catch (e) {
      debugPrint('Error loading completions: $e');
      await _loadFromStorage();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create job completion
  Future<JobCompletion> createCompletion({
    required String timeEntryId,
    required String projectId,
    required String userId,
    required bool isCompleted,
    String? completionReason,
    String? completionImagePath,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = {
        'time_entry_id': timeEntryId,
        'project_id': projectId,
        'user_id': userId,
        'is_completed': isCompleted,
        'completion_reason': completionReason,
        'completion_image_url': completionImagePath,
        'status': 'pending',
      };

      JobCompletion completion;
      if (ApiConfig.isApiEnabled) {
        try {
          final response = await ApiService.post('/job-completions', data);
          completion = JobCompletion.fromJson(response as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Failed to create completion via API: $e');
          // Create locally as fallback
          completion = JobCompletion(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timeEntryId: timeEntryId,
            projectId: projectId,
            userId: userId,
            isCompleted: isCompleted,
            completionReason: completionReason,
            completionImageUrl: completionImagePath,
            status: JobCompletionStatus.pending,
          );
        }
      } else {
        completion = JobCompletion(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          timeEntryId: timeEntryId,
          projectId: projectId,
          userId: userId,
          isCompleted: isCompleted,
          completionReason: completionReason,
          completionImageUrl: completionImagePath,
          status: JobCompletionStatus.pending,
        );
      }

      _completions.add(completion);
      await _saveToStorage();
      _isLoading = false;
      notifyListeners();
      return completion;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Approve completion (supervisor)
  Future<void> approveCompletion(String completionId, String supervisorId) async {
    final index = _completions.indexWhere((c) => c.id == completionId);
    if (index == -1) return;

    try {
      if (ApiConfig.isApiEnabled) {
        try {
          final response = await ApiService.put('/job-completions/$completionId/approve', {
            'approved_by': supervisorId,
          });
          _completions[index] = JobCompletion.fromJson(response as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Failed to approve via API: $e');
          // Update locally
          _completions[index] = _completions[index].copyWith(
            status: JobCompletionStatus.approved,
            approvedBy: supervisorId,
            approvedAt: DateTime.now(),
          );
        }
      } else {
        _completions[index] = _completions[index].copyWith(
          status: JobCompletionStatus.approved,
          approvedBy: supervisorId,
          approvedAt: DateTime.now(),
        );
      }

      await _saveToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('Error approving completion: $e');
      rethrow;
    }
  }

  // Reject completion (supervisor)
  Future<void> rejectCompletion(String completionId, String supervisorId, String reason) async {
    final index = _completions.indexWhere((c) => c.id == completionId);
    if (index == -1) return;

    try {
      if (ApiConfig.isApiEnabled) {
        try {
          final response = await ApiService.put('/job-completions/$completionId/reject', {
            'approved_by': supervisorId,
            'rejection_reason': reason,
          });
          _completions[index] = JobCompletion.fromJson(response as Map<String, dynamic>);
        } catch (e) {
          debugPrint('Failed to reject via API: $e');
          _completions[index] = _completions[index].copyWith(
            status: JobCompletionStatus.rejected,
            approvedBy: supervisorId,
            approvedAt: DateTime.now(),
            rejectionReason: reason,
          );
        }
      } else {
        _completions[index] = _completions[index].copyWith(
          status: JobCompletionStatus.rejected,
          approvedBy: supervisorId,
          approvedAt: DateTime.now(),
          rejectionReason: reason,
        );
      }

      await _saveToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('Error rejecting completion: $e');
      rethrow;
    }
  }

  // Save to local storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completionsJson = _completions.map((c) => c.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(completionsJson));
    } catch (e) {
      debugPrint('Error saving completions: $e');
    }
  }

  // Load from local storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completionsJsonString = prefs.getString(_storageKey);
      if (completionsJsonString != null && completionsJsonString.isNotEmpty) {
        final List<dynamic> completionsJson = jsonDecode(completionsJsonString);
        _completions = completionsJson
            .map((json) => JobCompletion.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading completions from storage: $e');
    }
  }
}


