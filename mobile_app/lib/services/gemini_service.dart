import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_attachment.dart';
import '../models/chat_message.dart';
import '../models/persona_type.dart';
import '../models/weather_models.dart';
import '../utils/constants.dart';

class GeminiService {
  static final http.Client _client = http.Client();

  /// Retrieve active Gemini API key from .env or storage
  static Future<String> getApiKey([String? overrideKey]) async {
    if (overrideKey != null && overrideKey.isNotEmpty) {
      return overrideKey;
    }

    // 1. SharedPreferences custom override if configured
    try {
      final prefs = await SharedPreferences.getInstance();
      final customKey = prefs.getString('gemini_api_key');
      if (customKey != null && customKey.trim().isNotEmpty) {
        return customKey.trim();
      }
    } catch (_) {}

    // 2. Primary from .env
    final envKey = dotenv.env['GEMINI_API_KEY'] ?? dotenv.env['VITE_GEMINI_API_KEY'];
    if (envKey != null && envKey.trim().isNotEmpty) {
      return envKey.trim();
    }

    // 3. Compile-time --dart-define parameter
    const dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');
    if (dartDefineKey.isNotEmpty) {
      return dartDefineKey;
    }

    // 4. Fallback constant
    return AppConstants.defaultGeminiApiKey;
  }

  /// Request personalized meteorological advice from Google Gemini API (gemini-2.5-flash)
  /// with multi-turn conversation memory, multimodal image/document analysis, and full token allowance.
  static Future<String> getAdvice({
    required String userPrompt,
    List<ChatMessage>? conversationHistory,
    List<ChatAttachment>? attachments,
    PersonaType? persona,
    String? cityName,
    double? temperature,
    double? apparentTemperature,
    int? humidity,
    int? aqi,
    double? uvIndex,
    WeatherTelemetry? telemetry,
    AirQualityData? airQuality,
    MarineData? marineData,
    int? rainProbability,
    String? apiKeyOverride,
  }) async {
    final apiKey = await getApiKey(apiKeyOverride);
    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set in .env. Please configure GEMINI_API_KEY in your .env file.');
    }

    // Resolve context values
    final personaType = persona ?? PersonaType.health;
    final resolvedCity = cityName ?? telemetry?.cityName ?? 'Current Location';
    final resolvedTemp = temperature ?? telemetry?.currentTemperature ?? 28.0;
    final resolvedApparentTemp = apparentTemperature ?? telemetry?.apparentTemperature ?? resolvedTemp;
    final resolvedHumidity = humidity ?? telemetry?.humidity ?? 65;
    final resolvedAqi = aqi ?? airQuality?.aqi ?? 42;
    final resolvedUv = uvIndex ?? telemetry?.uvIndex ?? 0.0;
    final resolvedRainProb = rainProbability ?? (telemetry != null ? (telemetry.precipitation > 0 ? 60 : 10) : 10);

    final int currentHour = DateTime.now().hour;
    final bool isNight = currentHour < 6 || currentHour >= 19;
    final bool zeroUv = resolvedUv <= 0.5;

    // Construct hyper-local system instruction
    final systemPrompt = '''
You are Mausam AdvisorAI, an expert hyper-local meteorological, lifestyle intelligence, and multimodal environmental assistant.

Current User & Weather Context:
- Active Persona: ${personaType.displayName} (${personaType.subtitle})
- City / Location: $resolvedCity
- Current Temperature: ${resolvedTemp.round()}°C (Feels like: ${resolvedApparentTemp.round()}°C)
- Relative Humidity: $resolvedHumidity%
- Air Quality Index (AQI): $resolvedAqi (PM2.5: ${airQuality?.pm2_5.toStringAsFixed(1) ?? '14.2'} µg/m³)
- UV Index: ${resolvedUv.toStringAsFixed(1)} (${(zeroUv || isNight) ? '0 Low / Nighttime' : 'Active Solar Radiation'})
- Time of Day: ${isNight ? 'Nighttime' : 'Daytime'}
- Rain Probability: $resolvedRainProb%
- Wind Speed & Direction: ${telemetry?.windSpeed.round() ?? 12} km/h ${telemetry?.windDirectionCardinal ?? 'S'} (Gusts: ${telemetry?.windGusts.round() ?? 15} km/h)
- Weather Condition: ${telemetry?.weatherCondition ?? 'Clear'}
- Root Soil Moisture (0-7cm): ${telemetry?.soilMoisture.toStringAsFixed(2) ?? '0.24'} m³/m³
- Coastal Wave Height: ${marineData?.waveHeight.toStringAsFixed(1) ?? '1.2'}m

Strict Operational Guidelines:
1. MINIMAL & CONCISE: Answer in maximum 2 to 3 short, direct sentences. Be brief and to the point.
2. NO ROBOTIC FILLER: Do NOT say "Hello! Welcome...", "I'm your assistant...", or closing questions like "How can I help you today?". Go directly to the answer.
3. MULTIMODAL CAPABILITY: If the user provides an image or document, carefully analyze the visual/documentary evidence (e.g. cloud formations, crop health, weather charts, tickets, damage photos) and integrate it directly into your meteorological advisory.
4. If providing tips or action items, provide at most 2 short bullet points starting with "- " (under 8 words each).
5. If the UV index is 0 or it is nighttime, never recommend sunscreen, hats, or daytime UV protection.
6. Multi-turn Memory: Remember previous messages, travel routes, dates, and details from this chat conversation.
7. Use 1-2 appropriate weather emojis naturally.
''';

