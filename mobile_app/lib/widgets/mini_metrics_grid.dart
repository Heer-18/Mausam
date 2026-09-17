import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/theme.dart';
import 'glass_container.dart';
import '../utils/weather_math.dart';

class MiniMetricsGrid extends StatefulWidget {
  final WeatherTelemetry telemetry;
  final AirQualityData airQuality;

  const MiniMetricsGrid({
    super.key,
    required this.telemetry,
    required this.airQuality,
  });

  @override
  State<MiniMetricsGrid> createState() => _MiniMetricsGridState();
}

class _MiniMetricsGridState extends State<MiniMetricsGrid>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final aqiStatus = widget.airQuality.aqi <= 50
        ? 'Good'
        : (widget.airQuality.aqi <= 100 ? 'Moderate' : 'Unhealthy');
    final uvLabel = WeatherMath.getUvIndexLabel(widget.telemetry.uvIndex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // 1. AQI Card
            Expanded(
              child: _buildMiniCard(
                title: 'AIR QUALITY',
                targetNum: widget.airQuality.aqi.toDouble(),
                unit: '',
                subtitle: aqiStatus,
                icon: Icons.eco_rounded,
                iconColor: widget.airQuality.aqi <= 50
                    ? AppColors.agriEmerald
                    : AppColors.warningAmber,
                progressPercentage: (widget.airQuality.aqi / 200.0).clamp(0.0, 1.0),
              ),
            ),
            const SizedBox(width: 12),
            // 2. UV Index Card
            Expanded(
              child: _buildMiniCard(
                title: 'UV INDEX',
                targetNum: widget.telemetry.uvIndex,
                unit: '',
                subtitle: uvLabel,
                icon: Icons.wb_sunny_rounded,
                iconColor: widget.telemetry.uvIndex >= 6
                    ? AppColors.warningAmber
                    : AppColors.electricCyan,
                progressPercentage: (widget.telemetry.uvIndex / 12.0).clamp(0.0, 1.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 3. Humidity Card
            Expanded(
              child: _buildMiniCard(
                title: 'HUMIDITY',
                targetNum: widget.telemetry.humidity.toDouble(),
                unit: '%',
                subtitle:
                    widget.telemetry.humidity > 70 ? 'High Moisture' : 'Comfortable',
                icon: Icons.water_drop_rounded,
                iconColor: AppColors.electricCyan,
                progressPercentage: widget.telemetry.humidity / 100.0,
              ),
            ),
            const SizedBox(width: 12),
            // 4. Wind Card
            Expanded(
              child: _buildMiniCard(
                title: 'WIND',
                targetNum: widget.telemetry.windSpeed,
                unit: ' km/h',
                subtitle:
                    '${widget.telemetry.windDirectionCardinal} (Gusts ${widget.telemetry.windGusts.round()})',
                icon: Icons.air_rounded,
                iconColor: AppColors.primary,
                progressPercentage:
                    (widget.telemetry.windSpeed / 40.0).clamp(0.0, 1.0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required String title,
    required double targetNum,
    required String unit,
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
          // Header label and icon with strong contrast
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.labelCaps.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),

          const SizedBox(height: 6),

          // Steady Constant Value and Subtitle (No restarting on scroll)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${targetNum.round()}$unit',
                style: AppTypography.titleMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 11,
                    color: const Color(0xFFE2E8F0),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Mini progress line indicator (Steady, no redraw flicker)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercentage.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.10),
              valueColor: AlwaysStoppedAnimation<Color>(iconColor.withOpacity(0.90)),
              minHeight: 3.5,
            ),
          ),
        ],
      ),
    );
  }
}
