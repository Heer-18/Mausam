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

    // Determine overall min and max across all days for normalized range bars
    double globalMin = dailyList.first.temperatureMin;
    double globalMax = dailyList.first.temperatureMax;
    for (var d in dailyList) {
      if (d.temperatureMin < globalMin) globalMin = d.temperatureMin;
      if (d.temperatureMax > globalMax) globalMax = d.temperatureMax;
    }
    final double rangeSpan = (globalMax - globalMin).clamp(1.0, 50.0);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      borderRadius: 24.0,
      fillColor: const Color(0xFF0F172A).withOpacity(0.4),
      borderColor: Colors.white.withOpacity(0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header inside frosted card with calendar icon
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Text(
                '${dailyList.length}-DAY FORECAST',
                style: AppTypography.labelCaps.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 4),

          // Daily Forecast Rows
          ListView.separated(
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
              final isToday = index == 0;
              final dayLabel = isToday ? 'Today' : (index == 1 ? 'Tomorrow' : item.dayName);

              // Normalize bar min and max positions
              final double leftFactor = ((item.temperatureMin - globalMin) / rangeSpan).clamp(0.0, 0.9);
              final double widthFactor = ((item.temperatureMax - item.temperatureMin) / rangeSpan).clamp(0.1, 1.0 - leftFactor);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 9.0),
                child: Row(
                  children: [
                    // Day Name
                    SizedBox(
                      width: 78,
                      child: Text(
                        dayLabel,
                        style: AppTypography.bodyMd.copyWith(
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday ? Colors.white : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),

                    // Condition Icon & Rain %
                    SizedBox(
                      width: 44,
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: iconColor),
                          if (item.precipitationProbabilityMax > 20) ...[
                            const SizedBox(width: 2),
                            Text(
                              '${item.precipitationProbabilityMax}%',
                              style: AppTypography.labelCaps.copyWith(
                                fontSize: 9,
                                color: AppColors.electricCyan,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Min Temp
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${item.temperatureMin.round()}°',
                        style: AppTypography.dataMono.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Gradient Visual Temperature Bar (iOS style)
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final barWidth = constraints.maxWidth;
                          return Container(
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: leftFactor * barWidth,
                                  width: widthFactor * barWidth,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF38BDF8), // Cyan for min
                                          Color(0xFFFBBF24), // Amber
                                          Color(0xFFFB923C), // Orange for max
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Max Temp
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${item.temperatureMax.round()}°',
                        style: AppTypography.dataMono.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
