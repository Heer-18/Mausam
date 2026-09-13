import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/services/gemini_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(mergeWith: {
      'GEMINI_API_KEY': 'test_gemini_api_key_12345',
      'API_BASE_URL': 'http://127.0.0.1:8000',
    });
  });

  group('GeminiService Tests', () {
    test('getApiKey retrieves key from dotenv testLoad', () async {
      final key = await GeminiService.getApiKey();
      expect(key, equals('test_gemini_api_key_12345'));
    });

    test('extractActionItems parses bullet points properly', () {
      const responseText = '''
Here is your meteorological advice for your evening run.
- Wear reflective running gear
* Keep hydrated with electrolytes
• Perform a 5-minute cool down
Enjoy your workout!
''';
      final actionItems = GeminiService.extractActionItems(responseText);
      expect(actionItems.length, equals(3));
      expect(actionItems[0], equals('Wear reflective running gear'));
      expect(actionItems[1], equals('Keep hydrated with electrolytes'));
      expect(actionItems[2], equals('Perform a 5-minute cool down'));
    });
  });
}
