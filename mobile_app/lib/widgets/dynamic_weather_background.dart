import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/celestial_math.dart';

enum WeatherAtmosphereType {
  clearDay,
  clearNight,
  cloudyDay,
  cloudyTwilight,
  rainy,
  thunderstorm,
  snowy,
  foggy,
}

class WeatherAtmosphereConfig {
  final WeatherAtmosphereType type;
  final List<Color> gradientColors;
  final List<double> gradientStops;
  final Color cardGlassFill;
  final Color cardGlassBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentColor;
  final bool hasRain;
  final bool hasClouds;
  final bool hasStars;
  final bool hasThunder;
  final bool hasSun;
  final bool hasMoon;
  final bool isSunOccluded;
  final Color cloudBodyColor;
  final Color cloudHighlightColor;
  final Color cloudShadowColor;
  final Color cloudRimColor;
  final CelestialEventType celestialEvent;
  final DateTime currentTime;

  const WeatherAtmosphereConfig({
    required this.type,
    required this.gradientColors,
    required this.gradientStops,
    required this.cardGlassFill,
    required this.cardGlassBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentColor,
    required this.cloudBodyColor,
    required this.cloudHighlightColor,
    required this.cloudShadowColor,
    required this.cloudRimColor,
    required this.currentTime,
    this.hasRain = false,
    this.hasClouds = false,
    this.hasStars = false,
    this.hasThunder = false,
    this.hasSun = false,
    this.hasMoon = false,
    this.isSunOccluded = false,
    this.celestialEvent = CelestialEventType.none,
  });

