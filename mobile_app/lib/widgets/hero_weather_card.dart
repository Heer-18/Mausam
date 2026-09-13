import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/theme.dart';
import '../utils/weather_icons.dart';
import 'glass_container.dart';

class HeroWeatherCard extends StatelessWidget {
  final WeatherTelemetry telemetry;
  final String? statusChipText;
  final IconData? statusChipIcon;
  final Color? statusChipColor;

  const HeroWeatherCard({
    super.key,
    required this.telemetry,
    this.statusChipText,
    this.statusChipIcon,
    this.statusChipColor,
  });

  @override
  Widget build(BuildContext context) {
    final conditionIcon = WeatherIcons.getIconForWmoCode(telemetry.weatherCode);
    final iconColor = WeatherIcons.getIconColorForWmoCode(telemetry.weatherCode);

    return GlassContainer(
      padding: const EdgeInsets.all(22.0),
      borderRadius: 24.0,
      gradient: AppColors.heroCardGradient,
      borderColor: AppColors.glassBorderBright,
      child: Stack(
        children: [
          // Background ambient radial blur
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.12),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weather Condition Header
              Row(
                children: [
                  Icon(conditionIcon, color: iconColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    telemetry.weatherCondition,
                    style: AppTypography.titleMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Main Temperature & Illustration Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${telemetry.currentTemperature.round()}°',
                    style: AppTypography.displayTemp,
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'Feels ${telemetry.apparentTemperature.round()}°',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Weather Condition Animated / Glowing Icon Representation
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          iconColor.withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        conditionIcon,
                        size: 48,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Telemetry Sub-row & Action Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Humidity & Wind
                  Row(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.water_drop_outlined, size: 16, color: AppColors.electricCyan),
                          const SizedBox(width: 4),
                          Text(
                            'H: ${telemetry.humidity}%',
                            style: AppTypography.dataMono.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(Icons.air_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'W: ${telemetry.windSpeed.round()} km/h ${telemetry.windDirectionCardinal}',
                            style: AppTypography.dataMono.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Capsule Status Badge
                  if (statusChipText != null && statusChipText!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (statusChipColor ?? AppColors.warningAmber).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (statusChipColor ?? AppColors.warningAmber).withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusChipIcon ?? Icons.info_outline_rounded,
                            size: 13,
                            color: statusChipColor ?? AppColors.warningAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusChipText!,
                            style: AppTypography.labelCaps.copyWith(
                              fontSize: 10,
                              color: statusChipColor ?? AppColors.warningAmber,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
