import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'routing/app_router.dart';

class ChatWaveApp extends StatefulWidget {
  const ChatWaveApp({super.key});

  @override
  State<ChatWaveApp> createState() => _ChatWaveAppState();
}

class _ChatWaveAppState extends State<ChatWaveApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    final authProvider = context.read<AuthProvider>();

    _router = createAppRouter(authProvider);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChatWave',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      routerConfig: _router,
    );
  }
}
