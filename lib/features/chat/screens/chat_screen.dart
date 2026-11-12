import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/message_provider.dart';

class ChatScreen extends StatefulWidget {
  final User otherUser;
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.otherUser,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final messageProvider = context.read<MessageProvider>();

      // Start listening and join the Socket.IO room.
      messageProvider.connectToConversation(widget.conversationId);

      // Load previous messages.
      await messageProvider.fetchMessages(widget.conversationId);

      if (!mounted) return;

      // Mark received messages as read.
      await messageProvider.markMessagesAsRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    context.read<MessageProvider>().disconnectFromConversation();

    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();

    if (content.isEmpty) {
      return;
    }

    final messageProvider = context.read<MessageProvider>();

    final success = await messageProvider.sendMessage(
      conversationId: widget.conversationId,
      content: content,
    );

    if (!mounted) return;

    if (success) {
      _messageController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageProvider = context.watch<MessageProvider>();
    final currentUser = context.watch<AuthProvider>().user;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messageProvider.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  widget.otherUser.avatarUrl != null &&
                      widget.otherUser.avatarUrl!.isNotEmpty
                  ? NetworkImage(widget.otherUser.avatarUrl!)
                  : null,
              child:
                  widget.otherUser.avatarUrl == null ||
                      widget.otherUser.avatarUrl!.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUser.displayName,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(messageProvider, currentUser?.id)),

          if (messageProvider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                messageProvider.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          _buildMessageInput(messageProvider.isSending),
        ],
      ),
    );
  }

  Widget _buildMessageList(MessageProvider provider, String? currentUserId) {
    if (provider.isLoading && provider.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                provider.fetchMessages(widget.conversationId);
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (provider.messages.isEmpty) {
      return const Center(
        child: Text('No messages yet. Start the conversation!'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];

        final isMine = message.isSentBy(currentUserId ?? '');

        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMine
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message.content),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.formatMessageTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(bool isSending) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) {
                  if (!isSending) {
                    _sendMessage();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending ? null : _sendMessage,
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
