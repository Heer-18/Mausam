import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/persona_type.dart';
import '../providers/weather_provider.dart';
import '../utils/theme.dart';
import '../widgets/alert_banner.dart';
import '../widgets/daily_forecast_widget.dart';
import '../widgets/hero_weather_card.dart';
import '../widgets/hourly_forecast_widget.dart';
import '../widgets/location_search_modal.dart';
import '../widgets/mini_metrics_grid.dart';
import '../widgets/personalized_insights_section.dart';
import '../widgets/top_app_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.telemetry == null) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundStart,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Loading Mausam Intelligence...',
                    style: AppTypography.bodyMd,
                  ),
                ],
              ),
            ),
          );
        }

        final telemetry = provider.telemetry;
        final airQuality = provider.airQuality;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const MausamTopAppBar(),
          body: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainer,
            onRefresh: () => provider.fetchWeatherData(isRefresh: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 80.0),
              children: [
                // First-time Location Prompt Banner if needed
                if (provider.needsLocationSelection)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const LocationSearchModal(),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_searching_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Choose Your Location',
                                    style: AppTypography.titleMd.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap here to search your city or enable GPS detection.',
                                    style: AppTypography.bodySm.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Tier 1 Alerts Banner (Prepend dynamically if active)
                if (provider.alerts.isNotEmpty) ...[
                  ...provider.alerts.map(
                    (alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: AlertBanner(alert: alert),
                    ),
                  ),
                ],

                // Hero Weather Card
                if (telemetry != null)
                  HeroWeatherCard(
                    telemetry: telemetry,
                    statusChipText: provider.activePersona == PersonaType.fitness
                        ? 'Best Run: ${provider.optimalRunningWindow}'
                        : (provider.activePersona == PersonaType.farm
                            ? provider.irrigationAdvice.split('—')[0].trim()
                            : (provider.alerts.isNotEmpty
                                ? provider.alerts.first.title
                                : 'Forecast Optimal')),
                    statusChipIcon: provider.activePersona == PersonaType.fitness
                        ? Icons.directions_run_rounded
                        : (provider.activePersona == PersonaType.farm
                            ? Icons.eco_rounded
                            : Icons.check_circle_outline_rounded),
                    statusChipColor: provider.activePersona.accentColor,
                  ),
                const SizedBox(height: 14),

                // 4 Mini-Cards Grid (AQI, UV, Humidity, Wind)
                if (telemetry != null && airQuality != null)
                  MiniMetricsGrid(
                    telemetry: telemetry,
                    airQuality: airQuality,
                  ),
                const SizedBox(height: 16),

                // Tier 2 Personalized Insights Section
                PersonalizedInsightsSection(
                  persona: provider.activePersona,
                  slots: provider.personaSlots,
                  advisorySummary: provider.advisorySummary,
                  actionBullet: provider.actionBullet,
                ),
                const SizedBox(height: 24),

                // Tier 3 Baseline: 24-Hour Hourly Forecast
                HourlyForecastWidget(hourlyList: provider.hourlyForecast),
                const SizedBox(height: 24),

                // Tier 3 Baseline: 7-Day Daily Forecast List
                DailyForecastWidget(dailyList: provider.dailyForecast),
              ],
            ),
          ),
        );
      },
    );
  }
}
