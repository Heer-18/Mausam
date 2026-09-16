import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_models.dart';
import '../providers/weather_provider.dart';
import '../utils/theme.dart';
import 'glass_container.dart';

class NotificationsModal extends StatelessWidget {
  const NotificationsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, provider, _) {
        final alerts = provider.alerts;
        final telemetry = provider.telemetry;
        final airQuality = provider.airQuality;
        final persona = provider.activePersona;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: const Color(0xF80F172A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  // 1. Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // 2. Modal Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.electricCyan],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notification Center',
                                style: AppTypography.headlineMd.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${provider.cityName} • Live Weather Alerts',
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceVariant),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white10, height: 1),

                  // 3. Scrollable Notification Feed
                  Flexible(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      children: [
                        // System Status Bar Notification Controls & Test Buttons
                        GlassContainer(
                          padding: const EdgeInsets.all(14.0),
                          borderRadius: 20.0,
                          fillColor: AppColors.primaryContainer.withOpacity(0.12),
                          borderColor: AppColors.primaryContainer.withOpacity(0.3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_android_rounded,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'SYSTEM NOTIFICATIONS',
                                        style: AppTypography.labelCaps.copyWith(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch.adaptive(
                                    value: provider.notificationsEnabled,
                                    activeColor: AppColors.primary,
                                    onChanged: (val) {
                                      provider.toggleNotifications(val);
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                'Receive real-time weather alerts and AI persona suggestions in your phone notification drawer.',
                                style: AppTypography.bodySm.copyWith(
                                  fontSize: 11.5,
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.agriEmerald.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.agriEmerald.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.bolt_rounded, size: 16, color: AppColors.agriEmerald),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Automated AI Alerts & Contextual Weather Tips Active',
                                        style: AppTypography.labelCaps.copyWith(
                                          fontSize: 10.5,
                                          color: AppColors.agriEmerald,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Critical Weather Alerts (If Any)
                        if (alerts.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.alertRed),
                              const SizedBox(width: 6),
                              Text(
                                'CRITICAL WEATHER ALERTS',
                                style: AppTypography.labelCaps.copyWith(
                                  color: AppColors.alertRed,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...alerts.map((alert) => _buildAlertCard(alert)),
                          const SizedBox(height: 16),
                        ],

                        // Live Atmospheric Status Header
                        Row(
                          children: [
                            const Icon(Icons.sensors_rounded, size: 16, color: AppColors.electricCyan),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE TELEMETRY & ADVISORIES',
                              style: AppTypography.labelCaps.copyWith(
                                color: AppColors.electricCyan,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // All Clear Status Banner (when no severe warnings)
                        if (alerts.isEmpty)
                          _buildAllClearCard(provider.cityName),

                        const SizedBox(height: 10),

                        // Air Quality Advisory Card
                        if (airQuality != null)
                          _buildAdvisoryCard(
                            icon: Icons.eco_rounded,
                            iconColor: airQuality.aqi <= 50 ? AppColors.agriEmerald : AppColors.warningAmber,
                            title: 'Air Quality Advisory: AQI ${airQuality.aqi}',
                            subtitle: airQuality.aqi <= 50
                                ? 'Air quality is Good. Perfect for outdoor workouts, cycling, and general ventilation.'
                                : (airQuality.aqi <= 100
                                    ? 'Moderate air quality. Sensitive individuals should reduce prolonged outdoor exertion.'
                                    : 'Unhealthy air index. Wear an N95 mask outdoors and run indoor air purifiers.'),
                            badge: airQuality.aqi <= 50 ? 'Good Air' : 'Moderate',
                            badgeColor: airQuality.aqi <= 50 ? AppColors.agriEmerald : AppColors.warningAmber,
                          ),

                        const SizedBox(height: 10),

                        // UV & Sun Exposure Advisory
                        if (telemetry != null)
                          _buildAdvisoryCard(
                            icon: Icons.wb_sunny_rounded,
                            iconColor: telemetry.uvIndex >= 6 ? AppColors.warningAmber : AppColors.electricCyan,
                            title: 'UV Index Exposure: ${telemetry.uvIndex.round()} (${telemetry.uvIndex >= 6 ? "High" : (telemetry.uvIndex >= 3 ? "Moderate" : "Low")})',
                            subtitle: telemetry.uvIndex >= 6
                                ? 'High ultraviolet intensity. Apply SPF 30+ sunscreen and wear sunglasses if outdoors.'
                                : (telemetry.uvIndex >= 3
                                    ? 'Moderate ultraviolet levels. Seek shade during peak midday hours.'
                                    : 'Minimal UV radiation. No special sun protection required at this time.'),
                            badge: 'UV ${telemetry.uvIndex.round()}',
                            badgeColor: telemetry.uvIndex >= 6 ? AppColors.warningAmber : AppColors.electricCyan,
                          ),

                        const SizedBox(height: 10),

                        // Persona Targeted Recommendation Card
                        _buildAdvisoryCard(
                          icon: persona.icon,
                          iconColor: persona.accentColor,
                          title: '${persona.displayName} Daily Briefing',
                          subtitle: provider.advisorySummary.isNotEmpty
                              ? provider.advisorySummary
                              : provider.actionBullet,
                          badge: persona.shortTitle,
                          badgeColor: persona.accentColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
  }

  Widget _buildAllClearCard(String city) {
    return GlassContainer(
      padding: const EdgeInsets.all(14.0),
      borderRadius: 18.0,
      fillColor: AppColors.agriEmerald.withOpacity(0.08),
      borderColor: AppColors.agriEmerald.withOpacity(0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.agriEmerald.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.agriEmerald,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Clear in $city',
                  style: AppTypography.titleMd.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.agriEmerald,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Atmospheric conditions are stable. No active severe storm, flood, or extreme weather warnings in your coverage zone.',
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(WeatherAlert alert) {
    return GlassContainer(
      padding: const EdgeInsets.all(14.0),
      borderRadius: 18.0,
      fillColor: AppColors.alertRed.withOpacity(0.12),
      borderColor: AppColors.alertRed.withOpacity(0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.alertRed.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppColors.alertRed,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: AppTypography.titleMd.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.alertRed,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.alertRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.severity.toUpperCase(),
                        style: AppTypography.labelCaps.copyWith(
                          fontSize: 9,
                          color: AppColors.alertRed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  alert.description,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisoryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(14.0),
      borderRadius: 18.0,
      fillColor: AppColors.surface.withOpacity(0.6),
      borderColor: AppColors.glassBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.titleMd.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badgeColor.withOpacity(0.3), width: 0.8),
                      ),
                      child: Text(
                        badge,
                        style: AppTypography.labelCaps.copyWith(
                          fontSize: 9,
                          color: badgeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 11.5,
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