  factory WeatherAtmosphereConfig.fromTelemetry(
    WeatherTelemetry? telemetry, [
    DateTime? time,
    CelestialEventType? overrideEvent,
  ]) {
    final now = time ?? DateTime.now();
    final hour = now.hour;
    final isNight = hour < 6 || hour >= 19;
    final isSunsetOrSunrise = (hour >= 5 && hour < 7) || (hour >= 17 && hour < 19);

    final code = telemetry?.weatherCode ?? 0;
    final temp = telemetry?.currentTemperature ?? 25.0;
    final cloudCover = telemetry?.cloudCover ?? 20;

    // Detect celestial events from conditions or explicit override
    CelestialEventType celestialEvent = overrideEvent ?? CelestialEventType.none;
    final condLower = (telemetry?.weatherCondition ?? '').toLowerCase();
    if (condLower.contains('solar eclipse') || condLower.contains('suryagrahan')) {
      celestialEvent = CelestialEventType.solarEclipse;
    } else if (condLower.contains('lunar eclipse') || condLower.contains('chandragrahan')) {
      celestialEvent = CelestialEventType.lunarEclipse;
    } else if (condLower.contains('blood moon') || condLower.contains('red moon')) {
      celestialEvent = CelestialEventType.bloodMoon;
    }

    final isOccluded = (code >= 51 && code <= 67) ||
        (code >= 80 && code <= 82) ||
        code >= 95 ||
        cloudCover >= 70;

    // 1. Thunderstorm (95, 96, 99)
    if (code >= 95) {
      return WeatherAtmosphereConfig(
        type: WeatherAtmosphereType.thunderstorm,
        gradientColors: const [
          Color(0xFF0F172A),
          Color(0xFF1E1B4B),
          Color(0xFF312E81),
          Color(0xFF1E293B),
        ],
        gradientStops: const [0.0, 0.35, 0.7, 1.0],
        cardGlassFill: const Color(0xC6161438),
        cardGlassBorder: const Color(0x38818CF8),
        textPrimary: Colors.white,
        textSecondary: const Color(0xFFCBD5E1),
        accentColor: const Color(0xFFA855F7),
        cloudBodyColor: const Color(0xFF1E1B4B),
        cloudHighlightColor: const Color(0xFF312E81),
        cloudShadowColor: const Color(0xFF0F172A),
        cloudRimColor: const Color(0xFF818CF8),
        hasRain: true,
        hasClouds: true,
        hasThunder: true,
        hasSun: !isNight,
        hasMoon: isNight,
        isSunOccluded: true,
        celestialEvent: celestialEvent,
        currentTime: now,
      );
    }

    // 2. Rain / Drizzle (51..67, 80..82)
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return WeatherAtmosphereConfig(
        type: WeatherAtmosphereType.rainy,
        gradientColors: isNight
            ? const [
                Color(0xFF090D16),
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF0D1527),
              ]
            : const [
                Color(0xFF1E293B),
                Color(0xFF334155),
                Color(0xFF475569),
                Color(0xFF283548),
              ],
        gradientStops: const [0.0, 0.4, 0.75, 1.0],
        cardGlassFill: const Color(0xC6162234),
        cardGlassBorder: const Color(0x3094A3B8),
        textPrimary: Colors.white,
        textSecondary: const Color(0xFFE2E8F0),
        accentColor: const Color(0xFF38BDF8),
        cloudBodyColor: const Color(0xFF475569),
        cloudHighlightColor: const Color(0xFF64748B),
        cloudShadowColor: const Color(0xFF1E293B),
        cloudRimColor: const Color(0xFF94A3B8),
        hasRain: true,
        hasClouds: true,
        hasSun: !isNight,
        hasMoon: isNight,
        isSunOccluded: true,
        celestialEvent: celestialEvent,
        currentTime: now,
      );
    }

    // 3. Snow (71..77, 85..86)
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return WeatherAtmosphereConfig(
        type: WeatherAtmosphereType.snowy,
        gradientColors: const [
          Color(0xFF1E293B),
          Color(0xFF3B4D66),
          Color(0xFF64748B),
          Color(0xFF94A3B8),
        ],
        gradientStops: const [0.0, 0.35, 0.7, 1.0],
        cardGlassFill: const Color(0xC41A283D),
        cardGlassBorder: const Color(0x35FFFFFF),
        textPrimary: Colors.white,
        textSecondary: const Color(0xFFF1F5F9),
        accentColor: const Color(0xFF7DD3FC),
        cloudBodyColor: const Color(0xFFCBD5E1),
        cloudHighlightColor: const Color(0xFFF8FAFC),
        cloudShadowColor: const Color(0xFF64748B),
        cloudRimColor: const Color(0xFFFFFFFF),
        hasClouds: true,
        hasSun: !isNight,
        hasMoon: isNight,
        isSunOccluded: isOccluded,
        celestialEvent: celestialEvent,
        currentTime: now,
      );
    }

    // 4. Fog / Mist (45, 48)
    if (code == 45 || code == 48) {
      return WeatherAtmosphereConfig(
        type: WeatherAtmosphereType.foggy,
        gradientColors: const [
          Color(0xFF1E293B),
          Color(0xFF334155),
          Color(0xFF475569),
          Color(0xFF3B485A),
        ],
        gradientStops: const [0.0, 0.3, 0.65, 1.0],
        cardGlassFill: const Color(0xC4182438),
        cardGlassBorder: const Color(0x33FFFFFF),
        textPrimary: Colors.white,
        textSecondary: const Color(0xFFE2E8F0),
        accentColor: const Color(0xFF94A3B8),
        cloudBodyColor: const Color(0xFF94A3B8),
        cloudHighlightColor: const Color(0xFFCBD5E1),
        cloudShadowColor: const Color(0xFF475569),
        cloudRimColor: const Color(0xFFE2E8F0),
        hasClouds: true,
        hasSun: !isNight,
        hasMoon: isNight,
        isSunOccluded: true,
        celestialEvent: celestialEvent,
        currentTime: now,
      );
    }

    // 5. Cloudy (1, 2, 3) or Sunset/Twilight
    if (code >= 1 && code <= 3) {
      if (isSunsetOrSunrise) {
        return WeatherAtmosphereConfig(
          type: WeatherAtmosphereType.cloudyTwilight,
          gradientColors: const [
            Color(0xFF36395A),
            Color(0xFF4A4B75),
            Color(0xFF6B6E9B),
            Color(0xFF7B7293),
            Color(0xFFB07D7B),
          ],
          gradientStops: const [0.0, 0.28, 0.55, 0.78, 1.0],
          cardGlassFill: const Color(0xC41E1A33),
          cardGlassBorder: const Color(0x38FFFFFF),
          textPrimary: Colors.white,
          textSecondary: const Color(0xFFF1F5F9),
          accentColor: const Color(0xFFFED7AA),
          cloudBodyColor: const Color(0xFFFBCFE8),
          cloudHighlightColor: const Color(0xFFFEF08A),
          cloudShadowColor: const Color(0xFF4A4B75),
          cloudRimColor: const Color(0xFFFED7AA),
          hasClouds: true,
          hasSun: true,
          isSunOccluded: isOccluded,
          celestialEvent: celestialEvent,
          currentTime: now,
        );
      }

      if (isNight) {
        return WeatherAtmosphereConfig(
          type: WeatherAtmosphereType.cloudyDay,
          gradientColors: const [
            Color(0xFF0B0F19),
            Color(0xFF141C2E),
            Color(0xFF1F293D),
            Color(0xFF111827),
          ],
          gradientStops: const [0.0, 0.35, 0.7, 1.0],
          cardGlassFill: const Color(0xC80F1829),
          cardGlassBorder: const Color(0x2EFFFFFF),
          textPrimary: Colors.white,
          textSecondary: const Color(0xFFCBD5E1),
          accentColor: const Color(0xFF93C5FD),
          cloudBodyColor: const Color(0xFF1E293B),
          cloudHighlightColor: const Color(0xFF334155),
          cloudShadowColor: const Color(0xFF0B0F19),
          cloudRimColor: const Color(0xFF94A3B8),
          hasClouds: true,
          hasStars: true,
          hasMoon: true,
          celestialEvent: celestialEvent,
          currentTime: now,
        );
      }

      // Daytime Cloudy with dynamic warmth
      final isHot = temp >= 30;
      return WeatherAtmosphereConfig(
        type: WeatherAtmosphereType.cloudyDay,
        gradientColors: isHot
            ? const [
                Color(0xFF434E72),
                Color(0xFF5B698C),
                Color(0xFF7684A6),
                Color(0xFF8F93AA),
              ]
            : const [
                Color(0xFF2A3B5C),
                Color(0xFF3F547A),
                Color(0xFF556F99),
                Color(0xFF6B83A8),
              ],
        gradientStops: const [0.0, 0.35, 0.7, 1.0],
        cardGlassFill: const Color(0xC4152136),
        cardGlassBorder: const Color(0x33FFFFFF),
        textPrimary: Colors.white,
        textSecondary: const Color(0xFFF8FAFC),
        accentColor: const Color(0xFFBAE6FD),
        cloudBodyColor: const Color(0xFFE2E8F0),
        cloudHighlightColor: const Color(0xFFFFFFFF),
        cloudShadowColor: const Color(0xFF94A3B8),
        cloudRimColor: const Color(0xFFF1F5F9),
        hasClouds: true,
        hasSun: true,
        isSunOccluded: isOccluded,
        celestialEvent: celestialEvent,
        currentTime: now,
      );
    }

    // 6. Clear Sky (0)
    if (isNight) {
      return WeatherAtmosphereConfig(
        type: WeatherAtmosphereType.clearNight,
        gradientColors: const [
          Color(0xFF050811),
          Color(0xFF0B132B),
          Color(0xFF1C2541),
          Color(0xFF0F172A),
        ],
        gradientStops: const [0.0, 0.3, 0.65, 1.0],
        cardGlassFill: const Color(0xC80B1322),
        cardGlassBorder: const Color(0x2EFFFFFF),
        textPrimary: Colors.white,
        textSecondary: const Color(0xFFCBD5E1),
        accentColor: const Color(0xFF60A5FA),
        cloudBodyColor: const Color(0xFF1E293B),
        cloudHighlightColor: const Color(0xFF475569),
        cloudShadowColor: const Color(0xFF0B0F19),
        cloudRimColor: const Color(0xFFCBD5E1),
        hasStars: true,
        hasMoon: true,
        hasClouds: cloudCover > 10,
        celestialEvent: celestialEvent,
        currentTime: now,
      );
    }

    if (isSunsetOrSunrise) {
      return WeatherAtmosphereConfig(
        type: WeatherAtmosphereType.clearDay,
        gradientColors: const [
          Color(0xFF1E1B4B),
          Color(0xFF4338CA),
          Color(0xFF7C3AED),
          Color(0xFFDB2777),
          Color(0xFFF59E0B),
        ],
        gradientStops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        cardGlassFill: const Color(0xC41E152F),
        cardGlassBorder: const Color(0x3BFFFFFF),
        textPrimary: Colors.white,
        textSecondary: const Color(0xFFFFFBEB),
        accentColor: const Color(0xFFFDE68A),
        cloudBodyColor: const Color(0xFFFED7AA),
        cloudHighlightColor: const Color(0xFFFFFBEB),
        cloudShadowColor: const Color(0xFF4A4B75),
        cloudRimColor: const Color(0xFFFEF08A),
        hasSun: true,
        hasClouds: cloudCover > 10,
        celestialEvent: celestialEvent,
        currentTime: now,
      );
    }

    // Clear Daytime (Radiant Natural Sky with Pure White Clouds matching reference Image 1)
    return WeatherAtmosphereConfig(
      type: WeatherAtmosphereType.clearDay,
      gradientColors: const [
        Color(0xFF386FA4), // Natural azure blue top matching Image 1
        Color(0xFF4C82BA),
        Color(0xFF6B9ED7),
        Color(0xFF90BDF0), // Soft atmospheric horizon
      ],
      gradientStops: const [0.0, 0.35, 0.7, 1.0],
      cardGlassFill: const Color(0xC4111E33), // Rich, uniform midnight glass (prevents background bleed-through)
      cardGlassBorder: const Color(0x35FFFFFF), // Crisp bright border
      textPrimary: Colors.white,
      textSecondary: const Color(0xFFF1F5F9),
      accentColor: const Color(0xFF38BDF8),
      cloudBodyColor: const Color(0xFFFFFFFF), // Pure radiant white clouds on clean sky
      cloudHighlightColor: const Color(0xFFF8FAFC),
      cloudShadowColor: const Color(0xFFCBD5E1),
      cloudRimColor: const Color(0xFFFFFFFF),
      hasSun: true,
      hasClouds: true, // Ensure soft ambient realistic wisps are always present
      celestialEvent: celestialEvent,
      currentTime: now,
    );
  }
}

