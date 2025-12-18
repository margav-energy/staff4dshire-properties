import 'package:flutter/foundation.dart';
import '../models/company_model.dart';
import '../services/company_api_service.dart';
import 'user_provider.dart';
import 'project_provider.dart';

class CompanyProvider extends ChangeNotifier {
  List<Company> _companies = [];
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, Map<String, dynamic>> _companyStats = {}; // companyId -> stats

  List<Company> get companies => _companies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalCompanies => _companies.length;
  int get activeCompanies => _companies.where((c) => c.isActive).length;

  /// Get stats for a specific company
  Map<String, dynamic> getCompanyStats(String companyId) {
    return _companyStats[companyId] ?? {
      'usersCount': 0,
      'projectsCount': 0,
      'activeUsersCount': 0,
    };
  }

  /// Load all companies from API
  Future<void> loadCompanies({String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('[CompanyProvider] Loading companies for userId: $userId');
      try {
        final companies = await CompanyApiService.getCompanies(userId: userId);
        _companies = companies;
        
        print('[CompanyProvider] Loaded ${companies.length} companies:');
        for (var company in companies) {
          print('  - ${company.name} (id: ${company.id})');
        }
      } catch (e) {
        // If 403 error, user might not be superadmin - that's okay, they'll get their own company
        if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
          print('[CompanyProvider] Access denied (403) - user is not superadmin, will return empty list');
          _companies = [];
        } else {
          rethrow;
        }
      }
      
      // Calculate stats for each company
      await _calculateStats(userId: userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Calculate statistics for all companies
  Future<void> _calculateStats({String? userId, UserProvider? userProvider, ProjectProvider? projectProvider}) async {
    // Stats will be calculated from providers in the dashboard
    notifyListeners();
  }

  /// Calculate stats using providers (called from dashboard)
  void calculateStatsFromProviders(UserProvider userProvider, ProjectProvider projectProvider) {
    _companyStats.clear();
    
    for (var company in _companies) {
      final usersInCompany = userProvider.users.where((u) => u.companyId == company.id).toList();
      final projectsInCompany = projectProvider.allProjects.where((p) => p.companyId == company.id).toList();
      
      _companyStats[company.id] = {
        'usersCount': usersInCompany.length,
        'projectsCount': projectsInCompany.length,
        'activeUsersCount': usersInCompany.where((u) => u.isActive).length,
      };
    }
    notifyListeners();
  }

  /// Create a new company
  Future<Company> createCompany(Map<String, dynamic> data, {String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final company = await CompanyApiService.createCompany(data, userId: userId);
      _companies.add(company);
      _isLoading = false;
      notifyListeners();
      return company;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update a company
  Future<Company> updateCompany(String id, Map<String, dynamic> data, {String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final company = await CompanyApiService.updateCompany(id, data, userId: userId);
      final index = _companies.indexWhere((c) => c.id == id);
      if (index != -1) {
        _companies[index] = company;
      }
      _isLoading = false;
      notifyListeners();
      return company;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a company
  Future<void> deleteCompany(String id, {String? userId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await CompanyApiService.deleteCompany(id, userId: userId);
      _companies.removeWhere((c) => c.id == id);
      _companyStats.remove(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get company by ID
  Company? getCompanyById(String id) {
    try {
      return _companies.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}

