import 'package:flutter_test/flutter_test.dart';
import 'package:mausam/models/chat_attachment.dart';
import 'package:mausam/models/chat_message.dart';
import 'package:mausam/models/chat_session.dart';

void main() {
  group('ChatAttachment Tests', () {
    test('ChatAttachment serialization and getters work correctly', () {
      final attachment = ChatAttachment(
        id: 'att_123',
        name: 'test_photo.jpg',
        mimeType: 'image/jpeg',
        base64Data: 'dGVzdGRhdGE=',
        isImage: true,
        sizeBytes: 2048,
      );

      expect(attachment.fileName, equals('test_photo.jpg'));
      expect(attachment.formattedSize, equals('2.0 KB'));
      expect(attachment.bytes.isNotEmpty, isTrue);

      final json = attachment.toJson();
      final restored = ChatAttachment.fromJson(json);

      expect(restored.id, equals('att_123'));
      expect(restored.name, equals('test_photo.jpg'));
      expect(restored.mimeType, equals('image/jpeg'));
      expect(restored.sizeBytes, equals(2048));
      expect(restored.isImage, isTrue);
    });
  });

  group('ChatSession Tests', () {
    test('ChatSession serialization and message nesting work properly', () {
      final session = ChatSession(
        id: 'session_999',
        title: 'Running Advice in Pune',
        createdAt: DateTime(2026, 9, 15, 10, 0),
        updatedAt: DateTime(2026, 9, 15, 10, 5),
        persona: 'Fitness',
        messages: [
          ChatMessage(
            id: 'm1',
            text: 'Is it good for running today?',
            isUser: true,
            timestamp: DateTime(2026, 9, 15, 10, 0),
            attachments: [
              ChatAttachment(
                id: 'att_1',
                name: 'sky.png',
                mimeType: 'image/png',
                base64Data: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
                isImage: true,
                sizeBytes: 68,
              ),
            ],
          ),
          ChatMessage(
            id: 'm2',
            text: 'Conditions are optimal with 24°C and AQI 35.',
            isUser: false,
            timestamp: DateTime(2026, 9, 15, 10, 1),
            actionItems: ['Hydrate beforehand', 'Wear running shoes'],
          ),
        ],
      );

      final json = session.toJson();
      final restored = ChatSession.fromJson(json);

      expect(restored.id, equals('session_999'));
      expect(restored.title, equals('Running Advice in Pune'));
      expect(restored.persona, equals('Fitness'));
      expect(restored.messages.length, equals(2));
      expect(restored.messages[0].attachments.length, equals(1));
      expect(restored.messages[0].attachments[0].name, equals('sky.png'));
      expect(restored.messages[1].actionItems.length, equals(2));
    });
  });
}
