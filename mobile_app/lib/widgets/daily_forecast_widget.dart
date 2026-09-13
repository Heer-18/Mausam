import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/theme.dart';
import '../utils/weather_icons.dart';
import 'glass_container.dart';

class DailyForecastWidget extends StatelessWidget {
  final List<DailyForecast> dailyList;

  const DailyForecastWidget({
    super.key,
    required this.dailyList,
  });

  @override
  Widget build(BuildContext context) {
    if (dailyList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '7-Day Forecast',
              style: AppTypography.headlineMd.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Weekly Trend',
              style: AppTypography.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          borderRadius: 22.0,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dailyList.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.white.withOpacity(0.06),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final item = dailyList[index];
              final icon = WeatherIcons.getIconForWmoCode(item.weatherCode);
              final iconColor = WeatherIcons.getIconColorForWmoCode(item.weatherCode);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  children: [
                    // Day Name
                    SizedBox(
                      width: 70,
                      child: Text(
                        item.dayName,
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: index == 0 ? FontWeight.w700 : FontWeight.w500,
                          color: index == 0 ? AppColors.primary : AppColors.onSurface,
                        ),
                      ),
                    ),

                    // Rain Prob if any
                    SizedBox(
                      width: 50,
                      child: item.precipitationProbabilityMax > 15
                          ? Row(
                              children: [
                                const Icon(Icons.water_drop_rounded, size: 12, color: AppColors.electricCyan),
                                const SizedBox(width: 2),
                                Text(
                                  '${item.precipitationProbabilityMax}%',
                                  style: AppTypography.labelCaps.copyWith(
                                    fontSize: 10,
                                    color: AppColors.electricCyan,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Condition Icon
                    Icon(icon, size: 22, color: iconColor),
                    const SizedBox(width: 14),

                    // Min Temp
                    Text(
                      '${item.temperatureMin.round()}°',
                      style: AppTypography.dataMono.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Visual Range Bar
                    Expanded(
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: 0.65,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.electricCyan, AppColors.warningAmber],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Max Temp
                    Text(
                      '${item.temperatureMax.round()}°',
                      style: AppTypography.dataMono.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
