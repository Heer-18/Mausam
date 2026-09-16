import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/persona_type.dart';
import '../providers/weather_provider.dart';
import '../utils/theme.dart';
import '../widgets/alert_banner.dart';
import '../widgets/atmospheric_hero_section.dart';
import '../widgets/celestial_almanac_card.dart';
import '../widgets/daily_forecast_widget.dart';
import '../widgets/hourly_forecast_widget.dart';
import '../widgets/location_search_modal.dart';
import '../widgets/mini_metrics_grid.dart';
import '../widgets/notifications_modal.dart';
import '../widgets/persona_modal.dart';
import '../widgets/personalized_insights_section.dart';
import '../widgets/settings_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
        final topPadding = MediaQuery.of(context).padding.top;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceContainer,
            onRefresh: () => provider.fetchWeatherData(isRefresh: true),
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(16.0, topPadding + 6.0, 16.0, 80.0),
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

                // Atmospheric Borderless Hero Section with Moving Cloud Overlap & Status Pills
                if (telemetry != null)
                  AtmosphericHeroSection(
                    telemetry: telemetry,
                    airQuality: airQuality,
                    dailyList: provider.dailyForecast,
                    activePersona: provider.activePersona,
                    cityName: provider.cityName,
                    alertCount: provider.alerts.length,
                    personaChipText: provider.activePersona == PersonaType.fitness
                        ? 'Best Run: ${provider.optimalRunningWindow}'
                        : (provider.activePersona == PersonaType.farm
                            ? provider.irrigationAdvice.split('—')[0].trim()
                            : (provider.alerts.isNotEmpty
                                ? provider.alerts.first.title
                                : 'Forecast Optimal')),
                    personaChipIcon: provider.activePersona == PersonaType.fitness
                        ? Icons.directions_run_rounded
                        : (provider.activePersona == PersonaType.farm
                            ? Icons.eco_rounded
                            : Icons.check_circle_outline_rounded),
                    personaChipColor: provider.activePersona.accentColor,
                    onLocationTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const LocationSearchModal(),
                      );
                    },
                    onSearchTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const LocationSearchModal(),
                      );
                    },
                    onNotificationsTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const NotificationsModal(),
                      );
                    },
                    onSettingsTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const SettingsModal(),
                      );
                    },
                    onPersonaTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const PersonaModal(),
                      );
                    },
                  ),
                const SizedBox(height: 18),

                // 4 Mini-Cards Grid (AQI, UV, Humidity, Wind)
                if (provider.showMiniMetrics && telemetry != null && airQuality != null) ...[
                  MiniMetricsGrid(
                    telemetry: telemetry,
                    airQuality: airQuality,
                  ),
                  const SizedBox(height: 16),
                ],

                // Tier 2 Personalized Insights Section (With Scroll-Driven Dynamic Parameter Animations)
                if (provider.showPersonalizedInsights) ...[
                  PersonalizedInsightsSection(
                    persona: provider.activePersona,
                    slots: provider.personaSlots,
                    advisorySummary: provider.advisorySummary,
                    actionBullet: provider.actionBullet,
                    scrollController: _scrollController,
                  ),
                  const SizedBox(height: 20),
                ],

                // Tier 3 Baseline: 24-Hour Hourly Forecast
                if (provider.showHourlyForecast) ...[
                  HourlyForecastWidget(hourlyList: provider.hourlyForecast),
                  const SizedBox(height: 20),
                ],

                // Tier 3 Baseline: 7-Day Daily Forecast List
                if (provider.showDailyForecast) ...[
                  DailyForecastWidget(
                    dailyList: provider.dailyForecast,
                    currentTemperature: telemetry?.currentTemperature,
                  ),
                  const SizedBox(height: 20),
                ],

                // Celestial Almanac & Moon Phase Card
                if (provider.showCelestialAlmanac) ...[
                  CelestialAlmanacCard(
                    telemetry: telemetry,
                    todayForecast: provider.dailyForecast.isNotEmpty ? provider.dailyForecast.first : null,
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
