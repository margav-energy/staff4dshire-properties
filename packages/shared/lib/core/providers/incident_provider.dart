import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/incident_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class IncidentProvider extends ChangeNotifier {
  static const String _storageKey = 'incidents_list';
  bool _isInitialized = false;
  
  List<Incident> _incidents = [];

  List<Incident> get incidents => _incidents;
  
  List<Incident> getReportedByUser(String userId) {
    return _incidents.where((incident) => incident.reporterId == userId).toList();
  }

  List<Incident> getPendingIncidents() {
    return _incidents.where((incident) => 
      incident.status == IncidentStatus.reported || 
      incident.status == IncidentStatus.attending ||
      incident.status == IncidentStatus.fixing ||
      incident.status == IncidentStatus.tracking
    ).toList();
  }

  List<Incident> getResolvedIncidents() {
    return _incidents.where((incident) => incident.status == IncidentStatus.resolved).toList();
  }

  Incident? getIncidentById(String id) {
    try {
      return _incidents.firstWhere((incident) => incident.id == id);
    } catch (e) {
      return null;
    }
  }

  // Initialize provider - load from storage or API
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Try to load from API first if enabled
      if (ApiConfig.isApiEnabled) {
        try {
          await _loadFromApi();
          _isInitialized = true;
          notifyListeners();
          return;
        } catch (e) {
          debugPrint('Failed to load incidents from API, trying local storage: $e');
          // Fall through to local storage
        }
      }
      
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final incidentsJsonString = prefs.getString(_storageKey);
      
      if (incidentsJsonString != null && incidentsJsonString.isNotEmpty) {
        final List<dynamic> incidentsJson = jsonDecode(incidentsJsonString);
        _incidents = incidentsJson
            .map((json) => Incident.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading incidents: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadFromApi() async {
    try {
      final response = await ApiService.get('/incidents');
      if (response is List) {
        _incidents = response
            .map((json) => _incidentFromApiJson(json as Map<String, dynamic>))
            .toList();
        await _saveToStorage();
      }
    } catch (e) {
      debugPrint('Error loading incidents from API: $e');
      rethrow;
    }
  }

  Incident _incidentFromApiJson(Map<String, dynamic> json) {
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
      reporterId: json['reporter_id'] as String,
      reporterName: json['reporter_name'] as String,
      projectId: json['project_id'] as String?,
      projectName: json['project_name'] as String?,
      description: json['description'] as String,
      photoPath: json['photo_path'] as String?,
      severity: severity,
      reportedAt: json['reported_at'] != null
          ? DateTime.parse(json['reported_at'] as String)
          : DateTime.now(),
      location: json['location'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      status: status,
      assignedTo: json['assigned_to'] as String?,
      assignedToName: json['assigned_to_name'] as String?,
      notes: json['notes'] as String?,
      statusUpdatedAt: json['status_updated_at'] != null
          ? DateTime.parse(json['status_updated_at'] as String)
          : null,
      statusUpdatedBy: json['status_updated_by'] as String?,
    );
  }

  Map<String, dynamic> _incidentToApiJson(Incident incident) {
    return {
      'description': incident.description,
      'severity': incident.severity.toString().split('.').last,
      'photo_path': incident.photoPath,
      'project_id': incident.projectId,
      'location': incident.location,
      'latitude': incident.latitude,
      'longitude': incident.longitude,
    };
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final incidentsJson = _incidents.map((incident) => incident.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(incidentsJson));
    } catch (e) {
      debugPrint('Error saving incidents: $e');
    }
  }

  Future<void> reportIncident({
    required String reporterId,
    required String reporterName,
    required String description,
    required String photoPath,
    IncidentSeverity severity = IncidentSeverity.medium,
    String? projectId,
    String? projectName,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final incidentId = DateTime.now().millisecondsSinceEpoch.toString();
      final incident = Incident(
        id: incidentId,
        reporterId: reporterId,
        reporterName: reporterName,
        projectId: projectId,
        projectName: projectName,
        description: description,
        photoPath: photoPath,
        severity: severity,
        location: location,
        latitude: latitude,
        longitude: longitude,
        status: IncidentStatus.reported,
      );

      // Try to save to API first if enabled
      if (ApiConfig.isApiEnabled) {
        try {
          final apiJson = _incidentToApiJson(incident);
          apiJson['reporter_id'] = reporterId;
          apiJson['reporter_name'] = reporterName;
          
          await ApiService.post('/incidents', apiJson);
          
          // Reload from API to get complete data (which will include the generated ID)
          await _loadFromApi();
          notifyListeners();
          return;
        } catch (e) {
          debugPrint('Failed to save incident to API, saving locally: $e');
          // Fall through to local storage
        }
      }

      // Fallback to local storage
      _incidents.add(incident);
      await _saveToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('Error reporting incident: $e');
      rethrow;
    }
  }

  Future<void> updateIncidentStatus({
    required String incidentId,
    required IncidentStatus newStatus,
    required String updatedBy,
    required String updatedByName,
    String? notes,
  }) async {
    try {
      final index = _incidents.indexWhere((incident) => incident.id == incidentId);
      if (index == -1) {
        throw Exception('Incident not found');
      }

      final incident = _incidents[index];
      final updatedIncident = incident.copyWith(
        status: newStatus,
        notes: notes ?? incident.notes,
        statusUpdatedAt: DateTime.now(),
        statusUpdatedBy: updatedBy,
        assignedTo: updatedBy,
        assignedToName: updatedByName,
      );

      // Try to update via API first if enabled
      if (ApiConfig.isApiEnabled) {
        try {
          await ApiService.put('/incidents/$incidentId', {
            'status': newStatus.toString().split('.').last,
            'assigned_to': updatedBy,
            'assigned_to_name': updatedByName,
            'notes': notes ?? incident.notes,
            'status_updated_at': DateTime.now().toIso8601String(),
            'status_updated_by': updatedBy,
          });
          
          // Reload from API to get complete data
          await _loadFromApi();
          notifyListeners();
          return;
        } catch (e) {
          debugPrint('Failed to update incident status in API, updating locally: $e');
          // Fall through to local storage
        }
      }

      // Fallback to local storage
      _incidents[index] = updatedIncident;
      await _saveToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating incident status: $e');
      rethrow;
    }
  }

  Future<void> loadIncidents() async {
    if (!_isInitialized) {
      await initialize();
    }
    notifyListeners();
  }
}
