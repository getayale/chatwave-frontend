import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../core/services/socket_service.dart';
import '../features/chat/services/conversation_service.dart';
import '../models/conversation.dart';

class ConversationProvider extends ChangeNotifier {
  final ConversationService _conversationService = ConversationService();
  final SocketService _socketService;

  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;

  ConversationProvider({required SocketService socketService})
    : _socketService = socketService {
    _socketService.listenForMessageRead(_handleMessageRead);
  }

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchConversations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _conversations = await _conversationService.getConversations();
    } on DioException catch (error) {
      _errorMessage =
          error.response?.data?['message'] ?? 'Unable to load conversations.';
    } catch (_) {
      _errorMessage = 'Something went wrong.';
    }

    _isLoading = false;
    notifyListeners();
  }

  void _handleMessageRead(Map<String, dynamic> event) {
    final conversationId = event['conversationId'];
    final userId = event['userId'];
    final messageIds = event['messageIds'];
    final readAt = event['readAt'];

    if (conversationId is! String ||
        userId is! String ||
        messageIds is! List ||
        readAt is! String) {
      return;
    }

    final conversationIndex = _conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );

    if (conversationIndex == -1) return;

    final conversation = _conversations[conversationIndex];

    if (conversation.lastMessageId == null ||
        !messageIds.contains(conversation.lastMessageId)) {
      return;
    }

    final alreadyRead = conversation.lastMessageReadReceipts.any(
      (receipt) => receipt['userId'] == userId,
    );

    if (alreadyRead) return;

    final updatedReceipts = [
      ...conversation.lastMessageReadReceipts,
      {'userId': userId, 'readAt': readAt},
    ];

    final updatedConversation = Conversation(
      id: conversation.id,
      participants: conversation.participants,
      lastMessageId: conversation.lastMessageId,
      lastMessage: conversation.lastMessage,
      lastMessageSenderId: conversation.lastMessageSenderId,
      lastMessageAt: conversation.lastMessageAt,
      lastMessageReadReceipts: updatedReceipts,
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
    );

    _conversations[conversationIndex] = updatedConversation;

    notifyListeners();
  }

  void clearConversations() {
    _conversations = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _socketService.stopListeningForMessageRead();
    super.dispose();
  }
}
