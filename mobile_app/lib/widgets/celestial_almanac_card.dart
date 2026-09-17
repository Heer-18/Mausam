import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../utils/celestial_math.dart';
import '../utils/theme.dart';
import 'glass_container.dart';

class CelestialAlmanacCard extends StatelessWidget {
  final WeatherTelemetry? telemetry;
  final DailyForecast? todayForecast;

  const CelestialAlmanacCard({
    super.key,
    this.telemetry,
    this.todayForecast,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final isNight = hour < 6 || hour >= 19;

    // Detect celestial event if any
    CelestialEventType eventType = CelestialEventType.none;
    final condLower = (telemetry?.weatherCondition ?? '').toLowerCase();
    if (condLower.contains('solar eclipse') || condLower.contains('suryagrahan')) {
      eventType = CelestialEventType.solarEclipse;
    } else if (condLower.contains('lunar eclipse') || condLower.contains('chandragrahan')) {
      eventType = CelestialEventType.lunarEclipse;
    } else if (condLower.contains('blood moon') || condLower.contains('red moon')) {
      eventType = CelestialEventType.bloodMoon;
    }

    final moonInfo = CelestialMath.getMoonPhaseInfo(now, eventType);
    final sunrise = todayForecast?.sunrise ?? '06:15';
    final sunset = todayForecast?.sunset ?? '18:35';
    final illuminationPct = (moonInfo.illumination * 100).round();

    return GlassContainer(
      padding: const EdgeInsets.all(16.0),
      borderRadius: 24.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isNight ? Icons.nightlight_round : Icons.wb_twilight_rounded,
                    size: 16,
                    color: isNight ? const Color(0xFF93C5FD) : const Color(0xFFFDE047),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CELESTIAL ALMANAC & MOON PHASE',
                    style: AppTypography.labelCaps.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              if (eventType != CelestialEventType.none)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: eventType == CelestialEventType.solarEclipse
                        ? const Color(0xFFD97706).withOpacity(0.25)
                        : const Color(0xFFE11D48).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: eventType == CelestialEventType.solarEclipse
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFFB7185),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    eventType == CelestialEventType.solarEclipse
                        ? 'Suryagrahan'
                        : (eventType == CelestialEventType.lunarEclipse
                            ? 'Chandragrahan'
                            : 'Blood Moon'),
                    style: AppTypography.labelCaps.copyWith(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.08), height: 1),
          const SizedBox(height: 12),

          // Main Celestial Body & Details Row
          Row(
            children: [
              // Mini Custom Painted Moon / Sun Sphere
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF090D16).withOpacity(0.6),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (eventType == CelestialEventType.bloodMoon
                              ? const Color(0xFFE11D48)
                              : (eventType == CelestialEventType.solarEclipse
                                  ? const Color(0xFFFBBF24)
                                  : const Color(0xFF60A5FA)))
                          .withOpacity(0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _MiniMoonPainter(moonInfo: moonInfo, eventType: eventType),
                ),
              ),

              const SizedBox(width: 14),

              // Moon Phase Name & Illumination
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moonInfo.name,
                      style: AppTypography.titleMd.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      moonInfo.isVisible
                          ? '$illuminationPct% Illumination • Synodic Cycle Day ${(moonInfo.phase * 29.53).toStringAsFixed(1)}'
                          : 'No Moon Day (Amavasya) • 0% Illumination',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 12,
                        color: const Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Sun Times Row (Sunrise & Sunset)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Sunrise
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_rounded, size: 16, color: Color(0xFFFDE047)),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUNRISE',
                          style: AppTypography.labelCaps.copyWith(
                            fontSize: 9,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          sunrise,
                          style: AppTypography.dataMono.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                Container(
                  width: 1,
                  height: 24,
                  color: Colors.white.withOpacity(0.12),
                ),

                // Sunset
                Row(
                  children: [
                    const Icon(Icons.wb_twilight_rounded, size: 16, color: Color(0xFFFB923C)),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SUNSET',
                          style: AppTypography.labelCaps.copyWith(
                            fontSize: 9,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          sunset,
                          style: AppTypography.dataMono.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMoonPainter extends CustomPainter {
  final MoonPhaseInfo moonInfo;
  final CelestialEventType eventType;

  _MiniMoonPainter({
    required this.moonInfo,
    required this.eventType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double r = size.width * 0.36;

    if (!moonInfo.isVisible && eventType == CelestialEventType.none) {
      // Invisible New Moon
      final darkDisk = Paint()..color = const Color(0xFF1E293B).withOpacity(0.3);
      canvas.drawCircle(center, r, darkDisk);
      return;
    }

    final bool isBloodMoon = eventType == CelestialEventType.bloodMoon;
    final bool isLunarEclipse = eventType == CelestialEventType.lunarEclipse;
    final bool isSolarEclipse = eventType == CelestialEventType.solarEclipse;

    if (isSolarEclipse) {
      // Shimmering Solar Corona Mini
      final corona = Paint()
        ..color = const Color(0xFFFBBF24).withOpacity(0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center, r * 1.25, corona);

      final transitMoon = Paint()..color = const Color(0xFF090D16);
      canvas.drawCircle(center, r, transitMoon);

      final diamond = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(center.dx - r * 0.65, center.dy - r * 0.65), 2.5, diamond);
      return;
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 4.7);

    // Lit phase path (Clean glowing crescent)
    final double phase = moonInfo.phase;
    final double theta = phase * 2 * math.pi;
    final Path litPath = Path();

    if (phase >= 0.47 && phase <= 0.53) {
      litPath.addOval(Rect.fromCircle(center: Offset.zero, radius: r));
    } else {
      final bool isWaxing = phase < 0.5;
      final double xTerminator = r * math.cos(theta);
      final double semiMinor = math.max((r * math.cos(theta)).abs(), 0.5);

      if (isWaxing) {
        litPath.moveTo(0, -r);
        litPath.arcToPoint(
          Offset(0, r),
          radius: Radius.circular(r),
          clockwise: true,
        );
        litPath.arcToPoint(
          Offset(0, -r),
          radius: Radius.elliptical(semiMinor, r),
          clockwise: xTerminator > 0,
        );
      } else {
        litPath.moveTo(0, -r);
        litPath.arcToPoint(
          Offset(0, r),
          radius: Radius.circular(r),
          clockwise: false,
        );
        litPath.arcToPoint(
          Offset(0, -r),
          radius: Radius.elliptical(semiMinor, r),
          clockwise: xTerminator < 0,
        );
      }
    }

    final Paint litPaint = Paint();
    if (isBloodMoon) {
      litPaint.shader = RadialGradient(
        colors: const [
          Color(0xFFFFE4E6),
          Color(0xFFE11D48),
          Color(0xFF881337),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    } else if (isLunarEclipse) {
      litPaint.color = const Color(0xFFF59E0B);
    } else {
      litPaint.shader = RadialGradient(
        center: const Alignment(0.4, -0.1),
        colors: const [
          Colors.white,
          Color(0xFFF1F5F9),
          Color(0xFFCBD5E1),
          Color(0xFF64748B),
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    }

    canvas.drawPath(litPath, litPaint);

    // Mare textures
    canvas.save();
    canvas.clipPath(litPath);
    final marePaint = Paint()
      ..color = const Color(0x331E293B)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.0);
    canvas.drawOval(Rect.fromCenter(center: const Offset(3, -2), width: 5, height: 4), marePaint);
    canvas.drawOval(Rect.fromCenter(center: const Offset(1, 4), width: 6, height: 4), marePaint);

    if (isLunarEclipse) {
      final umbra = Paint()..color = const Color(0xDD3B0764);
      canvas.drawCircle(const Offset(4, -3), r * 0.9, umbra);
    }
    canvas.restore();

    // Sharp outer rim
    final limbPaint = Paint()
      ..color = (isBloodMoon ? const Color(0xFFFFE4E6) : Colors.white).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final Path outerLimbPath = Path();
    if (phase < 0.5) {
      outerLimbPath.moveTo(0, -r);
      outerLimbPath.arcToPoint(Offset(0, r), radius: Radius.circular(r), clockwise: true);
    } else {
      outerLimbPath.moveTo(0, -r);
      outerLimbPath.arcToPoint(Offset(0, r), radius: Radius.circular(r), clockwise: false);
    }
    canvas.drawPath(outerLimbPath, limbPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniMoonPainter oldDelegate) => true;
}
