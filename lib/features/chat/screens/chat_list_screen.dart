import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../models/conversation.dart';
import '../../../models/user.dart';
import '../../../models/profile_photo.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/conversation_provider.dart';
import '../../../providers/profile_provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ConversationProvider>().fetchConversations();
      context.read<ProfileProvider>().fetchProfilePhotos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  User? getOtherParticipant(Conversation conversation, String currentUserId) {
    for (final participant in conversation.participants) {
      if (participant.id != currentUserId) {
        return participant;
      }
    }

    return null;
  }

  List<Conversation> _filterConversations(
    List<Conversation> conversations,
    String currentUserId,
  ) {
    if (_searchQuery.trim().isEmpty) {
      return conversations;
    }

    final query = _searchQuery.toLowerCase().trim();

    return conversations.where((conversation) {
      final otherUser = getOtherParticipant(conversation, currentUserId);

      if (otherUser == null) {
        return false;
      }

      return otherUser.displayName.toLowerCase().contains(query) ||
          otherUser.username.toLowerCase().contains(query) ||
          (conversation.lastMessage ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _logout() async {
    try {
      final auth = context.read<AuthProvider>();

      await auth.logout();

      if (!mounted) return;

      context.read<ConversationProvider>().clearConversations();

      context.go('/login');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Logout failed: $error')));
    }
  }

  bool _isLastMessageRead(Conversation conversation, String otherUserId) {
    return conversation.lastMessageReadReceipts.any(
      (receipt) => receipt['userId'] == otherUserId,
    );
  }

  Widget _buildMessagePreview(
    Conversation conversation,
    User otherUser,
    String currentUserId,
  ) {
    final message = conversation.lastMessage;

    if (message == null || message.isEmpty) {
      return const Text(
        'Start a conversation',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final isSentByMe = conversation.lastMessageSenderId == currentUserId;

    final isRead = isSentByMe && _isLastMessageRead(conversation, otherUser.id);

    final senderName = isSentByMe ? 'You' : otherUser.displayName;

    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$senderName: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: message),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isSentByMe) ...[
          const SizedBox(width: 5),
          Icon(
            isRead ? Icons.done_all : Icons.done,
            size: 17,
            color: isRead ? Colors.blue : Colors.grey,
          ),
        ],
      ],
    );
  }

  // Online/Offline indicator for another user.
  Widget _buildPresenceIndicator(bool isOnline) {
    final color = isOnline ? Colors.green : Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Current user's profile avatar in the AppBar.
  Widget _buildCurrentUserAvatar(User user) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        final firstPhoto = profileProvider.photos.isNotEmpty
            ? profileProvider.photos.first
            : null;

        return GestureDetector(
          onTap: () {
            context.push('/profile');
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: firstPhoto == null
                ? CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: const Icon(Icons.person),
                  )
                : _ChatProfileAvatar(
                    key: ValueKey(firstPhoto.imageUrl),
                    imageUrl: firstPhoto.imageUrl,
                    loadPhoto: profileProvider.fetchProfilePhotoBytes,
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conversationProvider = context.watch<ConversationProvider>();

    final currentUser = auth.user;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to continue.')),
      );
    }

    final filteredConversations = _filterConversations(
      conversationProvider.conversations,
      currentUser.id,
    );

    return Scaffold(
      appBar: AppBar(
        leading: _buildCurrentUserAvatar(currentUser),
        title: const Text(
          'ChatWave',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh conversations',
            onPressed: conversationProvider.isLoading
                ? null
                : conversationProvider.fetchConversations,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(currentUser),
          _buildSearchField(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${filteredConversations.length} chats',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildConversationBody(
              conversationProvider,
              filteredConversations,
              currentUser.id,
              auth,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            context.push('/contacts');
          } else if (index == 2) {
            context.push('/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            user.displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Stay connected with your people.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.close),
                )
              : null,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationBody(
    ConversationProvider provider,
    List<Conversation> conversations,
    String currentUserId,
    AuthProvider auth,
  ) {
    if (provider.isLoading && provider.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(provider.errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: provider.fetchConversations,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _searchQuery.isEmpty
                  ? Icons.chat_bubble_outline
                  : Icons.search_off,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'No conversations yet.'
                  : 'No matching conversations found.',
              style: const TextStyle(fontSize: 16),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 6),
              const Text(
                'Your conversations will appear here.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.fetchConversations,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: conversations.length,
        separatorBuilder: (context, index) {
          return const Divider(height: 1, indent: 76);
        },
        itemBuilder: (context, index) {
          final conversation = conversations[index];

          final otherUser = getOtherParticipant(conversation, currentUserId);

          if (otherUser == null) {
            return const SizedBox.shrink();
          }

          final isOnline = auth.isUserOnline(otherUser.id);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            leading: _OtherUserAvatar(
              key: ValueKey(otherUser.id),
              userId: otherUser.id,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    otherUser.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                _buildPresenceIndicator(isOnline),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: _buildMessagePreview(
                conversation,
                otherUser,
                currentUserId,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 22),
            onTap: () {
              context.push(
                '/chat',
                extra: {
                  'otherUser': otherUser,
                  'conversationId': conversation.id,
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Loads another user's public profile photo.
class _OtherUserAvatar extends StatefulWidget {
  final String userId;

  const _OtherUserAvatar({super.key, required this.userId});

  @override
  State<_OtherUserAvatar> createState() => _OtherUserAvatarState();
}

class _OtherUserAvatarState extends State<_OtherUserAvatar> {
  Future<Uint8List>? _photoFuture;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    try {
      final profileProvider = context.read<ProfileProvider>();

      final List<ProfilePhoto> photos = await profileProvider
          .fetchUserProfilePhotos(widget.userId);

      if (!mounted) return;

      if (photos.isNotEmpty) {
        final photoFuture = profileProvider.fetchProfilePhotoBytes(
          photos.first.imageUrl,
        );

        setState(() {
          _photoFuture = photoFuture;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _photoFuture = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CircleAvatar(
        radius: 27,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_photoFuture == null) {
      return const CircleAvatar(
        radius: 27,
        child: Icon(Icons.person, size: 28),
      );
    }

    return FutureBuilder<Uint8List>(
      future: _photoFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return CircleAvatar(
            radius: 27,
            backgroundImage: MemoryImage(snapshot.data!),
          );
        }

        if (snapshot.hasError) {
          return const CircleAvatar(
            radius: 27,
            child: Icon(Icons.person, size: 28),
          );
        }

        return CircleAvatar(
          radius: 27,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

// Small authenticated profile avatar for the ChatWave AppBar.
class _ChatProfileAvatar extends StatefulWidget {
  final String imageUrl;
  final Future<Uint8List> Function(String imageUrl) loadPhoto;

  const _ChatProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.loadPhoto,
  });

  @override
  State<_ChatProfileAvatar> createState() => _ChatProfileAvatarState();
}

class _ChatProfileAvatarState extends State<_ChatProfileAvatar> {
  late Future<Uint8List> _photoFuture;

  @override
  void initState() {
    super.initState();
    _photoFuture = widget.loadPhoto(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant _ChatProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imageUrl != widget.imageUrl) {
      _photoFuture = widget.loadPhoto(widget.imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _photoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.person, size: 22),
          );
        }

        return CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(snapshot.data!),
        );
      },
    );
  }
}