/// InheritedWidget providing active atmospheric styling to descendants (cards, typography)
class WeatherAtmosphereScope extends InheritedWidget {
  final WeatherAtmosphereConfig config;

  const WeatherAtmosphereScope({
    super.key,
    required this.config,
    required super.child,
  });

  static WeatherAtmosphereConfig? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WeatherAtmosphereScope>()?.config;
  }

  @override
  bool updateShouldNotify(WeatherAtmosphereScope oldWidget) {
    return config.type != oldWidget.config.type ||
        config.cardGlassFill != oldWidget.config.cardGlassFill ||
        config.textPrimary != oldWidget.config.textPrimary;
  }
}

/// Dynamic Weather Atmospheric Layer that wraps the app views
class DynamicWeatherBackground extends StatefulWidget {
  final WeatherTelemetry? telemetry;
  final Widget child;

  const DynamicWeatherBackground({
    super.key,
    required this.telemetry,
    required this.child,
  });

  @override
  State<DynamicWeatherBackground> createState() => _DynamicWeatherBackgroundState();
}

class _DynamicWeatherBackgroundState extends State<DynamicWeatherBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    // Majestic, slow atmospheric drift (85 seconds cycle)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 85),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = WeatherAtmosphereConfig.fromTelemetry(widget.telemetry);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: config.gradientColors,
          stops: config.gradientStops,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Ambient Weather Effects Canvas (Behind content)
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                painter: _AtmosphericPainter(
                  progress: _animController.value,
                  config: config,
                ),
                size: Size.infinite,
              );
            },
          ),

          // 2. Main App Content with Atmospheric Theme Scope
          WeatherAtmosphereScope(
            config: config,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Foreground Floating Cloud Overlay to overlap hero text and create depth
class ForegroundCloudOverlay extends StatefulWidget {
  final WeatherTelemetry? telemetry;
  final double height;

  const ForegroundCloudOverlay({
    super.key,
    this.telemetry,
    this.height = 240,
  });

  @override
  State<ForegroundCloudOverlay> createState() => _ForegroundCloudOverlayState();
}

class _ForegroundCloudOverlayState extends State<ForegroundCloudOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _cloudController;

  @override
  void initState() {
    super.initState();
    // Gentle foreground cloud drift (70 seconds cycle)
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 70),
    )..repeat();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = WeatherAtmosphereConfig.fromTelemetry(widget.telemetry);
    if (!config.hasClouds) return const SizedBox.shrink();

    return IgnorePointer(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _cloudController,
          builder: (context, _) {
            return CustomPaint(
              painter: _ForegroundCloudPainter(
                progress: _cloudController.value,
                config: config,
              ),
              size: Size(double.infinity, widget.height),
            );
          },
        ),
      ),
    );
  }
}

