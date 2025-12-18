import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';

class XeroConnection {
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? tenantId;
  final String? tenantName;
  final bool isConnected;

  XeroConnection({
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.tenantId,
    this.tenantName,
    this.isConnected = false,
  });

  bool get isTokenValid {
    if (accessToken == null || expiresAt == null) return false;
    return DateTime.now().isBefore(expiresAt!.subtract(const Duration(minutes: 5)));
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt?.toIso8601String(),
      'tenantId': tenantId,
      'tenantName': tenantName,
      'isConnected': isConnected,
    };
  }

  factory XeroConnection.fromJson(Map<String, dynamic> json) {
    return XeroConnection(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      tenantId: json['tenantId'],
      tenantName: json['tenantName'],
      isConnected: json['isConnected'] ?? false,
    );
  }

  XeroConnection copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? tenantId,
    String? tenantName,
    bool? isConnected,
  }) {
    return XeroConnection(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

class XeroProvider extends ChangeNotifier {
  XeroConnection? _connection;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Xero OAuth configuration
  // TODO: Replace with your actual Xero app credentials from https://developer.xero.com/myapps
  // For production, store these securely (e.g., environment variables, secure storage)
  static const String _clientId = 'YOUR_XERO_CLIENT_ID';
  // Note: Client secret is not needed for PKCE flow (more secure for mobile apps)
  static const String _redirectUri = 'staff4dshire://xero/callback';
  static const String _scope = 'accounting.transactions accounting.contacts offline_access';
  static const String _authorizationUrl = 'https://login.xero.com/identity/connect/authorize';
  static const String _tokenUrl = 'https://identity.xero.com/connect/token';
  static const String _apiBaseUrl = 'https://api.xero.com/api.xro/2.0';
  
  static const String _storageKey = 'xero_connection';

  XeroConnection? get connection => _connection;
  bool get isConnected => _connection?.isConnected ?? false;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isTokenValid => _connection?.isTokenValid ?? false;

  Future<void> initialize() async {
    await loadConnection();
  }

  Future<void> loadConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final connectionJson = prefs.getString(_storageKey);
      
      if (connectionJson != null) {
        final json = jsonDecode(connectionJson) as Map<String, dynamic>;
        _connection = XeroConnection.fromJson(json);
        
        // Check if token needs refresh
        if (_connection!.isConnected && !_connection!.isTokenValid && _connection!.refreshToken != null) {
          await _refreshToken();
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading Xero connection: $e');
      _errorMessage = 'Failed to load Xero connection';
      notifyListeners();
    }
  }

  Future<void> _saveConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_connection != null) {
        await prefs.setString(_storageKey, jsonEncode(_connection!.toJson()));
      } else {
        await prefs.remove(_storageKey);
      }
    } catch (e) {
      debugPrint('Error saving Xero connection: $e');
    }
  }

  Future<void> connectXero() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Generate state and code verifier for PKCE
      final state = _generateRandomString(32);
      final codeVerifier = _generateRandomString(128);
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // Store code verifier temporarily
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('xero_code_verifier', codeVerifier);
      await prefs.setString('xero_state', state);

      // Build authorization URL
      final authUrl = Uri.parse(_authorizationUrl).replace(queryParameters: {
        'response_type': 'code',
        'client_id': _clientId,
        'redirect_uri': _redirectUri,
        'scope': _scope,
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      });

      // Launch browser for OAuth flow
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(
          authUrl,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch authorization URL');
      }
    } catch (e) {
      _errorMessage = 'Failed to initiate Xero connection: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleOAuthCallback(String code, String state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedState = prefs.getString('xero_state');
      final codeVerifier = prefs.getString('xero_code_verifier');

      if (storedState != state) {
        throw Exception('Invalid state parameter');
      }

      if (codeVerifier == null) {
        throw Exception('Code verifier not found');
      }

      _isLoading = true;
      notifyListeners();

      // Exchange code for tokens
      final tokenResponse = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'code': code,
          'redirect_uri': _redirectUri,
          'code_verifier': codeVerifier,
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
        
        final accessToken = tokenData['access_token'] as String;
        final refreshToken = tokenData['refresh_token'] as String;
        final expiresIn = tokenData['expires_in'] as int;
        final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

        // Get tenant information
        final tenantInfo = await _getTenantInfo(accessToken);
        final tenantId = tenantInfo['tenantId'] as String?;
        final tenantName = tenantInfo['tenantName'] as String?;

        _connection = XeroConnection(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: expiresAt,
          tenantId: tenantId,
          tenantName: tenantName,
          isConnected: true,
        );

        // Clean up temporary storage
        await prefs.remove('xero_code_verifier');
        await prefs.remove('xero_state');

        await _saveConnection();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      } else {
        throw Exception('Failed to exchange code for tokens: ${tokenResponse.body}');
      }
    } catch (e) {
      _errorMessage = 'Failed to complete Xero connection: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _getTenantInfo(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.xero.com/connections'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final connections = jsonDecode(response.body) as List;
        if (connections.isNotEmpty) {
          final connection = connections.first as Map<String, dynamic>;
          return {
            'tenantId': connection['tenantId'],
            'tenantName': connection['tenantName'],
          };
        }
      }
    } catch (e) {
      debugPrint('Error getting tenant info: $e');
    }
    
    return {};
  }

  Future<void> _refreshToken() async {
    if (_connection?.refreshToken == null) return;

    try {
      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'client_id': _clientId,
          'refresh_token': _connection!.refreshToken!,
        },
      );

      if (response.statusCode == 200) {
        final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
        
        final accessToken = tokenData['access_token'] as String;
        final refreshToken = tokenData['refresh_token'] as String? ?? _connection!.refreshToken;
        final expiresIn = tokenData['expires_in'] as int;
        final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

        _connection = _connection!.copyWith(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: expiresAt,
        );

        await _saveConnection();
        notifyListeners();
      } else {
        // Token refresh failed, disconnect
        await disconnectXero();
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      await disconnectXero();
    }
  }

  Future<void> disconnectXero() async {
    _connection = null;
    _errorMessage = null;
    await _saveConnection();
    notifyListeners();
  }

  Future<void> ensureValidToken() async {
    if (_connection == null || !_connection!.isConnected) {
      throw Exception('Xero not connected');
    }

    if (!_connection!.isTokenValid) {
      await _refreshToken();
      if (!_connection!.isTokenValid) {
        throw Exception('Failed to refresh Xero token');
      }
    }
  }

  // Xero API Methods

  Future<List<Map<String, dynamic>>> getContacts() async {
    await ensureValidToken();

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/Contacts'),
        headers: {
          'Authorization': 'Bearer ${_connection!.accessToken}',
          'Xero-tenant-id': _connection!.tenantId!,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final contacts = data['Contacts'] as List?;
        return contacts?.cast<Map<String, dynamic>>() ?? [];
      } else {
        throw Exception('Failed to fetch contacts: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching Xero contacts: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createInvoice({
    required String contactId,
    required String invoiceNumber,
    required DateTime date,
    required DateTime dueDate,
    required List<Map<String, dynamic>> lineItems,
    String? reference,
    String? description,
  }) async {
    await ensureValidToken();

    try {
      final invoiceData = {
        'Type': 'ACCREC',
        'Contact': {'ContactID': contactId},
        'Date': date.toIso8601String().split('T')[0],
        'DueDate': dueDate.toIso8601String().split('T')[0],
        'InvoiceNumber': invoiceNumber,
        'Reference': reference,
        'LineItems': lineItems,
        'Status': 'AUTHORISED',
      };

      final response = await http.put(
        Uri.parse('$_apiBaseUrl/Invoices'),
        headers: {
          'Authorization': 'Bearer ${_connection!.accessToken}',
          'Xero-tenant-id': _connection!.tenantId!,
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'Invoices': [invoiceData]}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final invoices = data['Invoices'] as List;
        if (invoices.isNotEmpty) {
          return invoices.first as Map<String, dynamic>;
        }
        throw Exception('No invoice returned');
      } else {
        throw Exception('Failed to create invoice: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating Xero invoice: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getInvoices({
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
  }) async {
    await ensureValidToken();

    try {
      final queryParams = <String, String>{};
      if (fromDate != null) {
        queryParams['where'] = 'Date >= DateTime(${fromDate.year}, ${fromDate.month}, ${fromDate.day})';
      }
      if (status != null) {
        queryParams['Status'] = status;
      }

      final uri = Uri.parse('$_apiBaseUrl/Invoices').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${_connection!.accessToken}',
          'Xero-tenant-id': _connection!.tenantId!,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final invoices = data['Invoices'] as List?;
        return invoices?.cast<Map<String, dynamic>>() ?? [];
      } else {
        throw Exception('Failed to fetch invoices: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching Xero invoices: $e');
      rethrow;
    }
  }

  // Helper methods

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  String _generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }
}

