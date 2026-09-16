import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/models/persona_type.dart';
import 'package:mausam/providers/weather_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Persona-Scoped Parameters Tests', () {
    test('Default persona starts with matching default parameter IDs', () async {
      final provider = WeatherProvider();
      expect(provider.activePersona, PersonaType.health);
      expect(provider.activeParameterIds, isNotEmpty);
      expect(provider.activeParameterIds.contains('aqi'), isTrue);
      expect(provider.activeParameterIds.contains('grass_pollen'), isTrue);
    });

    test('Switching persona immediately updates activeParameterIds to new persona defaults', () async {
      final provider = WeatherProvider();
      expect(provider.activePersona, PersonaType.health);

      // Switch to farm
      await provider.switchPersona(PersonaType.farm);
      expect(provider.activePersona, PersonaType.farm);
      expect(provider.activeParameterIds.contains('irrigation_advice'), isTrue);
      expect(provider.activeParameterIds.contains('soil_moisture'), isTrue);
      expect(provider.activeParameterIds.contains('grass_pollen'), isFalse);

      // Switch to fitness
      await provider.switchPersona(PersonaType.fitness);
      expect(provider.activePersona, PersonaType.fitness);
      expect(provider.activeParameterIds.contains('workout_score'), isTrue);
      expect(provider.activeParameterIds.contains('best_run_window'), isTrue);
      expect(provider.activeParameterIds.contains('irrigation_advice'), isFalse);
    });

    test('Customizing parameters retains active persona and saves persona-specific configuration', () async {
      final provider = WeatherProvider();
      await provider.switchPersona(PersonaType.beach);
      expect(provider.activePersona, PersonaType.beach);

      // Toggle a parameter on Beach persona
      final initialCount = provider.activeParameterIds.length;
      await provider.toggleParameterSelection('pm10');

      // Persona must NOT change
      expect(provider.activePersona, PersonaType.beach);
      expect(provider.activeParameterIds.contains('pm10'), isTrue);
      expect(provider.activeParameterIds.length, initialCount + 1);

      // Switch to work persona
      await provider.switchPersona(PersonaType.work);
      expect(provider.activePersona, PersonaType.work);
      expect(provider.activeParameterIds.contains('apparent_temperature'), isTrue);

      // Switch back to beach persona -> customized parameters should be restored!
      await provider.switchPersona(PersonaType.beach);
      expect(provider.activePersona, PersonaType.beach);
      expect(provider.activeParameterIds.contains('pm10'), isTrue);
    });
  });
}
