import 'package:flutter/material.dart';

class WeatherIcons {
  static IconData getIconForWmoCode(int code, {bool isDay = true}) {
    switch (code) {
      case 0:
        return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
      case 1:
        return isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined;
      case 2:
        return isDay ? Icons.wb_cloudy_rounded : Icons.cloud_outlined;
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return Icons.grain_rounded;
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
        return Icons.water_drop_rounded;
      case 71:
      case 73:
      case 75:
      case 77:
        return Icons.ac_unit_rounded;
      case 80:
      case 81:
      case 82:
        return Icons.beach_access_rounded;
      case 85:
      case 86:
        return Icons.severe_cold_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }

  static Color getIconColorForWmoCode(int code) {
    if (code == 0 || code == 1) {
      return const Color(0xFFF59E0B); // Solar amber
    } else if (code >= 95) {
      return const Color(0xFFEF4444); // Alert red
    } else if (code >= 51 && code <= 82) {
      return const Color(0xFF06B6D4); // Cyan/Rain
    } else if (code >= 71 && code <= 86) {
      return const Color(0xFFADC6FF); // Ice
    } else {
      return const Color(0xFFADC6FF); // Cloud blue
    }
  }
}
