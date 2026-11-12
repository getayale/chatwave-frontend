import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/services/api_service.dart';
import '../../../models/user.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Register a new user
  Future<User> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _apiService.dio.post(
      '/auth/register',
      data: {
        'username': username,
        'email': email,
        'password': password,
        'displayName': displayName,
      },
    );

    return User.fromJson(response.data['user']);
  }

  // Log in an existing user
  Future<User> login({required String email, required String password}) async {
    final response = await _apiService.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final String token = response.data['token'];

    await _storage.write(key: 'auth_token', value: token);

    return User.fromJson(response.data['user']);
  }

  // Retrieve the saved JWT
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Get the currently authenticated user
  Future<User> getCurrentUser() async {
    final token = await getToken();

    if (token == null) {
      throw Exception('You are not logged in');
    }

    final response = await _apiService.dio.get(
      '/auth/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return User.fromJson(response.data['user']);
  }

  // Log out
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<User> updateProfile({
    required String displayName,
    required String bio,
    required String avatarUrl,
  }) async {
    final token = await getToken();

    if (token == null) {
      throw Exception('You are not logged in');
    }

    final response = await _apiService.dio.patch(
      '/users/me',
      data: {
        'displayName': displayName,
        'bio': bio,
        'avatarUrl': avatarUrl.isEmpty ? null : avatarUrl,
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return User.fromJson(response.data['user']);
  }
}
