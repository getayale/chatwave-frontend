import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/profile_photo.dart';
import '../features/profile/services/profile_photo_service.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfilePhotoService _profilePhotoService = ProfilePhotoService();

  List<ProfilePhoto> _photos = [];
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isDeleting = false;
  String? _deletingPhotoId;
  String? _errorMessage;

  // Profile visibility state.
  String _profileVisibility = 'PUBLIC';
  bool _isUpdatingVisibility = false;

  List<ProfilePhoto> get photos => _photos;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  bool get isDeleting => _isDeleting;
  String? get deletingPhotoId => _deletingPhotoId;
  String? get errorMessage => _errorMessage;

  String get profileVisibility => _profileVisibility;
  bool get isUpdatingVisibility => _isUpdatingVisibility;

  bool get isProfilePublic => _profileVisibility == 'PUBLIC';

  // Set the initial visibility obtained from the authenticated user's data.
  void setInitialProfileVisibility(String visibility) {
    if (visibility == 'PUBLIC' || visibility == 'PRIVATE') {
      _profileVisibility = visibility;
      notifyListeners();
    }
  }

  // Update profile visibility.
  Future<bool> updateProfileVisibility(String visibility) async {
    if (visibility != 'PUBLIC' && visibility != 'PRIVATE') {
      _errorMessage = 'Invalid profile visibility';
      notifyListeners();
      return false;
    }

    if (_isUpdatingVisibility) return false;

    _isUpdatingVisibility = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedVisibility = await _profilePhotoService
          .updateProfileVisibility(visibility);

      _profileVisibility = updatedVisibility;

      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isUpdatingVisibility = false;
      notifyListeners();
    }
  }

  // Retrieve profile photos.
  Future<void> fetchProfilePhotos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _photos = await _profilePhotoService.fetchProfilePhotos();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Retrieve another user's profile photos without changing own photos.
  Future<List<ProfilePhoto>> fetchUserProfilePhotos(String userId) async {
    try {
      return await _profilePhotoService.fetchProfilePhotos(userId: userId);
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Upload selected profile photos.
  Future<bool> uploadProfilePhotos(List<XFile> files) async {
    if (files.isEmpty) {
      _errorMessage = 'Please select at least one photo';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uploadedPhotos = await _profilePhotoService.uploadProfilePhotos(
        files,
      );

      _photos = [...uploadedPhotos, ..._photos];

      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // Delete a profile photo.
  Future<bool> deleteProfilePhoto(String photoId) async {
    if (_isDeleting) return false;

    _isDeleting = true;
    _deletingPhotoId = photoId;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profilePhotoService.deleteProfilePhoto(photoId);

      _photos.removeWhere((photo) => photo.id == photoId);

      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isDeleting = false;
      _deletingPhotoId = null;
      notifyListeners();
    }
  }

  // Download a profile photo.
  Future<void> downloadProfilePhoto(String imageUrl) async {
    try {
      await _profilePhotoService.downloadProfilePhoto(imageUrl);
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Build complete image URL.
  String getPhotoUrl(String imageUrl) {
    return _profilePhotoService.getProfilePhotoUrl(imageUrl);
  }

  // Retrieve profile photo bytes with authentication.
  Future<Uint8List> fetchProfilePhotoBytes(String imageUrl) async {
    return await _profilePhotoService.fetchProfilePhotoBytes(imageUrl);
  }
}
