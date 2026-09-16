import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_parameter_definition.dart';
import '../models/persona_type.dart';
import '../models/weather_models.dart';
import '../models/chat_message.dart';
import '../models/chat_attachment.dart';
import '../models/chat_session.dart';
import '../services/weather_api_service.dart';
import '../services/gemini_service.dart';
import '../services/location_service.dart';
import '../services/cache_service.dart';
import '../services/notification_service.dart';
import '../services/dynamic_icon_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/weather_math.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherApiService _apiService = WeatherApiService();
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;

  // Homescreen Section Customization State
  bool _showMiniMetrics = true;
  bool _showPersonalizedInsights = true;
  bool _showHourlyForecast = true;
  bool _showDailyForecast = true;
  bool _showCelestialAlmanac = true;

  // Custom Parameter Selection State
  List<String> _activeParameterIds = ['aqi', 'grass_pollen', 'tree_pollen', 'uv_index', 'humidity', 'temperature'];

  // Units & Formats
  String _tempUnit = 'C'; // 'C' or 'F'
  String _windUnit = 'km/h'; // 'km/h', 'mph', 'm/s'

  // Notification Automation Preferences
  bool _isAutoNotificationsActive = true;
  bool _isWittyAlertsActive = true;
  bool _isMorningBriefingActive = true;
  String _dynamicIconTheme = 'auto';

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

  // Chat Multi-Session State
  final List<ChatSession> _chatSessions = [];
  String _activeSessionId = '';
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

  // Getters - Customization & Preferences
  bool get showMiniMetrics => _showMiniMetrics;
  bool get showPersonalizedInsights => _showPersonalizedInsights;
  bool get showHourlyForecast => _showHourlyForecast;
  bool get showDailyForecast => _showDailyForecast;
  bool get showCelestialAlmanac => _showCelestialAlmanac;

  String get tempUnit => _tempUnit;
  String get windUnit => _windUnit;
  bool get isAutoNotificationsActive => _isAutoNotificationsActive;
  bool get isWittyAlertsActive => _isWittyAlertsActive;
  bool get isMorningBriefingActive => _isMorningBriefingActive;
  String get dynamicIconTheme => _dynamicIconTheme;

  // Getters - Core State
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

  List<ChatSession> get chatSessions => List.unmodifiable(_chatSessions);
  String get activeSessionId => _activeSessionId;
  ChatSession get activeSession {
    if (_chatSessions.isEmpty) {
      final defaultSession = _createDefaultChatSession();
      _chatSessions.add(defaultSession);
      _activeSessionId = defaultSession.id;
      return defaultSession;
    }
    return _chatSessions.firstWhere(
      (s) => s.id == _activeSessionId,
      orElse: () {
        _activeSessionId = _chatSessions.first.id;
        return _chatSessions.first;
      },
    );
  }

  List<ChatMessage> get chatMessages => activeSession.messages;
  bool get isChatLoading => _isChatLoading;

  double get mapLat => _mapLat;
  double get mapLon => _mapLon;
  bool get isRadarOverlayActive => _isRadarOverlayActive;
  WeatherTelemetry? get mapPreviewTelemetry => _mapPreviewTelemetry;
  bool get isMapPreviewLoading => _isMapPreviewLoading;

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  bool get notificationsEnabled => _notificationsEnabled;

  /// Trigger a live test Weather Alert notification into the status bar
  Future<void> sendTestAlertNotification() async {
    final title = '🚨 Severe Weather Alert: $_cityName';
    final desc = _alerts.isNotEmpty
        ? _alerts.first.description
        : 'High wind gusts (>48 km/h) & heavy rain expected in your zone. Secure outdoor items and drive cautiously.';
    await _notificationService.showWeatherAlert(
      id: 101,
      title: title,
      body: desc,
      payload: 'alert_tap',
    );
  }

  /// Trigger a live test Smart AI Persona Suggestion notification into the status bar
  Future<void> sendTestSuggestionNotification() async {
    final title = '💡 ${_activePersona.displayName} Smart Advisory';
    final desc = _advisorySummary.isNotEmpty
        ? _advisorySummary
        : _actionBullet.isNotEmpty
            ? _actionBullet
            : 'Optimal weather window for $_cityName today with clean air and mild temperatures.';
    await _notificationService.showPersonaSuggestion(
      id: 202,
      title: title,
      body: desc,
      payload: 'suggestion_tap',
    );
  }

  // Custom Selected Parameter IDs
  List<String> get activeParameterIds => List.unmodifiable(_activeParameterIds);

  /// Toggle selection of a parameter metric
  Future<void> toggleParameterSelection(String paramId) async {
    if (_activeParameterIds.contains(paramId)) {
      if (_activeParameterIds.length > 1) {
        _activeParameterIds.remove(paramId);
      }
    } else {
      _activeParameterIds.add(paramId);
    }
    await CacheService.saveStringList(CacheService.getPersonaCustomParamsKey(_activePersona.name), _activeParameterIds);
    await CacheService.saveStringList(CacheService.keyCustomParameterIds, _activeParameterIds);
    _buildPersonaSlots();
    notifyListeners();
  }

  /// Reset parameter metrics to persona defaults
  Future<void> resetParametersToDefault() async {
    _activeParameterIds = List<String>.from(_getDefaultParameterIdsForPersona(_activePersona));
    await CacheService.saveStringList(CacheService.getPersonaCustomParamsKey(_activePersona.name), _activeParameterIds);
    await CacheService.saveStringList(CacheService.keyCustomParameterIds, _activeParameterIds);
    _buildPersonaSlots();
    notifyListeners();
  }

  List<String> _getDefaultParameterIdsForPersona(PersonaType persona) {
    switch (persona) {
      case PersonaType.health:
        return ['aqi', 'grass_pollen', 'tree_pollen', 'uv_index', 'humidity', 'temperature'];
      case PersonaType.fitness:
        return ['workout_score', 'best_run_window', 'temperature', 'apparent_temperature', 'wind_speed', 'rain_probability'];
      case PersonaType.farm:
        return ['irrigation_advice', 'soil_moisture', 'mold_risk', 'wind_speed', 'rain_probability', 'wind_gusts'];
      case PersonaType.beach:
        return ['wave_height', 'uv_index', 'wind_speed', 'temperature', 'surface_pressure', 'rain_probability'];
      case PersonaType.commute:
        return ['commute_hazard', 'visibility', 'rain_probability', 'wind_gusts', 'apparent_temperature', 'temperature'];
      case PersonaType.travel:
        return ['temperature', 'uv_index', 'visibility', 'apparent_temperature', 'rain_probability', 'aqi'];
      case PersonaType.events:
        return ['apparent_temperature', 'wind_gusts', 'rain_probability', 'cloud_cover', 'temperature', 'uv_index'];
      case PersonaType.family:
        return ['aqi', 'temperature', 'uv_index', 'humidity', 'grass_pollen', 'rain_probability'];
      case PersonaType.work:
        return ['apparent_temperature', 'wind_gusts', 'pm10', 'temperature', 'uv_index', 'humidity'];
    }
  }

  /// Setters for Homescreen Customization
  Future<void> setShowMiniMetrics(bool val) async {
    _showMiniMetrics = val;
    await CacheService.saveBool(CacheService.keyShowMiniMetrics, val);
    notifyListeners();
  }

  Future<void> setShowPersonalizedInsights(bool val) async {
    _showPersonalizedInsights = val;
    await CacheService.saveBool(CacheService.keyShowPersonalizedInsights, val);
    notifyListeners();
  }

  Future<void> setShowHourlyForecast(bool val) async {
    _showHourlyForecast = val;
    await CacheService.saveBool(CacheService.keyShowHourlyForecast, val);
    notifyListeners();
  }

  Future<void> setShowDailyForecast(bool val) async {
    _showDailyForecast = val;
    await CacheService.saveBool(CacheService.keyShowDailyForecast, val);
    notifyListeners();
  }

  Future<void> setShowCelestialAlmanac(bool val) async {
    _showCelestialAlmanac = val;
    await CacheService.saveBool(CacheService.keyShowCelestialAlmanac, val);
    notifyListeners();
  }

  Future<void> setTempUnit(String unit) async {
    _tempUnit = unit;
    await CacheService.saveString(CacheService.keyTemperatureUnit, unit);
    _buildPersonaSlots();
    notifyListeners();
  }

  Future<void> setWindUnit(String unit) async {
    _windUnit = unit;
    await CacheService.saveString(CacheService.keyWindSpeedUnit, unit);
    _buildPersonaSlots();
    notifyListeners();
  }

  Future<void> setAutoNotifications(bool val) async {
    _isAutoNotificationsActive = val;
    await CacheService.saveBool(CacheService.keyAutoNotifications, val);
    notifyListeners();
  }

  Future<void> setWittyAlerts(bool val) async {
    _isWittyAlertsActive = val;
    await CacheService.saveBool(CacheService.keyWittyAlerts, val);
    notifyListeners();
  }

  Future<void> setMorningBriefing(bool val) async {
    _isMorningBriefingActive = val;
    await CacheService.saveBool(CacheService.keyMorningBriefing, val);
    notifyListeners();
  }

  Future<void> setDynamicIconTheme(String theme) async {
    _dynamicIconTheme = theme;
    await CacheService.saveString(CacheService.keyDynamicIconTheme, theme);
    if (_telemetry != null) {
      final isNight = DateTime.now().hour < 6 || DateTime.now().hour >= 19;
      await DynamicIconService.updateWeatherAdaptiveIcon(
        weatherCode: _telemetry!.weatherCode,
        isNight: isNight,
      );
    }
    notifyListeners();
  }

  /// Convert and format temperature according to user preference
  String formatTemperature(double celsius) {
    if (_tempUnit == 'F') {
      final f = (celsius * 9 / 5) + 32;
      return '${f.round()}°F';
    }
    return '${celsius.round()}°C';
  }

  /// Convert and format wind speed according to user preference
  String formatWindSpeed(double kmh) {
    if (_windUnit == 'mph') {
      final mph = kmh * 0.621371;
      return '${mph.round()} mph';
    } else if (_windUnit == 'm/s') {
      final ms = kmh / 3.6;
      return '${ms.toStringAsFixed(1)} m/s';
    }
    return '${kmh.round()} km/h';
  }

  /// Dispatch Automated Contextual Weather Notifications & Good Morning Briefings
  Future<void> checkAndDispatchAutomatedNotifications() async {
    if (!_notificationsEnabled || !_isAutoNotificationsActive || _telemetry == null) return;

    final t = _telemetry!;
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // 1. Morning Briefing Check (between 6:00 AM and 10:59 AM)
    if (_isMorningBriefingActive && now.hour >= 6 && now.hour < 11) {
      final lastMorningDate = await CacheService.getString(CacheService.keyLastMorningDate);
      if (lastMorningDate != todayStr) {
        await CacheService.saveString(CacheService.keyLastMorningDate, todayStr);
        final tip = _advisorySummary.isNotEmpty
            ? _advisorySummary
            : 'Conditions are favorable for your daily outdoor schedule.';
        await _notificationService.showDailyBriefing(
          id: 303,
          cityName: _cityName,
          temperature: t.currentTemperature,
          condition: t.weatherCondition,
          advice: tip,
        );
      }
    }

    // 2. Contextual / Witty Zomato-style Weather Alert Check
    if (_isWittyAlertsActive) {
      final lastWittyTime = await CacheService.getInt(CacheService.keyLastWittyAlertTime, defaultValue: 0);
      final currentMillis = now.millisecondsSinceEpoch;
      // Minimum 2.5 hours throttle between contextual ambient alerts
      if (currentMillis - lastWittyTime > 9000000) {
        String? wittyTitle;
        String? wittyBody;

        if (t.precipitation > 0 || (t.weatherCode >= 51 && t.weatherCode <= 67) || (t.weatherCode >= 80 && t.weatherCode <= 82)) {
          wittyTitle = 'Chai-Pakoda Weather Alert! ☕🌧️';
          wittyBody = 'It\'s raining in $_cityName (${t.currentTemperature.round()}°C). Perfect excuse to grab hot samosas and stay cozy!';
        } else if (t.currentTemperature >= 34.0) {
          wittyTitle = 'The Sun is in Main Character mode! 🕶️🔥';
          wittyBody = '${t.currentTemperature.round()}°C in $_cityName! Chilled nimbu pani or iced coffee is strictly mandatory today.';
        } else if (t.uvIndex >= 7.0 && now.hour >= 11 && now.hour <= 16) {
          wittyTitle = 'SPF is your best friend today! 🧴☀️';
          wittyBody = 'High UV index (${t.uvIndex.round()}) in $_cityName. Slather on sunscreen before stepping out.';
        } else if (now.hour >= 17 && now.hour <= 19 && t.weatherCode <= 3) {
          wittyTitle = 'Golden Hour Calling! 🌅✨';
          wittyBody = 'Pleasant ${t.currentTemperature.round()}°C in $_cityName with gentle breeze. Perfect time for an evening stroll!';
        } else if (t.currentTemperature <= 18.0) {
          wittyTitle = 'Cozy Hoodie Weather Unlocked! 🧥✨';
          wittyBody = 'Crisp ${t.currentTemperature.round()}°C in $_cityName. Keep that warm jacket handy.';
        }

        if (wittyTitle != null && wittyBody != null) {
          await CacheService.saveInt(CacheService.keyLastWittyAlertTime, currentMillis);
          await _notificationService.showWittyWeatherTip(
            id: 404,
            title: wittyTitle,
            body: wittyBody,
          );
        }
      }
    }
  }

  /// Toggle notification permissions
  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    if (enabled) {
      await _notificationService.requestPermissions();
    }
    notifyListeners();
  }

  /// Initialize Application State
  Future<void> initializeApp() async {
    _isLoading = true;
    notifyListeners();

    // 0. Load saved customization preferences
    _showMiniMetrics = await CacheService.getBool(CacheService.keyShowMiniMetrics, defaultValue: true);
    _showPersonalizedInsights = await CacheService.getBool(CacheService.keyShowPersonalizedInsights, defaultValue: true);
    _showHourlyForecast = await CacheService.getBool(CacheService.keyShowHourlyForecast, defaultValue: true);
    _showDailyForecast = await CacheService.getBool(CacheService.keyShowDailyForecast, defaultValue: true);
    _showCelestialAlmanac = await CacheService.getBool(CacheService.keyShowCelestialAlmanac, defaultValue: true);

    _tempUnit = await CacheService.getString(CacheService.keyTemperatureUnit, defaultValue: 'C');
    _windUnit = await CacheService.getString(CacheService.keyWindSpeedUnit, defaultValue: 'km/h');
    _isAutoNotificationsActive = await CacheService.getBool(CacheService.keyAutoNotifications, defaultValue: true);
    _isWittyAlertsActive = await CacheService.getBool(CacheService.keyWittyAlerts, defaultValue: true);
    _isMorningBriefingActive = await CacheService.getBool(CacheService.keyMorningBriefing, defaultValue: true);
    _dynamicIconTheme = await CacheService.getString(CacheService.keyDynamicIconTheme, defaultValue: 'auto');

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

    // Load parameters for active persona
    final savedPersonaParams = await CacheService.getStringList(CacheService.getPersonaCustomParamsKey(_activePersona.name));
    if (savedPersonaParams != null && savedPersonaParams.isNotEmpty) {
      _activeParameterIds = List<String>.from(savedPersonaParams);
    } else {
      _activeParameterIds = List<String>.from(_getDefaultParameterIdsForPersona(_activePersona));
    }

    // 2. Load saved multi-session chat threads
    final cachedSessions = await CacheService.loadAllChatSessions();
    if (cachedSessions.isNotEmpty) {
      _chatSessions.clear();
      for (var s in cachedSessions) {
        final session = ChatSession.fromJson(s);
        // Automatically sanitize and polish legacy raw lowercase snippet titles
        if (session.title.toLowerCase().startsWith('how are') ||
            session.title.toLowerCase() == 'hello' ||
            session.title.endsWith('...') ||
            session.title == session.title.toLowerCase()) {
          final firstUserMsg = session.messages.where((m) => m.isUser).firstOrNull;
          if (firstUserMsg != null) {
            session.title = _deriveSessionTitle(firstUserMsg.text, firstUserMsg.attachments);
          } else {
            session.title = _toTitleCase(session.title.replaceAll('...', ''));
          }
        }
        _chatSessions.add(session);
      }
      final savedActiveId = await CacheService.loadActiveSessionId();
      if (savedActiveId != null && _chatSessions.any((s) => s.id == savedActiveId)) {
        _activeSessionId = savedActiveId;
      } else {
        _activeSessionId = _chatSessions.first.id;
      }
    } else {
      // Legacy single-session migration or initial greeting
      final cachedChats = await CacheService.loadChatHistory();
      if (cachedChats.isNotEmpty) {
        final legacyMessages = cachedChats.map((m) => ChatMessage.fromJson(m)).toList();
        final migratedSession = ChatSession(
          id: 'session_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Recent Advisory',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          persona: _activePersona.shortTitle,
          messages: legacyMessages,
        );
        _chatSessions.add(migratedSession);
        _activeSessionId = migratedSession.id;
      } else {
        final defaultSession = _createDefaultChatSession();
        _chatSessions.add(defaultSession);
        _activeSessionId = defaultSession.id;
      }
      await _persistChatSessions();
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

  ChatSession _createDefaultChatSession({String? title}) {
    final now = DateTime.now();
    return ChatSession(
      id: 'session_${now.millisecondsSinceEpoch}',
      title: title ?? 'New Conversation',
      createdAt: now,
      updatedAt: now,
      persona: _activePersona.shortTitle,
      messages: [_createInitialGreetingMessage()],
    );
  }

  ChatMessage _createInitialGreetingMessage() {
    return ChatMessage(
      id: 'msg_welcome_${DateTime.now().millisecondsSinceEpoch}',
      text: "Hi! Ask me anything about local weather, running conditions, UV safety, crop moisture, or upload images and documents for analysis.",
      isUser: false,
      timestamp: DateTime.now(),
      persona: _activePersona.shortTitle,
      actionItems: ['What is the best running time today?', 'Do I need sunscreen this afternoon?', 'How is road visibility for travel?'],
    );
  }

  Future<void> _persistChatSessions() async {
    await CacheService.saveAllChatSessions(_chatSessions.map((s) => s.toJson()).toList());
    await CacheService.saveActiveSessionId(_activeSessionId);
  }

  /// Create a brand new chat session thread
  Future<void> createNewChatSession({String? title}) async {
    final newSession = _createDefaultChatSession(title: title);
    _chatSessions.insert(0, newSession);
    _activeSessionId = newSession.id;
    await _persistChatSessions();
    notifyListeners();
  }

  /// Switch active chat session
  Future<void> switchChatSession(String sessionId) async {
    if (_chatSessions.any((s) => s.id == sessionId)) {
      _activeSessionId = sessionId;
      await CacheService.saveActiveSessionId(sessionId);
      notifyListeners();
    }
  }

  /// Delete a chat session
  Future<void> deleteChatSession(String sessionId) async {
    _chatSessions.removeWhere((s) => s.id == sessionId);
    if (_chatSessions.isEmpty) {
      final newSession = _createDefaultChatSession();
      _chatSessions.add(newSession);
      _activeSessionId = newSession.id;
    } else if (_activeSessionId == sessionId) {
      _activeSessionId = _chatSessions.first.id;
    }
    await _persistChatSessions();
    notifyListeners();
  }

  /// Rename a chat session
  Future<void> renameChatSession(String sessionId, String newTitle) async {
    final sessionIndex = _chatSessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1 && newTitle.trim().isNotEmpty) {
      _chatSessions[sessionIndex].title = newTitle.trim();
      _chatSessions[sessionIndex].updatedAt = DateTime.now();
      await _persistChatSessions();
      notifyListeners();
    }
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      final lower = word.toLowerCase();
      // Keep known acronyms capitalized
      if (lower == 'aqi' || lower == 'uv' || lower == 'ai' || lower == 'pm25' || lower == 'gps') {
        return lower.toUpperCase();
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _deriveSessionTitle(String prompt, List<ChatAttachment>? attachments) {
    if (attachments != null && attachments.isNotEmpty && prompt.trim().isEmpty) {
      final firstAtt = attachments.first;
      return firstAtt.isImage ? 'Image Analysis' : _toTitleCase(firstAtt.fileName.split('.').first);
    }

    String clean = prompt.trim();
    if (clean.isEmpty) return '$_cityName Weather Check';

    // Remove punctuation from ends
    clean = clean.replaceAll(RegExp(r'[?!.,;:]+$'), '').trim();

    // Check for standard greeting or generic questions
    final lower = clean.toLowerCase();
    final isGreeting = RegExp(
      r'^(hi|hello|hey|how are you|how r u|good morning|good evening|good afternoon|namaste|sup|what’s up|whats up|advisor|yo)(\s+(there|advisor|ai|mausam|bot|my advisor|friend))?$',
      caseSensitive: false,
    ).hasMatch(lower);

    if (isGreeting) {
      return '$_cityName Weather Check';
    }

    // Strip common conversational filler prefixes
    final stripped = clean.replaceFirst(
      RegExp(
        r'^(what is the|what are the|what is|what are|tell me about the|tell me about|how is the|how are the|how is|how are|can you tell me|can you give me|can you|should i|is it safe to|is it safe for|is it|do i need to|do i need|will it|please give me|please tell me|please)\s+',
        caseSensitive: false,
      ),
      '',
    ).trim();

    if (stripped.isEmpty) {
      return '$_cityName Weather Check';
    }

    // Split words and take up to 4 meaningful words
    final words = stripped.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final meaningfulWords = words.take(4).toList();
    final titleString = meaningfulWords.join(' ');

    return _toTitleCase(titleString);
  }

  /// Change Persona and dynamically re-derive slot metrics & advisory
  Future<void> switchPersona(PersonaType newPersona) async {
    _activePersona = newPersona;
    await CacheService.savePersona(newPersona.name);

    // Load custom parameters specific to this persona or use persona defaults
    final savedPersonaParams = await CacheService.getStringList(CacheService.getPersonaCustomParamsKey(newPersona.name));
    if (savedPersonaParams != null && savedPersonaParams.isNotEmpty) {
      _activeParameterIds = List<String>.from(savedPersonaParams);
    } else {
      _activeParameterIds = List<String>.from(_getDefaultParameterIdsForPersona(newPersona));
    }

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

    if (cityName == null ||
        cityName.isEmpty ||
        cityName.startsWith('Pin') ||
        cityName == 'Current Location' ||
        cityName == 'My Location') {
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
    checkAndDispatchAutomatedNotifications();
    DynamicIconService.updateWeatherAdaptiveIcon(
      weatherCode: wCode,
      isNight: (DateTime.now().hour < 6 || DateTime.now().hour >= 19),
    );
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

    // Automatically trigger notification for critical active alerts
    if (_notificationsEnabled && _alerts.isNotEmpty) {
      final firstAlert = _alerts.first;
      _notificationService.showWeatherAlert(
        id: firstAlert.id.hashCode.abs() % 10000,
        title: '🚨 ${firstAlert.title} — $_cityName',
        body: firstAlert.description,
      );
    }

    // 6. 6 Parameter Slots per Active Persona
    _buildPersonaSlots();
  }

  void _buildPersonaSlots() {
    if (_telemetry == null || _airQuality == null) return;
    final t = _telemetry!;
    final a = _airQuality!;

    // 1. Establish persona targeted advisory summary & action bullet
    switch (_activePersona) {
      case PersonaType.health:
        final aqiLabel = a.aqi <= 50 ? 'Good' : (a.aqi <= 100 ? 'Moderate' : 'Unhealthy');
        _advisorySummary = '✓ AQI is ${aqiLabel.toLowerCase()} today (${a.aqi}). UV is high (${t.uvIndex.round()}) — wear sunscreen and sunglasses. Pollen is low, great for outdoor walks.';
        _actionBullet = 'Wear SPF 30+ and UV-blocking eyewear during midday hours.';
        break;
      case PersonaType.fitness:
        _advisorySummary = '🏃 Workout Safety Score is $_workoutScore/100. Optimal training window is $_optimalRunningWindow with lowest heat index and clean air.';
        _actionBullet = 'Plan workout session during $_optimalRunningWindow.';
        break;
      case PersonaType.farm:
        _advisorySummary = '🌱 $_irrigationAdvice. Soil moisture (0-7cm) is ${t.soilMoisture.toStringAsFixed(2)} m³/m³ with ET deficit of ${_agDeficit.toStringAsFixed(1)} mm.';
        _actionBullet = 'Execute micro-irrigation schedule if deficit exceeds 3.5mm.';
        break;
      case PersonaType.beach:
        final waves = _marineData?.waveHeight ?? 1.2;
        _advisorySummary = '🌊 Wave height is currently ${waves.toStringAsFixed(1)}m. UV Index is high (${t.uvIndex.round()}) — apply water-resistant SPF 50+ sunscreen.';
        _actionBullet = 'Great conditions for beach strolls and water activities.';
        break;
      case PersonaType.commute:
        _advisorySummary = '🚗 Commute Hazard Rating: $_commuteHazard/100 ($_commuteCondition). Road traction is firm with excellent visibility.';
        _actionBullet = 'Normal cruising speed recommended along main highway routes.';
        break;
      case PersonaType.travel:
        _advisorySummary = '✈️ Excellent travel and destination conditions with ${t.currentTemperature.round()}°C and gentle breeze. Carry lightweight layers for evening.';
        _actionBullet = 'Keep boarding alert notifications on; clear flight routes expected.';
        break;
      case PersonaType.events:
        _advisorySummary = '🎪 Outdoor event feasibility is 88%. Weather stability is high with minimal rain probability and moderate breeze.';
        _actionBullet = 'Setup shade canopies to protect guests during peak UV hours.';
        break;
      case PersonaType.family:
        _advisorySummary = '👨‍👩‍👧 Air quality is clean (AQI ${a.aqi}) and temperature is comfortable. Great morning for school recess and park playtime.';
        _actionBullet = 'Pack full water bottles and apply sunscreen before school.';
        break;
      case PersonaType.work:
        _advisorySummary = '👷 Heat index feels like ${t.apparentTemperature.round()}°C. Mandatory 10-minute shade and water rest intervals required every 50 minutes.';
        _actionBullet = 'Wear breathable high-vis gear and safety helmet sun shields.';
        break;
    }

    // 2. Build custom/active parameter slots dynamically
    if (_activeParameterIds.isEmpty) {
      _activeParameterIds = _getDefaultParameterIdsForPersona(_activePersona);
    }

    _personaSlots = [];
    for (int i = 0; i < _activeParameterIds.length; i++) {
      final pid = _activeParameterIds[i];
      final def = WeatherParameterDefinition.allParameters.firstWhere(
        (p) => p.id == pid,
        orElse: () => WeatherParameterDefinition(
          id: pid,
          title: pid,
          shortTitle: pid,
          description: '',
          category: ParameterCategory.lifestyle,
          icon: Icons.insights_rounded,
          defaultColor: AppColors.primary,
        ),
      );

      _personaSlots.add(def.extractSlotData(
        slotIndex: i + 1,
        telemetry: t,
        airQuality: a,
        marineData: _marineData,
        workoutScore: _workoutScore,
        optimalRunWindow: _optimalRunningWindow,
        moldRisk: _moldRisk,
        irrigationAdvice: _irrigationAdvice,
        agDeficit: _agDeficit,
        commuteHazard: _commuteHazard,
        commuteCondition: _commuteCondition,
        tempUnit: _tempUnit,
        windUnit: _windUnit,
      ));
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

  /// Send Natural Language Message to AdvisorAI with optional Multimodal Attachments
  Future<void> sendChatMessage(String messageText, {List<ChatAttachment>? attachments}) async {
    final cleanText = messageText.trim();
    final hasAttachments = attachments != null && attachments.isNotEmpty;
    if (cleanText.isEmpty && !hasAttachments) return;

    final currentSession = activeSession;
    final historySnapshot = List<ChatMessage>.from(currentSession.messages);

    // Auto-title session if it is default title or first user interaction
    if (currentSession.title == 'New Conversation' || currentSession.title == 'New Chat' || currentSession.messages.length <= 1) {
      currentSession.title = _deriveSessionTitle(cleanText, attachments);
    }
    currentSession.updatedAt = DateTime.now();

    final userMsg = ChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      text: cleanText.isNotEmpty ? cleanText : (hasAttachments ? 'Analyze uploaded file' : ''),
      isUser: true,
      timestamp: DateTime.now(),
      attachments: attachments ?? [],
    );

    currentSession.messages.add(userMsg);
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
        conversationHistory: historySnapshot,
        attachments: attachments,
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

      currentSession.messages.add(aiMsg);
      await _persistChatSessions();

      // Asynchronously refine conversation title using Gemini AI if within initial exchange
      if (currentSession.messages.length <= 4) {
        GeminiService.generateChatTitle(
          userPrompt: cleanText,
          aiResponse: adviceText,
          cityName: _cityName,
          persona: _activePersona.displayName,
        ).then((aiTitle) {
          if (aiTitle != null && aiTitle.trim().isNotEmpty) {
            currentSession.title = _toTitleCase(aiTitle.trim());
            _persistChatSessions();
            notifyListeners();
          }
        });
      }
    } on GeminiQuotaExceededException catch (qe) {
      final quotaNotice = '⚠️ **Gemini API Rate Limit Reached**\n'
          'All ${qe.totalKeysTested} configured Gemini API keys have exceeded their current per-minute or daily quota.\n\n'
          '💡 **How to resolve:**\n'
          '• Please wait 1-2 minutes for Google\'s free-tier rate limit to reset.\n'
          '• Or add multiple Gemini API keys to your `.env` file (e.g. `GEMINI_API_KEYS=key1,key2,key3`).';

      final fallbackText = _generateOfflineFallbackAdvice(cleanText);
      final combinedText = '$quotaNotice\n\n---\n**Offline Weather Advisory:**\n$fallbackText';
      final actionItems = GeminiService.extractActionItems(fallbackText);

      final aiMsg = ChatMessage(
        id: 'ai_quota_${DateTime.now().millisecondsSinceEpoch}',
        text: combinedText,
        isUser: false,
        timestamp: DateTime.now(),
        persona: _activePersona.shortTitle,
        actionItems: actionItems,
      );

      currentSession.messages.add(aiMsg);
      await _persistChatSessions();
    } catch (e) {
      final errorPrefix = '⚠️ **AdvisorAI Notice**: $e\n\n';
      final fallbackText = _generateOfflineFallbackAdvice(cleanText);
      final combinedText = '$errorPrefix---\n**Offline Weather Advisory:**\n$fallbackText';
      final actionItems = GeminiService.extractActionItems(fallbackText);

      final aiMsg = ChatMessage(
        id: 'ai_fallback_${DateTime.now().millisecondsSinceEpoch}',
        text: combinedText,
        isUser: false,
        timestamp: DateTime.now(),
        persona: _activePersona.shortTitle,
        actionItems: actionItems,
      );

      currentSession.messages.add(aiMsg);
      await _persistChatSessions();
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
    final lowerPrompt = prompt.toLowerCase().trim();

    // Check for greeting exchange
    final isGreeting = RegExp(
      r'^(hi|hello|hey|good morning|good afternoon|good evening|good night|namaste|how are you|how r u|sup|yo|what’s up|whats up)',
      caseSensitive: false,
    ).hasMatch(lowerPrompt);

    if (isGreeting) {
      final hour = DateTime.now().hour;
      final timeGreeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
      return '$timeGreeting! 👋 Currently in $_cityName, it is $temp°C and ${t.weatherCondition} with an AQI of ${a.aqi}. How can I assist you today?\n- Ask about today\'s best workout window\n- Ask about rain timing and humidity';
    }

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

  /// Clear active chat messages
  Future<void> clearChatHistory() async {
    final currentSession = activeSession;
    currentSession.messages.clear();
    currentSession.messages.add(_createInitialGreetingMessage());
    currentSession.updatedAt = DateTime.now();
    await _persistChatSessions();
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
