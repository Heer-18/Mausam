import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/theme.dart';
import 'glass_container.dart';

import '../utils/weather_math.dart';

class MiniMetricsGrid extends StatelessWidget {
  final WeatherTelemetry telemetry;
  final AirQualityData airQuality;

  const MiniMetricsGrid({
    super.key,
    required this.telemetry,
    required this.airQuality,
  });

  @override
  Widget build(BuildContext context) {
    final aqiStatus = airQuality.aqi <= 50
        ? 'Good'
        : (airQuality.aqi <= 100 ? 'Moderate' : 'Unhealthy');
    final uvLabel = WeatherMath.getUvIndexLabel(telemetry.uvIndex);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.85,
      children: [
        // 1. AQI Card
        _buildMiniCard(
          title: 'AIR QUALITY',
          value: '${airQuality.aqi}',
          subtitle: aqiStatus,
          icon: Icons.eco_rounded,
          iconColor: airQuality.aqi <= 50 ? AppColors.agriEmerald : AppColors.warningAmber,
          progressPercentage: (airQuality.aqi / 200.0).clamp(0.0, 1.0),
        ),

        // 2. UV Index Card
        _buildMiniCard(
          title: 'UV INDEX',
          value: '${telemetry.uvIndex.round()}',
          subtitle: uvLabel,
          icon: Icons.wb_sunny_rounded,
          iconColor: telemetry.uvIndex >= 6 ? AppColors.warningAmber : AppColors.electricCyan,
          progressPercentage: (telemetry.uvIndex / 12.0).clamp(0.0, 1.0),
        ),

        // 3. Humidity Card
        _buildMiniCard(
          title: 'HUMIDITY',
          value: '${telemetry.humidity}%',
          subtitle: telemetry.humidity > 70 ? 'High Moisture' : 'Comfortable',
          icon: Icons.water_drop_rounded,
          iconColor: AppColors.electricCyan,
          progressPercentage: telemetry.humidity / 100.0,
        ),

        // 4. Wind Card
        _buildMiniCard(
          title: 'WIND',
          value: '${telemetry.windSpeed.round()} km/h',
          subtitle: '${telemetry.windDirectionCardinal} (Gusts ${telemetry.windGusts.round()})',
          icon: Icons.air_rounded,
          iconColor: AppColors.primary,
          progressPercentage: (telemetry.windSpeed / 40.0).clamp(0.0, 1.0),
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required double progressPercentage,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      borderRadius: 18.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header label and icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.labelCaps.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),

          // Value and Subtitle
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.titleMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Mini progress line indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor.withOpacity(0.8)),
              minHeight: 3.5,
            ),
          ),
        ],
      ),
    );
  }
}
