import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../models/onboarding_model.dart';
import '../models/cis_onboarding_model.dart';

class OnboardingProvider extends ChangeNotifier {
  OnboardingProgress? _progress;
  OnboardingNewStarterDetails? _newStarterDetails;
  CisOnboarding? _cisOnboarding;
  Map<String, dynamic>? _qualifications;
  Map<String, dynamic>? _policies;
  bool _isLoading = false;

  OnboardingProgress? get progress => _progress;
  OnboardingNewStarterDetails? get newStarterDetails => _newStarterDetails;
  CisOnboarding? get cisOnboarding => _cisOnboarding;
  Map<String, dynamic>? get qualifications => _qualifications;
  Map<String, dynamic>? get policies => _policies;
  bool get isLoading => _isLoading;
  bool get isComplete => _progress?.isComplete ?? false;
  bool get isCisComplete => _cisOnboarding?.isComplete ?? false;
  int get currentStep => _progress?.currentStep ?? 1;

  Future<void> loadProgress(String userId) async {
    if (!ApiConfig.isApiEnabled) {
      _progress = OnboardingProgress(userId: userId);
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/onboarding/progress/$userId');
      _progress = OnboardingProgress.fromJson(response);
      
      // Also load new starter details if step 1 is completed
      if (_progress?.step1Completed == true) {
        await loadNewStarterDetails(userId);
      }
    } catch (e) {
      debugPrint('Error loading onboarding progress: $e');
      _progress = OnboardingProgress(userId: userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNewStarterDetails(String userId) async {
    if (!ApiConfig.isApiEnabled) return;

    try {
      final response = await ApiService.get('/onboarding/new-starter/$userId');
      if (response != null) {
        _newStarterDetails = OnboardingNewStarterDetails.fromJson(response);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading new starter details: $e');
    }
  }

  Future<bool> saveNewStarterDetails(OnboardingNewStarterDetails details) async {
    if (!ApiConfig.isApiEnabled) {
      _newStarterDetails = details;
      notifyListeners();
      return true;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/onboarding/new-starter', details.toJson());
      _newStarterDetails = OnboardingNewStarterDetails.fromJson(response);
      
      // Reload progress to get updated step
      await loadProgress(details.userId);
      
      return true;
    } catch (e) {
      debugPrint('Error saving new starter details: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadQualifications(String userId) async {
    if (!ApiConfig.isApiEnabled) return;

    try {
      final response = await ApiService.get('/onboarding/qualifications/$userId');
      if (response != null) {
        _qualifications = response;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading qualifications: $e');
    }
  }

  Future<bool> saveQualifications(Map<String, dynamic> qualifications) async {
    if (!ApiConfig.isApiEnabled) return true;

    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.post('/onboarding/qualifications', qualifications);
      
      // Reload progress
      if (_progress != null) {
        await loadProgress(_progress!.userId);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error saving qualifications: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPolicies(String userId) async {
    if (!ApiConfig.isApiEnabled) return;

    try {
      final response = await ApiService.get('/onboarding/policies/$userId');
      if (response != null) {
        _policies = response;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading policies: $e');
    }
  }

  Future<bool> savePolicies(Map<String, dynamic> policies) async {
    if (!ApiConfig.isApiEnabled) return true;

    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.post('/onboarding/policies', policies);
      
      // Reload progress
      if (_progress != null) {
        await loadProgress(_progress!.userId);
      }
      
      return true;
    } catch (e) {
      debugPrint('Error saving policies: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CIS Onboarding methods
  Future<void> loadCisOnboarding(String userId) async {
    if (!ApiConfig.isApiEnabled) {
      _cisOnboarding = CisOnboarding(userId: userId);
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/onboarding/cis/$userId');
      if (response != null) {
        _cisOnboarding = CisOnboarding.fromJson(response);
      } else {
        _cisOnboarding = CisOnboarding(userId: userId);
      }
    } catch (e) {
      debugPrint('Error loading CIS onboarding: $e');
      _cisOnboarding = CisOnboarding(userId: userId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveCisOnboarding(CisOnboarding onboarding) async {
    if (!ApiConfig.isApiEnabled) {
      _cisOnboarding = onboarding;
      notifyListeners();
      return true;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/onboarding/cis', onboarding.toJson());
      _cisOnboarding = CisOnboarding.fromJson(response);
      return true;
    } catch (e) {
      debugPrint('Error saving CIS onboarding: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

