import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
  });
}

class LocationProvider extends ChangeNotifier {
  LocationData? _currentLocation;
  bool _isLoading = false;
  String? _error;

  LocationData? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _error = 'Location permissions are denied';
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _error = 'Location permissions are permanently denied';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<void> getCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool hasPermission = await requestPermission();
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates using geocoding
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 10));

        if (placemarks.isNotEmpty) {
          final place = placemarks[0];
          // Build a readable address - try multiple approaches
          final addressParts = <String>[];
          
          // Try name first (often has the most readable address)
          if (place.name != null && place.name!.isNotEmpty && place.name != place.street) {
            addressParts.add(place.name!);
          }
          
          // Add street number and name
          if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
            addressParts.add(place.subThoroughfare!);
          }
          if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
            addressParts.add(place.thoroughfare!);
          }
          
          // Add locality/subLocality
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          } else if (place.locality != null && place.locality!.isNotEmpty) {
            addressParts.add(place.locality!);
          }
          
          // Add administrative area
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            addressParts.add(place.administrativeArea!);
          }
          
          // Add postal code
          if (place.postalCode != null && place.postalCode!.isNotEmpty) {
            addressParts.add(place.postalCode!);
          }
          
          // Add country
          if (place.country != null && place.country!.isNotEmpty) {
            addressParts.add(place.country!);
          }

          if (addressParts.isNotEmpty) {
            address = addressParts.join(', ');
          } else {
            // Try alternative format with more fields
            final altParts = <String>[];
            
            // Try name field (sometimes has full address)
            if (place.name != null && place.name!.isNotEmpty) {
              altParts.add(place.name!);
            }
            
            // Try street
            if (place.street != null && place.street!.isNotEmpty) {
              altParts.add(place.street!);
            }
            
            // Try locality/city
            if (place.locality != null && place.locality!.isNotEmpty) {
              altParts.add(place.locality!);
            }
            
            // Try administrative area/state
            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
              altParts.add(place.administrativeArea!);
            }
            
            // Try country
            if (place.country != null && place.country!.isNotEmpty) {
              altParts.add(place.country!);
            }
            
            if (altParts.isNotEmpty) {
              address = altParts.join(', ');
            } else {
              // Final fallback - format coordinates nicely
              address = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
            }
          }
        } else {
          // No placemarks returned
          address = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }
      } catch (e) {
        // Geocoding failed, but we still have coordinates
        debugPrint('Geocoding error: $e');
        // Use coordinates as address
        address = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      }

      _currentLocation = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        timestamp: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error getting location: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearLocation() {
    _currentLocation = null;
    _error = null;
    notifyListeners();
  }

  // Set location manually (from map picker)
  void setLocation(LocationData location) {
    _currentLocation = location;
    _error = null;
    notifyListeners();
  }
}