    // Build multi-turn contents ensuring valid role alternation (user -> model -> user)
    final List<Map<String, dynamic>> contents = [];

    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final validHistory = conversationHistory.where((m) =>
        m.text.trim().isNotEmpty && !m.text.startsWith('⚠️')
      ).toList();

      final firstUserIndex = validHistory.indexWhere((m) => m.isUser);
      if (firstUserIndex != -1) {
        final turns = validHistory.sublist(firstUserIndex);
        final recentTurns = turns.length > 10 ? turns.sublist(turns.length - 10) : turns;

        for (final msg in recentTurns) {
          final role = msg.isUser ? 'user' : 'model';
          final List<Map<String, dynamic>> msgParts = [
            {'text': msg.text.trim()}
          ];

          // Add inline data for historical attachments if any
          if (msg.attachments.isNotEmpty) {
            for (final att in msg.attachments) {
              if (att.base64Data.isNotEmpty) {
                msgParts.add({
                  'inline_data': {
                    'mime_type': att.mimeType,
                    'data': att.base64Data,
                  }
                });
              }
            }
          }

          if (contents.isNotEmpty && contents.last['role'] == role) {
            final existingParts = contents.last['parts'] as List<dynamic>;
            existingParts.addAll(msgParts);
          } else {
            contents.add({
              'role': role,
              'parts': msgParts,
            });
          }
        }
      }
    }

    // Build current user message parts with text and attachments
    final List<Map<String, dynamic>> currentUserParts = [
      {'text': userPrompt.isNotEmpty ? userPrompt : 'Please analyze this attachment with hyper-local weather context.'}
    ];

    if (attachments != null && attachments.isNotEmpty) {
      for (final att in attachments) {
        if (att.base64Data.isNotEmpty) {
          currentUserParts.add({
            'inline_data': {
              'mime_type': att.mimeType,
              'data': att.base64Data,
            }
          });
        }
      }
    }

    if (contents.isNotEmpty && contents.last['role'] == 'user') {
      final existingParts = contents.last['parts'] as List<dynamic>;
      existingParts.addAll(currentUserParts);
    } else {
      contents.add({
        'role': 'user',
        'parts': currentUserParts,
      });
    }

    final primaryUri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );
    final fallbackUri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent?key=$apiKey',
    );

    final requestPayload = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.4,
        'maxOutputTokens': 2048,
      }
    };

    final requestBodyJson = jsonEncode(requestPayload);

    // Logging outgoing request
    final maskedKey = apiKey.length > 8
        ? '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}'
        : '***';
    debugPrint('[GeminiService] Outgoing POST Request to gemini-2.5-flash (key: $maskedKey)');
    debugPrint('[GeminiService] Request Body Payload: $requestBodyJson');

    try {
      var response = await _client
          .post(
            primaryUri,
            headers: {'Content-Type': 'application/json'},
            body: requestBodyJson,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[GeminiService] HTTP Status Code: ${response.statusCode}');

      // If gemini-2.5-flash is unavailable (404 model migration), fallback to gemini-3.6-flash
      if (response.statusCode == 404) {
        debugPrint('[GeminiService] gemini-2.5-flash returned 404, retrying with gemini-3.6-flash...');
        response = await _client
            .post(
              fallbackUri,
              headers: {'Content-Type': 'application/json'},
              body: requestBodyJson,
            )
            .timeout(const Duration(seconds: 15));

        debugPrint('[GeminiService fallback] HTTP Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final candidate = candidates[0] as Map<String, dynamic>;
          final content = candidate['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        }
        throw Exception('Gemini API returned 200 OK but candidate text was empty.');
      } else {
        String errorMsg = response.body;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['error'] != null && decoded['error']['message'] != null) {
            errorMsg = decoded['error']['message'];
          }
        } catch (_) {}
        throw Exception('Gemini API Error (HTTP ${response.statusCode}): $errorMsg');
      }
    } catch (e) {
      debugPrint('[GeminiService Error] $e');
      rethrow;
    }
  }

  /// Generate a concise, intelligent 2-4 word conversation title using Gemini AI
  static Future<String?> generateChatTitle({
    required String userPrompt,
    required String aiResponse,
    String? cityName,
    String? persona,
  }) async {
    try {
      final apiKey = await getApiKey();
      if (apiKey.isEmpty) return null;

      final titlePrompt = '''
You are a concise conversation title generator for Gemini AI weather chat.
Given the following user query and AI advice, generate a short, relevant, 2 to 4 word title in Title Case (e.g., "Surat Evening Forecast", "Running Safety Window", "UV & Skin Protection", "Crop Moisture Advisory").
Rules:
1. Return ONLY the 2 to 4 words title.
2. Do NOT use quotes, emojis, or punctuation.
3. Keep it professional and relevant.

User Query: $userPrompt
AI Response: $aiResponse
Context: City: $cityName, Persona: $persona

Title:''';

      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
      );

      final payload = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': titlePrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2,
          'maxOutputTokens': 30,
        }
      };

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final candidate = candidates[0] as Map<String, dynamic>;
          final content = candidate['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              final clean = text
                  .replaceAll('"', '')
                  .replaceAll("'", '')
                  .replaceAll('.', '')
                  .replaceAll('Title:', '')
                  .replaceAll('\n', ' ')
                  .trim();
              if (clean.isNotEmpty && clean.length <= 40) {
                return clean;
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Extract bullet action items from response text
  static List<String> extractActionItems(String text) {
    final List<String> items = [];
    final lines = text.split('\n');
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('• ')) {
        final item = trimmed.substring(2).trim();
        if (item.isNotEmpty) {
          items.add(item);
        }
      }
    }
    return items;
  }

  /// Structured helper returning Map for backwards compatibility
  static Future<Map<String, dynamic>> generateAdvice({
    required String userPrompt,
    List<ChatMessage>? conversationHistory,
    List<ChatAttachment>? attachments,
    required PersonaType persona,
    required WeatherTelemetry telemetry,
    required AirQualityData airQuality,
    MarineData? marineData,
    int rainProbability = 10,
    String? apiKeyOverride,
  }) async {
    final text = await getAdvice(
      userPrompt: userPrompt,
      conversationHistory: conversationHistory,
      attachments: attachments,
      persona: persona,
      cityName: telemetry.cityName,
      temperature: telemetry.currentTemperature,
      apparentTemperature: telemetry.apparentTemperature,
      humidity: telemetry.humidity,
      aqi: airQuality.aqi,
      uvIndex: telemetry.uvIndex,
      telemetry: telemetry,
      airQuality: airQuality,
      marineData: marineData,
      rainProbability: rainProbability,
      apiKeyOverride: apiKeyOverride,
    );

    final actionItems = extractActionItems(text);

    return {
      'text': text,
      'isOffline': false,
      'actionItems': actionItems,
    };
  }
}

/// Backwards-compatibility client wrapper
class GeminiClientService {
  Future<Map<String, dynamic>> generateAdvice({
    required String userPrompt,
    List<ChatMessage>? conversationHistory,
    List<ChatAttachment>? attachments,
    required PersonaType persona,
    required WeatherTelemetry telemetry,
    required AirQualityData airQuality,
    MarineData? marineData,
    int rainProbability = 10,
  }) =>
      GeminiService.generateAdvice(
        userPrompt: userPrompt,
        conversationHistory: conversationHistory,
        attachments: attachments,
        persona: persona,
        telemetry: telemetry,
        airQuality: airQuality,
        marineData: marineData,
        rainProbability: rainProbability,
      );
}
