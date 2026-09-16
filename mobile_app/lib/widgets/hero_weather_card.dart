import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/theme.dart';
import '../utils/weather_icons.dart';
import 'glass_container.dart';

class HeroWeatherCard extends StatefulWidget {
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
  State<HeroWeatherCard> createState() => _HeroWeatherCardState();
}

class _HeroWeatherCardState extends State<HeroWeatherCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutSine,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conditionIcon =
        WeatherIcons.getIconForWmoCode(widget.telemetry.weatherCode);
    final iconColor =
        WeatherIcons.getIconColorForWmoCode(widget.telemetry.weatherCode);

    return GlassContainer(
      padding: const EdgeInsets.all(22.0),
      borderRadius: 24.0,
      fillColor: const Color(0xFF0F172A).withOpacity(0.4),
      borderColor: Colors.white.withOpacity(0.18),
      child: Stack(
        children: [
          // Ambient glow behind condition icon
          Positioned(
            right: -20,
            top: -20,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) => Container(
                width: 130 * _glowAnimation.value,
                height: 130 * _glowAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withOpacity(0.12),
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Weather Condition Header & AQI Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(conditionIcon, color: iconColor, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        widget.telemetry.weatherCondition,
                        style: AppTypography.titleMd.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (widget.statusChipText != null && widget.statusChipText!.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: (widget.statusChipColor ?? AppColors.primary).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (widget.statusChipColor ?? AppColors.primary).withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.statusChipIcon ?? Icons.eco_rounded,
                              size: 13,
                              color: widget.statusChipColor ?? AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.statusChipText!,
                                style: AppTypography.labelCaps.copyWith(
                                  fontSize: 10,
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
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Main Large Temperature & Floating Animated Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Text(
                      '${widget.telemetry.currentTemperature.round()}°',
                      key: ValueKey(widget.telemetry.currentTemperature.round()),
                      style: AppTypography.displayTemp,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      'Feels ${widget.telemetry.apparentTemperature.round()}°',
                      style: AppTypography.bodyMd.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Animated Floating Icon
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: Transform.scale(
                          scale: _glowAnimation.value,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  iconColor.withOpacity(0.28),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                conditionIcon,
                                size: 46,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Humidity, Wind Speed, UV stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.water_drop_outlined,
                              size: 15, color: AppColors.electricCyan),
                          const SizedBox(width: 3),
                          Text(
                            'Humidity ${widget.telemetry.humidity}%',
                            style: AppTypography.dataMono.copyWith(
                              fontSize: 12,
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.air_rounded,
                              size: 15, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            'Wind ${widget.telemetry.windSpeed.round()} km/h',
                            style: AppTypography.dataMono.copyWith(
                              fontSize: 12,
                              color: const Color(0xFFE2E8F0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 14, color: AppColors.warningAmber),
                      const SizedBox(width: 3),
                      Text(
                        'UV ${widget.telemetry.uvIndex.toStringAsFixed(1)}',
                        style: AppTypography.dataMono.copyWith(
                          fontSize: 12,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
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
