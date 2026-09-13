class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? persona;
  final List<String> actionItems;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.persona,
    this.actionItems = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'persona': persona,
    'actionItems': actionItems,
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
  );
}
