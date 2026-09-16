import 'dart:math' as math;

enum CelestialEventType {
  none,
  bloodMoon,
  lunarEclipse, // Chandragrahan
  solarEclipse, // Suryagrahan
}

enum MoonPhaseType {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

class MoonPhaseInfo {
  final double phase; // 0.0 to 1.0 (0.0 = New Moon, 0.5 = Full Moon)
  final double illumination; // 0.0 to 1.0
  final MoonPhaseType phaseType;
  final String name;
  final bool isVisible;
  final CelestialEventType eventType;

  const MoonPhaseInfo({
    required this.phase,
    required this.illumination,
    required this.phaseType,
    required this.name,
    required this.isVisible,
    this.eventType = CelestialEventType.none,
  });
}

class CelestialMath {
  // Known New Moon reference epoch: 2000-01-06 18:14 UTC
  static final DateTime _knownNewMoonEpoch = DateTime.utc(2000, 1, 6, 18, 14);
  static const double synodicMonthDays = 29.53058770576;

  /// Calculates the current moon phase (0.0 to 1.0)
  static double getMoonPhase([DateTime? date]) {
    final now = date ?? DateTime.now();
    final diffMs = now.toUtc().difference(_knownNewMoonEpoch).inMilliseconds;
    final diffDays = diffMs / (1000.0 * 60 * 60 * 24);
    final cycles = diffDays / synodicMonthDays;
    double phase = cycles - cycles.floor();
    if (phase < 0) phase += 1.0;
    return phase;
  }

  /// Calculates illumination percentage (0.0 to 1.0)
  static double getIllumination(double phase) {
    return (1.0 - math.cos(phase * 2 * math.pi)) / 2.0;
  }

  /// Returns rich Moon phase info for rendering and UI
  static MoonPhaseInfo getMoonPhaseInfo([
    DateTime? date,
    CelestialEventType eventType = CelestialEventType.none,
  ]) {
    final phase = getMoonPhase(date);
    final illumination = getIllumination(phase);

    MoonPhaseType phaseType;
    String name;
    bool isVisible = true;

    if (phase < 0.03 || phase >= 0.97) {
      phaseType = MoonPhaseType.newMoon;
      name = 'New Moon (Amavasya)';
      isVisible = false; // Invisible on No Moon Day
    } else if (phase < 0.22) {
      phaseType = MoonPhaseType.waxingCrescent;
      name = 'Waxing Crescent';
    } else if (phase < 0.28) {
      phaseType = MoonPhaseType.firstQuarter;
      name = 'First Quarter';
    } else if (phase < 0.47) {
      phaseType = MoonPhaseType.waxingGibbous;
      name = 'Waxing Gibbous';
    } else if (phase < 0.53) {
      phaseType = MoonPhaseType.fullMoon;
      name = 'Full Moon (Purnima)';
    } else if (phase < 0.72) {
      phaseType = MoonPhaseType.waningGibbous;
      name = 'Waning Gibbous';
    } else if (phase < 0.78) {
      phaseType = MoonPhaseType.lastQuarter;
      name = 'Last Quarter';
    } else {
      phaseType = MoonPhaseType.waningCrescent;
      name = 'Waning Crescent';
    }

    return MoonPhaseInfo(
      phase: phase,
      illumination: illumination,
      phaseType: phaseType,
      name: name,
      isVisible: isVisible,
      eventType: eventType,
    );
  }
}
