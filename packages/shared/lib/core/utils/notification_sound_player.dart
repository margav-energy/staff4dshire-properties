import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart' as audio;

class NotificationSoundPlayer {
  static final audio.AudioPlayer _player = audio.AudioPlayer();
  static bool _isPlaying = false;
  static bool _isPrimed = false;

  /// Get the correct audio source for the current platform
  static audio.Source _getAudioSource() {
    // Use AssetSource for all platforms - Flutter should handle the path correctly
    return audio.AssetSource('assets/notification_sound.mp3');
  }

  /// Get URL source for web fallback (when AssetSource fails)
  static audio.Source _getWebUrlSource() {
    // On web, try to load from the assets folder in the web build
    // This path is relative to the web root after Flutter builds
    return audio.UrlSource('/assets/notification_sound.mp3');
  }

  /// Prime audio playback (mainly for web where audio may be blocked until a user gesture).
  /// Call this from a user interaction (e.g. first tap) to unlock audio.
  static Future<void> prime() async {
    if (_isPrimed) return;
    try {
      // Web: require a user gesture; we "warm up" silently on first gesture.
      await _player.setVolume(0);
      await _player.play(_getAudioSource());
      await Future.delayed(const Duration(milliseconds: 80));
      await _player.stop();
      await _player.setVolume(1);
      _isPrimed = true;
      debugPrint('[NotificationSoundPlayer] ✅ Primed');
    } catch (e) {
      // If priming fails, don't block future attempts.
      debugPrint('[NotificationSoundPlayer] Prime failed: $e');
      // On web, if asset fails, try alternative path
      if (kIsWeb) {
        try {
          debugPrint('[NotificationSoundPlayer] Trying web alternative path...');
          await _player.setVolume(0);
          // Try without assets/ prefix for web
          await _player.play(audio.AssetSource('notification_sound.mp3'));
          await Future.delayed(const Duration(milliseconds: 80));
          await _player.stop();
          await _player.setVolume(1);
          _isPrimed = true;
          debugPrint('[NotificationSoundPlayer] ✅ Primed with alternative path');
        } catch (e2) {
          debugPrint('[NotificationSoundPlayer] Alternative path also failed: $e2');
        }
      }
    }
  }

  /// Play notification sound
  /// Works on web, mobile, and desktop platforms
  static Future<void> playNotificationSound() async {
    try {
      // Prevent overlapping sounds
      if (_isPlaying) {
        debugPrint('[NotificationSoundPlayer] Sound already playing, skipping');
        return;
      }

      _isPlaying = true;
      debugPrint('[NotificationSoundPlayer] 🔔 Playing notification sound...');

      // Stop any currently playing sound first
      await _player.stop();
      
      // Set volume to 1.0 to ensure sound plays
      await _player.setVolume(1.0);
      
      // Set player mode to low latency for notifications
      await _player.setPlayerMode(audio.PlayerMode.lowLatency);
      
      // Play the sound using platform-appropriate source
      await _player.play(_getAudioSource());

      // Wait for sound to complete, then reset flag (use first to avoid multiple listeners)
      _player.onPlayerComplete.first.then((_) {
        _isPlaying = false;
        debugPrint('[NotificationSoundPlayer] ✅ Sound completed');
      }).catchError((e) {
        debugPrint('[NotificationSoundPlayer] Error in completion listener: $e');
        _isPlaying = false;
      });

      // Fallback: reset after 3 seconds if event doesn't fire
      Future.delayed(const Duration(seconds: 3), () {
        if (_isPlaying) {
          _isPlaying = false;
          debugPrint('[NotificationSoundPlayer] ⏱️ Sound timeout - reset flag');
        }
      });
    } catch (e) {
      debugPrint('[NotificationSoundPlayer] ❌ Error playing sound: $e');
      _isPlaying = false;
      
      // Fallback: try alternative paths
      if (kIsWeb) {
        // On web, try URL source as fallback
        try {
          debugPrint('[NotificationSoundPlayer] Trying web URL source...');
          await _player.stop();
          await _player.setVolume(1.0);
          await _player.setPlayerMode(audio.PlayerMode.lowLatency);
          await _player.play(_getWebUrlSource());
          debugPrint('[NotificationSoundPlayer] ✅ Web URL source worked');
          
          // Set up completion listener
          _player.onPlayerComplete.first.then((_) {
            _isPlaying = false;
          }).catchError((_) {
            _isPlaying = false;
          });
          return; // Success
        } catch (e2) {
          debugPrint('[NotificationSoundPlayer] ❌ Web URL source failed: $e2');
        }
        
        // Try alternative asset paths
        final fallbackPaths = ['notification_sound.mp3'];
        for (final path in fallbackPaths) {
          try {
            debugPrint('[NotificationSoundPlayer] Trying fallback asset path: $path');
            await _player.stop();
            await _player.setVolume(1.0);
            await _player.setPlayerMode(audio.PlayerMode.lowLatency);
            await _player.play(audio.AssetSource(path));
            debugPrint('[NotificationSoundPlayer] ✅ Fallback asset path worked: $path');
            
            _player.onPlayerComplete.first.then((_) {
              _isPlaying = false;
            }).catchError((_) {
              _isPlaying = false;
            });
            return; // Success
          } catch (e3) {
            debugPrint('[NotificationSoundPlayer] ❌ Fallback asset path failed ($path): $e3');
          }
        }
      } else {
        // On mobile/desktop, try without assets/ prefix
        try {
          debugPrint('[NotificationSoundPlayer] Trying fallback path...');
          await _player.stop();
          await _player.setVolume(1.0);
          await _player.setPlayerMode(audio.PlayerMode.lowLatency);
          await _player.play(audio.AssetSource('notification_sound.mp3'));
          debugPrint('[NotificationSoundPlayer] ✅ Fallback path worked');
          
          _player.onPlayerComplete.first.then((_) {
            _isPlaying = false;
          }).catchError((_) {
            _isPlaying = false;
          });
          return; // Success
        } catch (e2) {
          debugPrint('[NotificationSoundPlayer] ❌ Fallback path failed: $e2');
        }
      }
      
      debugPrint('[NotificationSoundPlayer] ❌ All fallback paths failed');
    }
  }

  /// Stop any currently playing sound
  static Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      print('[NotificationSoundPlayer] Error stopping sound: $e');
    }
  }

  /// Dispose the audio player (call on app exit)
  static Future<void> dispose() async {
    try {
      await _player.dispose();
      _isPlaying = false;
    } catch (e) {
      print('[NotificationSoundPlayer] Error disposing player: $e');
    }
  }
}

