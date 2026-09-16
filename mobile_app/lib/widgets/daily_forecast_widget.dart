import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/theme.dart';
import '../utils/weather_icons.dart';
import 'glass_container.dart';

class DailyForecastWidget extends StatelessWidget {
  final List<DailyForecast> dailyList;
  final double? currentTemperature;

  const DailyForecastWidget({
    super.key,
    required this.dailyList,
    this.currentTemperature,
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
              final double leftFactor = ((item.temperatureMin - globalMin) / rangeSpan).clamp(0.0, 0.88);
              final double widthFactor = ((item.temperatureMax - item.temperatureMin) / rangeSpan).clamp(0.12, 1.0 - leftFactor);

              // Current temp dot factor for today
              final double? currentFactor = (isToday && currentTemperature != null)
                  ? ((currentTemperature! - globalMin) / rangeSpan).clamp(0.0, 1.0)
                  : null;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.5),
                child: Row(
                  children: [
                    // Day Name
                    SizedBox(
                      width: 76,
                      child: Text(
                        dayLabel,
                        style: AppTypography.bodyMd.copyWith(
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday ? Colors.white : const Color(0xFFE2E8F0),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Condition Icon & Animated Rain %
                    SizedBox(
                      width: 50,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 18, color: iconColor),
                          if (item.precipitationProbabilityMax > 20) ...[
                            const SizedBox(width: 2),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 0,
                                    end: item.precipitationProbabilityMax.toDouble(),
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
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Min Temp (Animated Counter)
                    SizedBox(
                      width: 28,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: item.temperatureMin),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, _) {
                          return Text(
                            '${val.round()}°',
                            style: AppTypography.dataMono.copyWith(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Gradient Visual Temperature Bar (Animated Horizontal Expansion)
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final barWidth = constraints.maxWidth;
                          return Container(
                            height: 5.0,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 800 + (index * 80).clamp(0, 400)),
                              curve: Curves.easeOutCubic,
                              builder: (context, animProgress, _) {
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    // Colored range span (Expands smoothly)
                                    Positioned(
                                      left: leftFactor * barWidth,
                                      width: (widthFactor * animProgress) * barWidth,
                                      top: 0,
                                      bottom: 0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF38BDF8), // Cyan
                                              Color(0xFFFBBF24), // Amber
                                              Color(0xFFFB923C), // Sunset orange
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),

                                    // Current Temperature Indicator Dot for Today
                                    if (currentFactor != null && animProgress > 0.4)
                                      Positioned(
                                        left: (currentFactor * barWidth - 3.5).clamp(0.0, barWidth - 7.0),
                                        top: -1.0,
                                        child: Transform.scale(
                                          scale: animProgress,
                                          child: Container(
                                            width: 7.0,
                                            height: 7.0,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFF0F172A),
                                                width: 1.2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white.withOpacity(0.7),
                                                  blurRadius: 3,
                                                  spreadRadius: 0.5,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Max Temp (Animated Counter)
                    SizedBox(
                      width: 28,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: item.temperatureMax),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, _) {
                          return Text(
                            '${val.round()}°',
                            style: AppTypography.dataMono.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.right,
                          );
                        },
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
