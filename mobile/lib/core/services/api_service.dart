import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static String get apiBaseUrl => ApiConfig.baseUrl;

  // Generic GET request
  static Future<dynamic> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('API GET Error: $e');
      rethrow;
    }
  }

  // Generic POST request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('API POST Error: $e');
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
      print('API PUT Error: $e');
      rethrow;
    }
  }

  // Generic DELETE request
  static Future<void> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiBaseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to delete: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('API DELETE Error: $e');
      rethrow;
    }
  }
}

