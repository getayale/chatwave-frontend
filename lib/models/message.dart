class Message {
  final String id;
  final String content;
  final String senderId;
  final String conversationId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRead;

  const Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.conversationId,
    required this.createdAt,
    required this.updatedAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      senderId: json['senderId'],
      conversationId: json['conversationId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isRead: json['isRead'] == true,
    );
  }

  bool isSentBy(String userId) {
    return senderId == userId;
  }

  Message copyWith({bool? isRead}) {
    return Message(
      id: id,
      content: content,
      senderId: senderId,
      conversationId: conversationId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
