import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/conversation_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    context.read<ConversationProvider>().clearConversations();

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),

          Center(
            child: CircleAvatar(
              radius: 55,
              backgroundImage:
                  user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 55)
                  : null,
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              user.displayName,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 5),

          Center(
            child: Text(
              '@${user.username}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ),

          const SizedBox(height: 25),

          OutlinedButton.icon(
            onPressed: () {
              context.push('/edit-profile');
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Account Information',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _buildInfoTile(
            icon: Icons.person_outline,
            title: 'Display Name',
            value: user.displayName,
          ),

          _buildInfoTile(
            icon: Icons.alternate_email,
            title: 'Username',
            value: '@${user.username}',
          ),

          _buildInfoTile(
            icon: Icons.email_outlined,
            title: 'Email',
            value: user.email ?? 'Not available',
          ),

          _buildInfoTile(
            icon: Icons.info_outline,
            title: 'Bio',
            value: user.bio?.isNotEmpty == true
                ? user.bio!
                : 'No bio added yet',
          ),

          const SizedBox(height: 30),

          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            context.go('/chats');
          } else if (index == 1) {
            context.go('/contacts');
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

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value),
    );
  }
}
