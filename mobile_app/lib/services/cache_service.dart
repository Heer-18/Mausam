import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String keyWeatherPrefix = 'mausam_weather_cache_';
  static const String keySavedLat = 'mausam_saved_lat';
  static const String keySavedLon = 'mausam_saved_lon';
  static const String keySavedCity = 'mausam_saved_city';
  static const String keySavedPersona = 'mausam_saved_persona';
  static const String keyChatHistory = 'mausam_chat_history';
  static const String keyChatSessions = 'mausam_chat_sessions_v1';
  static const String keyActiveSessionId = 'mausam_active_session_id';

  // Homescreen Section Customization Keys
  static const String keyShowMiniMetrics = 'mausam_show_mini_metrics';
  static const String keyShowPersonalizedInsights = 'mausam_show_insights';
  static const String keyShowHourlyForecast = 'mausam_show_hourly';
  static const String keyShowDailyForecast = 'mausam_show_daily';
  static const String keyShowCelestialAlmanac = 'mausam_show_celestial';

  // Units & Formats Keys
  static const String keyTemperatureUnit = 'mausam_temp_unit'; // 'C' or 'F'
  static const String keyWindSpeedUnit = 'mausam_wind_unit'; // 'km/h', 'mph', 'm/s'

  // Notification Automation Keys
  static const String keyAutoNotifications = 'mausam_auto_notifications';
  static const String keyWittyAlerts = 'mausam_witty_alerts';
  static const String keyMorningBriefing = 'mausam_morning_briefing';
  static const String keyLastWittyAlertTime = 'mausam_last_witty_alert_time';
  static const String keyLastMorningDate = 'mausam_last_morning_date';

  // Dynamic Icon Theme
  static const String keyDynamicIconTheme = 'mausam_dynamic_icon_theme'; // 'auto', 'default', 'sunny', 'rainy', 'cloudy', 'night'

  // Custom Selected Parameters Key
  static const String keyCustomParameterIds = 'mausam_custom_param_ids';
  static String getPersonaCustomParamsKey(String personaName) => 'mausam_params_$personaName';

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

  /// Save Chat History (Legacy single session fallback)
  static Future<void> saveChatHistory(List<Map<String, dynamic>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyChatHistory, jsonEncode(messages));
  }

  /// Load Chat History (Legacy single session fallback)
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

  /// Save All Multi-Session Chat Threads
  static Future<void> saveAllChatSessions(List<Map<String, dynamic>> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyChatSessions, jsonEncode(sessions));
    } catch (_) {}
  }

  /// Load All Multi-Session Chat Threads
  static Future<List<Map<String, dynamic>>> loadAllChatSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(keyChatSessions);
      if (str == null) return [];
      final List<dynamic> list = jsonDecode(str);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save Active Session ID
  static Future<void> saveActiveSessionId(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyActiveSessionId, sessionId);
    } catch (_) {}
  }

  /// Load Active Session ID
  static Future<String?> loadActiveSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyActiveSessionId);
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // HOMESCREEN CUSTOMIZATION & SETTINGS PERSISTENCE
  // =========================================================================

  static Future<void> saveBool(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  static Future<bool> getBool(String key, {bool defaultValue = true}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  static Future<void> saveString(String key, String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, val);
  }

  static Future<String> getString(String key, {String defaultValue = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
  }

  static Future<void> saveInt(String key, int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, val);
  }

  static Future<int> getInt(String key, {int defaultValue = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? defaultValue;
  }

  static Future<void> saveStringList(String key, List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, list);
  }

  static Future<List<String>?> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }
}
