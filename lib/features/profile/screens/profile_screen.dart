import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/conversation_provider.dart';
import '../../../providers/profile_provider.dart';
import 'profile_photo_viewer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      context.read<ProfileProvider>().fetchProfilePhotos();
    });
  }

  // Select and upload profile photos.
  Future<void> _pickAndUploadPhotos() async {
    try {
      final ImagePicker picker = ImagePicker();

      final List<XFile> selectedPhotos = await picker.pickMultiImage();

      if (selectedPhotos.isEmpty) return;

      if (selectedPhotos.length > 5) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can select a maximum of 5 photos.'),
          ),
        );

        return;
      }

      if (!mounted) return;

      final success = await context.read<ProfileProvider>().uploadProfilePhotos(
        selectedPhotos,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile photos uploaded successfully!'
                : context.read<ProfileProvider>().errorMessage ??
                      'Photo upload failed.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to select photos: $error')),
      );
    }
  }

  // Log out the current user.
  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();

    if (!context.mounted) return;

    context.read<ConversationProvider>().clearConversations();

    context.go('/login');
  }

  // Open the full-screen photo viewer.
  void _openPhotoViewer(ProfileProvider profileProvider) {
    if (profileProvider.photos.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfilePhotoViewer(photos: profileProvider.photos, initialIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final profileProvider = context.watch<ProfileProvider>();

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firstPhoto = profileProvider.photos.isNotEmpty
        ? profileProvider.photos.first
        : null;

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

          // Profile photo with full-screen viewer navigation.
          Center(
            child: GestureDetector(
              onTap: firstPhoto == null
                  ? null
                  : () => _openPhotoViewer(profileProvider),
              child: firstPhoto == null
                  ? CircleAvatar(
                      radius: 55,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: const Icon(Icons.person, size: 55),
                    )
                  : AuthenticatedProfileAvatar(
                      key: ValueKey(firstPhoto.imageUrl),
                      imageUrl: firstPhoto.imageUrl,
                      loadPhoto: profileProvider.fetchProfilePhotoBytes,
                    ),
            ),
          ),

          const SizedBox(height: 10),

          // Upload profile photos.
          Center(
            child: TextButton.icon(
              onPressed: profileProvider.isUploading
                  ? null
                  : _pickAndUploadPhotos,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add Profile Photos'),
            ),
          ),

          if (profileProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(),
              ),
            ),

          if (profileProvider.isUploading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Uploading photos...', textAlign: TextAlign.center),
          ],

          if (profileProvider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                profileProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          if (profileProvider.photos.isNotEmpty)
            Center(
              child: Text(
                '${profileProvider.photos.length} profile photo(s)',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),

          const SizedBox(height: 16),

          // User display name.
          Center(
            child: Text(
              user.displayName,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 5),

          // Username.
          Center(
            child: Text(
              '@${user.username}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ),

          const SizedBox(height: 25),

          // Edit profile.
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

          // Logout.
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

      // Bottom navigation.
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

  // Reusable account information tile.
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

// Authenticated profile image widget.
class AuthenticatedProfileAvatar extends StatefulWidget {
  final String imageUrl;
  final Future<Uint8List> Function(String imageUrl) loadPhoto;

  const AuthenticatedProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.loadPhoto,
  });

  @override
  State<AuthenticatedProfileAvatar> createState() =>
      _AuthenticatedProfileAvatarState();
}

class _AuthenticatedProfileAvatarState
    extends State<AuthenticatedProfileAvatar> {
  late Future<Uint8List> _photoFuture;

  @override
  void initState() {
    super.initState();

    _photoFuture = widget.loadPhoto(widget.imageUrl);
  }

  @override
  void didUpdateWidget(covariant AuthenticatedProfileAvatar oldWidget) {
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
            radius: 55,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return CircleAvatar(
            radius: 55,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: const Icon(Icons.person, size: 55),
          );
        }

        return CircleAvatar(
          radius: 55,
          backgroundImage: MemoryImage(snapshot.data!),
        );
      },
    );
  }
}
