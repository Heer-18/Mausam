import 'dart:math';
import '../models/weather_models.dart';

class WeatherMath {
  /// Calculate Workout Safety Score (0–100)
  static int calculateWorkoutScore({
    required double temp,
    required double humidity,
    required double aqi,
    required double rainProb,
  }) {
    final double tempPenalty = temp > 28.0 ? (temp - 28.0) * 4.0 : 0.0;
    final double humidityPenalty = humidity > 70.0 ? (humidity - 70.0) * 0.7 : 0.0;
    final double aqiPenalty = aqi > 100.0 ? (aqi - 100.0) * 0.4 : 0.0;
    final double rainPenalty = rainProb * 0.5;

    final double rawScore = 100.0 - tempPenalty - humidityPenalty - aqiPenalty - rainPenalty;
    return rawScore.clamp(0.0, 100.0).round();
  }

  /// Scan upcoming 12 hours and find optimal running window
  static String findOptimalRunningWindow(List<HourlyForecast> hourlyList) {
    if (hourlyList.isEmpty) return '6:00 AM – 8:00 AM';

    final List<int> scores = [];
    final List<int> qualifyingIndices = [];

    final int limit = min(12, hourlyList.length);
    for (int i = 0; i < limit; i++) {
      final h = hourlyList[i];
      final sc = calculateWorkoutScore(
        temp: h.temperature,
        humidity: 65.0, // baseline
        aqi: 45.0,
        rainProb: h.precipitationProbability.toDouble(),
      );
      scores.add(sc);
      if (sc >= 75) {
        qualifyingIndices.add(i);
      }
    }

    if (qualifyingIndices.isEmpty) {
      if (scores.isEmpty) return 'Early Morning (6:00 AM)';
      int maxIdx = 0;
      int maxScore = scores[0];
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIdx = i;
        }
      }
      return 'Best: ${hourlyList[maxIdx].time} (Score $maxScore)';
    }

    // Group contiguous
    final List<List<int>> blocks = [];
    List<int> currentBlock = [qualifyingIndices[0]];

    for (int i = 1; i < qualifyingIndices.length; i++) {
      final idx = qualifyingIndices[i];
      if (idx == currentBlock.last + 1) {
        currentBlock.add(idx);
      } else {
        blocks.add(currentBlock);
        currentBlock = [idx];
      }
    }
    blocks.add(currentBlock);

    // Pick longest block
    List<int> longestBlock = blocks[0];
    for (var b in blocks) {
      if (b.length > longestBlock.length) {
        longestBlock = b;
      }
    }

    final start = hourlyList[longestBlock.first].time;
    final end = hourlyList[longestBlock.last].time;

    if (longestBlock.length == 1) {
      return 'Around $start';
    }
    return '$start – $end';
  }

  /// Mold Risk Engine
  static String calculateMoldRisk({
    required double temp,
    required double humidity,
  }) {
    if (humidity >= 75.0 && temp >= 20.0 && temp <= 32.0) {
      return 'High';
    } else if (humidity >= 65.0 && temp >= 18.0 && temp <= 35.0) {
      return 'Moderate';
    }
    return 'Low';
  }

  /// Agricultural Deficit & Irrigation Advice
  static Map<String, dynamic> calculateIrrigationAdvice({
    required double et0,
    required double rainfallAccumulation,
    required double soilMoisture,
    required double rainProbMax,
    required double rainSum,
  }) {
    final double deficit = (et0 - rainfallAccumulation);
    final double formattedDeficit = double.parse(deficit.toStringAsFixed(1));

    String advice;
    String status;

    if (rainProbMax > 60.0 || rainSum > 8.0) {
      advice = 'Hold Irrigation — Rain Predicted';
      status = 'Rain Imminent';
    } else if (formattedDeficit > 3.5 && soilMoisture < 0.22) {
      advice = 'Irrigation Recommended (20–30 min cycle)';
      status = 'Action Required';
    } else {
      advice = 'Soil Moisture Optimal — No Irrigation Needed';
      status = 'Optimal';
    }

    return {
      'advice': advice,
      'deficit': formattedDeficit,
      'status': status,
    };
  }

  /// Commute Hazard Rating (0–100)
  static Map<String, dynamic> calculateCommuteHazard({
    required double visibilityMeters,
    required int weatherCode,
    required double precipitationRate,
    required double windGusts,
  }) {
    double hazard = 0.0;

    if (visibilityMeters < 500) {
      hazard += 40.0;
    } else if (visibilityMeters < 1000) {
      hazard += 30.0;
    } else if (visibilityMeters < 2000) {
      hazard += 20.0;
    } else if (visibilityMeters < 5000) {
      hazard += 10.0;
    }

    // Fog presence (45: fog, 48: depositing rime fog)
    if (weatherCode == 45 || weatherCode == 48) {
      hazard += 25.0;
    }

    // Thunderstorm or heavy rain
    if (weatherCode >= 95) {
      hazard += 35.0;
    } else if (weatherCode == 65 || weatherCode == 67 || weatherCode == 82) {
      hazard += 25.0;
    } else if (weatherCode == 61 || weatherCode == 63 || weatherCode == 80 || weatherCode == 81) {
      hazard += 15.0;
    }

    if (precipitationRate > 15.0) {
      hazard += 20.0;
    } else if (precipitationRate > 5.0) {
      hazard += 10.0;
    } else if (precipitationRate > 1.0) {
      hazard += 5.0;
    }

    if (windGusts > 60.0) {
      hazard += 20.0;
    } else if (windGusts > 40.0) {
      hazard += 10.0;
    }

    final int rating = hazard.clamp(0.0, 100.0).round();

    String condition;
    if (rating >= 70) {
      condition = 'Severe Hazard — High Delay Risk';
    } else if (rating >= 40) {
      condition = 'Moderate Hazard — Wet Roads & Caution';
    } else if (rating >= 20) {
      condition = 'Minor Caution — Light Rain/Breeze';
    } else {
      condition = 'Clear Route — Normal Commute';
    }

    return {
      'rating': rating,
      'condition': condition,
    };
  }

  /// WMO Weather code to readable condition string
  static String getWeatherConditionString(int code) {
    switch (code) {
      case 0:
        return 'Clear Sky';
      case 1:
        return 'Mainly Clear';
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Overcast';
      case 45:
        return 'Foggy';
      case 48:
        return 'Depositing Rime Fog';
      case 51:
        return 'Light Drizzle';
      case 53:
        return 'Moderate Drizzle';
      case 55:
        return 'Dense Drizzle';
      case 56:
      case 57:
        return 'Freezing Drizzle';
      case 61:
        return 'Slight Rain';
      case 63:
        return 'Moderate Rain';
      case 65:
        return 'Heavy Rain';
      case 66:
      case 67:
        return 'Freezing Rain';
      case 71:
      case 73:
      case 75:
        return 'Snowfall';
      case 77:
        return 'Snow Grains';
      case 80:
        return 'Slight Showers';
      case 81:
        return 'Moderate Showers';
      case 82:
        return 'Violent Showers';
      case 85:
      case 86:
        return 'Snow Showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with Hail';
      default:
        return 'Partly Cloudy';
    }
  }

  /// Wind degree to cardinal direction
  static String windDegToCardinal(double deg) {
    const dirs = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final int idx = (((deg + 11.25) / 22.5).floor() % 16);
    return dirs[idx];
  }

  /// Categorize UV Index according to WHO standard scale
  static String getUvIndexLabel(double uv) {
    if (uv <= 2.0) {
      return 'Low';
    } else if (uv <= 5.0) {
      return 'Moderate';
    } else if (uv <= 7.0) {
      return 'High';
    } else if (uv <= 10.0) {
      return 'Very High';
    } else {
      return 'Extreme';
    }
  }

  /// Get formatted UV display string e.g. "0 Low", "6 High", "9 Very High"
  static String getUvDisplayString(double uv) {
    final label = getUvIndexLabel(uv);
    return '${uv.round()} $label';
  }
}
