import 'package:dio/dio.dart';

import '../../../../core/services/api_service.dart';
import '../../../../models/conversation.dart';
import '../../../../features/auth/services/auth_service.dart';

class ConversationService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<List<Conversation>> getConversations() async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception('You are not logged in');
    }

    final response = await _apiService.dio.get(
      '/conversations',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final List<dynamic> conversationsJson = response.data['conversations'];

    return conversationsJson
        .map(
          (conversation) =>
              Conversation.fromJson(conversation as Map<String, dynamic>),
        )
        .toList();
  }
}
