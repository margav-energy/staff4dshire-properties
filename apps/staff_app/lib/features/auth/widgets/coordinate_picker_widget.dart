import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:staff4dshire_shared/shared.dart';
class CoordinatePickerWidget extends StatefulWidget {
  final LocationData? initialLocation;
  final Function(LocationData) onLocationSelected;

  const CoordinatePickerWidget({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<CoordinatePickerWidget> createState() => _CoordinatePickerWidgetState();
}

class _CoordinatePickerWidgetState extends State<CoordinatePickerWidget> {
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _address;
  bool _isLoadingAddress = false;
  LocationData? _currentLocationData;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _latitudeController.text = widget.initialLocation!.latitude.toStringAsFixed(6);
      _longitudeController.text = widget.initialLocation!.longitude.toStringAsFixed(6);
      _address = widget.initialLocation!.address;
      _currentLocationData = widget.initialLocation;
    }
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _geocodeCoordinates() async {
    try {
      final lat = double.parse(_latitudeController.text.trim());
      final lng = double.parse(_longitudeController.text.trim());

      if (lat < -90 || lat > 90) {
        _showError('Latitude must be between -90 and 90');
        return;
      }

      if (lng < -180 || lng > 180) {
        _showError('Longitude must be between -180 and 180');
        return;
      }

      setState(() {
        _isLoadingAddress = true;
      });

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng)
            .timeout(const Duration(seconds: 10));

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
          if (place.thoroughfare != null &&
              place.thoroughfare!.isNotEmpty) {
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
                '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
          }
        } else {
          address = '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
        }

        _currentLocationData = LocationData(
          latitude: lat,
          longitude: lng,
          address: address,
          timestamp: DateTime.now(),
        );

        setState(() {
          _address = address;
          _isLoadingAddress = false;
        });
      } catch (e) {
        debugPrint('Geocoding error: $e');
        _currentLocationData = LocationData(
          latitude: lat,
          longitude: lng,
          address: '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
          timestamp: DateTime.now(),
        );
        setState(() {
          _address = '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingAddress = false;
      });
      _showError('Invalid coordinates: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.getCurrentLocation();

    if (locationProvider.currentLocation != null) {
      final location = locationProvider.currentLocation!;
      _latitudeController.text = location.latitude.toStringAsFixed(6);
      _longitudeController.text = location.longitude.toStringAsFixed(6);
      setState(() {
        _address = location.address;
        _currentLocationData = location;
      });
    } else if (mounted) {
      _showError('Unable to get current location');
    }
  }

  void _confirmLocation() {
    if (_currentLocationData != null) {
      widget.onLocationSelected(_currentLocationData!);
      Navigator.pop(context, _currentLocationData);
    } else {
      _showError('Please enter valid coordinates first');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: theme.colorScheme.primary.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enter coordinates or use current location',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Latitude input
              TextFormField(
                controller: _latitudeController,
                decoration: const InputDecoration(
                  labelText: 'Latitude *',
                  hintText: 'e.g., 51.5074',
                  prefixIcon: Icon(Icons.north),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Latitude is required';
                  }
                  final lat = double.tryParse(value.trim());
                  if (lat == null) {
                    return 'Invalid latitude format';
                  }
                  if (lat < -90 || lat > 90) {
                    return 'Latitude must be between -90 and 90';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Longitude input
              TextFormField(
                controller: _longitudeController,
                decoration: const InputDecoration(
                  labelText: 'Longitude *',
                  hintText: 'e.g., -0.1278',
                  prefixIcon: Icon(Icons.east),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Longitude is required';
                  }
                  final lng = double.tryParse(value.trim());
                  if (lng == null) {
                    return 'Invalid longitude format';
                  }
                  if (lng < -180 || lng > 180) {
                    return 'Longitude must be between -180 and 180';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Lookup Address Button
              ElevatedButton.icon(
                onPressed: _isLoadingAddress
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _geocodeCoordinates();
                        }
                      },
                icon: _isLoadingAddress
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoadingAddress ? 'Looking up address...' : 'Lookup Address'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Address Display
              if (_address != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Address',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _address!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Confirm Button
              ElevatedButton.icon(
                onPressed: _currentLocationData != null ? _confirmLocation : null,
                icon: const Icon(Icons.check),
                label: const Text('Confirm Location'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

