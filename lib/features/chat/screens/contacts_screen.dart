import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/contact_provider.dart';
import '../../../providers/conversation_provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openConversation(User user) async {
    final contactProvider = context.read<ContactProvider>();

    final conversation = await contactProvider.createConversation(user.id);

    if (!mounted) return;

    if (conversation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            contactProvider.errorMessage ?? 'Unable to open conversation.',
          ),
        ),
      );
      return;
    }

    await context.read<ConversationProvider>().fetchConversations();

    if (!mounted) return;

    context.push(
      '/chat',
      extra: {'otherUser': user, 'conversationId': conversation.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactProvider = context.watch<ContactProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contacts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          _buildSearchField(contactProvider),
          Expanded(child: _buildContactList(contactProvider, authProvider)),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            context.go('/chats');
          } else if (index == 2) {
            context.go('/profile');
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
            activeIcon: Icon(Icons.people),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ContactProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<ContactProvider>().searchUsers(value);
        },
        decoration: InputDecoration(
          hintText: 'Search by name or username...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    provider.clearUsers();
                    setState(() {});
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

  Widget _buildContactList(
    ContactProvider provider,
    AuthProvider authProvider,
  ) {
    if (_searchController.text.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Find your people',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Search by name or username to get started.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (provider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!));
    }

    if (provider.users.isEmpty) {
      return const Center(child: Text('No users found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: provider.users.length,
      separatorBuilder: (context, index) {
        return const Divider(indent: 72);
      },
      itemBuilder: (context, index) {
        final user = provider.users[index];

        return _buildContactTile(user, provider, authProvider);
      },
    );
  }

  Widget _buildContactTile(
    User user,
    ContactProvider provider,
    AuthProvider authProvider,
  ) {
    final isOnline = authProvider.isUserOnline(user.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundImage:
                user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: isOnline ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        isOnline ? '@${user.username} · Online' : '@${user.username} · Offline',
        style: TextStyle(color: isOnline ? Colors.green : Colors.grey),
      ),
      trailing: provider.isCreatingConversation
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chat_outlined),
      onTap: provider.isCreatingConversation
          ? null
          : () => _openConversation(user),
    );
  }
}
