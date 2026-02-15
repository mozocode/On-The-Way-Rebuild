import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, location, system }

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final MessageType type;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final bool read;
  final DateTime? timestamp;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.read = false,
    this.timestamp,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: _parseMessageType(data['type']),
      imageUrl: data['imageUrl'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      read: data['read'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  static MessageType _parseMessageType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'location':
        return MessageType.location;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }
}
