import 'chat_attachment.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? persona;
  final List<String> actionItems;
  final List<ChatAttachment> attachments;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.persona,
    this.actionItems = const [],
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'persona': persona,
    'actionItems': actionItems,
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    text: json['text'] ?? '',
    isUser: json['isUser'] ?? false,
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
        : DateTime.now(),
    persona: json['persona'],
    actionItems: (json['actionItems'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    attachments: (json['attachments'] as List<dynamic>?)
            ?.map((a) => ChatAttachment.fromJson(a as Map<String, dynamic>))
            .toList() ??
        [],
  );
}
