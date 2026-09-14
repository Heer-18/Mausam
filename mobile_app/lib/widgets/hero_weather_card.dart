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
      gradient: AppColors.heroCardGradient,
      borderColor: AppColors.glassBorderBright,
      child: Stack(
        children: [
          // Background ambient radial blur
          Positioned(
            right: -30,
            top: -30,
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) => Container(
                width: 140 * _glowAnimation.value,
                height: 140 * _glowAnimation.value,
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
              // Weather Condition Header
              Row(
                children: [
                  Icon(conditionIcon, color: iconColor, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    widget.telemetry.weatherCondition,
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
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Weather Condition Animated / Glowing Floating Icon
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: Transform.scale(
                          scale: _glowAnimation.value,
                          child: Container(
                            width: 72,
                            height: 72,
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
                                size: 48,
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

              // Telemetry Sub-row & Action Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Humidity & Wind
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
                            'H: ${widget.telemetry.humidity}%',
                            style: AppTypography.dataMono.copyWith(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.air_rounded,
                              size: 15, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            'W: ${widget.telemetry.windSpeed.round()} km/h',
                            style: AppTypography.dataMono.copyWith(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),

                  // Capsule Status Badge (Constrained with Flexible & Ellipsis)
                  if (widget.statusChipText != null &&
                      widget.statusChipText!.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (widget.statusChipColor ??
                                  AppColors.warningAmber)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (widget.statusChipColor ??
                                    AppColors.warningAmber)
                                .withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.statusChipIcon ??
                                  Icons.info_outline_rounded,
                              size: 13,
                              color: widget.statusChipColor ??
                                  AppColors.warningAmber,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.statusChipText!,
                                style: AppTypography.labelCaps.copyWith(
                                  fontSize: 10,
                                  color: widget.statusChipColor ??
                                      AppColors.warningAmber,
                                  letterSpacing: 0.2,
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
            ],
          ),
        ],
      ),
    );
  }
}
