import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class LocationService {
  /// Request GPS location permission and fetch current position
  /// Returns null if permissions are denied or service is disabled
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  /// Perform reverse geocoding to resolve coordinates into human-readable City, State
  static Future<String> reverseGeocode(double lat, double lon) async {
    try {
      // 1. Primary: BigDataCloud Reverse Geocoding API (Fast, free, reliable)
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en',
      );
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'MausamApp/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final city = (data['city'] as String?)?.trim() ??
            (data['locality'] as String?)?.trim() ??
            (data['principalSubdivision'] as String?)?.trim();
        final state = (data['principalSubdivision'] as String?)?.trim() ??
            (data['countryName'] as String?)?.trim();

        if (city != null && city.isNotEmpty) {
          if (state != null && state.isNotEmpty && city != state) {
            return '$city, $state';
          }
          return city;
        }
      }
    } catch (_) {}

    try {
      // 2. Fallback: OpenStreetMap Nominatim Reverse Geocoding
      final nomUri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=12',
      );
      final nomRes = await http.get(
        nomUri,
        headers: {'User-Agent': 'MausamApp/1.0 (contact: mausam@app.internal)'},
      ).timeout(const Duration(seconds: 5));

      if (nomRes.statusCode == 200) {
        final nomData = jsonDecode(nomRes.body) as Map<String, dynamic>;
        final address = nomData['address'] as Map<String, dynamic>?;
        if (address != null) {
          final city = (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['state_district'] ??
              address['county'] ??
              address['suburb'] ??
              address['municipality']) as String?;
          final state = (address['state'] ?? address['country']) as String?;
          if (city != null && city.isNotEmpty) {
            if (state != null && state.isNotEmpty && city != state) {
              return '$city, $state';
            }
            return city;
          }
        }
      }
    } catch (_) {}

    // 3. Fallback: Closest popular city by geometric distance
    double minDistance = double.infinity;
    String closestName = 'New Delhi, Delhi';

    for (final city in AppConstants.popularCities) {
      final double cLat = city['lat'];
      final double cLon = city['lon'];
      final double dLat = lat - cLat;
      final double dLon = lon - cLon;
      final double dist = (dLat * dLat) + (dLon * dLon);
      if (dist < minDistance) {
        minDistance = dist;
        closestName = '${city['name']}, ${city['state']}';
      }
    }

    return closestName;
  }
}
