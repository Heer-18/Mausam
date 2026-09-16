import 'package:flutter/services.dart';
import 'cache_service.dart';

class DynamicIconService {
  static const MethodChannel _channel = MethodChannel('com.mausam.app/dynamic_icon');

  static const String themeAuto = 'auto';
  static const String themeDefault = 'default';
  static const String themeSunny = 'sunny';
  static const String themeRainy = 'rainy';
  static const String themeCloudy = 'cloudy';
  static const String themeNight = 'night';

  /// Apply an icon preset directly or update dynamically based on live weather
  static Future<void> updateWeatherAdaptiveIcon({
    required int weatherCode,
    required bool isNight,
  }) async {
    try {
      final savedTheme = await CacheService.getString(
        CacheService.keyDynamicIconTheme,
        defaultValue: themeAuto,
      );

      String targetAlias = 'default';

      if (savedTheme == themeAuto) {
        if (isNight) {
          targetAlias = 'night';
        } else if ((weatherCode >= 51 && weatherCode <= 67) ||
            (weatherCode >= 80 && weatherCode <= 82) ||
            (weatherCode >= 95 && weatherCode <= 99)) {
          targetAlias = 'rainy';
        } else if (weatherCode == 2 || weatherCode == 3 || weatherCode == 45 || weatherCode == 48) {
          targetAlias = 'cloudy';
        } else {
          targetAlias = 'sunny';
        }
      } else {
        targetAlias = savedTheme;
      }

      await setIcon(targetAlias);
    } catch (_) {
      // Gracefully handle if platform channel not supported on current platform
    }
  }

  /// Explicitly set the app launcher icon alias
  static Future<bool> setIcon(String iconName) async {
    try {
      final String? result = await _channel.invokeMethod<String>('setIcon', {
        'icon': iconName,
      });
      return result == 'success';
    } catch (_) {
      return false;
    }
  }
}
