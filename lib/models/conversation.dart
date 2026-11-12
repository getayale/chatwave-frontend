import 'user.dart';

class Conversation {
  final String id;
  final List<User> participants;
  final String? lastMessageId;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final List<Map<String, dynamic>> lastMessageReadReceipts;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.participants,
    this.lastMessageId,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageAt,
    this.lastMessageReadReceipts = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final messages = json['messages'] as List<dynamic>? ?? [];

    final latestMessage = messages.isNotEmpty
        ? messages.first as Map<String, dynamic>
        : null;

    final readReceipts = latestMessage?['readReceipts'] as List<dynamic>? ?? [];

    return Conversation(
      id: json['id'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map(
            (participant) =>
                User.fromJson(participant['user'] as Map<String, dynamic>),
          )
          .toList(),
      lastMessageId: latestMessage?['id'] as String?,
      lastMessage: latestMessage?['content'] as String?,
      lastMessageSenderId: latestMessage?['senderId'] as String?,
      lastMessageAt: latestMessage?['createdAt'] != null
          ? DateTime.parse(latestMessage!['createdAt'] as String)
          : null,
      lastMessageReadReceipts: readReceipts
          .map((receipt) => receipt as Map<String, dynamic>)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
