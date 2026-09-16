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

/// Exception thrown when all configured Gemini API keys have exceeded their quota / rate limits.
class GeminiQuotaExceededException implements Exception {
  final int totalKeysTested;
  final String message;
  final String? lastRawError;

  GeminiQuotaExceededException({
    required this.totalKeysTested,
    required this.message,
    this.lastRawError,
  });

  @override
  String toString() => message;
}

class GeminiService {
  static final http.Client _client = http.Client();
  static int _activeKeyIndex = 0;

  /// Retrieve all available Gemini API keys from .env, shared preferences, and environment variables
  static Future<List<String>> getAllApiKeys([String? overrideKey]) async {
    final List<String> keys = [];

    // 1. Explicit override parameter
    if (overrideKey != null && overrideKey.trim().isNotEmpty) {
      keys.add(overrideKey.trim());
    }

    // 2. SharedPreferences custom user-configured keys
    try {
      final prefs = await SharedPreferences.getInstance();
      final customKey = prefs.getString('gemini_api_key');
      if (customKey != null && customKey.trim().isNotEmpty) {
        keys.addAll(_splitKeys(customKey));
      }
      final customKeysList = prefs.getStringList('gemini_api_keys');
      if (customKeysList != null) {
        for (final k in customKeysList) {
          if (k.trim().isNotEmpty) keys.add(k.trim());
        }
      }
    } catch (_) {}

    // 3. Comma / Semicolon separated GEMINI_API_KEYS in .env
    final envMultiKeys = dotenv.env['GEMINI_API_KEYS'];
    if (envMultiKeys != null && envMultiKeys.trim().isNotEmpty) {
      keys.addAll(_splitKeys(envMultiKeys));
    }

    // 4. Primary GEMINI_API_KEY / VITE_GEMINI_API_KEY in .env
    final envKey = dotenv.env['GEMINI_API_KEY'];
    if (envKey != null && envKey.trim().isNotEmpty) {
      keys.addAll(_splitKeys(envKey));
    }
    final viteKey = dotenv.env['VITE_GEMINI_API_KEY'];
    if (viteKey != null && viteKey.trim().isNotEmpty) {
      keys.addAll(_splitKeys(viteKey));
    }

    // 5. Numbered env keys: GEMINI_API_KEY_1, GEMINI_API_KEY_2, etc.
    for (int i = 1; i <= 10; i++) {
      final numberedKey = dotenv.env['GEMINI_API_KEY_$i'];
      if (numberedKey != null && numberedKey.trim().isNotEmpty) {
        keys.add(numberedKey.trim());
      }
    }

    // 6. Compile-time --dart-define parameter
    const dartDefineKey = String.fromEnvironment('GEMINI_API_KEY');
    if (dartDefineKey.isNotEmpty) {
      keys.addAll(_splitKeys(dartDefineKey));
    }

    // 7. Fallback constant
    if (AppConstants.defaultGeminiApiKey.isNotEmpty) {
      keys.add(AppConstants.defaultGeminiApiKey);
    }

    // Deduplicate and filter non-empty
    final uniqueKeys = <String>[];
    for (final k in keys) {
      final trimmed = k.trim();
      if (trimmed.isNotEmpty && !uniqueKeys.contains(trimmed)) {
        uniqueKeys.add(trimmed);
      }
    }

    return uniqueKeys;
  }

  /// Helper to split comma, semicolon, or newline delimited key strings
  static List<String> _splitKeys(String raw) {
    return raw
        .split(RegExp(r'[,;\n\r\t]+'))
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();
  }

  /// Mask key for secure debugging
  static String _maskKey(String key) {
    if (key.length <= 8) return '***';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  /// Request personalized meteorological advice from Google Gemini API
  /// with automatic Multi-Key Rotation and Failover upon HTTP 429 / Quota Exhaustion.
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
    final allKeys = await getAllApiKeys(apiKeyOverride);
    if (allKeys.isEmpty) {
      throw Exception('GEMINI_API_KEY is not configured. Please add GEMINI_API_KEYS=key1,key2 to your .env file.');
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

    // Construct hyper-local system instruction with natural conversational greetings support
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

Operational Guidelines:
1. NATURAL GREETINGS: If the user says hello, hi, good morning/evening, or greets you, warmly greet them back in a friendly tone (e.g. "Hello! Good morning! It's currently ${resolvedTemp.round()}°C and ${telemetry?.weatherCondition ?? 'Clear'} in $resolvedCity. How can I help you today?").
2. CONCISE & PRACTICAL: Give direct, helpful answers in 2 to 4 sentences. Avoid repetitive corporate filler.
3. CONTEXT INTEGRATION: Weave in relevant weather conditions (temperature, rain window, UV protection, humidity, wind) whenever it relates to their questions or plans.
4. ACTION ITEMS: If providing tips or action items, include at most 2-3 short bullet points starting with "- " (under 10 words each).
5. NIGHT & ZERO UV: If it is nighttime or UV is 0, do NOT advise sunscreen or sunglasses.
6. MULTIMODAL CAPABILITY: If an image or document is attached, analyze the visual/documentary evidence with meteorological insight.
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

    // Build current user message parts
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

    final requestPayload = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.5,
        'maxOutputTokens': 2048,
      }
    };

