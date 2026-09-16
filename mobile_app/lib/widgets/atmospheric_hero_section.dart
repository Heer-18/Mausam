import 'package:flutter/material.dart';
import '../models/persona_type.dart';
import '../models/weather_models.dart';
import '../utils/theme.dart';
import '../utils/weather_icons.dart';
import 'dynamic_weather_background.dart';

class AtmosphericHeroSection extends StatelessWidget {
  final WeatherTelemetry telemetry;
  final AirQualityData? airQuality;
  final List<DailyForecast> dailyList;
  final PersonaType activePersona;
  final String? personaChipText;
  final IconData? personaChipIcon;
  final Color? personaChipColor;
  final String cityName;
  final int alertCount;
  final VoidCallback? onLocationTap;
  final VoidCallback? onSearchTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onPersonaTap;

  const AtmosphericHeroSection({
    super.key,
    required this.telemetry,
    this.airQuality,
    this.dailyList = const [],
    required this.activePersona,
    this.personaChipText,
    this.personaChipIcon,
    this.personaChipColor,
    required this.cityName,
    this.alertCount = 0,
    this.onLocationTap,
    this.onSearchTap,
    this.onNotificationsTap,
    this.onSettingsTap,
    this.onPersonaTap,
  });

  @override
  Widget build(BuildContext context) {
    final conditionIcon = WeatherIcons.getIconForWmoCode(telemetry.weatherCode);
    final iconColor = WeatherIcons.getIconColorForWmoCode(telemetry.weatherCode);

    // Today's High and Low from dailyList if available
    final hasDaily = dailyList.isNotEmpty;
    final maxTemp = hasDaily ? dailyList.first.temperatureMax.round() : (telemetry.currentTemperature + 3).round();
    final minTemp = hasDaily ? dailyList.first.temperatureMin.round() : (telemetry.currentTemperature - 4).round();

    // Air Quality Status
    final aqiVal = airQuality?.aqi ?? 28;
    final aqiStatus = aqiVal <= 50 ? 'Good' : (aqiVal <= 100 ? 'Moderate' : 'Unhealthy');
    final aqiColor = aqiVal <= 50
        ? AppColors.agriEmerald
        : (aqiVal <= 100 ? AppColors.warningAmber : AppColors.alertRed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Top Bar / Location & Action Controls Row (Responsive & Overflow-Proof)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location Selector Pill
              Flexible(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onLocationTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            cityName,
                            style: AppTypography.heroCity,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Action Buttons: Search, Notifications, Persona Badge
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onSearchTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 19,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Notification Bell with Alert Dot
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onNotificationsTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.onSurfaceVariant,
                              size: 19,
                            ),
                            if (alertCount > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.alertRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Settings / Customization Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onSettingsTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 19,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Persona Avatar Button (Compact Circular Glass Badge)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onPersonaTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: activePersona.accentColor.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: activePersona.accentColor.withOpacity(0.45),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: activePersona.accentColor.withOpacity(0.25),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          activePersona.icon,
                          size: 18,
                          color: activePersona.accentColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Display Temperature with Overlapping Dynamic Cloud Layer Stack & Counting Animation
        SizedBox(
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Hero Big Temperature Text with Smooth Increasing Animation
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: telemetry.currentTemperature),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return Text(
                      '${val.round()}°',
                      style: AppTypography.displayTemp,
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ),

              // Dynamic Drifting Volumetric Cloud Overlay (Passing over the text)
              Positioned.fill(
                child: ForegroundCloudOverlay(
                  telemetry: telemetry,
                  height: 140,
                ),
              ),
            ],
          ),
        ),

        // 3. Condition & High/Low Range Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(conditionIcon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              '${telemetry.weatherCondition} • $maxTemp° / $minTemp°',
              style: AppTypography.heroCondition,
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Feels Like Subtitle
        Text(
          'Feels like ${telemetry.apparentTemperature.round()}°',
          style: AppTypography.bodySm.copyWith(
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 14),

        // 4. Compact Status Chips Row: AQI Pill (with count animation) + Persona Status Pill
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              // AQI Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: aqiColor.withOpacity(0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: aqiColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: aqiColor.withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: aqiVal.toDouble()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, _) {
                        return Text(
                          'AQI ${val.round()} • $aqiStatus',
                          style: AppTypography.labelCaps.copyWith(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Persona Quick Status Pill
              if (personaChipText != null && personaChipText!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (personaChipColor ?? AppColors.primary).withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (personaChipColor ?? AppColors.primary).withOpacity(0.38),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (personaChipIcon != null) ...[
                        Icon(
                          personaChipIcon,
                          size: 14,
                          color: personaChipColor ?? AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                      ],
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.45,
                        ),
                        child: Text(
                          personaChipText!,
                          style: AppTypography.labelCaps.copyWith(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
