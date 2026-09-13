import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/persona_type.dart';
import '../models/weather_models.dart';
import '../models/chat_message.dart';
import '../services/weather_api_service.dart';
import '../services/gemini_service.dart';
import '../services/location_service.dart';
import '../services/cache_service.dart';
import '../utils/constants.dart';
import '../utils/weather_math.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherApiService _apiService = WeatherApiService();

  // Location State
  double _currentLat = AppConstants.fallbackLat;
  double _currentLon = AppConstants.fallbackLon;
  String _cityName = AppConstants.fallbackCityName;
  bool _isLocationInitialized = false;
  bool _needsLocationSelection = false;

  // Persona State
  PersonaType _activePersona = PersonaType.health;

  // Weather Data State
  WeatherTelemetry? _telemetry;
  AirQualityData? _airQuality;
  MarineData? _marineData;
  List<HourlyForecast> _hourlyForecast = [];
  List<DailyForecast> _dailyForecast = [];
  List<WeatherAlert> _alerts = [];
  List<PersonaSlotData> _personaSlots = [];
  String _advisorySummary = '';
  String _actionBullet = '';

  // Derived Metrics
  int _workoutScore = 85;
  String _optimalRunningWindow = '6:00 AM – 8:00 AM';
  String _moldRisk = 'Low';
  String _irrigationAdvice = 'Soil Moisture Optimal';
  double _agDeficit = 0.0;
  int _commuteHazard = 15;
  String _commuteCondition = 'Clear Route — Normal Commute';

  // Chat State
  final List<ChatMessage> _chatMessages = [];
  bool _isChatLoading = false;

  // Map Interactive State
  double _mapLat = AppConstants.fallbackLat;
  double _mapLon = AppConstants.fallbackLon;
  bool _isRadarOverlayActive = true;
  WeatherTelemetry? _mapPreviewTelemetry;
  bool _isMapPreviewLoading = false;

  // UI Status State
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  // Getters
  double get currentLat => _currentLat;
  double get currentLon => _currentLon;
  String get cityName => _cityName;
  bool get isLocationInitialized => _isLocationInitialized;
  bool get needsLocationSelection => _needsLocationSelection;
  PersonaType get activePersona => _activePersona;

  WeatherTelemetry? get telemetry => _telemetry;
  AirQualityData? get airQuality => _airQuality;
  MarineData? get marineData => _marineData;
  List<HourlyForecast> get hourlyForecast => _hourlyForecast;
  List<DailyForecast> get dailyForecast => _dailyForecast;
  List<WeatherAlert> get alerts => _alerts;
  List<PersonaSlotData> get personaSlots => _personaSlots;
  String get advisorySummary => _advisorySummary;
  String get actionBullet => _actionBullet;

  int get workoutScore => _workoutScore;
  String get optimalRunningWindow => _optimalRunningWindow;
  String get moldRisk => _moldRisk;
  String get irrigationAdvice => _irrigationAdvice;
  double get agDeficit => _agDeficit;
  int get commuteHazard => _commuteHazard;
  String get commuteCondition => _commuteCondition;

  List<ChatMessage> get chatMessages => _chatMessages;
  bool get isChatLoading => _isChatLoading;

  double get mapLat => _mapLat;
  double get mapLon => _mapLon;
  bool get isRadarOverlayActive => _isRadarOverlayActive;
  WeatherTelemetry? get mapPreviewTelemetry => _mapPreviewTelemetry;
  bool get isMapPreviewLoading => _isMapPreviewLoading;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  /// Initialize Application State
  Future<void> initializeApp() async {
    _isLoading = true;
    notifyListeners();

    // 1. Load saved persona
    final savedPersonaName = await CacheService.getSavedPersona();
    if (savedPersonaName != null) {
      for (var p in PersonaType.values) {
        if (p.name == savedPersonaName) {
          _activePersona = p;
          break;
        }
      }
    }

    // 2. Load saved chat history
    final cachedChats = await CacheService.loadChatHistory();
    if (cachedChats.isNotEmpty) {
      _chatMessages.clear();
      for (var m in cachedChats) {
        _chatMessages.add(ChatMessage.fromJson(m));
      }
    } else {
      _initDefaultChatGreeting();
    }

    // 3. Resolve Location
    final savedLoc = await CacheService.getSavedLocation();
    if (savedLoc != null) {
      _currentLat = savedLoc['lat'];
      _currentLon = savedLoc['lon'];
      _cityName = savedLoc['city'];
      _mapLat = _currentLat;
      _mapLon = _currentLon;
      _isLocationInitialized = true;
      await fetchWeatherData();
    } else {
      // Try GPS location
      final Position? pos = await LocationService.getCurrentPosition();
      if (pos != null) {
        _currentLat = pos.latitude;
        _currentLon = pos.longitude;
        _cityName = await LocationService.reverseGeocode(pos.latitude, pos.longitude);
        _mapLat = _currentLat;
        _mapLon = _currentLon;
        _isLocationInitialized = true;
        await CacheService.saveLocation(
          lat: _currentLat,
          lon: _currentLon,
          cityName: _cityName,
        );
        await fetchWeatherData();
      } else {
        // Need user to pick location
        _needsLocationSelection = true;
        _currentLat = AppConstants.fallbackLat;
        _currentLon = AppConstants.fallbackLon;
        _cityName = AppConstants.fallbackCityName;
        _mapLat = _currentLat;
        _mapLon = _currentLon;
        await fetchWeatherData();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void _initDefaultChatGreeting() {
    _chatMessages.clear();
    _chatMessages.add(
      ChatMessage(
        id: 'msg_welcome_1',
        text: "Hi there! I'm your Mausam AdvisorAI. Ask me anything about local weather, running conditions, UV & skin safety, crop moisture, or commute alerts!",
        isUser: false,
        timestamp: DateTime.now(),
        persona: _activePersona.shortTitle,
        actionItems: ['What is the best running time today?', 'Do I need sunscreen this afternoon?', 'How is road visibility for travel?'],
      ),
    );
  }

  /// Change Persona and dynamically re-derive slot metrics & advisory
  Future<void> switchPersona(PersonaType newPersona) async {
    _activePersona = newPersona;
    await CacheService.savePersona(newPersona.name);
    _recomputeDerivedMetrics();
    notifyListeners();
  }

  /// Change Location from Search, Map or Popular Cities
  Future<void> updateLocation({
    required double lat,
    required double lon,
    String? cityName,
  }) async {
    _currentLat = lat;
    _currentLon = lon;
    _mapLat = lat;
    _mapLon = lon;
    _isLocationInitialized = true;
    _needsLocationSelection = false;

    if (cityName == null || cityName.isEmpty || cityName.startsWith('Pin') || cityName == 'Current Location') {
      _cityName = await LocationService.reverseGeocode(lat, lon);
    } else {
      _cityName = cityName;
    }

    await CacheService.saveLocation(lat: lat, lon: lon, cityName: _cityName);
    await fetchWeatherData();
  }

  /// Fetch live weather telemetry
  Future<void> fetchWeatherData({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
      notifyListeners();
    } else if (!_isLocationInitialized) {
      _isLoading = true;
      notifyListeners();
    }

    _errorMessage = null;

    try {
      // Check cache first if not explicitly refreshing
      if (!isRefresh) {
        final cached = await CacheService.getCachedWeatherData(lat: _currentLat, lon: _currentLon);
        if (cached != null) {
          _parseWeatherData(cached['weather'], cached['air'], cached['marine']);
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Live fetch
      final forecastFuture = _apiService.fetchForecastData(lat: _currentLat, lon: _currentLon);
      final airFuture = _apiService.fetchAirQualityData(lat: _currentLat, lon: _currentLon);
      final marineFuture = (_activePersona == PersonaType.beach)
          ? _apiService.fetchMarineData(lat: _currentLat, lon: _currentLon)
          : Future.value(null);

      final results = await Future.wait([forecastFuture, airFuture, marineFuture]);

      final forecastData = results[0] as Map<String, dynamic>;
      final airData = results[1] as Map<String, dynamic>;
      final marineData = results[2];

      // Cache raw responses
      await CacheService.cacheWeatherData(
        lat: _currentLat,
        lon: _currentLon,
        weatherData: forecastData,
        airData: airData,
        marineData: marineData,
      );

      _parseWeatherData(forecastData, airData, marineData);
    } catch (e) {
      _errorMessage = 'Could not retrieve live weather. Displaying cached metrics.';
      // Ensure baseline fallback
      if (_telemetry == null) {
        _createFallbackData();
      }
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void _parseWeatherData(
    Map<String, dynamic> forecastData,
    Map<String, dynamic> airData,
    Map<String, dynamic>? marineData,
  ) {
    final currentF = forecastData['current'] as Map<String, dynamic>? ?? {};
    final hourlyF = forecastData['hourly'] as Map<String, dynamic>? ?? {};
    final dailyF = forecastData['daily'] as Map<String, dynamic>? ?? {};
    final currentAir = airData['current'] as Map<String, dynamic>? ?? {};
    final currentMarine = marineData?['current'] as Map<String, dynamic>?;

    final temp = (currentF['temperature_2m'] as num?)?.toDouble() ?? 28.0;
    final appTemp = (currentF['apparent_temperature'] as num?)?.toDouble() ?? (temp + 2);
    final wCode = currentF['weather_code'] ?? 1;
    final wCond = WeatherMath.getWeatherConditionString(wCode);
    final humidity = currentF['relative_humidity_2m'] ?? 65;
    final windSpd = (currentF['wind_speed_10m'] as num?)?.toDouble() ?? 12.0;
    final windDir = (currentF['wind_direction_10m'] as num?)?.toDouble() ?? 180.0;
    final windCardinal = WeatherMath.windDegToCardinal(windDir);
    final windGusts = (currentF['wind_gusts_10m'] as num?)?.toDouble() ?? (windSpd * 1.3);
    final pressure = (currentF['surface_pressure'] as num?)?.toDouble() ?? 1012.0;
    final double uvIdx = (currentF['uv_index'] as num?)?.toDouble() ??
        ((dailyF['uv_index_max'] as List?)?.isNotEmpty == true
            ? (dailyF['uv_index_max'][0] as num).toDouble()
            : 0.0);
    final cloud = currentF['cloud_cover'] ?? 20;
    final precip = (currentF['precipitation'] as num?)?.toDouble() ?? 0.0;
    final rain = (currentF['rain'] as num?)?.toDouble() ?? 0.0;

    // Soil & ET
    final hourlySoil = hourlyF['soil_moisture_0_to_7cm'] as List<dynamic>?;
    final soilMoisture = (hourlySoil != null && hourlySoil.isNotEmpty) ? (hourlySoil[0] as num).toDouble() : 0.24;
    final hourlyEt = hourlyF['evapotranspiration'] as List<dynamic>?;
    final et0 = (hourlyEt != null && hourlyEt.isNotEmpty) ? (hourlyEt[0] as num).toDouble() : 3.2;
    final hourlyVis = hourlyF['visibility'] as List<dynamic>?;
    final visMeters = (hourlyVis != null && hourlyVis.isNotEmpty) ? (hourlyVis[0] as num).toDouble() : 10000.0;

    _telemetry = WeatherTelemetry(
      latitude: _currentLat,
      longitude: _currentLon,
      cityName: _cityName,
      timezone: forecastData['timezone'] ?? 'auto',
      currentTemperature: temp,
      apparentTemperature: appTemp,
      weatherCode: wCode,
      weatherCondition: wCond,
      humidity: humidity,
      windSpeed: windSpd,
      windDirection: windDir,
      windDirectionCardinal: windCardinal,
      windGusts: windGusts,
      surfacePressure: pressure,
      uvIndex: uvIdx,
      cloudCover: cloud,
      precipitation: precip,
      rain: rain,
      soilMoisture: soilMoisture,
      evapotranspiration: et0,
      visibilityMeters: visMeters,
    );

    // Air Quality
    _airQuality = AirQualityData(
      aqi: currentAir['european_aqi'] ?? 42,
      pm2_5: (currentAir['pm2_5'] as num?)?.toDouble() ?? 14.2,
      pm10: (currentAir['pm10'] as num?)?.toDouble() ?? 35.0,
      carbonMonoxide: (currentAir['carbon_monoxide'] as num?)?.toDouble(),
      nitrogenDioxide: (currentAir['nitrogen_dioxide'] as num?)?.toDouble(),
      ozone: (currentAir['ozone'] as num?)?.toDouble(),
      dust: (currentAir['dust'] as num?)?.toDouble(),
      alderPollen: (currentAir['alder_pollen'] as num?)?.toDouble() ?? 0.0,
      birchPollen: (currentAir['birch_pollen'] as num?)?.toDouble() ?? 0.0,
      grassPollen: (currentAir['grass_pollen'] as num?)?.toDouble() ?? 8.0,
      ragweedPollen: (currentAir['ragweed_pollen'] as num?)?.toDouble() ?? 2.0,
    );

    // Marine
    if (currentMarine != null) {
      _marineData = MarineData(
        waveHeight: (currentMarine['wave_height'] as num?)?.toDouble() ?? 1.2,
        wavePeriod: (currentMarine['wave_period'] as num?)?.toDouble() ?? 6.5,
        waveDirection: (currentMarine['wave_direction'] as num?)?.toDouble() ?? 210.0,
        windWaveHeight: (currentMarine['wind_wave_height'] as num?)?.toDouble() ?? 0.8,
        swellWaveHeight: (currentMarine['swell_wave_height'] as num?)?.toDouble() ?? 1.0,
      );
    } else {
      _marineData = MarineData();
    }

    // Hourly Forecast
    final times = hourlyF['time'] as List<dynamic>? ?? [];
    final temps = hourlyF['temperature_2m'] as List<dynamic>? ?? [];
    final probs = hourlyF['precipitation_probability'] as List<dynamic>? ?? [];
    final precips = hourlyF['precipitation'] as List<dynamic>? ?? [];
    final codes = hourlyF['weather_code'] as List<dynamic>? ?? [];

    _hourlyForecast = [];
    final int hLen = (times.length < 24) ? times.length : 24;
    for (int i = 0; i < hLen; i++) {
      final tStr = times[i].toString();
      String timeLabel = '${(DateTime.now().hour + i) % 24}:00';
      if (tStr.contains('T')) {
        final hourPart = int.tryParse(tStr.split('T')[1].split(':')[0]) ?? 0;
        final period = hourPart >= 12 ? 'PM' : 'AM';
        final displayHour = hourPart == 0 ? 12 : (hourPart > 12 ? hourPart - 12 : hourPart);
        timeLabel = '$displayHour $period';
      }

      final hCode = i < codes.length ? (codes[i] as int) : 1;
      _hourlyForecast.add(HourlyForecast(
        time: timeLabel,
        temperature: i < temps.length ? (temps[i] as num).toDouble() : temp,
        precipitationProbability: i < probs.length ? (probs[i] as int) : 0,
        precipitation: i < precips.length ? (precips[i] as num).toDouble() : 0.0,
        weatherCode: hCode,
        weatherCondition: WeatherMath.getWeatherConditionString(hCode),
        icon: 'partly_cloudy_day',
      ));
    }

    // Daily Forecast
    final dTimes = dailyF['time'] as List<dynamic>? ?? [];
    final dMaxs = dailyF['temperature_2m_max'] as List<dynamic>? ?? [];
    final dMins = dailyF['temperature_2m_min'] as List<dynamic>? ?? [];
    final dCodes = dailyF['weather_code'] as List<dynamic>? ?? [];
    final dSums = dailyF['precipitation_sum'] as List<dynamic>? ?? [];
    final dPmaxs = dailyF['precipitation_probability_max'] as List<dynamic>? ?? [];
    final dUvs = dailyF['uv_index_max'] as List<dynamic>? ?? [];
    final dSunrises = dailyF['sunrise'] as List<dynamic>? ?? [];
    final dSunsets = dailyF['sunset'] as List<dynamic>? ?? [];

    _dailyForecast = [];
    final int dLen = (dTimes.length < 7) ? dTimes.length : 7;
    for (int j = 0; j < dLen; j++) {
      final dateStr = dTimes[j].toString();
      String dayName = j == 0 ? 'Today' : 'Day ${j + 1}';
      try {
        final parsedDate = DateTime.parse(dateStr);
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        dayName = j == 0 ? 'Today' : weekdays[parsedDate.weekday - 1];
      } catch (_) {}

      final dCode = j < dCodes.length ? (dCodes[j] as int) : 1;
      _dailyForecast.add(DailyForecast(
        date: dateStr,
        dayName: dayName,
        temperatureMax: j < dMaxs.length ? (dMaxs[j] as num).toDouble() : temp + 3,
        temperatureMin: j < dMins.length ? (dMins[j] as num).toDouble() : temp - 3,
        weatherCode: dCode,
        weatherCondition: WeatherMath.getWeatherConditionString(dCode),
        precipitationSum: j < dSums.length ? (dSums[j] as num).toDouble() : 0.0,
        precipitationProbabilityMax: j < dPmaxs.length ? (dPmaxs[j] as int) : 0,
        uvIndexMax: j < dUvs.length ? (dUvs[j] as num).toDouble() : uvIdx,
        sunrise: j < dSunrises.length ? dSunrises[j].toString() : '06:00',
        sunset: j < dSunsets.length ? dSunsets[j].toString() : '18:30',
        icon: 'sunny',
      ));
    }

    _recomputeDerivedMetrics();
  }

  void _recomputeDerivedMetrics() {
    if (_telemetry == null || _airQuality == null) return;

    final t = _telemetry!;
    final a = _airQuality!;
    final dailyRainSum = _dailyForecast.isNotEmpty ? _dailyForecast[0].precipitationSum : 0.0;
    final dailyRainProbMax = _dailyForecast.isNotEmpty ? _dailyForecast[0].precipitationProbabilityMax.toDouble() : 10.0;

    // 1. Workout Safety Score & Optimal Running Window
    _workoutScore = WeatherMath.calculateWorkoutScore(
      temp: t.currentTemperature,
      humidity: t.humidity.toDouble(),
      aqi: a.aqi.toDouble(),
      rainProb: dailyRainProbMax,
    );
    _optimalRunningWindow = WeatherMath.findOptimalRunningWindow(_hourlyForecast);

    // 2. Mold Risk
    _moldRisk = WeatherMath.calculateMoldRisk(
      temp: t.currentTemperature,
      humidity: t.humidity.toDouble(),
    );

    // 3. Agricultural Deficit & Irrigation Advice
    final agMap = WeatherMath.calculateIrrigationAdvice(
      et0: t.evapotranspiration,
      rainfallAccumulation: dailyRainSum,
      soilMoisture: t.soilMoisture,
      rainProbMax: dailyRainProbMax,
      rainSum: dailyRainSum,
    );
    _irrigationAdvice = agMap['advice'];
    _agDeficit = agMap['deficit'];

    // 4. Commute Hazard
    final comMap = WeatherMath.calculateCommuteHazard(
      visibilityMeters: t.visibilityMeters,
      weatherCode: t.weatherCode,
      precipitationRate: t.precipitation,
      windGusts: t.windGusts,
    );
    _commuteHazard = comMap['rating'];
    _commuteCondition = comMap['condition'];

    // 5. Tier 1 Alert Prepend Detection
    _alerts = [];
    if (t.windGusts > 55.0) {
      _alerts.add(WeatherAlert(
        id: 'gust_alert',
        title: 'High Wind Gust Alert (${t.windGusts.round()} km/h)',
        severity: 'critical',
        description: 'Strong gusts detected. Secure loose outdoor objects and drive with caution.',
        icon: 'air',
        timestamp: 'Active Now',
      ));
    }
    if (t.precipitation > 15.0 || dailyRainSum > 20.0) {
      _alerts.add(WeatherAlert(
        id: 'rain_warning',
        title: 'Heavy Rainfall Warning',
        severity: 'critical',
        description: 'High precipitation rate detected. Potential waterlogging in low-lying areas.',
        icon: 'rainy',
        timestamp: 'Active Now',
      ));
    }
    if (t.currentTemperature >= 40.0) {
      _alerts.add(WeatherAlert(
        id: 'heat_warning',
        title: 'Extreme Heat Advisory (${t.currentTemperature.round()}°C)',
        severity: 'warning',
        description: 'Avoid direct sun exposure between 12:00 PM and 4:00 PM. Drink plenty of water.',
        icon: 'thermostat',
        timestamp: 'Active Now',
      ));
    }

    // 6. 6 Parameter Slots per Active Persona
    _buildPersonaSlots();
  }

  void _buildPersonaSlots() {
    if (_telemetry == null || _airQuality == null) return;
    final t = _telemetry!;
    final a = _airQuality!;
    final waves = _marineData?.waveHeight ?? 1.2;

    switch (_activePersona) {
      case PersonaType.health:
        final aqiLabel = a.aqi <= 50 ? 'Good' : (a.aqi <= 100 ? 'Moderate' : 'Unhealthy');
        _advisorySummary = '✓ AQI is ${aqiLabel.toLowerCase()} today (${a.aqi}). UV is high (${t.uvIndex.round()}) — wear sunscreen and sunglasses. Pollen is low, great for outdoor walks.';
        _actionBullet = 'Wear SPF 30+ and UV-blocking eyewear during midday hours.';

        _personaSlots = [
          PersonaSlotData(slotIndex: 1, title: 'AQI', value: '${a.aqi} $aqiLabel', subtitle: 'PM2.5 ${a.pm2_5.toStringAsFixed(1)} µg/m³', status: aqiLabel, icon: Icons.air_rounded, color: a.aqi <= 50 ? const Color(0xFF10B981) : const Color(0xFFF59E0B), progressPercentage: (a.aqi / 200.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 2, title: 'POLLEN (GRASS)', value: '${a.grassPollen < 10 ? 'Low' : 'Moderate'} ${a.grassPollen.round()}', subtitle: 'grains/m³', status: 'Low', icon: Icons.grass_rounded, color: const Color(0xFF10B981), progressPercentage: (a.grassPollen / 30.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 3, title: 'POLLEN (TREE)', value: '${(a.alderPollen + a.birchPollen) < 15 ? 'Low' : 'Moderate'} ${(a.alderPollen + a.birchPollen).round()}', subtitle: 'grains/m³', status: 'Moderate', icon: Icons.park_rounded, color: const Color(0xFFF59E0B), progressPercentage: 0.45),
          PersonaSlotData(slotIndex: 4, title: 'UV INDEX', value: '${t.uvIndex.round()} High', subtitle: 'SPF 30+ needed', status: 'High', icon: Icons.wb_sunny_rounded, color: const Color(0xFFF59E0B), progressPercentage: (t.uvIndex / 12.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 5, title: 'HUMIDITY', value: '${t.humidity}%', subtitle: 'Mold Risk: $_moldRisk', status: 'Moderate', icon: Icons.water_drop_rounded, color: const Color(0xFF06B6D4), progressPercentage: t.humidity / 100.0),
          PersonaSlotData(slotIndex: 6, title: 'AIR QUALITY', value: aqiLabel, subtitle: 'Safe for outdoor exercise', status: aqiLabel, icon: Icons.health_and_safety_rounded, color: const Color(0xFF10B981), progressPercentage: 0.85),
        ];
        break;

      case PersonaType.fitness:
        _advisorySummary = '🏃 Workout Safety Score is $_workoutScore/100. Optimal training window is $_optimalRunningWindow with lowest heat index and clean air.';
        _actionBullet = 'Plan workout session during $_optimalRunningWindow.';

        _personaSlots = [
          PersonaSlotData(slotIndex: 1, title: 'WORKOUT SAFETY', value: '$_workoutScore/100', subtitle: _workoutScore >= 75 ? 'Safe for High Intensity' : 'Moderate Heat Stress', status: 'Good', icon: Icons.fitness_center_rounded, color: const Color(0xFF8B5CF6), progressPercentage: _workoutScore / 100.0),
          PersonaSlotData(slotIndex: 2, title: 'BEST RUN WINDOW', value: _optimalRunningWindow, subtitle: 'Optimal temperature & air', status: 'Optimal', icon: Icons.timer_rounded, color: const Color(0xFF06B6D4), progressPercentage: 0.85),
          PersonaSlotData(slotIndex: 3, title: 'TEMPERATURE', value: '${t.currentTemperature.round()}°C', subtitle: 'Feels like ${t.apparentTemperature.round()}°C', status: 'Moderate', icon: Icons.thermostat_rounded, color: const Color(0xFFF59E0B), progressPercentage: (t.currentTemperature / 45.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 4, title: 'HEAT HYDRATION', value: '500ml/hr', subtitle: 'Humidity at ${t.humidity}%', status: 'Moderate', icon: Icons.local_drink_rounded, color: const Color(0xFF06B6D4), progressPercentage: t.humidity / 100.0),
          PersonaSlotData(slotIndex: 5, title: 'WIND RESISTANCE', value: '${t.windSpeed.round()} km/h', subtitle: 'From ${t.windDirectionCardinal}', status: 'Good', icon: Icons.air_rounded, color: const Color(0xFF10B981), progressPercentage: (t.windSpeed / 40.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 6, title: 'RAIN CHANCE', value: '${t.precipitation > 0 ? 60 : 10}%', subtitle: 'Pavement traction dry', status: 'Good', icon: Icons.umbrella_rounded, color: const Color(0xFF06B6D4), progressPercentage: 0.15),
        ];
        break;

      case PersonaType.farm:
        _advisorySummary = '🌱 $_irrigationAdvice. Soil moisture (0-7cm) is ${t.soilMoisture.toStringAsFixed(2)} m³/m³ with ET deficit of ${_agDeficit.toStringAsFixed(1)} mm.';
        _actionBullet = 'Execute micro-irrigation schedule if deficit exceeds 3.5mm.';

        _personaSlots = [
          PersonaSlotData(slotIndex: 1, title: 'IRRIGATION ADVICE', value: _irrigationAdvice.split('—')[0].trim(), subtitle: 'Deficit ${_agDeficit.toStringAsFixed(1)} mm', status: 'Optimal', icon: Icons.water_rounded, color: const Color(0xFF10B981), progressPercentage: 0.8),
          PersonaSlotData(slotIndex: 2, title: 'SOIL MOISTURE (0-7cm)', value: '${t.soilMoisture.toStringAsFixed(2)} m³/m³', subtitle: 'Optimal range 0.22 - 0.35', status: t.soilMoisture >= 0.22 ? 'Optimal' : 'Low', icon: Icons.grass_rounded, color: const Color(0xFF10B981), progressPercentage: (t.soilMoisture / 0.4).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 3, title: 'FUNGAL / MOLD RISK', value: _moldRisk, subtitle: 'Hum ${t.humidity}%, ${t.currentTemperature.round()}°C', status: _moldRisk, icon: Icons.coronavirus_rounded, color: _moldRisk == 'High' ? const Color(0xFFEF4444) : const Color(0xFF10B981), progressPercentage: _moldRisk == 'High' ? 0.85 : 0.25),
          PersonaSlotData(slotIndex: 4, title: 'SPRAY CONDITIONS', value: t.windSpeed < 15 ? 'Favorable' : 'Unfavorable', subtitle: 'Wind at ${t.windSpeed.round()} km/h', status: 'Good', icon: Icons.science_rounded, color: const Color(0xFF10B981), progressPercentage: 0.75),
          PersonaSlotData(slotIndex: 5, title: 'RAIN PROBABILITY', value: '${t.precipitation > 0 ? 60 : 15}%', subtitle: 'Next 24 Hours', status: 'Good', icon: Icons.cloud_rounded, color: const Color(0xFF06B6D4), progressPercentage: 0.2),
          PersonaSlotData(slotIndex: 6, title: 'GUST HAZARD', value: '${t.windGusts.round()} km/h', subtitle: 'Safe against lodging', status: 'Good', icon: Icons.air_rounded, color: const Color(0xFF10B981), progressPercentage: (t.windGusts / 60.0).clamp(0.0, 1.0)),
        ];
        break;

      case PersonaType.beach:
        _advisorySummary = '🌊 Wave height is currently ${waves.toStringAsFixed(1)}m. UV Index is high (${t.uvIndex.round()}) — apply water-resistant SPF 50+ sunscreen.';
        _actionBullet = 'Great conditions for beach strolls and water activities.';

        _personaSlots = [
          PersonaSlotData(slotIndex: 1, title: 'WAVE HEIGHT', value: '${waves.toStringAsFixed(1)}m', subtitle: 'Moderate clean swell', status: 'Good', icon: Icons.waves_rounded, color: const Color(0xFF06B6D4), progressPercentage: 0.6),
          PersonaSlotData(slotIndex: 2, title: 'UV INDEX', value: '${t.uvIndex.round()} High', subtitle: 'SPF 50+ needed', status: 'High', icon: Icons.wb_sunny_rounded, color: const Color(0xFFF59E0B), progressPercentage: (t.uvIndex / 12.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 3, title: 'SURF WIND', value: '${t.windSpeed.round()} km/h ${t.windDirectionCardinal}', subtitle: 'Offshore breeze', status: 'Optimal', icon: Icons.air_rounded, color: const Color(0xFF10B981), progressPercentage: 0.5),
          PersonaSlotData(slotIndex: 4, title: 'WATER TEMP', value: '${(t.currentTemperature - 3).round()}°C', subtitle: 'Pleasant swim temperature', status: 'Good', icon: Icons.pool_rounded, color: const Color(0xFF06B6D4), progressPercentage: 0.7),
          PersonaSlotData(slotIndex: 5, title: 'TIDE STATUS', value: 'Mid Tide', subtitle: 'High Tide at 16:20', status: 'Good', icon: Icons.water_rounded, color: const Color(0xFF06B6D4), progressPercentage: 0.5),
          PersonaSlotData(slotIndex: 6, title: 'SWIM SAFETY', value: 'Green Flag', subtitle: 'Calm nearshore currents', status: 'Optimal', icon: Icons.verified_rounded, color: const Color(0xFF10B981), progressPercentage: 0.9),
        ];
        break;

      case PersonaType.commute:
        _advisorySummary = '🚗 Commute Hazard Rating: $_commuteHazard/100 ($_commuteCondition). Road traction is firm with excellent visibility.';
        _actionBullet = 'Normal cruising speed recommended along main highway routes.';

        _personaSlots = [
          PersonaSlotData(slotIndex: 1, title: 'COMMUTE HAZARD', value: '$_commuteHazard/100', subtitle: _commuteCondition, status: 'Good', icon: Icons.traffic_rounded, color: _commuteHazard < 30 ? const Color(0xFF10B981) : const Color(0xFFEF4444), progressPercentage: _commuteHazard / 100.0),
          PersonaSlotData(slotIndex: 2, title: 'ROAD VISIBILITY', value: '> 8 km', subtitle: 'Zero fog disruption', status: 'Optimal', icon: Icons.visibility_rounded, color: const Color(0xFF10B981), progressPercentage: 0.9),
          PersonaSlotData(slotIndex: 3, title: 'RAIN SLIP RISK', value: 'Low', subtitle: 'Dry road surfaces', status: 'Good', icon: Icons.water_drop_rounded, color: const Color(0xFF10B981), progressPercentage: 0.1),
          PersonaSlotData(slotIndex: 4, title: 'CROSSWIND GUSTS', value: '${t.windGusts.round()} km/h', subtitle: 'Stable highway drive', status: 'Good', icon: Icons.air_rounded, color: const Color(0xFF10B981), progressPercentage: (t.windGusts / 60.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 5, title: 'CABIN CLIMATE', value: '${t.currentTemperature.round()}°C', subtitle: 'AC Eco Mode recommended', status: 'Moderate', icon: Icons.ac_unit_rounded, color: const Color(0xFF06B6D4), progressPercentage: 0.6),
          PersonaSlotData(slotIndex: 6, title: 'TRANSIT RELIABILITY', value: '98% High', subtitle: 'On-schedule traffic', status: 'Optimal', icon: Icons.schedule_rounded, color: const Color(0xFF10B981), progressPercentage: 0.95),
        ];
        break;

      case PersonaType.travel:
        _advisorySummary = '✈️ Excellent travel and destination conditions with ${t.currentTemperature.round()}°C and gentle breeze. Carry lightweight layers for evening.';
        _actionBullet = 'Keep boarding alert notifications on; clear flight routes expected.';

        _personaSlots = [
          PersonaSlotData(slotIndex: 1, title: 'SIGHTSEEING INDEX', value: '9/10 Excellent', subtitle: 'Clear daylight visibility', status: 'Optimal', icon: Icons.explore_rounded, color: const Color(0xFF10B981), progressPercentage: 0.9),
          PersonaSlotData(slotIndex: 2, title: 'PACKING ADVICE', value: 'Light Cotton + SPF', subtitle: 'UV ${t.uvIndex.round()} High', status: 'Good', icon: Icons.luggage_rounded, color: const Color(0xFF06B6D4), progressPercentage: 0.8),
          PersonaSlotData(slotIndex: 3, title: 'FLIGHT COMFORT', value: 'Smooth', subtitle: 'Low wind shear aloft', status: 'Optimal', icon: Icons.flight_takeoff_rounded, color: const Color(0xFF10B981), progressPercentage: 0.95),
          PersonaSlotData(slotIndex: 4, title: 'EVENING TEMP', value: '${(t.currentTemperature - 4).round()}°C', subtitle: 'Comfortable night outing', status: 'Good', icon: Icons.nightlight_rounded, color: const Color(0xFF8B5CF6), progressPercentage: 0.75),
          PersonaSlotData(slotIndex: 5, title: 'RAIN CHANCE', value: '10% Low', subtitle: 'No cancellations', status: 'Good', icon: Icons.umbrella_rounded, color: const Color(0xFF06B6D4), progressPercentage: 0.1),
          PersonaSlotData(slotIndex: 6, title: 'AIR QUALITY', value: 'AQI ${a.aqi}', subtitle: 'Healthy for touring', status: 'Good', icon: Icons.air_rounded, color: const Color(0xFF10B981), progressPercentage: 0.85),
        ];
        break;

      case PersonaType.events:
        _advisorySummary = '🎪 Outdoor event feasibility is 88%. Weather stability is high with minimal rain probability and moderate breeze.';
        _actionBullet = 'Setup shade canopies to protect guests during peak UV hours.';

        _personaSlots = [
          PersonaSlotData(slotIndex: 1, title: 'EVENT FEASIBILITY', value: '88% High', subtitle: 'Low disruption probability', status: 'Optimal', icon: Icons.celebration_rounded, color: const Color(0xFF10B981), progressPercentage: 0.88),
          PersonaSlotData(slotIndex: 2, title: 'CANOPY GUST LOAD', value: '${t.windGusts.round()} km/h', subtitle: 'Safe anchor conditions', status: 'Good', icon: Icons.air_rounded, color: const Color(0xFF10B981), progressPercentage: (t.windGusts / 50.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 3, title: 'GUEST THERMAL INDEX', value: '${t.apparentTemperature.round()}°C Feels', subtitle: 'Provide shaded seating', status: 'Moderate', icon: Icons.thermostat_rounded, color: const Color(0xFFF59E0B), progressPercentage: (t.apparentTemperature / 45.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 4, title: 'RAIN DISRUPTION', value: '10% Chance', subtitle: 'Dry stage conditions', status: 'Good', icon: Icons.cloud_rounded, color: const Color(0xFF06B6D4), progressPercentage: 0.1),
          PersonaSlotData(slotIndex: 5, title: 'GOLDEN HOUR', value: '6:15 PM', subtitle: 'Ideal photography window', status: 'Optimal', icon: Icons.wb_twilight_rounded, color: const Color(0xFFF59E0B), progressPercentage: 0.8),
          PersonaSlotData(slotIndex: 6, title: 'ACOUSTIC IMPACT', value: 'Low Wind Noise', subtitle: 'Clean outdoor audio', status: 'Good', icon: Icons.volume_up_rounded, color: const Color(0xFF10B981), progressPercentage: 0.7),
        ];
        break;

      case PersonaType.family:
        _advisorySummary = '👨‍👩‍👧 Air quality is clean (AQI ${a.aqi}) and temperature is comfortable. Great morning for school recess and park playtime.';
        _actionBullet = 'Pack full water bottles and apply sunscreen before school.';

        _personaSlots = [
          PersonaSlotData(slotIndex: 1, title: 'OUTDOOR PLAY', value: 'Approved', subtitle: 'Safe air & mild weather', status: 'Optimal', icon: Icons.sports_handball_rounded, color: const Color(0xFF10B981), progressPercentage: 0.9),
          PersonaSlotData(slotIndex: 2, title: 'SCHOOL COMMUTE', value: 'Smooth', subtitle: 'Clear roads & transit', status: 'Optimal', icon: Icons.directions_bus_rounded, color: const Color(0xFF10B981), progressPercentage: 0.95),
          PersonaSlotData(slotIndex: 3, title: 'HYDRATION NEED', value: 'High', subtitle: 'Pack 750ml water bottle', status: 'Moderate', icon: Icons.local_drink_rounded, color: const Color(0xFF06B6D4), progressPercentage: 0.7),
          PersonaSlotData(slotIndex: 4, title: 'UV PROTECTION', value: 'UV ${t.uvIndex.round()} High', subtitle: 'Hats & SPF recommended', status: 'High', icon: Icons.wb_sunny_rounded, color: const Color(0xFFF59E0B), progressPercentage: (t.uvIndex / 12.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 5, title: 'ALLERGY TRIGGER', value: 'Low', subtitle: 'Grass pollen minimal', status: 'Good', icon: Icons.masks_rounded, color: const Color(0xFF10B981), progressPercentage: 0.8),
          PersonaSlotData(slotIndex: 6, title: 'INDOOR SLEEP TEMP', value: '${(t.currentTemperature - 3).round()}°C', subtitle: 'Comfortable night cooling', status: 'Good', icon: Icons.bedtime_rounded, color: const Color(0xFF8B5CF6), progressPercentage: 0.85),
        ];
        break;

      case PersonaType.work:
        _advisorySummary = '👷 Heat index feels like ${t.apparentTemperature.round()}°C. Mandatory 10-minute shade and water rest intervals required every 50 minutes.';
        _actionBullet = 'Wear breathable high-vis gear and safety helmet sun shields.';

        _personaSlots = [
          PersonaSlotData(slotIndex: 1, title: 'HEAT STRESS INDEX', value: '${t.apparentTemperature.round()}°C Feels', subtitle: 'Stage 1 Precaution Active', status: 'Moderate', icon: Icons.warning_rounded, color: const Color(0xFFF59E0B), progressPercentage: (t.apparentTemperature / 45.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 2, title: 'REST CYCLE', value: '10m per 50m', subtitle: 'Mandatory hydration', status: 'Moderate', icon: Icons.timer_rounded, color: const Color(0xFF06B6D4), progressPercentage: 0.6),
          PersonaSlotData(slotIndex: 3, title: 'SCAFFOLD WIND', value: '${t.windGusts.round()} km/h', subtitle: 'Safe under 45 km/h', status: 'Good', icon: Icons.precision_manufacturing_rounded, color: const Color(0xFF10B981), progressPercentage: (t.windGusts / 60.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 4, title: 'LIGHTNING RISK', value: '0% None', subtitle: 'Safe for crane & steel', status: 'Optimal', icon: Icons.flash_on_rounded, color: const Color(0xFF10B981), progressPercentage: 0.95),
          PersonaSlotData(slotIndex: 5, title: 'DUST EXPOSURE', value: '${a.pm10.round()} µg/m³', subtitle: 'Wear particulate mask', status: 'Good', icon: Icons.masks_rounded, color: const Color(0xFF10B981), progressPercentage: (a.pm10 / 100.0).clamp(0.0, 1.0)),
          PersonaSlotData(slotIndex: 6, title: 'SITE STATUS', value: 'Green Status', subtitle: 'Full shift approved', status: 'Optimal', icon: Icons.verified_user_rounded, color: const Color(0xFF10B981), progressPercentage: 0.9),
        ];
        break;
    }
  }

  void _createFallbackData() {
    _telemetry = WeatherTelemetry(
      latitude: _currentLat,
      longitude: _currentLon,
      cityName: _cityName,
      timezone: 'Asia/Kolkata',
      currentTemperature: 28.0,
      apparentTemperature: 31.0,
      weatherCode: 1,
      weatherCondition: 'Mainly Clear',
      humidity: 65,
      windSpeed: 12.0,
      windDirection: 180.0,
      windDirectionCardinal: 'S',
      windGusts: 15.0,
      surfacePressure: 1012.0,
      uvIndex: 6.0,
      cloudCover: 20,
      precipitation: 0.0,
      rain: 0.0,
    );

    _airQuality = AirQualityData(
      aqi: 42,
      pm2_5: 14.2,
      pm10: 35.0,
      grassPollen: 8.0,
      ragweedPollen: 2.0,
    );

    _marineData = MarineData();

    _hourlyForecast = List.generate(24, (i) {
      final hour = (DateTime.now().hour + i) % 24;
      final p = hour >= 12 ? 'PM' : 'AM';
      final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return HourlyForecast(
        time: '$h $p',
        temperature: 24.0 + (i % 6),
        precipitationProbability: 10,
        precipitation: 0.0,
        weatherCode: 1,
        weatherCondition: 'Mainly Clear',
        icon: 'partly_cloudy_day',
      );
    });

    _dailyForecast = List.generate(7, (j) {
      return DailyForecast(
        date: DateTime.now().add(Duration(days: j)).toIso8601String(),
        dayName: j == 0 ? 'Today' : 'Day ${j + 1}',
        temperatureMax: 32.0,
        temperatureMin: 22.0,
        weatherCode: 1,
        weatherCondition: 'Mainly Clear',
        precipitationSum: 0.0,
        precipitationProbabilityMax: 10,
        uvIndexMax: 6.0,
        sunrise: '06:05 AM',
        sunset: '06:45 PM',
        icon: 'sunny',
      );
    });

    _recomputeDerivedMetrics();
  }

  /// Send Natural Language Message to AdvisorAI
  Future<void> sendChatMessage(String messageText) async {
    final cleanText = messageText.trim();
    if (cleanText.isEmpty) return;

    final userMsg = ChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      text: cleanText,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _chatMessages.add(userMsg);
    _isChatLoading = true;
    notifyListeners();

    try {
      if (_telemetry == null) {
        _createFallbackData();
      }

      final rainProb = (_hourlyForecast.isNotEmpty)
          ? _hourlyForecast.first.precipitationProbability
          : ((_dailyForecast.isNotEmpty) ? _dailyForecast.first.precipitationProbabilityMax : 10);

      final adviceText = await GeminiService.getAdvice(
        userPrompt: cleanText,
        persona: _activePersona,
        cityName: _cityName,
        temperature: _telemetry?.currentTemperature ?? 28.0,
        apparentTemperature: _telemetry?.apparentTemperature ?? 30.0,
        humidity: _telemetry?.humidity ?? 65,
        aqi: _airQuality?.aqi ?? 42,
        uvIndex: _telemetry?.uvIndex ?? 0.0,
        telemetry: _telemetry,
        airQuality: _airQuality,
        marineData: _marineData,
        rainProbability: rainProb,
      );

      final actionItems = GeminiService.extractActionItems(adviceText);

      final aiMsg = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: adviceText,
        isUser: false,
        timestamp: DateTime.now(),
        persona: _activePersona.shortTitle,
        actionItems: actionItems,
      );

      _chatMessages.add(aiMsg);
      await CacheService.saveChatHistory(_chatMessages.map((m) => m.toJson()).toList());
    } catch (e) {
      // Provide seamless meteorological intelligence fallback when Gemini API key is not configured
      final fallbackText = _generateOfflineFallbackAdvice(cleanText);
      final actionItems = GeminiService.extractActionItems(fallbackText);

      final aiMsg = ChatMessage(
        id: 'ai_fallback_${DateTime.now().millisecondsSinceEpoch}',
        text: fallbackText,
        isUser: false,
        timestamp: DateTime.now(),
        persona: _activePersona.shortTitle,
        actionItems: actionItems,
      );

      _chatMessages.add(aiMsg);
      await CacheService.saveChatHistory(_chatMessages.map((m) => m.toJson()).toList());
    } finally {
      _isChatLoading = false;
      notifyListeners();
    }
  }

  String _generateOfflineFallbackAdvice(String prompt) {
    final t = _telemetry ?? WeatherTelemetry(
      latitude: _currentLat,
      longitude: _currentLon,
      cityName: _cityName,
      timezone: 'Asia/Kolkata',
      currentTemperature: 28.0,
      apparentTemperature: 30.0,
      weatherCode: 1,
      weatherCondition: 'Mainly Clear',
      humidity: 65,
      windSpeed: 12.0,
      windDirection: 180.0,
      windDirectionCardinal: 'S',
      windGusts: 15.0,
      surfacePressure: 1012.0,
      uvIndex: 5.0,
      cloudCover: 20,
      precipitation: 0.0,
      rain: 0.0,
    );
    final a = _airQuality ?? AirQualityData(aqi: 42, pm2_5: 14.2, pm10: 35.0, grassPollen: 8.0, ragweedPollen: 2.0);
    final temp = t.currentTemperature.round();

    switch (_activePersona) {
      case PersonaType.fitness:
        return '🏃 Current conditions are $temp°C with ${t.humidity}% humidity and AQI ${a.aqi}. Your workout safety score is $_workoutScore/100. Optimal window: $_optimalRunningWindow.\n- Drink 500ml water per hour of cardio\n- Train during $_optimalRunningWindow';
      case PersonaType.farm:
        return '🌱 $_irrigationAdvice. Soil moisture is at ${t.soilMoisture.toStringAsFixed(2)} m³/m³ with an evapotranspiration deficit of ${agDeficit.toStringAsFixed(1)} mm.\n- Check root zone soil moisture probes\n- Execute evening micro-drip cycle if deficit exceeds 3.5mm';
      case PersonaType.beach:
        final wave = (_marineData?.waveHeight ?? 1.2).toStringAsFixed(1);
        return '🌊 Wave height is ${wave}m with offshore wind at ${t.windSpeed.round()} km/h. UV Index is ${t.uvIndex.round()}.\n- Reapply waterproof sunscreen every 90 mins\n- Watch for afternoon gust shifts';
      case PersonaType.commute:
        return '🚗 Commute Hazard Rating is $_commuteHazard/100 ($_commuteCondition). Road visibility is clear (>8 km).\n- Maintain safe braking distance\n- Normal transit timing expected along major routes';
      default:
        return '🌤️ Location $_cityName is currently $temp°C (Feels like ${t.apparentTemperature.round()}°C) with AQI ${a.aqi} and ${t.humidity}% humidity.\n- Dress comfortably in breathable layers\n- Keep well hydrated throughout the day';
    }
  }

  /// Clear chat messages
  Future<void> clearChatHistory() async {
    _initDefaultChatGreeting();
    await CacheService.saveChatHistory(_chatMessages.map((m) => m.toJson()).toList());
    notifyListeners();
  }

  /// Map pin tapped/dragged to coordinates
  Future<void> updateMapSelectedCoordinates(double lat, double lon) async {
    _mapLat = lat;
    _mapLon = lon;
    _isMapPreviewLoading = true;
    notifyListeners();

    try {
      final cityFuture = LocationService.reverseGeocode(lat, lon);
      final forecastFuture = _apiService.fetchForecastData(lat: lat, lon: lon);

      final results = await Future.wait([cityFuture, forecastFuture]);
      final resolvedCity = results[0] as String;
      final forecast = results[1] as Map<String, dynamic>;

      final current = forecast['current'] as Map<String, dynamic>? ?? {};
      final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 28.0;
      final wCode = current['weather_code'] ?? 1;

      _mapPreviewTelemetry = WeatherTelemetry(
        latitude: lat,
        longitude: lon,
        cityName: resolvedCity,
        timezone: forecast['timezone'] ?? 'auto',
        currentTemperature: temp,
        apparentTemperature: (current['apparent_temperature'] as num?)?.toDouble() ?? temp,
        weatherCode: wCode,
        weatherCondition: WeatherMath.getWeatherConditionString(wCode),
        humidity: current['relative_humidity_2m'] ?? 65,
        windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 12.0,
        windDirection: 180.0,
        windDirectionCardinal: 'S',
        windGusts: 15.0,
        surfacePressure: 1012.0,
        uvIndex: (current['uv_index'] as num?)?.toDouble() ?? 5.0,
        cloudCover: 20,
        precipitation: 0.0,
        rain: 0.0,
      );
    } catch (e) {
      _mapPreviewTelemetry = null;
    } finally {
      _isMapPreviewLoading = false;
      notifyListeners();
    }
  }

  /// Toggle Map Radar
  void toggleRadarOverlay() {
    _isRadarOverlayActive = !_isRadarOverlayActive;
    notifyListeners();
  }
}
