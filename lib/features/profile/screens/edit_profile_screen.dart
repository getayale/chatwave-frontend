import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final user = context.read<AuthProvider>().user;

    _displayNameController.text = user?.displayName ?? '';
    _bioController.text = user?.bio ?? '';

    if (user != null) {
      context.read<ProfileProvider>().setInitialProfileVisibility(
        user.profileVisibility,
      );
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await context.read<AuthProvider>().updateProfile(
      displayName: _displayNameController.text.trim(),
      bio: _bioController.text.trim(),
      avatarUrl: '',
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.of(context).pop();
    } else {
      final errorMessage =
          context.read<AuthProvider>().errorMessage ??
          'Unable to update profile.';

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<void> _changeVisibility(bool isPublic) async {
    final visibility = isPublic ? 'PUBLIC' : 'PRIVATE';

    final success = await context
        .read<ProfileProvider>()
        .updateProfileVisibility(visibility);

    if (!mounted) return;

    final message = success
        ? 'Profile visibility changed to $visibility'
        : context.read<ProfileProvider>().errorMessage ??
              'Unable to update profile visibility';

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Display name must have at least 2 characters.';
                  }

                  if (value.trim().length > 40) {
                    return 'Display name cannot exceed 40 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell people something about yourself...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              const Divider(),

              const SizedBox(height: 10),

              const Text(
                'Profile Photo Visibility',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Choose who can see your profile photos.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 10),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  profileProvider.isProfilePublic
                      ? Icons.public
                      : Icons.lock_outline,
                ),
                title: Text(
                  profileProvider.isProfilePublic ? 'Public' : 'Private',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  profileProvider.isProfilePublic
                      ? 'Other users can view your profile photos.'
                      : 'Only you can view your profile photos.',
                ),
                value: profileProvider.isProfilePublic,
                onChanged: profileProvider.isUpdatingVisibility
                    ? null
                    : _changeVisibility,
              ),

              if (profileProvider.isUpdatingVisibility)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: LinearProgressIndicator(),
                ),

              const SizedBox(height: 20),

              const Divider(),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: authProvider.isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
