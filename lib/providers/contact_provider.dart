import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../features/chat/services/contact_service.dart';
import '../models/user.dart';
import '../models/conversation.dart';

class ContactProvider extends ChangeNotifier {
  final ContactService _contactService = ContactService();

  List<User> _users = [];
  bool _isSearching = false;
  bool _isCreatingConversation = false;
  String? _errorMessage;

  List<User> get users => _users;
  bool get isSearching => _isSearching;
  bool get isCreatingConversation => _isCreatingConversation;
  String? get errorMessage => _errorMessage;

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _users = [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _contactService.searchUsers(query.trim());
    } on DioException catch (error) {
      _errorMessage =
          error.response?.data?['message'] ?? 'Unable to search users.';

      _users = [];
    } catch (_) {
      _errorMessage = 'Something went wrong.';
      _users = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  Future<Conversation?> createConversation(String participantId) async {
    _isCreatingConversation = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final conversation = await _contactService.createConversation(
        participantId,
      );

      _isCreatingConversation = false;
      notifyListeners();

      return conversation;
    } on DioException catch (error) {
      _errorMessage =
          error.response?.data?['message'] ?? 'Unable to create conversation.';
    } catch (_) {
      _errorMessage = 'Something went wrong.';
    }

    _isCreatingConversation = false;
    notifyListeners();

    return null;
  }

  void clearUsers() {
    _users = [];
    _errorMessage = null;
    notifyListeners();
  }
}
