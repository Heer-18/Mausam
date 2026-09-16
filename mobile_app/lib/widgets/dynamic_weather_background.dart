import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_models.dart';

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

  const WeatherAtmosphereConfig({
    required this.type,
    required this.gradientColors,
    required this.gradientStops,
    required this.cardGlassFill,
    required this.cardGlassBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentColor,
    this.hasRain = false,
    this.hasClouds = false,
    this.hasStars = false,
    this.hasThunder = false,
  });

  factory WeatherAtmosphereConfig.fromTelemetry(WeatherTelemetry? telemetry, [DateTime? time]) {
    final now = time ?? DateTime.now();
    final hour = now.hour;
    final isNight = hour < 6 || hour >= 19;
    final isSunsetOrSunrise = (hour >= 5 && hour < 7) || (hour >= 17 && hour < 19);

    final code = telemetry?.weatherCode ?? 0;
    final temp = telemetry?.currentTemperature ?? 25.0;

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
        cardGlassFill: const Color(0x2E1E1B4B),
        cardGlassBorder: const Color(0x40818CF8),
        textPrimary: Colors.white,
        textSecondary: const Color(0xFFCBD5E1),
        accentColor: const Color(0xFFA855F7),
        hasRain: true,
        hasClouds: true,
        hasThunder: true,
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
        cardGlassFill: const Color(0x331E293B),
        cardGlassBorder: const Color(0x3394A3B8),
        textPrimary: Colors.white,
        textSecondary: const Color(0xFFE2E8F0),
        accentColor: const Color(0xFF38BDF8),
        hasRain: true,
        hasClouds: true,
      );
    }

    // 3. Snow (71..77, 85..86)
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return const WeatherAtmosphereConfig(
        type: WeatherAtmosphereType.snowy,
        gradientColors: [
          Color(0xFF1E293B),
          Color(0xFF3B4D66),
          Color(0xFF64748B),
          Color(0xFF94A3B8),
        ],
        gradientStops: [0.0, 0.35, 0.7, 1.0],
        cardGlassFill: Color(0x33FFFFFF),
        cardGlassBorder: Color(0x4DFFFFFF),
        textPrimary: Colors.white,
        textSecondary: Color(0xFFF1F5F9),
        accentColor: Color(0xFF7DD3FC),
        hasClouds: true,
      );
    }

    // 4. Fog / Mist (45, 48)
    if (code == 45 || code == 48) {
      return const WeatherAtmosphereConfig(
        type: WeatherAtmosphereType.foggy,
        gradientColors: [
          Color(0xFF1E293B),
          Color(0xFF334155),
          Color(0xFF475569),
          Color(0xFF3B485A),
        ],
        gradientStops: [0.0, 0.3, 0.65, 1.0],
        cardGlassFill: Color(0x29FFFFFF),
        cardGlassBorder: Color(0x2EFFFFFF),
        textPrimary: Colors.white,
        textSecondary: Color(0xFFE2E8F0),
        accentColor: Color(0xFF94A3B8),
        hasClouds: true,
      );
    }

    // 5. Cloudy (1, 2, 3) or Sunset/Twilight
    if (code >= 1 && code <= 3) {
      if (isSunsetOrSunrise) {
        // Sunset / Twilight cloudy aesthetic (Matching reference image!)
        return const WeatherAtmosphereConfig(
          type: WeatherAtmosphereType.cloudyTwilight,
          gradientColors: [
            Color(0xFF36395A), // Deep twilight indigo/purple top
            Color(0xFF4A4B75), // Mid atmospheric lavender
            Color(0xFF6B6E9B), // Cloud layer violet
            Color(0xFF7B7293), // Soft evening mauve
            Color(0xFFB07D7B), // Warm sunset horizon touch
          ],
          gradientStops: [0.0, 0.28, 0.55, 0.78, 1.0],
          cardGlassFill: Color(0x2BFFFFFF),
          cardGlassBorder: Color(0x38FFFFFF),
          textPrimary: Colors.white,
          textSecondary: Color(0xFFF1F5F9),
          accentColor: Color(0xFFFED7AA),
          hasClouds: true,
        );
      }

      if (isNight) {
        return const WeatherAtmosphereConfig(
          type: WeatherAtmosphereType.cloudyDay,
          gradientColors: [
            Color(0xFF0B0F19),
            Color(0xFF141C2E),
            Color(0xFF1F293D),
            Color(0xFF111827),
          ],
          gradientStops: [0.0, 0.35, 0.7, 1.0],
          cardGlassFill: Color(0x261E293B),
          cardGlassBorder: Color(0x2BFFFFFF),
          textPrimary: Colors.white,
          textSecondary: Color(0xFFCBD5E1),
          accentColor: Color(0xFF93C5FD),
          hasClouds: true,
          hasStars: true,
        );
      }

      // Daytime Cloudy with dynamic temperature warmth
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
        cardGlassFill: const Color(0x29FFFFFF),
        cardGlassBorder: const Color(0x38FFFFFF),
        textPrimary: Colors.white,
        textSecondary: const Color(0xFFF8FAFC),
        accentColor: const Color(0xFFBAE6FD),
        hasClouds: true,
      );
    }

    // 6. Clear Sky (0)
    if (isNight) {
      return const WeatherAtmosphereConfig(
        type: WeatherAtmosphereType.clearNight,
        gradientColors: [
          Color(0xFF050811),
          Color(0xFF0B132B),
          Color(0xFF1C2541),
          Color(0xFF0F172A),
        ],
        gradientStops: [0.0, 0.3, 0.65, 1.0],
        cardGlassFill: Color(0x241E293B),
        cardGlassBorder: Color(0x2EFFFFFF),
        textPrimary: Colors.white,
        textSecondary: Color(0xFFCBD5E1),
        accentColor: Color(0xFF60A5FA),
        hasStars: true,
      );
    }

    if (isSunsetOrSunrise) {
      return const WeatherAtmosphereConfig(
        type: WeatherAtmosphereType.clearDay,
        gradientColors: [
          Color(0xFF1E1B4B),
          Color(0xFF4338CA),
          Color(0xFF7C3AED),
          Color(0xFFDB2777),
          Color(0xFFF59E0B),
        ],
        gradientStops: [0.0, 0.25, 0.5, 0.75, 1.0],
        cardGlassFill: Color(0x2EFFFFFF),
        cardGlassBorder: Color(0x40FFFFFF),
        textPrimary: Colors.white,
        textSecondary: Color(0xFFFFFBEB),
        accentColor: Color(0xFFFDE68A),
      );
    }

    // Clear Daytime (Radiant Azure Sky)
    return const WeatherAtmosphereConfig(
      type: WeatherAtmosphereType.clearDay,
      gradientColors: [
        Color(0xFF1E40AF),
        Color(0xFF2563EB),
        Color(0xFF3B82F6),
        Color(0xFF60A5FA),
      ],
      gradientStops: [0.0, 0.35, 0.7, 1.0],
      cardGlassFill: Color(0x26FFFFFF),
      cardGlassBorder: Color(0x38FFFFFF),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFEFF6FF),
      accentColor: Color(0xFFBAE6FD),
    );
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
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
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
          // Animated Ambient Weather Effects Canvas
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

          // Main App Content
          widget.child,
        ],
      ),
    );
  }
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
    if (config.hasStars) {
      _paintStars(canvas, size);
    }
    if (config.hasClouds) {
      _paintFloatingClouds(canvas, size);
    }
    if (config.hasRain) {
      _paintRain(canvas, size);
    }
    if (config.hasThunder) {
      _paintThunderFlash(canvas, size);
    }
  }

  void _paintFloatingClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36);

    final darkCloudPaint = Paint()
      ..color = const Color(0xFF1E1B4B).withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);

    final double w = size.width;

    // Layer 1: Upper soft clouds moving gently
    final double offset1 = (progress * w * 0.4) % (w * 1.5) - (w * 0.25);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(offset1, size.height * 0.12),
        width: w * 0.9,
        height: 140,
      ),
      cloudPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(offset1 + w * 0.6, size.height * 0.18),
        width: w * 0.8,
        height: 120,
      ),
      darkCloudPaint,
    );

    // Layer 2: Mid atmosphere cloud puff
    final double offset2 = ((1.0 - progress) * w * 0.3) % (w * 1.4) - (w * 0.2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w - offset2, size.height * 0.26),
        width: w * 0.85,
        height: 160,
      ),
      cloudPaint,
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
    const starCount = 38;

    for (int i = 0; i < starCount; i++) {
      final x = rand.nextDouble() * size.width;
      final y = rand.nextDouble() * (size.height * 0.55);
      final radius = 0.8 + (rand.nextDouble() * 1.4);
      final twinkle = 0.3 + 0.7 * math.sin((progress * 2 * math.pi * 3) + i);

      final starPaint = Paint()
        ..color = Colors.white.withOpacity(twinkle.clamp(0.15, 0.95))
        ..maskFilter = radius > 1.4 ? const MaskFilter.blur(BlurStyle.normal, 1.5) : null;

      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  void _paintThunderFlash(Canvas canvas, Size size) {
    // Occasional subtle purple flash
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
