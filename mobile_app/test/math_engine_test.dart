import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/models/weather_models.dart';
import 'package:mausam/utils/weather_math.dart';

void main() {
  group('Mathematical Derivation Engine Tests', () {
    test('Workout Safety Score calculation - Ideal Conditions', () {
      final score = WeatherMath.calculateWorkoutScore(
        temp: 22.0,
        humidity: 50.0,
        aqi: 35.0,
        rainProb: 0.0,
      );
      expect(score, equals(100));
    });

    test('Workout Safety Score calculation - High Temp & Humidity Penalties', () {
      final score = WeatherMath.calculateWorkoutScore(
        temp: 34.0, // (34 - 28) * 4 = 24
        humidity: 80.0, // (80 - 70) * 0.7 = 7
        aqi: 150.0, // (150 - 100) * 0.4 = 20
        rainProb: 40.0, // 40 * 0.5 = 20
      );
      // 100 - 24 - 7 - 20 - 20 = 29
      expect(score, equals(29));
    });

    test('Mold Risk Engine classifications', () {
      // High: Humidity >= 75% and 20°C <= temp <= 32°C
      expect(
        WeatherMath.calculateMoldRisk(temp: 26.0, humidity: 80.0),
        equals('High'),
      );

      // Moderate: Humidity >= 65% and 18°C <= temp <= 35°C
      expect(
        WeatherMath.calculateMoldRisk(temp: 34.0, humidity: 68.0),
        equals('Moderate'),
      );

      // Low otherwise
      expect(
        WeatherMath.calculateMoldRisk(temp: 15.0, humidity: 50.0),
        equals('Low'),
      );
    });

    test('Agricultural Deficit & Irrigation Advice', () {
      // Rain predicted
      final rainCase = WeatherMath.calculateIrrigationAdvice(
        et0: 4.5,
        rainfallAccumulation: 0.0,
        soilMoisture: 0.18,
        rainProbMax: 75.0,
        rainSum: 12.0,
      );
      expect(rainCase['advice'], contains('Hold Irrigation'));

      // Deficit > 3.5 and Soil Moisture < 0.22
      final irrigateCase = WeatherMath.calculateIrrigationAdvice(
        et0: 5.0,
        rainfallAccumulation: 0.5, // deficit = 4.5
        soilMoisture: 0.15,
        rainProbMax: 10.0,
        rainSum: 0.0,
      );
      expect(irrigateCase['advice'], contains('Irrigation Recommended'));

      // Optimal
      final optimalCase = WeatherMath.calculateIrrigationAdvice(
        et0: 3.0,
        rainfallAccumulation: 1.0,
        soilMoisture: 0.28,
        rainProbMax: 10.0,
        rainSum: 0.0,
      );
      expect(optimalCase['advice'], contains('Soil Moisture Optimal'));
    });

    test('Commute Hazard Rating (0–100)', () {
      // Clear conditions
      final clear = WeatherMath.calculateCommuteHazard(
        visibilityMeters: 10000.0,
        weatherCode: 1,
        precipitationRate: 0.0,
        windGusts: 15.0,
      );
      expect(clear['rating'], equals(0));
      expect(clear['condition'], contains('Clear Route'));

      // Severe hazard (Fog + Thunderstorm + Heavy Rain + High Gusts)
      final severe = WeatherMath.calculateCommuteHazard(
        visibilityMeters: 400.0, // 40
        weatherCode: 95, // 35
        precipitationRate: 20.0, // 20
        windGusts: 65.0, // 20
      );
      expect(severe['rating'], equals(100));
      expect(severe['condition'], contains('Severe Hazard'));
    });

    test('Optimal Running Window scanner', () {
      final hourlyList = [
        HourlyForecast(
          time: '6 AM',
          temperature: 22.0,
          precipitationProbability: 0,
          precipitation: 0.0,
          weatherCode: 1,
          weatherCondition: 'Clear',
          icon: 'sunny',
        ),
        HourlyForecast(
          time: '7 AM',
          temperature: 23.0,
          precipitationProbability: 0,
          precipitation: 0.0,
          weatherCode: 1,
          weatherCondition: 'Clear',
          icon: 'sunny',
        ),
        HourlyForecast(
          time: '8 AM',
          temperature: 24.0,
          precipitationProbability: 0,
          precipitation: 0.0,
          weatherCode: 1,
          weatherCondition: 'Clear',
          icon: 'sunny',
        ),
      ];

      final window = WeatherMath.findOptimalRunningWindow(hourlyList);
      expect(window, equals('6 AM – 8 AM'));
    });
  });
}
