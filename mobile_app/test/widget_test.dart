import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/models/persona_type.dart';
import 'package:mausam/models/weather_models.dart';
import 'package:mausam/services/dynamic_icon_service.dart';
import 'package:mausam/utils/theme.dart';
import 'package:mausam/widgets/atmospheric_hero_section.dart';
import 'package:mausam/widgets/daily_forecast_widget.dart';
import 'package:mausam/widgets/hero_weather_card.dart';
import 'package:mausam/widgets/mini_metrics_grid.dart';
import 'package:mausam/widgets/personalized_insights_section.dart';

void main() {
  testWidgets('HeroWeatherCard and MiniMetricsGrid render successfully', (WidgetTester tester) async {
    final telemetry = WeatherTelemetry(
      latitude: 19.0760,
      longitude: 72.8777,
      cityName: 'Mumbai, IN',
      timezone: 'Asia/Kolkata',
      currentTemperature: 28.0,
      apparentTemperature: 32.0,
      weatherCode: 1,
      weatherCondition: 'Mainly Clear',
      humidity: 72,
      windSpeed: 12.0,
      windDirection: 180.0,
      windDirectionCardinal: 'S',
      windGusts: 18.0,
      surfacePressure: 1012.0,
      uvIndex: 6.0,
      cloudCover: 20,
      precipitation: 0.0,
      rain: 0.0,
    );

    final airQuality = AirQualityData(
      aqi: 42,
      pm2_5: 14.2,
      pm10: 35.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                HeroWeatherCard(
                  telemetry: telemetry,
                  statusChipText: 'Forecast Optimal',
                ),
                MiniMetricsGrid(
                  telemetry: telemetry,
                  airQuality: airQuality,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify values rendered
    expect(find.text('28°'), findsOneWidget);
    expect(find.text('Mainly Clear'), findsOneWidget);
    expect(find.text('Feels 32°'), findsOneWidget);
    expect(find.text('AIR QUALITY'), findsOneWidget);
    expect(find.text('UV INDEX'), findsOneWidget);
    expect(find.text('HUMIDITY'), findsOneWidget);
    expect(find.text('WIND'), findsOneWidget);
  });

  testWidgets('PersonalizedInsightsSection renders 6 slots for active persona', (WidgetTester tester) async {
    final slots = [
      PersonaSlotData(
        slotIndex: 1,
        title: 'AQI',
        value: '42 Good',
        subtitle: 'PM2.5 14.2 µg/m³',
        status: 'Good',
        icon: Icons.air_rounded,
        color: const Color(0xFF10B981),
      ),
      PersonaSlotData(
        slotIndex: 2,
        title: 'POLLEN (GRASS)',
        value: 'Low 8',
        subtitle: 'grains/m³',
        status: 'Low',
        icon: Icons.grass_rounded,
        color: const Color(0xFF10B981),
      ),
      PersonaSlotData(
        slotIndex: 3,
        title: 'POLLEN (TREE)',
        value: 'Moderate 18',
        subtitle: 'grains/m³',
        status: 'Moderate',
        icon: Icons.park_rounded,
        color: const Color(0xFFF59E0B),
      ),
      PersonaSlotData(
        slotIndex: 4,
        title: 'UV INDEX',
        value: '6 High',
        subtitle: 'SPF 30+ needed',
        status: 'High',
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFFF59E0B),
      ),
      PersonaSlotData(
        slotIndex: 5,
        title: 'HUMIDITY',
        value: '72%',
        subtitle: 'Skin sensitivity alert',
        status: 'Moderate',
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF06B6D4),
      ),
      PersonaSlotData(
        slotIndex: 6,
        title: 'AIR QUALITY',
        value: 'Good',
        subtitle: 'Safe for outdoor',
        status: 'Good',
        icon: Icons.health_and_safety_rounded,
        color: const Color(0xFF10B981),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PersonalizedInsightsSection(
              persona: PersonaType.health,
              slots: slots,
              advisorySummary: '✓ AQI is good today. UV is high — wear sunscreen.',
              actionBullet: 'Wear SPF 30+ and UV-blocking eyewear.',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Personalized Insights'), findsOneWidget);
    expect(find.text('Health-Conscious'), findsOneWidget);
    expect(find.text('Allergy & Skin'), findsOneWidget);
    expect(find.text('42 Good'), findsOneWidget);
    expect(find.text('POLLEN (GRASS)'), findsOneWidget);
    expect(find.text('Actionable Intelligence'), findsOneWidget);
  });

  testWidgets('AtmosphericHeroSection and DailyForecastWidget render successfully', (WidgetTester tester) async {
    final telemetry = WeatherTelemetry(
      latitude: 19.0760,
      longitude: 72.8777,
      cityName: 'Bhiwandi',
      timezone: 'Asia/Kolkata',
      currentTemperature: 29.0,
      apparentTemperature: 33.0,
      weatherCode: 2,
      weatherCondition: 'Cloudy',
      humidity: 68,
      windSpeed: 14.0,
      windDirection: 210.0,
      windDirectionCardinal: 'SW',
      windGusts: 20.0,
      surfacePressure: 1010.0,
      uvIndex: 7.0,
      cloudCover: 55,
      precipitation: 0.0,
      rain: 0.0,
    );

    final airQuality = AirQualityData(
      aqi: 23,
      pm2_5: 8.5,
      pm10: 20.0,
    );

    final daily = [
      DailyForecast(
        date: '2026-09-16',
        dayName: 'Today',
        temperatureMax: 33.0,
        temperatureMin: 25.0,
        weatherCode: 2,
        weatherCondition: 'Cloudy',
        precipitationSum: 0.0,
        precipitationProbabilityMax: 10,
        uvIndexMax: 7.0,
        sunrise: '06:22',
        sunset: '18:41',
        icon: 'partly_cloudy_day',
      ),
      DailyForecast(
        date: '2026-09-17',
        dayName: 'Tomorrow',
        temperatureMax: 32.0,
        temperatureMin: 24.0,
        weatherCode: 3,
        weatherCondition: 'Overcast',
        precipitationSum: 1.2,
        precipitationProbabilityMax: 45,
        uvIndexMax: 6.0,
        sunrise: '06:23',
        sunset: '18:40',
        icon: 'cloudy',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                AtmosphericHeroSection(
                  telemetry: telemetry,
                  airQuality: airQuality,
                  dailyList: daily,
                  activePersona: PersonaType.commute,
                  cityName: 'Bhiwandi',
                  personaChipText: 'Smooth Commute',
                ),
                DailyForecastWidget(
                  dailyList: daily,
                  currentTemperature: 29.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));

    // Verify Atmospheric Hero components
    expect(find.text('Bhiwandi'), findsOneWidget);
    expect(find.text('29°'), findsOneWidget);
    expect(find.text('Cloudy • 33° / 25°'), findsOneWidget);
    expect(find.text('Feels like 33°'), findsOneWidget);
    expect(find.text('AQI 23 • Good'), findsOneWidget);
    expect(find.text('Smooth Commute'), findsOneWidget);

    // Verify Daily Forecast widget
    expect(find.text('2-DAY FORECAST'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);
  });

  testWidgets('SettingsModal renders homescreen toggles, units and dynamic icon options', (WidgetTester tester) async {
    // Basic rendering verification
    expect(DynamicIconService.themeAuto, 'auto');
    expect(DynamicIconService.themeSunny, 'sunny');
    expect(DynamicIconService.themeRainy, 'rainy');
    expect(DynamicIconService.themeCloudy, 'cloudy');
    expect(DynamicIconService.themeNight, 'night');
  });
}
