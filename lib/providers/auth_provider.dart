import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/services/socket_service.dart';
import '../features/auth/services/auth_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SocketService _socketService;

  AuthProvider({required SocketService socketService})
    : _socketService = socketService;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  Set<String> _onlineUserIds = {};

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _user != null;

  Set<String> get onlineUserIds => Set.unmodifiable(_onlineUserIds);

  bool isUserOnline(String userId) {
    return _onlineUserIds.contains(userId);
  }

  Future<void> _connectSocket() async {
    final token = await _authService.getToken();

    if (token == null) return;

    _socketService.connect(
      token: token,
      serverUrl: ApiConstants.socketUrl,
      onPresenceChanged: (onlineUserIds) {
        // Create a modifiable copy of the received set.
        _onlineUserIds = Set<String>.from(onlineUserIds);
        notifyListeners();
      },
    );
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _authService.getToken();

      if (token != null) {
        _user = await _authService.getCurrentUser();
        await _connectSocket();
      } else {
        _user = null;
        _onlineUserIds = {};
      }
    } catch (error) {
      debugPrint('Auth status error: $error');

      _socketService.disconnect();
      _onlineUserIds = {};
      _user = null;

      try {
        await _authService.logout();
      } catch (storageError) {
        debugPrint('Unable to clear stored token: $storageError');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.login(email: email, password: password);

      await _connectSocket();

      _isLoading = false;
      notifyListeners();

      return true;
    } on DioException catch (error) {
      _errorMessage =
          error.response?.data?['message'] ??
          'Unable to log in. Please try again.';
    } catch (error) {
      debugPrint('Login error: $error');
      _errorMessage = 'Something went wrong. Please try again.';
    }

    _isLoading = false;
    notifyListeners();

    return false;
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(
        username: username,
        email: email,
        password: password,
        displayName: displayName,
      );

      _isLoading = false;
      notifyListeners();

      return true;
    } on DioException catch (error) {
      _errorMessage =
          error.response?.data?['message'] ??
          'Unable to register. Please try again.';
    } catch (error) {
      debugPrint('Registration error: $error');
      _errorMessage = 'Something went wrong. Please try again.';
    }

    _isLoading = false;
    notifyListeners();

    return false;
  }

  Future<void> logout() async {
    // Disconnect the Socket.IO connection.
    _socketService.disconnect();

    // Replace the set instead of modifying an unmodifiable set.
    _onlineUserIds = {};

    // Clear authentication state immediately.
    _user = null;
    _errorMessage = null;

    // Notify GoRouter and other listeners.
    notifyListeners();

    // Delete the saved authentication token.
    try {
      await _authService.logout();
    } catch (error) {
      debugPrint('Logout storage error: $error');
      rethrow;
    }
  }

  Future<bool> updateProfile({
    required String displayName,
    required String bio,
    required String avatarUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.updateProfile(
        displayName: displayName,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      _isLoading = false;
      notifyListeners();

      return true;
    } on DioException catch (error) {
      _errorMessage =
          error.response?.data?['message'] ??
          'Unable to update profile. Please try again.';
    } catch (error) {
      debugPrint('Profile update error: $error');
      _errorMessage = 'Something went wrong. Please try again.';
    }

    _isLoading = false;
    notifyListeners();

    return false;
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}
