import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/theme.dart';
import '../utils/weather_icons.dart';
import 'glass_container.dart';

class HourlyForecastWidget extends StatelessWidget {
  final List<HourlyForecast> hourlyList;

  const HourlyForecastWidget({
    super.key,
    required this.hourlyList,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hourly Forecast',
              style: AppTypography.headlineMd.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '24 Hours',
              style: AppTypography.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: hourlyList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = hourlyList[index];
              final icon = WeatherIcons.getIconForWmoCode(item.weatherCode);
              final iconColor = WeatherIcons.getIconColorForWmoCode(item.weatherCode);
              final isCurrentHour = index == 0;

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 500 + (index * 50).clamp(0, 500)),
                curve: Curves.easeOutCubic,
                builder: (context, animVal, child) {
                  return Opacity(
                    opacity: animVal,
                    child: Transform.translate(
                      offset: Offset(0, (1.0 - animVal) * 12),
                      child: child,
                    ),
                  );
                },
                child: GlassContainer(
                  width: 82,
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                  borderRadius: 18.0,
                  fillColor: isCurrentHour
                      ? AppColors.primary.withOpacity(0.12)
                      : (item.isBestRunningHour
                          ? AppColors.fitnessViolet.withOpacity(0.12)
                          : AppColors.glassFill),
                  borderColor: isCurrentHour
                      ? AppColors.primary.withOpacity(0.4)
                      : (item.isBestRunningHour
                          ? AppColors.fitnessViolet.withOpacity(0.4)
                          : AppColors.glassBorder),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Time
                      Text(
                        item.time,
                        style: AppTypography.dataMono.copyWith(
                          fontSize: 12,
                          color: isCurrentHour ? AppColors.primary : AppColors.onSurfaceVariant,
                          fontWeight: isCurrentHour ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),

                      // Icon
                      Icon(icon, size: 24, color: iconColor),

                      // Animated Temp Counting Number
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: item.temperature),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, _) {
                          return Text(
                            '${val.round()}°',
                            style: AppTypography.titleMd.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),

                      // Animated Rain Probability or Running badge
                      if (item.isBestRunningHour)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.fitnessViolet.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'RUN',
                            style: AppTypography.labelCaps.copyWith(
                              fontSize: 8,
                              color: AppColors.fitnessViolet,
                            ),
                          ),
                        )
                      else if (item.precipitationProbability > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.water_drop_rounded,
                              size: 10,
                              color: AppColors.electricCyan,
                            ),
                            const SizedBox(width: 2),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: item.precipitationProbability.toDouble(),
                              ),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              builder: (context, val, _) {
                                return Text(
                                  '${val.round()}%',
                                  style: AppTypography.labelCaps.copyWith(
                                    fontSize: 9,
                                    color: AppColors.electricCyan,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              },
                            ),
                          ],
                        )
                      else
                        const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
