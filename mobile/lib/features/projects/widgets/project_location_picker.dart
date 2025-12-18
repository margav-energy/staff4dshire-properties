import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/providers/location_provider.dart';

// Helper class to store address search results with display name
class AddressSearchResult {
  final double latitude;
  final double longitude;
  final String displayName;

  AddressSearchResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}

class ProjectLocationPicker extends StatefulWidget {
  final LocationData? initialLocation;
  final Function(LocationData) onLocationSelected;

  const ProjectLocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<ProjectLocationPicker> createState() => _ProjectLocationPickerState();
}

class _ProjectLocationPickerState extends State<ProjectLocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoadingAddress = false;
  bool _isSearching = false;
  LocationData? _currentLocationData;
  double _zoom = 16.0;
  List<AddressSearchResult> _searchResults = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
      _selectedAddress = widget.initialLocation!.address;
      _currentLocationData = widget.initialLocation;
      _searchController.text = widget.initialLocation!.address ?? '';
    } else {
      // Default to London if no initial location
      _selectedLocation = const LatLng(51.5074, -0.1278);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Web-compatible geocoding using Nominatim API (OpenStreetMap)
  Future<List<AddressSearchResult>> _geocodeAddressNominatim(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=5&addressdetails=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Staff4dshire Properties App',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        
        return results.map((result) {
          final latitude = double.parse(result['lat'] as String);
          final longitude = double.parse(result['lon'] as String);
          
          // Get display name from Nominatim result
          final displayName = result['display_name'] as String? ?? 
                            result['name'] as String? ?? 
                            'Location';
          
          return AddressSearchResult(
            latitude: latitude,
            longitude: longitude,
            displayName: displayName,
          );
        }).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Nominatim geocoding error: $e');
      return [];
    }
  }
  
  // Convert geocoding package Location to AddressSearchResult
  AddressSearchResult _locationToSearchResult(Location location, String query) {
    return AddressSearchResult(
      latitude: location.latitude,
      longitude: location.longitude,
      displayName: query, // Will be replaced by reverse geocoding later
    );
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      final searchQuery = query.trim();
      
      // Validate minimum query length
      if (searchQuery.length < 3) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _showSearchResults = false;
        });
        return;
      }

      List<AddressSearchResult> searchResults;
      
      // On web, use Nominatim API. On mobile, try geocoding package first, then fallback to Nominatim
      if (kIsWeb) {
        searchResults = await _geocodeAddressNominatim(searchQuery);
      } else {
        try {
          // Try geocoding package first on mobile
          final locations = await locationFromAddress(searchQuery)
              .timeout(const Duration(seconds: 5));
          
          // Convert to AddressSearchResult
          searchResults = locations.map((loc) => _locationToSearchResult(loc, searchQuery)).toList();
        } catch (e) {
          // Fallback to Nominatim if geocoding package fails
          debugPrint('Geocoding package failed, using Nominatim: $e');
          searchResults = await _geocodeAddressNominatim(searchQuery);
        }
      }

      // Filter out any invalid/null locations
      final validResults = searchResults.where((result) {
        return result.latitude.isFinite && 
               result.longitude.isFinite &&
               result.latitude != 0.0 && 
               result.longitude != 0.0;
      }).toList();

      if (validResults.isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _showSearchResults = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No results found for "$searchQuery".\nTry a full address, postcode, or city name.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _searchResults = validResults;
        _isSearching = false;
      });
    } catch (e, stackTrace) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showSearchResults = false;
      });
      
      String errorMessage = 'Unable to search for address';
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('null')) {
        errorMessage = 'Address search service unavailable.\n\nYou can:\n• Select location directly on the map\n• Use "Use Current Location" button\n• Try a different address format';
      } else if (errorStr.contains('network') || errorStr.contains('timeout') || errorStr.contains('socket')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (errorStr.contains('permission') || errorStr.contains('denied')) {
        errorMessage = 'Location services permission required for address search.';
      } else if (errorStr.contains('no results') || errorStr.contains('not found')) {
        errorMessage = 'Address not found. Try:\n• Full address (e.g., "123 Main St, London")\n• UK Postcode (e.g., "SW1A 1AA")\n• City name (e.g., "London, UK")';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      
      debugPrint('Address search error for "$query": $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _selectSearchResult(AddressSearchResult result) async {
    final latLng = LatLng(result.latitude, result.longitude);

    setState(() {
      _selectedLocation = latLng;
      _isLoadingAddress = false;
      _showSearchResults = false;
      _searchController.text = result.displayName; // Show the selected address name
      
      // Use the displayName directly as the address (it's already a full address)
      _selectedAddress = result.displayName;
      _currentLocationData = LocationData(
        latitude: result.latitude,
        longitude: result.longitude,
        address: result.displayName, // Use the full address from search result
        timestamp: DateTime.now(),
      );
    });

    // Move map to selected location
    _mapController.move(latLng, _zoom);
  }

  Future<void> _onMapTap(TapPosition position, LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoadingAddress = true;
      _showSearchResults = false;
    });

    // Get address from coordinates
    await _geocodeLocation(location);
  }

  Future<void> _geocodeLocation(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      ).timeout(const Duration(seconds: 10));

      String? address;
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final addressParts = <String>[];

        if (place.name != null &&
            place.name!.isNotEmpty &&
            place.name != place.street) {
          addressParts.add(place.name!);
        }

        if (place.subThoroughfare != null &&
            place.subThoroughfare!.isNotEmpty) {
          addressParts.add(place.subThoroughfare!);
        }
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          addressParts.add(place.thoroughfare!);
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        } else if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }

        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }

        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        if (addressParts.isNotEmpty) {
          address = addressParts.join(', ');
        } else {
          address =
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        }
      } else {
        address =
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      }

      final locationData = LocationData(
        latitude: location.latitude,
        longitude: location.longitude,
        address: address,
        timestamp: DateTime.now(),
      );

      setState(() {
        _selectedAddress = address;
        _currentLocationData = locationData;
        _isLoadingAddress = false;
        if (_searchController.text.isEmpty) {
          _searchController.text = address ?? '';
        }
      });
    } catch (e) {
      debugPrint('Geocoding error: $e');
      final locationData = LocationData(
        latitude: location.latitude,
        longitude: location.longitude,
        address:
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
        timestamp: DateTime.now(),
      );
      setState(() {
        _selectedAddress =
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        _currentLocationData = locationData;
        _isLoadingAddress = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.getCurrentLocation();

    if (locationProvider.currentLocation != null) {
      final location = locationProvider.currentLocation!;
      final latLng = LatLng(location.latitude, location.longitude);

      setState(() {
        _selectedLocation = latLng;
        _selectedAddress = location.address;
        _currentLocationData = location;
        _searchController.text = location.address ?? '';
      });

      // Move map to current location
      _mapController.move(latLng, _zoom);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get current location. Please select on the map.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _onMapMoved(MapEvent event) {
    if (event is MapEventMoveEnd) {
      final center = _mapController.camera.center;
      if (_selectedLocation == null ||
          (_selectedLocation!.latitude - center.latitude).abs() > 0.0001 ||
          (_selectedLocation!.longitude - center.longitude).abs() > 0.0001) {
        setState(() {
          _selectedLocation = center;
          _isLoadingAddress = true;
        });
        _geocodeLocation(center);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialLocation = _selectedLocation ?? const LatLng(51.5074, -0.1278);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Project Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Use Current Location',
            onPressed: _useCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialLocation,
              initialZoom: _zoom,
              minZoom: 5.0,
              maxZoom: 18.0,
              onTap: _onMapTap,
              onMapEvent: _onMapMoved,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.staff4dshire.properties',
              ),
              // Marker for selected location
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: theme.colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Search Box
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for address...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _showSearchResults = false;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.trim().isNotEmpty) {
                        _searchAddress(value);
                      } else {
                        setState(() {
                          _searchResults = [];
                          _showSearchResults = false;
                        });
                      }
                    },
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _searchAddress(value);
                      }
                    },
                  ),
                ),
                
                // Search Results
                if (_showSearchResults && _searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.place),
                          title: Text(
                            result.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
                if (_isSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom card with address and confirm button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isLoadingAddress)
                    const Center(child: CircularProgressIndicator())
                  else if (_selectedAddress != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedAddress!,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _currentLocationData != null
                          ? () {
                              widget.onLocationSelected(_currentLocationData!);
                              // Don't pop here - let the caller handle navigation
                              // This allows it to work both in dialogs and full-screen routes
                            }
                          : null,
                      child: const Text('Confirm Location'),
                    ),
                  ] else
                    Text(
                      'Select a location on the map',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

