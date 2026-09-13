import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/city_search_result.dart';
import '../utils/constants.dart';

class WeatherService {
  final http.Client _client = http.Client();

  /// Fetch forecast, soil, and UV index telemetry
  Future<Map<String, dynamic>> fetchForecastData({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(AppConstants.forecastApiUrl).replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,rain,weather_code,cloud_cover,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m,uv_index',
        'hourly': 'temperature_2m,relative_humidity_2m,precipitation_probability,precipitation,weather_code,visibility,evapotranspiration,soil_moisture_0_to_7cm',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_sum,precipitation_probability_max,wind_speed_10m_max',
        'timezone': 'auto',
      },
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json;
    } else {
      throw Exception('Failed to fetch forecast telemetry: HTTP ${response.statusCode}');
    }
  }

  /// Parse UV Index safely with fallback to daily max and 0.0 for night
  static double parseUvIndexSafely(Map<String, dynamic> json) {
    final currentData = json['current'] as Map<String, dynamic>? ?? {};
    final dailyData = json['daily'] as Map<String, dynamic>? ?? {};
    final double uv = (currentData['uv_index'] as num?)?.toDouble() ??
        ((dailyData['uv_index_max'] as List?)?.isNotEmpty == true
            ? (dailyData['uv_index_max'][0] as num).toDouble()
            : 0.0);
    return uv;
  }

  /// Fetch Air Quality & Pollen Telemetry
  Future<Map<String, dynamic>> fetchAirQualityData({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(AppConstants.airQualityApiUrl).replace(
      queryParameters: {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current': 'european_aqi,pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,ozone,dust,alder_pollen,birch_pollen,grass_pollen,ragweed_pollen',
        'timezone': 'auto',
      },
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch air quality telemetry: HTTP ${response.statusCode}');
    }
  }

  /// Fetch Marine Conditions
  Future<Map<String, dynamic>?> fetchMarineData({
    required double lat,
    required double lon,
  }) async {
    try {
      final uri = Uri.parse(AppConstants.marineApiUrl).replace(
        queryParameters: {
          'latitude': lat.toString(),
          'longitude': lon.toString(),
          'current': 'wave_height,wave_direction,wave_period,wind_wave_height,swell_wave_height',
          'timezone': 'auto',
        },
      );

      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Marine data may not exist for inland coordinates
    }
    return null;
  }

  /// Search matching cities via Open-Meteo Geocoding API
  Future<List<CitySearchResult>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(AppConstants.geocodingApiUrl).replace(
        queryParameters: {
          'name': query.trim(),
          'count': '6',
          'language': 'en',
          'format': 'json',
        },
      );

      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List<dynamic>?;
        if (results != null) {
          return results.map((e) => CitySearchResult.fromJson(e)).toList();
        }
      }
    } catch (e) {
      final lower = query.toLowerCase();
      return AppConstants.popularCities
          .where((c) => (c['name'] as String).toLowerCase().contains(lower) || (c['state'] as String).toLowerCase().contains(lower))
          .map((c) => CitySearchResult(
                id: c['name'].hashCode,
                name: c['name'],
                latitude: c['lat'],
                longitude: c['lon'],
                country: 'India',
                admin1: c['state'],
              ))
          .toList();
    }
    return [];
  }
}