class _ForegroundCloudPainter extends CustomPainter {
  final double progress;
  final WeatherAtmosphereConfig config;

  _ForegroundCloudPainter({
    required this.progress,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Dual offset continuous loop: clouds are ALWAYS gracefully draping across the lower portion of the temperature numbers
    final double span = w + 440;
    final double x1 = (progress * span) % span - 220;
    final double x2 = ((progress + 0.5) * span) % span - 220;

    // 1. Primary Volumetric Cloud Formation (Delicately overlapping digits with 42% opacity)
    _draw3DVolumetricCloud(
      canvas,
      Offset(x1, h * 0.58),
      scale: 1.25,
      bodyColor: config.cloudBodyColor,
      highlightColor: config.cloudHighlightColor,
      shadowColor: config.cloudShadowColor,
      rimColor: config.cloudRimColor,
      opacity: 0.42, // Beautiful visible overlap over temperature digits!
    );

    // 2. Secondary Interlaced Cloud Formation (Ensures continuous presence at all times)
    _draw3DVolumetricCloud(
      canvas,
      Offset(x2, h * 0.65),
      scale: 1.10,
      bodyColor: config.cloudBodyColor,
      highlightColor: config.cloudHighlightColor,
      shadowColor: config.cloudShadowColor,
      rimColor: config.cloudRimColor,
      opacity: 0.36,
    );

    // 3. Continuous Wispy Cirrus Streamer across middle of digits
    final double wispX = ((progress * 1.4) * (w + 260)) % (w + 260) - 130;
    final wispPaint = Paint()
      ..color = config.cloudHighlightColor.withOpacity(0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(wispX, h * 0.50), width: 150, height: 28),
      wispPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ForegroundCloudPainter oldDelegate) => true;
}

class _AtmosphericPainter extends CustomPainter {
  final double progress;
  final WeatherAtmosphereConfig config;

  _AtmosphericPainter({
    required this.progress,
    required this.config,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Night Stars
    if (config.hasStars) {
      _paintStars(canvas, size);
    }

    // 2. Sun (Daytime / Twilight / Suryagrahan)
    if (config.hasSun) {
      _paintSun(canvas, size);
    }

    // 3. Moon (Night / Moon phases / Chandragrahan / Blood Moon)
    if (config.hasMoon) {
      _paintMoon(canvas, size);
    }

    // 4. Floating Clouds (Drawn over celestial bodies to naturally hide/occlude them)
    if (config.hasClouds) {
      _paintFloatingClouds(canvas, size);
    }

    // 5. Rain Drops
    if (config.hasRain) {
      _paintRain(canvas, size);
    }

    // 6. Thunder Lightning Flash
    if (config.hasThunder) {
      _paintThunderFlash(canvas, size);
    }
  }

  void _paintSun(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    // Positioned at upper-left matching reference Image 1 (clears all top-right action buttons)
    final Offset sunCenter = Offset(w * 0.22, h * 0.11);
    const double baseRadius = 20.0;

    // Pulse breathing effect
    final double pulse = 1.0 + 0.03 * math.sin(progress * 2 * math.pi * 3);

    if (config.celestialEvent == CelestialEventType.solarEclipse) {
      // -------------------------------------------------------------
      // SURYAGRAHAN (SOLAR ECLIPSE) RENDERING
      // -------------------------------------------------------------
      final coronaPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFFBEB).withOpacity(0.95),
            const Color(0xFFFDE047).withOpacity(0.70),
            const Color(0xFFF59E0B).withOpacity(0.35),
            const Color(0xFFD97706).withOpacity(0.10),
            Colors.transparent,
          ],
          stops: const [0.0, 0.35, 0.65, 0.85, 1.0],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: baseRadius * 3.2 * pulse))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(sunCenter, baseRadius * 2.8 * pulse, coronaPaint);

