import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, debugPrint;

class ApiConfig {
  // API Base URL Configuration
  // 
  // DEVELOPMENT (local testing):
  // - Web: http://localhost:3001/api
  // - Android Emulator: http://10.0.2.2:3001/api
  // - iOS Simulator: http://localhost:3001/api
  // - Physical Device: Set via API_BASE_URL environment variable
  //
  // PRODUCTION (when app goes live):
  // - All platforms: https://api.yourcompany.com/api (your deployed backend URL)
  // - Users connect to YOUR backend, which stores all data in a cloud database
  // - You don't need users' IP addresses - they all connect to the same backend!
  
  // Production API URL - UPDATE THIS WHEN DEPLOYING TO PRODUCTION
  static const String _productionUrl = 'https://api.staff4dshire.com/api'; // TODO: Update to your production URL
  
  // Development URLs for different platforms
  static const String _devWebUrl = 'http://localhost:3001/api';
  static const String _devAndroidEmulatorUrl = 'http://10.0.2.2:3001/api';
  static const String _devIOSSimulatorUrl = 'http://localhost:3001/api';
  
  // Get base URL with environment detection
  static String get baseUrl {
    // Priority 1: Environment variable override (for testing/physical devices)
    // Usage: flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3001/api
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      // If running on web and env URL is provided, still use localhost for web
      // (web browsers can't access IP addresses from localhost due to CORS)
      if (kIsWeb && !envUrl.contains('localhost') && !envUrl.contains('127.0.0.1')) {
        debugPrint('⚠️  Web detected: Using localhost instead of $envUrl (CORS restrictions)');
        return _devWebUrl;
      }
      return envUrl;
    }
    
    // Priority 2: Production mode (release builds)
    // When you build for production, all users will connect to your deployed backend
    if (kReleaseMode) {
      return _productionUrl;
    }
    
    // Priority 3: Development mode - platform-specific defaults
    if (kIsWeb) {
      // Web browser - same machine as server (must use localhost)
      return _devWebUrl;
    } else {
      // Mobile platforms (Android emulator default)
      // For physical devices during development, use API_BASE_URL environment variable
      return _devAndroidEmulatorUrl;
    }
  }
  
  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Enable/disable API (for development/testing)
  static bool get isApiEnabled => true;
  
  // Helper to check if we're in development mode
  static bool get isDevelopment => !kReleaseMode;
  
  // Get app base URL (for invitation links, different from API URL)
  // This is the URL users will access the app from (not the API endpoint)
  static String get appBaseUrl {
    // Production app URL - UPDATE THIS WHEN DEPLOYING TO PRODUCTION
    const _productionAppUrl = 'https://app.staff4dshire.com'; // TODO: Update to your production app URL
    
    // Check for environment variable override
    const envUrl = String.fromEnvironment('APP_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Production mode - use production URL
    if (kReleaseMode) {
      return _productionAppUrl;
    }
    
    // Development mode
    if (kIsWeb) {
      // For Flutter web, detect the current window location
      // This ensures the invitation link uses the correct port the app is actually running on
      try {
        // Get current URL from browser (if on web)
        // This will return the actual port the app is running on (e.g., http://localhost:51735)
        return Uri.base.origin; 
      } catch (e) {
        return 'http://localhost:8080'; // Flutter web default port
      }
    }
    
    // For mobile apps, invitation links don't work the same way
    // Users should use invitation codes instead
    return 'Use invitation code'; // Mobile apps use codes, not URLs
  }
  
  // Get web-accessible URL (for web apps only)
  static String get webAppUrl {
    if (kIsWeb) {
      return Uri.base.origin; // Current origin (e.g., http://localhost:51735)
    }
    // For mobile, return empty - mobile uses invitation codes
    return '';
  }
}

