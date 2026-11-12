import 'package:dio/dio.dart';

import '../../../core/services/api_service.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../models/user.dart';
import '../../../models/conversation.dart';

class ContactService {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Future<String> _getToken() async {
    final token = await _authService.getToken();

    if (token == null) {
      throw Exception('You are not logged in');
    }

    return token;
  }

  Future<List<User>> searchUsers(String query) async {
    final token = await _getToken();

    final response = await _apiService.dio.get(
      '/users/search',
      queryParameters: {'q': query},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final List<dynamic> usersJson = response.data['users'];

    return usersJson
        .map((user) => User.fromJson(user as Map<String, dynamic>))
        .toList();
  }

  Future<Conversation> createConversation(String participantId) async {
    final token = await _getToken();

    final response = await _apiService.dio.post(
      '/conversations',
      data: {'participantId': participantId},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return Conversation.fromJson(
      response.data['conversation'] as Map<String, dynamic>,
    );
  }
}