      final moonTransitPaint = Paint()
        ..color = const Color(0xFF050811)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(sunCenter.dx + 1.2, sunCenter.dy - 0.8), baseRadius * 1.02, moonTransitPaint);

      final ringPaint = Paint()
        ..color = const Color(0xFFFEF08A).withOpacity(0.90)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

      canvas.drawCircle(sunCenter, baseRadius, ringPaint);

      final Offset diamondPoint = Offset(sunCenter.dx - baseRadius * 0.72, sunCenter.dy - baseRadius * 0.70);
      final diamondGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white,
            const Color(0xFFBAE6FD).withOpacity(0.8),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: diamondPoint, radius: 14));
      canvas.drawCircle(diamondPoint, 12, diamondGlow);

      final diamondCore = Paint()..color = Colors.white;
      canvas.drawCircle(diamondPoint, 3.5, diamondCore);
      return;
    }

    if (config.isSunOccluded) {
      // -------------------------------------------------------------
      // OCCLUDED SUN (Rainy / Overcast - Hiding Behind Rain Clouds)
      // -------------------------------------------------------------
      final diffuseGlow = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFEF08A).withOpacity(0.28),
            const Color(0xFFFDE047).withOpacity(0.15),
            const Color(0xFFF59E0B).withOpacity(0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: baseRadius * 3.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

      canvas.drawCircle(sunCenter, baseRadius * 3.2, diffuseGlow);

      final softCore = Paint()
        ..color = const Color(0xFFFEF9C3).withOpacity(0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(sunCenter, baseRadius * 0.85, softCore);
      return;
    }

    // -------------------------------------------------------------
    // REALISTIC RADIANT STAR (Matching Reference Image 1)
    // -------------------------------------------------------------
    // 1. Wide Atmospheric Sky Bloom (Soft ambient dissipation focused in upper sky)
    final atmosphericBloom = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.38),
          const Color(0xFFFFFBEB).withOpacity(0.18),
          const Color(0xFFBAE6FD).withOpacity(0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: baseRadius * 5.6 * pulse))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawCircle(sunCenter, baseRadius * 5.2 * pulse, atmosphericBloom);

    // 2. Chromatic Dispersion Halo Ring (Signature optical halo from Image 1)
    const double haloRadius = baseRadius * 4.4;
    final chromaticHalo = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          const Color(0xFFFED7AA).withOpacity(0.16),
          const Color(0xFFBAE6FD).withOpacity(0.20),
          const Color(0xFFDDD6FE).withOpacity(0.18),
          const Color(0xFFFEF08A).withOpacity(0.18),
          const Color(0xFFFED7AA).withOpacity(0.16),
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: haloRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(sunCenter, haloRadius, chromaticHalo);

    // 3. Warm Golden Inner Corona
    final innerCorona = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.95),
          const Color(0xFFFFFBEB).withOpacity(0.65),
          const Color(0xFFFEF08A).withOpacity(0.30),
          Colors.transparent,
        ],
        stops: const [0.0, 0.40, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: baseRadius * 2.8 * pulse))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    canvas.drawCircle(sunCenter, baseRadius * 2.5 * pulse, innerCorona);

    // 5. Blazing Pure White Solar Disc
    final sunBody = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawCircle(sunCenter, baseRadius * 0.95, sunBody);

    // 6. Camera Lens Flare Bokeh Orbs (Diagonally across upper sky, away from card bounds)
    const double flareVecX = 0.85;
    const double flareVecY = 0.35;

    // Orb 1: Soft Cyan Prismatic Ring
    final Offset orb1 = Offset(sunCenter.dx + 80 * flareVecX, sunCenter.dy + 80 * flareVecY);
    final orb1Paint = Paint()
      ..color = const Color(0xFFBAE6FD).withOpacity(0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(orb1, 20, orb1Paint);

    // Orb 2: Warm Golden Diffuse Disk
    final Offset orb2 = Offset(sunCenter.dx + 155 * flareVecX, sunCenter.dy + 155 * flareVecY);
    final orb2Paint = Paint()
      ..color = const Color(0xFFFEF08A).withOpacity(0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawCircle(orb2, 28, orb2Paint);

    // Orb 3: Violet / Magenta Aperture Artifact
    final Offset orb3 = Offset(sunCenter.dx + 235 * flareVecX, sunCenter.dy + 235 * flareVecY);
    final orb3Paint = Paint()
      ..color = const Color(0xFFC084FC).withOpacity(0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(orb3, 16, orb3Paint);
  }

  void _paintMoon(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset moonCenter = Offset(w * 0.78, h * 0.13);
    const double r = 25.0;

    final moonInfo = CelestialMath.getMoonPhaseInfo(config.currentTime, config.celestialEvent);

    // If No Moon Day (Amavasya) and no special eclipse, moon is invisible
    if (!moonInfo.isVisible && config.celestialEvent == CelestialEventType.none) {
      return;
    }

    final bool isBloodMoon = config.celestialEvent == CelestialEventType.bloodMoon;
    final bool isLunarEclipse = config.celestialEvent == CelestialEventType.lunarEclipse;

    canvas.save();
    canvas.translate(moonCenter.dx, moonCenter.dy);

    // Realistic astronomical inclination tilt angle (~38 degrees) matching real telescope/night sky photography!
    canvas.rotate(-math.pi / 4.7);

    // 1. Soft Celestial Corona Aura
    final Color glowColor = isBloodMoon
        ? const Color(0xFFE11D48)
        : isLunarEclipse
            ? const Color(0xFFD97706)
            : const Color(0xFFE2E8F0);

    final moonGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          glowColor.withOpacity(0.35),
          glowColor.withOpacity(0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 2.5))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset.zero, r * 2.3, moonGlow);

    // 2. Mathematical Lunar Phase Path (Clean illuminated crescent with no dark spot)
    final double phase = moonInfo.phase;
    final double theta = phase * 2 * math.pi;
    final Path litMoonPath = Path();

    if (phase >= 0.47 && phase <= 0.53) {
      // Full Moon
      litMoonPath.addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    } else {
      final bool isWaxing = phase < 0.5;
      final double xTerminator = r * math.cos(theta);
      final double semiMinor = math.max((r * math.cos(theta)).abs(), 0.5);

      if (isWaxing) {
        // Outer arc along right side (which with rotation tilts downwards-left as in real photography)
        litMoonPath.moveTo(0, -r);
        litMoonPath.arcToPoint(
          Offset(0, r),
          radius: const Radius.circular(r),
          clockwise: true,
        );
        // Inner arc along terminator
        litMoonPath.arcToPoint(
          Offset(0, -r),
          radius: Radius.elliptical(semiMinor, r),
          clockwise: xTerminator > 0,
        );
      } else {
        // Outer arc along left side
        litMoonPath.moveTo(0, -r);
        litMoonPath.arcToPoint(
          Offset(0, r),
          radius: const Radius.circular(r),
          clockwise: false,
        );
        // Inner arc along terminator
        litMoonPath.arcToPoint(
          Offset(0, -r),
          radius: Radius.elliptical(semiMinor, r),
          clockwise: xTerminator < 0,
        );
      }
    }

    // 4. Photorealistic Lunar Surface Gradient (Crisp bright sunlit limb transitioning into shaded rocky craters)
    final Paint litPaint = Paint();
    if (isBloodMoon) {
      litPaint.shader = RadialGradient(
        center: const Alignment(0.4, -0.2),
        radius: 1.0,
        colors: const [
          Color(0xFFFFE4E6),
          Color(0xFFFDA4AF),
          Color(0xFFE11D48),
          Color(0xFF9F1239),
          Color(0xFF4C0519),
        ],
        stops: const [0.0, 0.25, 0.55, 0.80, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    } else if (isLunarEclipse) {
      litPaint.shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: const [
          Color(0xFFFEF3C7),
          Color(0xFFFBBF24),
          Color(0xFFD97706),
          Color(0xFF78350F),
          Color(0xFF2E1065),
        ],
        stops: const [0.0, 0.25, 0.55, 0.80, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    } else {
      // Photo-Accurate Silver-White to Textured Lunar Gray
      litPaint.shader = RadialGradient(
        center: const Alignment(0.45, -0.15),
        radius: 0.95,
        colors: const [
          Color(0xFFFFFFFF), // Pure bright sunlit edge
          Color(0xFFF8FAFC),
          Color(0xFFE2E8F0),
          Color(0xFFCBD5E1),
          Color(0xFF94A3B8), // Rugged rocky terminator shadow
          Color(0xFF475569),
        ],
        stops: const [0.0, 0.22, 0.48, 0.70, 0.88, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    }

    canvas.drawPath(litMoonPath, litPaint);

    // 5. Realistic Lunar Maria (Seas) & Crater Terrain Details (Clipped to lit portion)
    canvas.save();
    canvas.clipPath(litMoonPath);

    final marePaint = Paint()
      ..color = (isBloodMoon ? const Color(0x444C0519) : const Color(0x381E293B))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    // Large Lunar Maria plains
    canvas.drawOval(Rect.fromCenter(center: const Offset(4, -4), width: 9, height: 7), marePaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(2, 6), width: 11, height: 8), marePaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(8, 2), width: 7, height: 9), marePaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(-4, -2), width: 8, height: 7), marePaint);

    // Micro Crater Relief and Highlights along Terminator
    final craterShadow = Paint()
      ..color = const Color(0x550F172A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
    final craterHighlight = Paint()
      ..color = Colors.white.withOpacity(0.70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6);

    final microCraters = [
      const Offset(1, -9),
      const Offset(-2, -5),
      const Offset(0, 0),
      const Offset(-1, 5),
      const Offset(3, 10),
      const Offset(6, -6),
    ];

    for (final mc in microCraters) {
      canvas.drawCircle(Offset(mc.dx + 0.5, mc.dy + 0.5), 1.2, craterShadow);
      canvas.drawCircle(Offset(mc.dx - 0.4, mc.dy - 0.4), 0.9, craterHighlight);
    }

    if (isLunarEclipse) {
      final umbra = Paint()
        ..color = const Color(0xDD2D0C03)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(const Offset(6, -4), r * 0.92, umbra);
    }

    canvas.restore();

    // 6. Crisp, Razor-Sharp Sunlit Outer Rim
    final limbPaint = Paint()
      ..color = (isBloodMoon ? const Color(0xFFFFE4E6) : Colors.white).withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Path outerLimbPath = Path();
    if (phase < 0.5) {
      outerLimbPath.moveTo(0, -r);
      outerLimbPath.arcToPoint(Offset(0, r), radius: const Radius.circular(r), clockwise: true);
    } else {
      outerLimbPath.moveTo(0, -r);
      outerLimbPath.arcToPoint(Offset(0, r), radius: const Radius.circular(r), clockwise: false);
    }
    canvas.drawPath(outerLimbPath, limbPaint);

    canvas.restore();
  }

  void _paintFloatingClouds(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. High-altitude feathered cirrus ribbons across upper sky (Image 1 realism)
    final cirrusPaint = Paint()
      ..color = config.cloudHighlightColor.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);

    final double cirrusDrift = (progress * 100) % (w + 240) - 120;
    final Path cirrus1 = Path();
    cirrus1.moveTo(cirrusDrift - 80, h * 0.08);
    cirrus1.quadraticBezierTo(cirrusDrift + w * 0.35, h * 0.04, cirrusDrift + w * 0.75, h * 0.09);
    cirrus1.quadraticBezierTo(cirrusDrift + w * 0.95, h * 0.11, cirrusDrift + w + 100, h * 0.07);
    cirrus1.lineTo(cirrusDrift + w + 100, h * 0.12);
    cirrus1.quadraticBezierTo(cirrusDrift + w * 0.60, h * 0.14, cirrusDrift - 80, h * 0.11);
    cirrus1.close();
    canvas.drawPath(cirrus1, cirrusPaint);

    final Path cirrus2 = Path();
    final double cirrusDrift2 = (((1.0 - progress) * 80) % (w + 240)) - 120;
    cirrus2.moveTo(cirrusDrift2 - 60, h * 0.16);
    cirrus2.quadraticBezierTo(cirrusDrift2 + w * 0.40, h * 0.13, cirrusDrift2 + w * 0.85, h * 0.18);
    cirrus2.lineTo(cirrusDrift2 + w * 0.85, h * 0.21);
    cirrus2.quadraticBezierTo(cirrusDrift2 + w * 0.35, h * 0.20, cirrusDrift2 - 60, h * 0.19);
    cirrus2.close();
    canvas.drawPath(cirrus2, cirrusPaint);

    // 2. Background Cloud 1: High-altitude atmospheric drift
    final double offset1 = (progress * (w + 340)) - 170;
    _draw3DVolumetricCloud(
      canvas,
      Offset(offset1, h * 0.13),
      scale: 1.35,
      bodyColor: config.cloudBodyColor,
      highlightColor: config.cloudHighlightColor,
      shadowColor: config.cloudShadowColor,
      rimColor: config.cloudRimColor,
      opacity: 0.52,
    );

    // 3. Background Cloud 2: Mid-level soft cumulus cloud drifting from right to left
    final double offset2 = (((1.0 - progress * 0.7) * (w + 300)) % (w + 300)) - 150;
    _draw3DVolumetricCloud(
      canvas,
      Offset(offset2, h * 0.25),
      scale: 1.15,
      bodyColor: config.cloudBodyColor,
      highlightColor: config.cloudHighlightColor,
      shadowColor: config.cloudShadowColor,
      rimColor: config.cloudRimColor,
      opacity: 0.44,
    );
  }

  void _paintRain(Canvas canvas, Size size) {
    final rainPaint = Paint()
      ..color = const Color(0xFFBAE6FD).withOpacity(0.35)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final rand = math.Random(42);
    const dropCount = 45;

    for (int i = 0; i < dropCount; i++) {
      final double startX = (rand.nextDouble() * size.width + (progress * 80)) % size.width;
      final double baseSpeed = 0.8 + (rand.nextDouble() * 0.6);
      final double startY = ((progress * size.height * 2.2 * baseSpeed) + (i * 28)) % size.height;
      const double dropLength = 16.0;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX - 2.5, startY + dropLength),
        rainPaint,
      );
    }
  }

  void _paintStars(Canvas canvas, Size size) {
    final rand = math.Random(1337);
    const starCount = 55;

    for (int i = 0; i < starCount; i++) {
      final double x = rand.nextDouble() * size.width;
      final double y = rand.nextDouble() * (size.height * 0.65);

      final isBright = i % 5 == 0;
      final double radius = isBright ? 1.2 + rand.nextDouble() * 0.5 : 0.6 + rand.nextDouble() * 0.5;

      final double freq = 1.0 + ((i % 4) * 0.5);
      final double phase = (progress * 2 * math.pi * freq) + (i * 1.5);
      final double twinkle = 0.20 + 0.45 * math.sin(phase);
      final double currentOpacity = twinkle.clamp(0.10, 0.60);

      final starPaint = Paint()
        ..color = Colors.white.withOpacity(currentOpacity)
        ..style = PaintingStyle.fill;

      if (isBright && currentOpacity > 0.35) {
        final glowPaint = Paint()
          ..color = Colors.white.withOpacity(currentOpacity * 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        canvas.drawCircle(Offset(x, y), radius * 1.6, glowPaint);
      }

      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }

    // Gentle occasional shooting star
    final double meteorPhase = (progress * 2.0) % 1.0;
    if (meteorPhase > 0.92) {
      final double t = (meteorPhase - 0.92) / 0.08;
      final double startX = size.width * 0.80 - (t * size.width * 0.35);
      final double startY = size.height * 0.06 + (t * size.height * 0.16);
      const double tailLength = 32.0;

      final meteorHead = Offset(startX, startY);
      final meteorTail = Offset(startX + tailLength * 0.85, startY - tailLength * 0.52);

      final meteorPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity((1.0 - t) * 0.6),
            const Color(0xFF38BDF8).withOpacity((1.0 - t) * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 1.0],
        ).createShader(Rect.fromPoints(meteorHead, meteorTail))
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(meteorHead, meteorTail, meteorPaint);
    }
  }

  void _paintThunderFlash(Canvas canvas, Size size) {
    final double flashPhase = (progress * 6) % 1.0;
    if (flashPhase > 0.94) {
      final double intensity = ((flashPhase - 0.94) / 0.06);
      final flashPaint = Paint()
        ..color = const Color(0xFFC084FC).withOpacity(intensity * 0.14);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AtmosphericPainter oldDelegate) => true;
}

