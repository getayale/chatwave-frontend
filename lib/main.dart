import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/socket_service.dart';
import 'providers/auth_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/message_provider.dart';
import 'providers/contact_provider.dart';

void main() {
  final socketService = SocketService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(socketService: socketService)..checkAuthStatus(),
        ),
        ChangeNotifierProvider(
          create: (_) => ConversationProvider(socketService: socketService),
        ),
        ChangeNotifierProvider(
          create: (_) => MessageProvider(socketService: socketService),
        ),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
      ],
      child: const ChatWaveApp(),
    ),
  );
}
