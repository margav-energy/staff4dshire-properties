import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';

/// Service to sync photos between SharedPreferences and database
class PhotoSyncService {
  /// Sync photo from SharedPreferences to database if it exists locally but not in DB
  /// This helps migrate legacy users from pref: URLs to base64 storage
  static Future<void> syncPhotoToDatabase(String userId, String? currentPhotoUrl) async {
    if (!ApiConfig.isApiEnabled || currentPhotoUrl == null) return;
    
    // If photo URL is already base64 data, no need to sync
    if (currentPhotoUrl.startsWith('data:image')) return;
    
    // If photo URL is pref: but photo exists in SharedPreferences, upload to database
    if (currentPhotoUrl.startsWith('pref:')) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final photoKey = currentPhotoUrl.replaceFirst('pref:', '');
        final base64Data = prefs.getString(photoKey);
        
        if (base64Data != null && base64Data.isNotEmpty) {
          // Photo exists in SharedPreferences - convert to base64 data URL and save to DB
          final sizeInMB = base64Data.length / (1024 * 1024);
          if (sizeInMB <= 2.0) {
            final mimeType = 'image/jpeg'; // Default
            final photoUrl = 'data:$mimeType;base64,$base64Data';
            
            // Update user's photo URL in database
            await ApiService.put('/users/$userId', {'photo_url': photoUrl});
            
            // Reload user to get updated photo URL
            return;
          }
        }
      } catch (e) {
        // Fail silently - photo will still work from SharedPreferences if available
      }
    }
  }
  
  /// Sync photo from database to SharedPreferences if it's base64 data
  static Future<void> syncPhotoToLocal(String userId, String? photoUrl) async {
    if (photoUrl == null || !photoUrl.startsWith('data:image')) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final photoKey = 'profile_photo_$userId';
      
      // Extract base64 data
      if (photoUrl.contains(',')) {
        final base64Data = photoUrl.split(',')[1];
        final sizeInMB = base64Data.length / (1024 * 1024);
        
        // Only cache if reasonable size (under 1.5MB to leave room for other data)
        if (sizeInMB <= 1.5) {
          await prefs.setString(photoKey, base64Data);
        }
      }
    } catch (e) {
      if (e.toString().contains('QuotaExceeded') || e.toString().contains('quota')) {
        // Try to clear old photo cache to free up space
        try {
          final prefs = await SharedPreferences.getInstance();
          final photoKey = 'profile_photo_$userId';
          await prefs.remove(photoKey);
        } catch (clearError) {
          // Silent fail
        }
      }
      // Fail silently - photo will still work from database
    }
  }
}

