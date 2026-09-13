import 'package:flutter/material.dart';

class WeatherAlert {
  final String id;
  final String title;
  final String severity; // "critical", "warning", "advisory"
  final String description;
  final String icon;
  final String timestamp;

  WeatherAlert({
    required this.id,
    required this.title,
    required this.severity,
    required this.description,
    required this.icon,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'severity': severity,
    'description': description,
    'icon': icon,
    'timestamp': timestamp,
  };

  factory WeatherAlert.fromJson(Map<String, dynamic> json) => WeatherAlert(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    severity: json['severity'] ?? 'warning',
    description: json['description'] ?? '',
    icon: json['icon'] ?? 'warning',
    timestamp: json['timestamp'] ?? 'Active Now',
  );
}

class HourlyForecast {
  final String time;
  final double temperature;
  final int precipitationProbability;
  final double precipitation;
  final int weatherCode;
  final String weatherCondition;
  final String icon;
  final bool isBestRunningHour;
  final bool isSafeCommuteHour;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.precipitation,
    required this.weatherCode,
    required this.weatherCondition,
    required this.icon,
    this.isBestRunningHour = false,
    this.isSafeCommuteHour = true,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) => HourlyForecast(
    time: json['time'] ?? '',
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
    precipitationProbability: json['precipitation_probability'] ?? 0,
    precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
    weatherCode: json['weather_code'] ?? 1,
    weatherCondition: json['weather_condition'] ?? 'Clear',
    icon: json['icon'] ?? 'partly_cloudy_day',
    isBestRunningHour: json['is_best_running_hour'] ?? false,
    isSafeCommuteHour: json['is_safe_commute_hour'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'time': time,
    'temperature': temperature,
    'precipitation_probability': precipitationProbability,
    'precipitation': precipitation,
    'weather_code': weatherCode,
    'weather_condition': weatherCondition,
    'icon': icon,
    'is_best_running_hour': isBestRunningHour,
    'is_safe_commute_hour': isSafeCommuteHour,
  };
}

class DailyForecast {
  final String date;
  final String dayName;
  final double temperatureMax;
  final double temperatureMin;
  final int weatherCode;
  final String weatherCondition;
  final double precipitationSum;
  final int precipitationProbabilityMax;
  final double uvIndexMax;
  final String sunrise;
  final String sunset;
  final String icon;

  DailyForecast({
    required this.date,
    required this.dayName,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.weatherCode,
    required this.weatherCondition,
    required this.precipitationSum,
    required this.precipitationProbabilityMax,
    required this.uvIndexMax,
    required this.sunrise,
    required this.sunset,
    required this.icon,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
    date: json['date'] ?? '',
    dayName: json['day_name'] ?? 'Today',
    temperatureMax: (json['temperature_max'] as num?)?.toDouble() ?? 0.0,
    temperatureMin: (json['temperature_min'] as num?)?.toDouble() ?? 0.0,
    weatherCode: json['weather_code'] ?? 1,
    weatherCondition: json['weather_condition'] ?? 'Clear',
    precipitationSum: (json['precipitation_sum'] as num?)?.toDouble() ?? 0.0,
    precipitationProbabilityMax: json['precipitation_probability_max'] ?? 0,
    uvIndexMax: (json['uv_index_max'] as num?)?.toDouble() ?? 5.0,
    sunrise: json['sunrise'] ?? '06:00',
    sunset: json['sunset'] ?? '18:30',
    icon: json['icon'] ?? 'sunny',
  );

  Map<String, dynamic> toJson() => {
    'date': date,
    'day_name': dayName,
    'temperature_max': temperatureMax,
    'temperature_min': temperatureMin,
    'weather_code': weatherCode,
    'weather_condition': weatherCondition,
    'precipitation_sum': precipitationSum,
    'precipitation_probability_max': precipitationProbabilityMax,
    'uv_index_max': uvIndexMax,
    'sunrise': sunrise,
    'sunset': sunset,
    'icon': icon,
  };
}

class AirQualityData {
  final int aqi;
  final double pm2_5;
  final double pm10;
  final double? carbonMonoxide;
  final double? nitrogenDioxide;
  final double? ozone;
  final double? dust;
  final double alderPollen;
  final double birchPollen;
  final double grassPollen;
  final double ragweedPollen;

  AirQualityData({
    required this.aqi,
    required this.pm2_5,
    required this.pm10,
    this.carbonMonoxide,
    this.nitrogenDioxide,
    this.ozone,
    this.dust,
    this.alderPollen = 0.0,
    this.birchPollen = 0.0,
    this.grassPollen = 8.0,
    this.ragweedPollen = 2.0,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) => AirQualityData(
    aqi: json['aqi'] ?? json['european_aqi'] ?? 42,
    pm2_5: (json['pm2_5'] as num?)?.toDouble() ?? 14.2,
    pm10: (json['pm10'] as num?)?.toDouble() ?? 35.0,
    carbonMonoxide: (json['carbon_monoxide'] as num?)?.toDouble(),
    nitrogenDioxide: (json['nitrogen_dioxide'] as num?)?.toDouble(),
    ozone: (json['ozone'] as num?)?.toDouble(),
    dust: (json['dust'] as num?)?.toDouble(),
    alderPollen: (json['alder_pollen'] as num?)?.toDouble() ?? 0.0,
    birchPollen: (json['birch_pollen'] as num?)?.toDouble() ?? 0.0,
    grassPollen: (json['grass_pollen'] as num?)?.toDouble() ?? 8.0,
    ragweedPollen: (json['ragweed_pollen'] as num?)?.toDouble() ?? 2.0,
  );

  Map<String, dynamic> toJson() => {
    'aqi': aqi,
    'pm2_5': pm2_5,
    'pm10': pm10,
    'carbon_monoxide': carbonMonoxide,
    'nitrogen_dioxide': nitrogenDioxide,
    'ozone': ozone,
    'dust': dust,
    'alder_pollen': alderPollen,
    'birch_pollen': birchPollen,
    'grass_pollen': grassPollen,
    'ragweed_pollen': ragweedPollen,
  };
}

class MarineData {
  final double waveHeight;
  final double wavePeriod;
  final double waveDirection;
  final double windWaveHeight;
  final double swellWaveHeight;

