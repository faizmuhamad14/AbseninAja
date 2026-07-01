import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationHelper {
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 8),
      ),
    );
  }

  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> parts = [];
        
        if (place.street != null && place.street!.trim().isNotEmpty) {
          parts.add(place.street!.trim());
        }
        if (place.subLocality != null && place.subLocality!.trim().isNotEmpty) {
          parts.add(place.subLocality!.trim());
        }
        if (place.locality != null && place.locality!.trim().isNotEmpty) {
          parts.add(place.locality!.trim());
        }
        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.trim().isNotEmpty) {
          parts.add(place.subAdministrativeArea!.trim());
        }
        if (place.postalCode != null && place.postalCode!.trim().isNotEmpty) {
          parts.add(place.postalCode!.trim());
        }
        
        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
      return "Latitude: $lat, Longitude: $lng";
    } catch (e) {
      return "Latitude: $lat, Longitude: $lng";
    }
  }
}
