import 'dart:convert';
import 'dart:typed_data';

class ChatAttachment {
  final String id;
  final String name;
  final String mimeType;
  final String base64Data;
  final bool isImage;
  final int sizeBytes;
  final String? localPath;

  ChatAttachment({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.base64Data,
    required this.isImage,
    required this.sizeBytes,
    this.localPath,
  });

  Uint8List get bytes => base64Decode(base64Data);

  String get fileName => name;
  int get fileSizeBytes => sizeBytes;
  String get formattedSize => humanReadableSize;

  String get humanReadableSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mimeType': mimeType,
    'base64Data': base64Data,
    'isImage': isImage,
    'sizeBytes': sizeBytes,
    'localPath': localPath,
  };

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => ChatAttachment(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: json['name'] ?? 'attachment',
    mimeType: json['mimeType'] ?? 'image/jpeg',
    base64Data: json['base64Data'] ?? '',
    isImage: json['isImage'] ?? true,
    sizeBytes: json['sizeBytes'] ?? 0,
    localPath: json['localPath'],
  );
}
