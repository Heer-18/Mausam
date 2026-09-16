import 'package:flutter/material.dart';
import 'weather_models.dart';

enum ParameterCategory {
  airQuality('Air Quality & Allergy', Icons.air_rounded, Color(0xFF10B981)),
  thermal('Thermal & Sky', Icons.thermostat_rounded, Color(0xFFF59E0B)),
  windPrecip('Wind & Rain', Icons.cloud_queue_rounded, Color(0xFF06B6D4)),
  agroSoil('Agro & Soil Moisture', Icons.grass_rounded, Color(0xFF10B981)),
  lifestyle('Lifestyle & Commute', Icons.psychology_rounded, Color(0xFF8B5CF6));

  final String title;
  final IconData icon;
  final Color color;
  const ParameterCategory(this.title, this.icon, this.color);
}

class WeatherParameterDefinition {
  final String id;
  final String title;
  final String shortTitle;
  final String description;
  final ParameterCategory category;
  final IconData icon;
  final Color defaultColor;

  const WeatherParameterDefinition({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.category,
    required this.icon,
    required this.defaultColor,
  });

  /// Derive actual slot data for this parameter from live telemetry and air quality
  PersonaSlotData extractSlotData({
    required int slotIndex,
    required WeatherTelemetry? telemetry,
    required AirQualityData? airQuality,
    required MarineData? marineData,
    required int workoutScore,
    required String optimalRunWindow,
    required String moldRisk,
    required String irrigationAdvice,
    required double agDeficit,
    required int commuteHazard,
    required String commuteCondition,
    required String tempUnit,
    required String windUnit,
  }) {
    if (telemetry == null || airQuality == null) {
      return PersonaSlotData(
        slotIndex: slotIndex,
        title: title,
        value: '--',
        subtitle: 'Loading data...',
        status: 'Optimal',
        icon: icon,
        color: defaultColor,
        progressPercentage: 0.5,
      );
    }

    final t = telemetry;
    final a = airQuality;

    String fmtTemp(double c) => tempUnit == 'F' ? '${((c * 9 / 5) + 32).round()}°F' : '${c.round()}°C';
    String fmtWind(double k) => windUnit == 'mph' ? '${(k * 0.621371).round()} mph' : (windUnit == 'm/s' ? '${(k / 3.6).toStringAsFixed(1)} m/s' : '${k.round()} km/h');

    switch (id) {
      // 1. Air Quality
      case 'aqi':
        final aqiLabel = a.aqi <= 50 ? 'Good' : (a.aqi <= 100 ? 'Moderate' : 'Unhealthy');
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'AQI',
          value: '${a.aqi} $aqiLabel',
          subtitle: 'PM2.5 ${a.pm2_5.toStringAsFixed(1)} µg/m³',
          status: aqiLabel,
          icon: Icons.air_rounded,
          color: a.aqi <= 50 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          progressPercentage: (a.aqi / 200.0).clamp(0.0, 1.0),
        );
      case 'pm2_5':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'PM2.5 Index',
          value: '${a.pm2_5.toStringAsFixed(1)} µg/m³',
          subtitle: a.pm2_5 <= 15 ? 'Clean air' : 'Particulate haze',
          status: a.pm2_5 <= 15 ? 'Good' : 'Moderate',
          icon: Icons.grain_rounded,
          color: a.pm2_5 <= 15 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          progressPercentage: (a.pm2_5 / 60.0).clamp(0.0, 1.0),
        );
      case 'pm10':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'PM10 Dust',
          value: '${a.pm10.round()} µg/m³',
          subtitle: 'Coarse dust particles',
          status: 'Good',
          icon: Icons.masks_rounded,
          color: const Color(0xFF10B981),
          progressPercentage: (a.pm10 / 100.0).clamp(0.0, 1.0),
        );
      case 'grass_pollen':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Grass Pollen',
          value: '${a.grassPollen < 10 ? 'Low' : 'Moderate'} ${a.grassPollen.round()}',
          subtitle: 'grains/m³',
          status: 'Low',
          icon: Icons.grass_rounded,
          color: const Color(0xFF10B981),
          progressPercentage: (a.grassPollen / 30.0).clamp(0.0, 1.0),
        );
      case 'tree_pollen':
        final totalTree = (a.alderPollen + a.birchPollen).round();
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Tree Pollen',
          value: '${totalTree < 15 ? 'Low' : 'Moderate'} $totalTree',
          subtitle: 'Alder & Birch pollen',
          status: 'Moderate',
          icon: Icons.park_rounded,
          color: const Color(0xFFF59E0B),
          progressPercentage: 0.45,
        );

      // 2. Thermal & Sky
      case 'temperature':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Temperature',
          value: fmtTemp(t.currentTemperature),
          subtitle: 'Feels like ${fmtTemp(t.apparentTemperature)}',
          status: 'Moderate',
          icon: Icons.thermostat_rounded,
          color: const Color(0xFFF59E0B),
          progressPercentage: (t.currentTemperature / 45.0).clamp(0.0, 1.0),
        );
      case 'apparent_temperature':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Heat Index',
          value: fmtTemp(t.apparentTemperature),
          subtitle: 'Actual ${fmtTemp(t.currentTemperature)}',
          status: 'Moderate',
          icon: Icons.device_thermostat_rounded,
          color: const Color(0xFFF59E0B),
          progressPercentage: (t.apparentTemperature / 45.0).clamp(0.0, 1.0),
        );
      case 'humidity':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Humidity',
          value: '${t.humidity}%',
          subtitle: 'Mold Risk: $moldRisk',
          status: 'Moderate',
          icon: Icons.water_drop_rounded,
          color: const Color(0xFF06B6D4),
          progressPercentage: t.humidity / 100.0,
        );
      case 'uv_index':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'UV Index',
          value: '${t.uvIndex.round()} ${t.uvIndex >= 6 ? 'High' : (t.uvIndex >= 3 ? 'Moderate' : 'Low')}',
          subtitle: t.uvIndex >= 6 ? 'SPF 30+ needed' : 'Safe sun exposure',
          status: t.uvIndex >= 6 ? 'High' : 'Moderate',
          icon: Icons.wb_sunny_rounded,
          color: t.uvIndex >= 6 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          progressPercentage: (t.uvIndex / 12.0).clamp(0.0, 1.0),
        );
      case 'cloud_cover':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Cloud Cover',
          value: '${t.cloudCover}%',
          subtitle: t.cloudCover > 60 ? 'Overcast skies' : 'Clear visibility',
          status: 'Optimal',
          icon: Icons.cloud_rounded,
          color: const Color(0xFF94A3B8),
          progressPercentage: t.cloudCover / 100.0,
        );
      case 'visibility':
        final visKm = (t.visibilityMeters / 1000.0).toStringAsFixed(1);
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Visibility',
          value: '$visKm km',
          subtitle: t.visibilityMeters >= 8000 ? 'Crystal clear route' : 'Haze present',
          status: 'Optimal',
          icon: Icons.visibility_rounded,
          color: const Color(0xFF10B981),
          progressPercentage: (t.visibilityMeters / 10000.0).clamp(0.0, 1.0),
        );
      case 'surface_pressure':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Pressure',
          value: '${t.surfacePressure.round()} hPa',
          subtitle: 'Barometric equilibrium',
          status: 'Optimal',
          icon: Icons.speed_rounded,
          color: const Color(0xFF38BDF8),
          progressPercentage: 0.75,
        );

      // 3. Wind & Rain
      case 'wind_speed':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Wind Speed',
          value: fmtWind(t.windSpeed),
          subtitle: 'From ${t.windDirectionCardinal}',
          status: 'Good',
          icon: Icons.air_rounded,
          color: const Color(0xFF10B981),
          progressPercentage: (t.windSpeed / 40.0).clamp(0.0, 1.0),
        );
      case 'wind_gusts':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Wind Gusts',
          value: fmtWind(t.windGusts),
          subtitle: t.windGusts > 40 ? 'Breezy conditions' : 'Calm air',
          status: 'Good',
          icon: Icons.storm_rounded,
          color: const Color(0xFF06B6D4),
          progressPercentage: (t.windGusts / 60.0).clamp(0.0, 1.0),
        );
      case 'rain_probability':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Rain Chance',
          value: '${t.precipitation > 0 ? 60 : 10}%',
          subtitle: 'Next 24 hours',
          status: 'Good',
          icon: Icons.umbrella_rounded,
          color: const Color(0xFF06B6D4),
          progressPercentage: t.precipitation > 0 ? 0.6 : 0.15,
        );
      case 'precipitation':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Precipitation',
          value: '${t.precipitation.toStringAsFixed(1)} mm/h',
          subtitle: t.precipitation > 0 ? 'Active rain' : 'Dry ground',
          status: 'Good',
          icon: Icons.water_drop_rounded,
          color: const Color(0xFF06B6D4),
          progressPercentage: (t.precipitation / 15.0).clamp(0.0, 1.0),
        );

      // 4. Agro & Soil
      case 'soil_moisture':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Soil Moisture',
          value: '${t.soilMoisture.toStringAsFixed(2)} m³/m³',
          subtitle: '0-7cm Topsoil',
          status: t.soilMoisture >= 0.22 ? 'Optimal' : 'Low',
          icon: Icons.grass_rounded,
          color: const Color(0xFF10B981),
          progressPercentage: (t.soilMoisture / 0.4).clamp(0.0, 1.0),
        );
      case 'evapotranspiration':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Evapotranspiration',
          value: '${t.evapotranspiration.toStringAsFixed(1)} mm/d',
          subtitle: 'ET₀ crop consumption',
          status: 'Optimal',
          icon: Icons.wb_twilight_rounded,
          color: const Color(0xFF06B6D4),
          progressPercentage: (t.evapotranspiration / 6.0).clamp(0.0, 1.0),
        );
      case 'irrigation_advice':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Irrigation',
          value: irrigationAdvice.split('—')[0].trim(),
          subtitle: 'Deficit ${agDeficit.toStringAsFixed(1)} mm',
          status: 'Optimal',
          icon: Icons.water_rounded,
          color: const Color(0xFF10B981),
          progressPercentage: 0.8,
        );
      case 'mold_risk':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Mold / Fungal Risk',
          value: moldRisk,
          subtitle: 'Hum ${t.humidity}%, ${fmtTemp(t.currentTemperature)}',
          status: moldRisk,
          icon: Icons.coronavirus_rounded,
          color: moldRisk == 'High' ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          progressPercentage: moldRisk == 'High' ? 0.85 : 0.25,
        );

      // 5. Lifestyle & AI
      case 'workout_score':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Workout Safety',
          value: '$workoutScore/100',
          subtitle: workoutScore >= 75 ? 'Safe for High Intensity' : 'Moderate Heat Stress',
          status: 'Good',
          icon: Icons.fitness_center_rounded,
          color: const Color(0xFF8B5CF6),
          progressPercentage: workoutScore / 100.0,
        );
      case 'best_run_window':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Best Run Window',
          value: optimalRunWindow,
          subtitle: 'Optimal temperature & air',
          status: 'Optimal',
          icon: Icons.timer_rounded,
          color: const Color(0xFF06B6D4),
          progressPercentage: 0.85,
        );
      case 'commute_hazard':
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Commute Hazard',
          value: '$commuteHazard/100',
          subtitle: commuteCondition,
          status: commuteHazard < 30 ? 'Good' : 'Hazard',
          icon: Icons.traffic_rounded,
          color: commuteHazard < 30 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          progressPercentage: commuteHazard / 100.0,
        );
      case 'wave_height':
        final waves = marineData?.waveHeight ?? 1.2;
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: 'Wave Height',
          value: '${waves.toStringAsFixed(1)}m',
          subtitle: 'Moderate swell',
          status: 'Good',
          icon: Icons.waves_rounded,
          color: const Color(0xFF06B6D4),
          progressPercentage: (waves / 3.0).clamp(0.0, 1.0),
        );

      default:
        return PersonaSlotData(
          slotIndex: slotIndex,
          title: title,
          value: 'Optimal',
          subtitle: 'Normal conditions',
          status: 'Optimal',
          icon: icon,
          color: defaultColor,
          progressPercentage: 0.8,
        );
    }
  }

  /// Master list of all available meteorological parameters
  static const List<WeatherParameterDefinition> allParameters = [
    // Air Quality
    WeatherParameterDefinition(
      id: 'aqi',
      title: 'Air Quality Index (AQI)',
      shortTitle: 'AQI',
      description: 'Overall European Air Quality index with PM2.5 tracking',
      category: ParameterCategory.airQuality,
      icon: Icons.air_rounded,
      defaultColor: Color(0xFF10B981),
    ),
    WeatherParameterDefinition(
      id: 'pm2_5',
      title: 'PM2.5 Fine Particles',
      shortTitle: 'PM2.5',
      description: 'Microscopic inhalable airborne particulate matter',
      category: ParameterCategory.airQuality,
      icon: Icons.grain_rounded,
      defaultColor: Color(0xFF10B981),
    ),
    WeatherParameterDefinition(
      id: 'pm10',
      title: 'PM10 Coarse Dust',
      shortTitle: 'PM10',
      description: 'Coarse dust, sand and pollen particulates in air',
      category: ParameterCategory.airQuality,
      icon: Icons.masks_rounded,
      defaultColor: Color(0xFF10B981),
    ),
    WeatherParameterDefinition(
      id: 'grass_pollen',
      title: 'Grass Pollen',
      shortTitle: 'Grass Pollen',
      description: 'Airborne grass pollen allergen count in grains/m³',
      category: ParameterCategory.airQuality,
      icon: Icons.grass_rounded,
      defaultColor: Color(0xFF10B981),
    ),
    WeatherParameterDefinition(
      id: 'tree_pollen',
      title: 'Tree Pollen (Alder/Birch)',
      shortTitle: 'Tree Pollen',
      description: 'Alder, Birch and seasonal tree allergen count',
      category: ParameterCategory.airQuality,
      icon: Icons.park_rounded,
      defaultColor: Color(0xFFF59E0B),
    ),

    // Thermal & Sky
    WeatherParameterDefinition(
      id: 'temperature',
      title: 'Temperature',
      shortTitle: 'Temperature',
      description: 'Live 2m atmospheric ambient temperature',
      category: ParameterCategory.thermal,
      icon: Icons.thermostat_rounded,
      defaultColor: Color(0xFFF59E0B),
    ),
    WeatherParameterDefinition(
      id: 'apparent_temperature',
      title: 'Apparent Heat Index',
      shortTitle: 'Feels Like',
      description: 'Combined temperature & relative humidity perceived heat',
      category: ParameterCategory.thermal,
      icon: Icons.device_thermostat_rounded,
      defaultColor: Color(0xFFF59E0B),
    ),
    WeatherParameterDefinition(
      id: 'humidity',
      title: 'Relative Humidity',
      shortTitle: 'Humidity',
      description: 'Atmospheric moisture saturation percentage',
      category: ParameterCategory.thermal,
      icon: Icons.water_drop_rounded,
      defaultColor: Color(0xFF06B6D4),
    ),
    WeatherParameterDefinition(
      id: 'uv_index',
      title: 'UV Solar Index',
      shortTitle: 'UV Index',
      description: 'Direct ultraviolet radiation intensity for skin safety',
      category: ParameterCategory.thermal,
      icon: Icons.wb_sunny_rounded,
      defaultColor: Color(0xFFF59E0B),
    ),
    WeatherParameterDefinition(
      id: 'cloud_cover',
      title: 'Cloud Cover Percentage',
      shortTitle: 'Cloud Cover',
      description: 'Total sky fraction obscured by cloud layers',
      category: ParameterCategory.thermal,
      icon: Icons.cloud_rounded,
      defaultColor: Color(0xFF94A3B8),
    ),
    WeatherParameterDefinition(
      id: 'visibility',
      title: 'Atmospheric Visibility',
      shortTitle: 'Visibility',
      description: 'Horizontal line-of-sight clarity in kilometers',
      category: ParameterCategory.thermal,
      icon: Icons.visibility_rounded,
      defaultColor: Color(0xFF10B981),
    ),
    WeatherParameterDefinition(
      id: 'surface_pressure',
      title: 'Surface Pressure',
      shortTitle: 'Pressure',
      description: 'Barometric air pressure in hectopascals (hPa)',
      category: ParameterCategory.thermal,
      icon: Icons.speed_rounded,
      defaultColor: Color(0xFF38BDF8),
    ),

    // Wind & Rain
    WeatherParameterDefinition(
      id: 'wind_speed',
      title: 'Wind Speed',
      shortTitle: 'Wind',
      description: 'Sustained 10-meter wind velocity & compass heading',
      category: ParameterCategory.windPrecip,
      icon: Icons.air_rounded,
      defaultColor: Color(0xFF10B981),
    ),
    WeatherParameterDefinition(
      id: 'wind_gusts',
      title: 'Peak Wind Gusts',
      shortTitle: 'Wind Gusts',
      description: 'Peak transient wind speed bursts and gusts',
      category: ParameterCategory.windPrecip,
      icon: Icons.storm_rounded,
      defaultColor: Color(0xFF06B6D4),
    ),
    WeatherParameterDefinition(
      id: 'rain_probability',
      title: 'Rain Probability',
      shortTitle: 'Rain Chance',
      description: 'Statistical probability of precipitation in next 24h',
      category: ParameterCategory.windPrecip,
      icon: Icons.umbrella_rounded,
      defaultColor: Color(0xFF06B6D4),
    ),
    WeatherParameterDefinition(
      id: 'precipitation',
      title: 'Precipitation Rate',
      shortTitle: 'Precipitation',
      description: 'Hourly rainfall and precipitation rate in mm/h',
      category: ParameterCategory.windPrecip,
      icon: Icons.water_drop_rounded,
      defaultColor: Color(0xFF06B6D4),
    ),

    // Agro & Soil
    WeatherParameterDefinition(
      id: 'soil_moisture',
      title: 'Soil Moisture (0-7cm)',
      shortTitle: 'Soil Moisture',
      description: 'Volumetric soil moisture fraction in root zone',
      category: ParameterCategory.agroSoil,
      icon: Icons.grass_rounded,
      defaultColor: Color(0xFF10B981),
    ),
    WeatherParameterDefinition(
      id: 'evapotranspiration',
      title: 'Evapotranspiration (ET₀)',
      shortTitle: 'ET₀',
      description: 'Daily crop atmospheric water loss rate',
      category: ParameterCategory.agroSoil,
      icon: Icons.wb_twilight_rounded,
      defaultColor: Color(0xFF06B6D4),
    ),
    WeatherParameterDefinition(
      id: 'irrigation_advice',
      title: 'Irrigation & Soil Deficit',
      shortTitle: 'Irrigation',
      description: 'Smart watering schedule based on moisture & rain',
      category: ParameterCategory.agroSoil,
      icon: Icons.water_rounded,
      defaultColor: Color(0xFF10B981),
    ),
    WeatherParameterDefinition(
      id: 'mold_risk',
      title: 'Fungal & Mold Spore Risk',
      shortTitle: 'Mold Risk',
      description: 'Crop and indoor fungal spore growth susceptibility',
      category: ParameterCategory.agroSoil,
      icon: Icons.coronavirus_rounded,
      defaultColor: Color(0xFF10B981),
    ),

    // Lifestyle & AI
    WeatherParameterDefinition(
      id: 'workout_score',
      title: 'Workout Safety Score',
      shortTitle: 'Workout Score',
      description: 'AI athletic safety index based on heat, humidity & AQI',
      category: ParameterCategory.lifestyle,
      icon: Icons.fitness_center_rounded,
      defaultColor: Color(0xFF8B5CF6),
    ),
    WeatherParameterDefinition(
      id: 'best_run_window',
      title: 'Optimal Running Window',
      shortTitle: 'Best Run Time',
      description: 'Calculated daily time slot with coolest temps & clean air',
      category: ParameterCategory.lifestyle,
      icon: Icons.timer_rounded,
      defaultColor: Color(0xFF06B6D4),
    ),
    WeatherParameterDefinition(
      id: 'commute_hazard',
      title: 'Commute Hazard Rating',
      shortTitle: 'Commute Hazard',
      description: 'Road traction and driving safety risk rating (0-100)',
      category: ParameterCategory.lifestyle,
      icon: Icons.traffic_rounded,
      defaultColor: Color(0xFF10B981),
    ),
    WeatherParameterDefinition(
      id: 'wave_height',
      title: 'Coastal Wave Height',
      shortTitle: 'Waves',
      description: 'Marine swell and surf wave heights in meters',
      category: ParameterCategory.lifestyle,
      icon: Icons.waves_rounded,
      defaultColor: Color(0xFF06B6D4),
    ),
  ];
}
