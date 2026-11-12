import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../models/message.dart';

class MessageService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<String> _getToken() async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception('You are not logged in');
    }

    return token;
  }

  // Get conversation messages
  Future<List<Message>> getMessages(String conversationId) async {
    final token = await _getToken();

    final response = await _apiService.dio.get(
      '/conversations/$conversationId/messages',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final List<dynamic> messagesJson = response.data['messages'];

    return messagesJson
        .map((message) => Message.fromJson(message as Map<String, dynamic>))
        .toList();
  }

  // Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final token = await _getToken();

    final response = await _apiService.dio.post(
      '/conversations/$conversationId/messages',
      data: {'content': content},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return Message.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // Mark conversation messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final token = await _getToken();

    await _apiService.dio.patch(
      '/conversations/$conversationId/read',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // Get read receipts for a message
  Future<List<Map<String, dynamic>>> getMessageReadReceipts(
    String messageId,
  ) async {
    final token = await _getToken();

    final response = await _apiService.dio.get(
      '/messages/$messageId/read-receipts',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final List<dynamic> receiptsJson = response.data['readReceipts'];

    return receiptsJson
        .map((receipt) => receipt as Map<String, dynamic>)
        .toList();
  }
}
