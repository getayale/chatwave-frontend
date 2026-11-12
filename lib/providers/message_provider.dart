import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../core/services/socket_service.dart';
import '../features/chat/services/message_service.dart';
import '../models/message.dart';

class MessageProvider extends ChangeNotifier {
  final MessageService _messageService = MessageService();
  final SocketService _socketService;

  MessageProvider({required SocketService socketService})
    : _socketService = socketService;

  List<Message> _messages = [];

  bool _isLoading = false;
  bool _isSending = false;
  bool _isMarkingAsRead = false;

  String? _errorMessage;
  String? _activeConversationId;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isMarkingAsRead => _isMarkingAsRead;
  String? get errorMessage => _errorMessage;

  void _addMessage(Message message) {
    final alreadyExists = _messages.any(
      (existing) => existing.id == message.id,
    );

    if (alreadyExists) return;

    _messages.add(message);

    _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    notifyListeners();
  }

  void _handleIncomingMessage(Message message) {
    if (message.conversationId != _activeConversationId) return;

    _addMessage(message);
  }

  void connectToConversation(String conversationId) {
    if (_activeConversationId == conversationId) return;

    if (_activeConversationId != null) {
      _socketService.leaveConversation(_activeConversationId!);
    }

    _socketService.stopListeningForNewMessages();

    _messages = [];
    _errorMessage = null;
    _activeConversationId = conversationId;

    _socketService.listenForNewMessages(_handleIncomingMessage);
    _socketService.joinConversation(conversationId);

    notifyListeners();
  }

  void disconnectFromConversation() {
    if (_activeConversationId != null) {
      _socketService.leaveConversation(_activeConversationId!);
    }

    _socketService.stopListeningForNewMessages();

    _activeConversationId = null;
  }

  Future<void> fetchMessages(String conversationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedMessages = await _messageService.getMessages(conversationId);

      if (_activeConversationId == conversationId) {
        final messageMap = {
          for (final message in _messages) message.id: message,
          for (final message in fetchedMessages) message.id: message,
        };

        _messages = messageMap.values.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
    } on DioException catch (error) {
      _errorMessage =
          error.response?.data?['message'] ?? 'Unable to load messages.';
    } catch (error) {
      _errorMessage = 'Something went wrong.';
      debugPrint('Fetch messages error: $error');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    if (content.trim().isEmpty) return false;

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await _messageService.sendMessage(
        conversationId: conversationId,
        content: content.trim(),
      );

      _addMessage(message);

      _isSending = false;
      notifyListeners();

      return true;
    } on DioException catch (error) {
      _errorMessage =
          error.response?.data?['message'] ?? 'Unable to send message.';
    } catch (error) {
      _errorMessage = 'Something went wrong.';
      debugPrint('Send message error: $error');
    }

    _isSending = false;
    notifyListeners();

    return false;
  }

  Future<bool> markMessagesAsRead(String conversationId) async {
    _isMarkingAsRead = true;
    notifyListeners();

    try {
      await _messageService.markMessagesAsRead(conversationId);

      _isMarkingAsRead = false;
      notifyListeners();

      return true;
    } on DioException catch (error) {
      _errorMessage =
          error.response?.data?['message'] ??
          'Unable to mark messages as read.';
    } catch (error) {
      _errorMessage = 'Something went wrong.';
      debugPrint('Mark messages as read error: $error');
    }

    _isMarkingAsRead = false;
    notifyListeners();

    return false;
  }

  Future<List<Map<String, dynamic>>> getMessageReadReceipts(
    String messageId,
  ) async {
    try {
      return await _messageService.getMessageReadReceipts(messageId);
    } on DioException catch (error) {
      _errorMessage =
          error.response?.data?['message'] ?? 'Unable to load read receipts.';
    } catch (error) {
      _errorMessage = 'Something went wrong.';
      debugPrint('Read receipts error: $error');
    }

    notifyListeners();
    return [];
  }

  void clearMessages() {
    _messages = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnectFromConversation();
    super.dispose();
  }
}
