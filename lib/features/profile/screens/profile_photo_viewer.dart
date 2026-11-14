import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/profile_photo.dart';
import '../../../providers/profile_provider.dart';

class ProfilePhotoViewer extends StatefulWidget {
  final List<ProfilePhoto> photos;
  final int initialIndex;

  const ProfilePhotoViewer({
    super.key,
    required this.photos,
    this.initialIndex = 0,
  });

  @override
  State<ProfilePhotoViewer> createState() => _ProfilePhotoViewerState();
}

class _ProfilePhotoViewerState extends State<ProfilePhotoViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  // Cache image requests to avoid fetching the same photo repeatedly.
  final Map<String, Future<Uint8List>> _photoFutures = {};

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Retrieve and cache photo bytes.
  Future<Uint8List> _getPhotoBytes(String imageUrl) {
    return _photoFutures.putIfAbsent(
      imageUrl,
      () => context.read<ProfileProvider>().fetchProfilePhotoBytes(imageUrl),
    );
  }

  // Download the currently displayed photo.
  Future<void> _downloadPhoto() async {
    final photos = context.read<ProfileProvider>().photos;

    if (_currentIndex >= photos.length) return;

    final photo = photos[_currentIndex];

    try {
      await context.read<ProfileProvider>().downloadProfilePhoto(
        photo.imageUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo downloaded successfully')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to download photo: $error')),
      );
    }
  }

  // Show photo actions.
  void _showPhotoMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF252525),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.download_outlined,
                  color: Colors.white,
                ),
                title: const Text(
                  'Download photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _downloadPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeletePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Confirm and delete the currently displayed photo.
  Future<void> _confirmDeletePhoto() async {
    final photos = context.read<ProfileProvider>().photos;

    if (_currentIndex >= photos.length) return;

    final photo = photos[_currentIndex];

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete photo?'),
          content: const Text(
            'Are you sure you want to delete this profile photo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    final success = await context.read<ProfileProvider>().deleteProfilePhoto(
      photo.id,
    );

    if (!mounted) return;

    if (success) {
      final remainingPhotos = context.read<ProfileProvider>().photos;

      if (remainingPhotos.isEmpty) {
        Navigator.pop(context);
        return;
      }

      final nextIndex = _currentIndex >= remainingPhotos.length
          ? remainingPhotos.length - 1
          : _currentIndex;

      setState(() {
        _currentIndex = nextIndex;
      });

      _pageController.jumpToPage(nextIndex);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<ProfileProvider>().errorMessage ??
                'Unable to delete photo',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = context.watch<ProfileProvider>().photos;

    if (photos.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No profile photos available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipeable photos.
          PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final photo = photos[index];

              return FutureBuilder<Uint8List>(
                future: _getPhotoBytes(photo.imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 60,
                      ),
                    );
                  }

                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Center(
                      child: Image.memory(snapshot.data!, fit: BoxFit.contain),
                    ),
                  );
                },
              );
            },
          ),

          // Top controls.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Text(
                    '${_currentIndex + 1} / ${photos.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: _showPhotoMenu,
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