    final requestBodyJson = jsonEncode(requestPayload);

    // Multi-key and multi-model failover loop
    String? lastErrorMessage;
    int quotaExhaustedCount = 0;

    for (int attempt = 0; attempt < allKeys.length; attempt++) {
      final keyIndex = (_activeKeyIndex + attempt) % allKeys.length;
      final currentApiKey = allKeys[keyIndex];

      debugPrint('[GeminiService] Attempting key ${attempt + 1}/${allKeys.length} (${_maskKey(currentApiKey)})');

      bool keyQuotaExhausted = false;

      for (final model in candidateModels) {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$currentApiKey',
        );

        try {
          final response = await _client
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: requestBodyJson,
              )
              .timeout(const Duration(seconds: 15));

          // If model is not found (404), fall back to next candidate model immediately
          if (response.statusCode == 404) {
            debugPrint('[GeminiService] Model $model returned 404 for key #${keyIndex + 1}, trying next candidate model...');
            lastErrorMessage = 'HTTP 404: Model $model not found';
            continue;
          }

          // Check for 200 OK
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
                  // Success! Set this as the active key for subsequent calls
                  _activeKeyIndex = keyIndex;
                  return text.trim();
                }
              }
            }
          }

          // Rate Limit / Quota Exceeded (HTTP 429) or Resource Exhausted
          final isQuotaError = response.statusCode == 429 ||
              response.body.contains('RESOURCE_EXHAUSTED') ||
              response.body.toLowerCase().contains('quota exceeded') ||
              response.body.toLowerCase().contains('rate limit');

          if (isQuotaError) {
            keyQuotaExhausted = true;
            quotaExhaustedCount++;
            debugPrint('[GeminiService] Key #${keyIndex + 1} (${_maskKey(currentApiKey)}) exceeded quota (HTTP ${response.statusCode}). Rotating to next key...');
            lastErrorMessage = 'HTTP ${response.statusCode} Quota Exceeded: ${response.body}';
            break; // Stop trying models on this key, rotate to next API key
          }

          // Other HTTP error
          String errorMsg = response.body;
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map && decoded['error'] != null && decoded['error']['message'] != null) {
              errorMsg = decoded['error']['message'];
            }
          } catch (_) {}

          lastErrorMessage = 'HTTP ${response.statusCode}: $errorMsg';
          debugPrint('[GeminiService] Error with model $model on key #${keyIndex + 1}: $lastErrorMessage');
        } catch (e) {
          debugPrint('[GeminiService] Exception with model $model on key #${keyIndex + 1}: $e');
          lastErrorMessage = e.toString();
        }
      }

      if (keyQuotaExhausted) {
        continue;
      }
    }

    // If all keys failed
    if (quotaExhaustedCount > 0 && quotaExhaustedCount >= allKeys.length) {
      throw GeminiQuotaExceededException(
        totalKeysTested: allKeys.length,
        message: 'All $quotaExhaustedCount configured Gemini API keys have exceeded their current quota / rate limit.',
        lastRawError: lastErrorMessage,
      );
    }

    throw Exception('Gemini API request failed across all ${allKeys.length} configured keys. Last error: $lastErrorMessage');
  }

  /// Candidate Gemini models prioritized from most modern to fallback
  static const List<String> candidateModels = [
    'gemini-3.6-flash',
    'gemini-3.7-flash',
    'gemini-3.5-flash',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-1.5-pro',
  ];

  /// Generate a concise conversation title with multi-key support
  static Future<String?> generateChatTitle({
    required String userPrompt,
    required String aiResponse,
    String? cityName,
    String? persona,
  }) async {
    try {
      final allKeys = await getAllApiKeys();
      if (allKeys.isEmpty) return null;
      final apiKey = allKeys[_activeKeyIndex % allKeys.length];

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

      for (final model in candidateModels) {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

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
        } else if (response.statusCode == 404) {
          continue;
        } else {
          break;
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
