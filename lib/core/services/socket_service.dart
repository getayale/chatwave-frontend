import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../models/message.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  SocketService._internal();

  IO.Socket? _socket;

  final Set<String> _onlineUserIds = {};
  final Set<String> _joinedConversationIds = {};

  void Function(Map<String, dynamic>)? _onMessageRead;

  IO.Socket? get socket => _socket;

  Set<String> get onlineUserIds => Set.unmodifiable(_onlineUserIds);

  void connect({
    required String token,
    required String serverUrl,
    required void Function(Set<String>) onPresenceChanged,
  }) {
    if (_socket?.connected == true || _socket?.active == true) {
      return;
    }

    _socket?.dispose();

    _onlineUserIds.clear();

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('Socket connected: ${_socket!.id}');

      // Rejoin previously requested conversations.
      for (final conversationId in _joinedConversationIds) {
        _socket!.emit('conversation:join', conversationId);
      }

      // Register the read-receipt listener after connecting.
      _registerMessageReadListener();
    });

    _socket!.onConnectError((error) {
      print('Socket connection error: $error');
    });

    _socket!.on('presence:online-users', (data) {
      if (data is! Map || data['userIds'] is! List) {
        return;
      }

      _onlineUserIds
        ..clear()
        ..addAll((data['userIds'] as List).whereType<String>());

      onPresenceChanged(onlineUserIds);
    });

    _socket!.on('presence:online', (data) {
      if (data is! Map || data['userId'] is! String) {
        return;
      }

      _onlineUserIds.add(data['userId'] as String);

      onPresenceChanged(onlineUserIds);
    });

    _socket!.on('presence:offline', (data) {
      if (data is! Map || data['userId'] is! String) {
        return;
      }

      _onlineUserIds.remove(data['userId'] as String);

      onPresenceChanged(onlineUserIds);
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');

      _onlineUserIds.clear();

      onPresenceChanged(onlineUserIds);
    });

    _socket!.connect();
  }

  // Register the saved read-receipt callback.
  void _registerMessageReadListener() {
    if (_socket == null || _onMessageRead == null) {
      return;
    }

    _socket!.off('message:read');

    _socket!.on('message:read', (data) {
      if (data is! Map) {
        return;
      }

      try {
        final eventData = Map<String, dynamic>.from(data);

        if (eventData['conversationId'] is! String ||
            eventData['userId'] is! String ||
            eventData['messageIds'] is! List) {
          return;
        }

        _onMessageRead?.call(eventData);
      } catch (error) {
        print('Unable to parse read receipt event: $error');
      }
    });
  }

  void joinConversation(String conversationId) {
    _joinedConversationIds.add(conversationId);

    if (_socket?.connected == true) {
      _socket!.emit('conversation:join', conversationId);
    }
  }

  void leaveConversation(String conversationId) {
    _joinedConversationIds.remove(conversationId);

    if (_socket?.connected == true) {
      _socket!.emit('conversation:leave', conversationId);
    }
  }

  void listenForNewMessages(void Function(Message) onMessage) {
    _socket?.off('message:new');

    _socket?.on('message:new', (data) {
      if (data is! Map) {
        return;
      }

      try {
        final message = Message.fromJson(Map<String, dynamic>.from(data));

        onMessage(message);
      } catch (error) {
        print('Unable to parse incoming message: $error');
      }
    });
  }

  void stopListeningForNewMessages() {
    _socket?.off('message:new');
  }

  // Save the callback, even if the socket is not connected yet.
  void listenForMessageRead(void Function(Map<String, dynamic>) onRead) {
    _onMessageRead = onRead;

    if (_socket?.connected == true) {
      _registerMessageReadListener();
    }
  }

  // Remove the callback and its socket listener.
  void stopListeningForMessageRead() {
    _onMessageRead = null;
    _socket?.off('message:read');
  }

  void disconnect() {
    _joinedConversationIds.clear();

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    _onlineUserIds.clear();
  }
}