  MarineData({
    this.waveHeight = 1.2,
    this.wavePeriod = 6.5,
    this.waveDirection = 210.0,
    this.windWaveHeight = 0.8,
    this.swellWaveHeight = 1.0,
  });

  factory MarineData.fromJson(Map<String, dynamic> json) => MarineData(
    waveHeight: (json['wave_height'] as num?)?.toDouble() ?? 1.2,
    wavePeriod: (json['wave_period'] as num?)?.toDouble() ?? 6.5,
    waveDirection: (json['wave_direction'] as num?)?.toDouble() ?? 210.0,
    windWaveHeight: (json['wind_wave_height'] as num?)?.toDouble() ?? 0.8,
    swellWaveHeight: (json['swell_wave_height'] as num?)?.toDouble() ?? 1.0,
  );

  Map<String, dynamic> toJson() => {
    'wave_height': waveHeight,
    'wave_period': wavePeriod,
    'wave_direction': waveDirection,
    'wind_wave_height': windWaveHeight,
    'swell_wave_height': swellWaveHeight,
  };
}

class PersonaSlotData {
  final int slotIndex;
  final String title;
  final String value;
  final String subtitle;
  final String status;
  final IconData icon;
  final Color color;
  final double? progressPercentage;

  PersonaSlotData({
    required this.slotIndex,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.status,
    required this.icon,
    required this.color,
    this.progressPercentage,
  });
}

class WeatherTelemetry {
  final double latitude;
  final double longitude;
  final String cityName;
  final String timezone;
  final double currentTemperature;
  final double apparentTemperature;
  final int weatherCode;
  final String weatherCondition;
  final int humidity;
  final double windSpeed;
  final double windDirection;
  final String windDirectionCardinal;
  final double windGusts;
  final double surfacePressure;
  final double uvIndex;
  final int cloudCover;
  final double precipitation;
  final double rain;
  final double soilMoisture;
  final double evapotranspiration;
  final double visibilityMeters;

  WeatherTelemetry({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.timezone,
    required this.currentTemperature,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.weatherCondition,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.windDirectionCardinal,
    required this.windGusts,
    required this.surfacePressure,
    required this.uvIndex,
    required this.cloudCover,
    required this.precipitation,
    required this.rain,
    this.soilMoisture = 0.24,
    this.evapotranspiration = 3.2,
    this.visibilityMeters = 10000.0,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'cityName': cityName,
    'timezone': timezone,
    'currentTemperature': currentTemperature,
    'apparentTemperature': apparentTemperature,
    'weatherCode': weatherCode,
    'weatherCondition': weatherCondition,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'windDirection': windDirection,
    'windDirectionCardinal': windDirectionCardinal,
    'windGusts': windGusts,
    'surfacePressure': surfacePressure,
    'uvIndex': uvIndex,
    'cloudCover': cloudCover,
    'precipitation': precipitation,
    'rain': rain,
    'soilMoisture': soilMoisture,
    'evapotranspiration': evapotranspiration,
    'visibilityMeters': visibilityMeters,
  };

  factory WeatherTelemetry.fromJson(Map<String, dynamic> json) => WeatherTelemetry(
    latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
    cityName: json['cityName'] ?? json['city_name'] ?? 'Selected Location',
    timezone: json['timezone'] ?? 'auto',
    currentTemperature: (json['currentTemperature'] ?? json['current_temperature'] as num?)?.toDouble() ?? 28.0,
    apparentTemperature: (json['apparentTemperature'] ?? json['apparent_temperature'] as num?)?.toDouble() ?? 30.0,
    weatherCode: json['weatherCode'] ?? json['weather_code'] ?? 1,
    weatherCondition: json['weatherCondition'] ?? json['weather_condition'] ?? 'Mainly Clear',
    humidity: json['humidity'] ?? 65,
    windSpeed: (json['windSpeed'] ?? json['wind_speed'] as num?)?.toDouble() ?? 12.0,
    windDirection: (json['windDirection'] ?? json['wind_direction'] as num?)?.toDouble() ?? 180.0,
    windDirectionCardinal: json['windDirectionCardinal'] ?? json['wind_direction_cardinal'] ?? 'S',
    windGusts: (json['windGusts'] ?? json['wind_gusts'] as num?)?.toDouble() ?? 15.0,
    surfacePressure: (json['surfacePressure'] ?? json['surface_pressure'] as num?)?.toDouble() ?? 1012.0,
    uvIndex: (json['uvIndex'] ?? json['uv_index'] as num?)?.toDouble() ?? 5.0,
    cloudCover: json['cloudCover'] ?? json['cloud_cover'] ?? 20,
    precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
    rain: (json['rain'] as num?)?.toDouble() ?? 0.0,
    soilMoisture: (json['soilMoisture'] ?? json['soil_moisture'] as num?)?.toDouble() ?? 0.24,
    evapotranspiration: (json['evapotranspiration'] as num?)?.toDouble() ?? 3.2,
    visibilityMeters: (json['visibilityMeters'] ?? json['visibility_meters'] as num?)?.toDouble() ?? 10000.0,
  );
}
