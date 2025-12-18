import 'package:flutter/material.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:provider/provider.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:latlong2/latlong.dart';
import 'package:staff4dshire_shared/shared.dart';
import 'package:geocoding/geocoding.dart';
import 'package:staff4dshire_shared/shared.dart';
class MapLocationPicker extends StatefulWidget {
  final LocationData? initialLocation;
  final Function(LocationData) onLocationSelected;

  const MapLocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoadingAddress = false;
  LocationData? _currentLocationData;
  double _zoom = 16.0;

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
    } else {
      // Default to London if no initial location
      _selectedLocation = const LatLng(51.5074, -0.1278);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onMapTap(TapPosition position, LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoadingAddress = true;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialLocation = _selectedLocation ?? const LatLng(51.5074, -0.1278);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
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
          // OpenStreetMap using flutter_map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialLocation,
              initialZoom: _zoom,
              minZoom: 5.0,
              maxZoom: 18.0,
              onTap: _onMapTap,
            ),
            children: [
              // OpenStreetMap tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.staff4dshire.properties',
                maxZoom: 19,
              ),
              // Marker for selected location
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      child: Icon(
                        Icons.location_on,
                        color: theme.colorScheme.primary,
                        size: 50,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Center marker (always visible)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                Container(
                  width: 2,
                  height: 20,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),

          // Location info card at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Selected Location',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingAddress)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Getting address...'),
                      ],
                    )
                  else if (_selectedLocation != null) ...[
                    if (_selectedAddress != null)
                      Text(
                        _selectedAddress!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ]
                  else
                    Text(
                      'Tap on the map to select a location',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectedLocation != null &&
                              _currentLocationData != null
                          ? () {
                              widget.onLocationSelected(_currentLocationData!);
                              Navigator.pop(context, _currentLocationData);
                            }
                          : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm Location'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
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
