import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> _checkLocationServices() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check and request location permissions
  Future<LocationPermission> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission;
  }

  // Get the current position
  Future<Position?> getCurrentPosition() async {
    // Check if location services are enabled
    bool serviceEnabled = await _checkLocationServices();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check permissions
    LocationPermission permission = await _checkPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current position
    return await Geolocator.getCurrentPosition();
  }
  
  // Get placemark from coordinates (reverse geocoding)
  Future<Placemark?> getPlacemarkFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        return placemarks.first;
      }
      return null;
    } catch (e) {
      print('Error in reverse geocoding: $e');
      return null;
    }
  }
} 