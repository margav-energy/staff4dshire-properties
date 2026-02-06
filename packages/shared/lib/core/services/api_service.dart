import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static String get apiBaseUrl => ApiConfig.baseUrl;

  // Generic GET request
  static Future<dynamic> get(String endpoint) async {
    try {
      final uri = Uri.parse('$apiBaseUrl$endpoint');
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Generic POST request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final url = '$apiBaseUrl$endpoint';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        // Try to parse error message from response
        String errorMessage = 'Failed to create: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map<String, dynamic>) {
            if (errorBody['error'] != null) {
              errorMessage = errorBody['error'] as String;
              // Include details if available
              if (errorBody['details'] != null) {
                errorMessage = '${errorMessage}: ${errorBody['details']}';
              }
            } else if (errorBody['message'] != null) {
              errorMessage = errorBody['message'] as String;
            } else if (errorBody['details'] != null) {
              errorMessage = errorBody['details'] as String;
            } else {
              errorMessage = '${errorMessage} - ${response.body}';
            }
          } else {
            errorMessage = '${errorMessage} - ${response.body}';
          }
        } catch (_) {
          errorMessage = '${errorMessage} - ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Generic PUT request
  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Generic DELETE request
  static Future<dynamic> delete(String endpoint, [Map<String, dynamic>? data]) async {
    try {
      final request = http.Request('DELETE', Uri.parse('$apiBaseUrl$endpoint'));
      request.headers['Content-Type'] = 'application/json';
      if (data != null) {
        request.body = jsonEncode(data);
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) {
          return {'success': true};
        }
        return jsonDecode(response.body);
      } else {
        String errorMessage = 'Failed to delete: ${response.statusCode}';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map<String, dynamic>) {
            if (errorBody['error'] != null) {
              errorMessage = errorBody['error'] as String;
            } else if (errorBody['message'] != null) {
              errorMessage = errorBody['message'] as String;
            }
          }
        } catch (_) {
          errorMessage = '${errorMessage} - ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }
}

