import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.'
      );
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  static Future<void> requestPermission() async {
    final status = await Permission.location.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      throw Exception('Location permission is required for attendance tracking');
    }
  }

  static Future<String> getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        
        // Build a readable address from placemark components
        List<String> addressParts = [];
        
        if (placemark.street?.isNotEmpty == true) {
          addressParts.add(placemark.street!);
        }
        if (placemark.subLocality?.isNotEmpty == true) {
          addressParts.add(placemark.subLocality!);
        }
        if (placemark.locality?.isNotEmpty == true) {
          addressParts.add(placemark.locality!);
        }
        if (placemark.administrativeArea?.isNotEmpty == true) {
          addressParts.add(placemark.administrativeArea!);
        }
        if (placemark.country?.isNotEmpty == true) {
          addressParts.add(placemark.country!);
        }
        
        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
      
      // Fallback to coordinates if no address found
      return 'Lat: ${position.latitude.toStringAsFixed(4)}, '
             'Lng: ${position.longitude.toStringAsFixed(4)}';
    } catch (e) {
      // Fallback to coordinates on error
      return 'Location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }
  }

  // Add a static method to convert lat/lng to address
  static Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        
        // Build a readable address from placemark components
        List<String> addressParts = [];
        
        if (placemark.street?.isNotEmpty == true) {
          addressParts.add(placemark.street!);
        }
        if (placemark.subLocality?.isNotEmpty == true) {
          addressParts.add(placemark.subLocality!);
        }
        if (placemark.locality?.isNotEmpty == true) {
          addressParts.add(placemark.locality!);
        }
        if (placemark.administrativeArea?.isNotEmpty == true) {
          addressParts.add(placemark.administrativeArea!);
        }
        if (placemark.country?.isNotEmpty == true) {
          addressParts.add(placemark.country!);
        }
        
        if (addressParts.isNotEmpty) {
          return addressParts.join(', ');
        }
      }
      
      // Fallback to coordinates if no address found
      return 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}';
    } catch (e) {
      // Fallback to coordinates on error
      return 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
  }

  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static bool isWithinOfficeRadius({
    required double currentLat,
    required double currentLon,
    required double officeLat,
    required double officeLon,
    double radiusInMeters = 100.0,
  }) {
    final distance = calculateDistance(currentLat, currentLon, officeLat, officeLon);
    return distance <= radiusInMeters;
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  static String getLocationPermissionStatus(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Location permission denied';
      case LocationPermission.deniedForever:
        return 'Location permission permanently denied';
      case LocationPermission.whileInUse:
        return 'Location permission granted while in use';
      case LocationPermission.always:
        return 'Location permission always granted';
      default:
        return 'Unknown permission status';
    }
  }
}
