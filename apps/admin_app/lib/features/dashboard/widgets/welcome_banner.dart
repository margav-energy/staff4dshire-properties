import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:intl/intl.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:staff4dshire_shared/shared.dart';
class WelcomeBanner extends StatefulWidget {
  const WelcomeBanner({super.key});

  @override
  State<WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends State<WelcomeBanner> {
  // Cache for photo data to prevent multiple loads
  final Map<String, Uint8List?> _photoCache = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<AuthProvider>(context).currentUser;

    if (user == null) {
      return const SizedBox.shrink();
    }

    // Use Consumer to listen to UserProvider changes for photo updates
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Get the latest photoUrl from UserProvider (source of truth)
        String? photoUrl = user.photoUrl;
        
        // Try to get user by ID first, then by email as fallback
        UserModel? userModel = userProvider.getUserById(user.id);
        if (userModel == null) {
          // Fallback: try by email
          userModel = userProvider.getUserByEmail(user.email);
        }
        
        if (userModel != null && userModel.photoUrl != null && userModel.photoUrl!.isNotEmpty) {
          photoUrl = userModel.photoUrl;
        }

        return _buildBannerContent(context, theme, user, photoUrl);
      },
    );
  }

  Widget _buildBannerContent(BuildContext context, ThemeData theme, User user, String? photoUrl) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm:ss a');
    
    // Cache the photo widget key to prevent unnecessary rebuilds
    final photoKey = ValueKey<String?>('photo_${user.id}_$photoUrl');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Picture or Icon - Use RepaintBoundary to prevent unnecessary rebuilds
            RepaintBoundary(
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? ClipOval(
                        key: ValueKey<String>('photo_widget_${user.id}'),
                        child: photoUrl.startsWith('data:image')
                            ? _buildBase64Image(photoUrl)
                            : photoUrl.startsWith('pref:')
                                ? _buildPhotoFromPrefs(photoUrl, user.id)
                                : photoUrl.startsWith('db:')
                                    ? _buildPlaceholderIcon(theme) // db: references - photo loaded from API
                                    : (kIsWeb
                                        ? Image.network(
                                            photoUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return _buildPlaceholderIcon(theme);
                                            },
                                          )
                                        : Image.file(
                                            File(photoUrl),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return _buildPlaceholderIcon(theme);
                                            },
                                          )),
                      )
                    : _buildPlaceholderIcon(theme),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Welcome Text and Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome ${user.firstName}!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _TimeDisplay(dateFormat: dateFormat, timeFormat: timeFormat),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(ThemeData theme) {
    return Icon(
      Icons.person,
      color: Colors.white,
      size: 30,
    );
  }

  Widget _buildBase64Image(String base64String) {
    try {
      // Handle both formats: "data:image/jpeg;base64,{data}" and just "{data}"
      String base64Data = base64String;
      if (base64String.contains(',')) {
        base64Data = base64String.split(',')[1];
      }
      
      final bytes = base64Decode(base64Data);
      
      // Cache the decoded bytes
      if (base64String.contains(',')) {
        final key = base64String.split(',')[0]; // Use data:image/jpeg;base64 as cache key
        _photoCache[key] = bytes;
      }
      
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('WelcomeBanner: Error displaying base64 image: $error');
          return _buildPlaceholderIcon(Theme.of(context));
        },
      );
    } catch (e) {
      debugPrint('WelcomeBanner: Error decoding base64 image: $e');
      return _buildPlaceholderIcon(Theme.of(context));
    }
  }

  Widget _buildPhotoFromPrefs(String prefKey, String userId) {
    final actualKey = prefKey.replaceFirst('pref:', '');
    
    // Use a stable key for the FutureBuilder based on the photo key and user ID
    return FutureBuilder<String?>(
      key: ValueKey<String>('photo_future_${userId}_$actualKey'),
      future: _loadPhotoFromPrefs(actualKey),
      builder: (context, snapshot) {
        // Check cache first for immediate display
        if (_photoCache.containsKey(actualKey)) {
          final cachedBytes = _photoCache[actualKey];
          if (cachedBytes != null) {
            return Image.memory(
              cachedBytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('WelcomeBanner: Error displaying cached photo: $error');
                return _buildPlaceholderIcon(Theme.of(context));
              },
            );
          } else {
            // Cached as null - no photo available
            return _buildPlaceholderIcon(Theme.of(context));
          }
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPlaceholderIcon(Theme.of(context));
        }

        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          try {
            final bytes = base64Decode(snapshot.data!);
            // Cache the result
            _photoCache[actualKey] = bytes;
            debugPrint('WelcomeBanner: Successfully loaded photo from SharedPreferences. Key: $actualKey, Size: ${bytes.length} bytes');
            return Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('WelcomeBanner: Error displaying photo from memory: $error');
                return _buildPlaceholderIcon(Theme.of(context));
              },
            );
          } catch (e) {
            debugPrint('WelcomeBanner: Error decoding base64 photo: $e');
            // Cache null result
            _photoCache[actualKey] = null;
            return _buildPlaceholderIcon(Theme.of(context));
          }
        }

        // Cache null result to prevent repeated lookups
        if (!_photoCache.containsKey(actualKey)) {
          _photoCache[actualKey] = null;
          // Only log once per session to avoid spam
          // This is expected for legacy users with pref: URLs but no local photo
        }
        return _buildPlaceholderIcon(Theme.of(context));
      },
    );
  }

  Future<String?> _loadPhotoFromPrefs(String key) async {
    // Return cached result immediately if available
    if (_photoCache.containsKey(key)) {
      final cached = _photoCache[key];
      if (cached != null) {
        // Re-encode to base64 string for return (though we won't use it)
        return base64Encode(cached);
      }
      return null;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final photoData = prefs.getString(key);
      if (photoData != null) {
        // Cache immediately when we get the data
        try {
          final bytes = base64Decode(photoData);
          _photoCache[key] = bytes;
          debugPrint('WelcomeBanner: Cached photo data for key: $key, Size: ${bytes.length} bytes');
        } catch (e) {
          debugPrint('WelcomeBanner: Error caching photo: $e');
          _photoCache[key] = null;
        }
      } else {
        _photoCache[key] = null;
        // Silent fail - missing photos are expected for legacy users with pref: URLs
      }
      return photoData;
    } catch (e) {
      debugPrint('WelcomeBanner: Exception loading photo: $e');
      _photoCache[key] = null;
      return null;
    }
  }
}

// Separate widget for time display to isolate rebuilds
class _TimeDisplay extends StatefulWidget {
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  const _TimeDisplay({
    required this.dateFormat,
    required this.timeFormat,
  });

  @override
  State<_TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<_TimeDisplay> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Update time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                widget.dateFormat.format(_currentTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                widget.timeFormat.format(_currentTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
