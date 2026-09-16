import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/utils/celestial_math.dart';

void main() {
  group('CelestialMath Tests', () {
    test('calculateMoonPhase returns accurate values between 0.0 and 1.0', () {
      final now = DateTime.now();
      final phase = CelestialMath.getMoonPhase(now);
      expect(phase, greaterThanOrEqualTo(0.0));
      expect(phase, lessThan(1.0));
    });

    test('getIllumination matches phase accurately', () {
      // 0.0 phase (New Moon) -> 0.0 illumination
      expect(CelestialMath.getIllumination(0.0), closeTo(0.0, 0.01));
      // 0.5 phase (Full Moon) -> 1.0 illumination
      expect(CelestialMath.getIllumination(0.5), closeTo(1.0, 0.01));
      // 0.25 phase (Quarter) -> 0.5 illumination
      expect(CelestialMath.getIllumination(0.25), closeTo(0.5, 0.01));
    });

    test('New Moon correctly marks isVisible as false', () {
      // Known reference New Moon date
      final newMoonDate = DateTime.utc(2000, 1, 6, 18, 14);
      final info = CelestialMath.getMoonPhaseInfo(newMoonDate);
      expect(info.phaseType, equals(MoonPhaseType.newMoon));
      expect(info.isVisible, isFalse);
    });

    test('Full Moon has high illumination and is visible', () {
      // 14.765 days after known new moon
      final fullMoonDate = DateTime.utc(2000, 1, 6, 18, 14).add(const Duration(hours: 354));
      final info = CelestialMath.getMoonPhaseInfo(fullMoonDate);
      expect(info.illumination, greaterThan(0.9));
      expect(info.isVisible, isTrue);
    });

    test('CelestialEventType overrides function properly', () {
      final bloodMoonInfo = CelestialMath.getMoonPhaseInfo(
        DateTime.now(),
        CelestialEventType.bloodMoon,
      );
      expect(bloodMoonInfo.eventType, equals(CelestialEventType.bloodMoon));

      final solarEclipseInfo = CelestialMath.getMoonPhaseInfo(
        DateTime.now(),
        CelestialEventType.solarEclipse,
      );
      expect(solarEclipseInfo.eventType, equals(CelestialEventType.solarEclipse));
    });
  });
}