class _CloudLobe {
  final Offset offset;
  final double radiusX;
  final double radiusY;
  final double highlight;

  const _CloudLobe(this.offset, this.radiusX, this.radiusY, this.highlight);
}

void _draw3DVolumetricCloud(
  Canvas canvas,
  Offset center, {
  required double scale,
  required Color bodyColor,
  required Color highlightColor,
  required Color shadowColor,
  required Color rimColor,
  double opacity = 1.0,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(scale);

  // 1. Volumetric Under-Shadow Shelf (Deep ambient occlusion)
  final baseShadowPaint = Paint()
    ..shader = RadialGradient(
      center: const Alignment(0.0, 0.4),
      radius: 0.9,
      colors: [
        shadowColor.withOpacity(0.45 * opacity),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    ).createShader(const Rect.fromLTWH(-90, -5, 180, 65))
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

  canvas.drawOval(
    const Rect.fromLTWH(-85, 14, 170, 48),
    baseShadowPaint,
  );

  // 2. Organic Multi-Lobe Cumulus Billows
  const lobes = [
    // Lower body fill
    _CloudLobe(Offset(0, 16), 65, 26, 0.70),
    // Left lower shelf
    _CloudLobe(Offset(-52, 12), 28, 24, 0.80),
    // Right lower shelf
    _CloudLobe(Offset(54, 14), 30, 25, 0.80),
    // Central core billow
    _CloudLobe(Offset(-16, 2), 38, 34, 0.95),
    // Central-right billow
    _CloudLobe(Offset(22, 4), 36, 32, 0.92),
    // Top crown crest puff
    _CloudLobe(Offset(2, -18), 30, 28, 1.0),
    // Top-left shoulder puff
    _CloudLobe(Offset(-36, -6), 26, 24, 0.90),
    // Top-right shoulder puff
    _CloudLobe(Offset(38, -4), 28, 25, 0.88),
  ];

  for (final lobe in lobes) {
    final rect = Rect.fromCenter(
      center: lobe.offset,
      width: lobe.radiusX * 2,
      height: lobe.radiusY * 2,
    );

    // 3D Spherical Light Shader with organic atmospheric feathering
    final lobePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.45),
        radius: 0.88,
        colors: [
          highlightColor.withOpacity(0.95 * opacity * lobe.highlight),
          bodyColor.withOpacity(0.85 * opacity),
          shadowColor.withOpacity(0.48 * opacity),
        ],
        stops: const [0.0, 0.52, 1.0],
      ).createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9.0);

    canvas.drawOval(rect, lobePaint);
  }

  // 3. Lit Top Crest Rim Highlights (Soft atmospheric sun reflection)
  final rimPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        rimColor.withOpacity(0.95 * opacity),
        rimColor.withOpacity(0.0),
      ],
      stops: const [0.0, 0.75],
    ).createShader(const Rect.fromLTWH(-70, -35, 140, 50))
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

  canvas.drawOval(
    Rect.fromCenter(center: const Offset(2, -20), width: 52, height: 24),
    rimPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(-28, -6), width: 46, height: 22),
    rimPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(30, -4), width: 46, height: 22),
    rimPaint,
  );

  canvas.restore();
}
