import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String keyWeatherPrefix = 'mausam_weather_cache_';
  static const String keySavedLat = 'mausam_saved_lat';
  static const String keySavedLon = 'mausam_saved_lon';
  static const String keySavedCity = 'mausam_saved_city';
  static const String keySavedPersona = 'mausam_saved_persona';
  static const String keyChatHistory = 'mausam_chat_history';

  static const int cacheValidityMinutes = 15;

  /// Cache weather data with current timestamp
  static Future<void> cacheWeatherData({
    required double lat,
    required double lon,
    required Map<String, dynamic> weatherData,
    required Map<String, dynamic> airData,
    Map<String, dynamic>? marineData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$keyWeatherPrefix${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
      
      final payload = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'weather': weatherData,
        'air': airData,
        'marine': marineData ?? {},
      };

      await prefs.setString(cacheKey, jsonEncode(payload));
    } catch (e) {
      // Ignore cache write errors
    }
  }

  /// Retrieve cached weather data if within 15-minute validity window
  static Future<Map<String, dynamic>?> getCachedWeatherData({
    required double lat,
    required double lon,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$keyWeatherPrefix${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}';
      final cachedStr = prefs.getString(cacheKey);

      if (cachedStr == null) return null;

      final Map<String, dynamic> payload = jsonDecode(cachedStr);
      final int timestamp = payload['timestamp'] ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;

      final int diffMinutes = ((now - timestamp) / (1000 * 60)).round();
      if (diffMinutes <= cacheValidityMinutes) {
        return payload;
      }
      return null; // Expired
    } catch (e) {
      return null;
    }
  }

  /// Save active location
  static Future<void> saveLocation({
    required double lat,
    required double lon,
    required String cityName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keySavedLat, lat);
    await prefs.setDouble(keySavedLon, lon);
    await prefs.setString(keySavedCity, cityName);
  }

  /// Load saved location
  static Future<Map<String, dynamic>?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(keySavedLat);
    final lon = prefs.getDouble(keySavedLon);
    final city = prefs.getString(keySavedCity);

    if (lat != null && lon != null && city != null) {
      return {'lat': lat, 'lon': lon, 'city': city};
    }
    return null;
  }

  /// Save selected persona
  static Future<void> savePersona(String personaName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySavedPersona, personaName);
  }

  /// Load selected persona
  static Future<String?> getSavedPersona() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keySavedPersona);
  }

  /// Save Chat History
  static Future<void> saveChatHistory(List<Map<String, dynamic>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyChatHistory, jsonEncode(messages));
  }

  /// Load Chat History
  static Future<List<Map<String, dynamic>>> loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(keyChatHistory);
      if (str == null) return [];
      final List<dynamic> list = jsonDecode(str);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }
}
