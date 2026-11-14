import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_saver/file_saver.dart';

import '../../../core/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../models/profile_photo.dart';

class ProfilePhotoService {
  final ApiService _apiService = ApiService();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Retrieve profile photos belonging to the authenticated user
  // or another user when a userId is provided.
  Future<List<ProfilePhoto>> fetchProfilePhotos({String? userId}) async {
    debugPrint('========== FETCH PROFILE PHOTOS ==========');

    try {
      final token = await _storage.read(key: 'auth_token');

      if (token == null) {
        throw Exception('You are not logged in');
      }

      final response = await _apiService.dio.get(
        '/users/profile-photos',
        queryParameters: userId != null ? {'userId': userId} : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final List<dynamic> photos = response.data['photos'];

      debugPrint('Fetch status: ${response.statusCode}');
      debugPrint('Requested user: ${userId ?? 'Current user'}');
      debugPrint('Photos received: ${photos.length}');
      debugPrint('==========================================');

      return photos.map((photo) => ProfilePhoto.fromJson(photo)).toList();
    } catch (error) {
      debugPrint('FETCH PHOTOS ERROR: $error');
      rethrow;
    }
  }

  // Update the authenticated user's profile photo visibility.
  Future<String> updateProfileVisibility(String profileVisibility) async {
    debugPrint('========== UPDATE PROFILE VISIBILITY ==========');

    try {
      if (profileVisibility != 'PUBLIC' && profileVisibility != 'PRIVATE') {
        throw Exception('Invalid profile visibility');
      }

      final token = await _storage.read(key: 'auth_token');

      if (token == null) {
        throw Exception('You are not logged in');
      }

      final response = await _apiService.dio.patch(
        '/users/profile-visibility',
        data: {'profileVisibility': profileVisibility},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final updatedVisibility =
          response.data['user']['profileVisibility'] as String;

      debugPrint('Visibility status: ${response.statusCode}');
      debugPrint('Updated visibility: $updatedVisibility');
      debugPrint('================================================');

      return updatedVisibility;
    } on DioException catch (error) {
      debugPrint('UPDATE VISIBILITY ERROR');
      debugPrint('Status: ${error.response?.statusCode}');
      debugPrint('Response: ${error.response?.data}');
      rethrow;
    } catch (error) {
      debugPrint('UPDATE VISIBILITY ERROR: $error');
      rethrow;
    }
  }

  // Upload profile photos to the backend.
  Future<List<ProfilePhoto>> uploadProfilePhotos(
    List<XFile> selectedFiles,
  ) async {
    debugPrint('========== UPLOAD PROFILE PHOTOS ==========');

    try {
      if (selectedFiles.isEmpty) {
        throw Exception('Please select at least one photo');
      }

      if (selectedFiles.length > 5) {
        throw Exception('You can upload a maximum of 5 photos');
      }

      final token = await _storage.read(key: 'auth_token');

      if (token == null) {
        throw Exception('You are not logged in');
      }

      final multipartFiles = await Future.wait(
        selectedFiles.map((file) async {
          debugPrint('Preparing file: ${file.name}');

          return MultipartFile.fromBytes(
            await file.readAsBytes(),
            filename: file.name,
          );
        }),
      );

      final formData = FormData.fromMap({'photos': multipartFiles});

      final response = await _apiService.dio.post(
        '/users/profile-photos',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: Headers.multipartFormDataContentType,
        ),
      );

      final List<dynamic> photos = response.data['photos'];

      debugPrint('Upload status: ${response.statusCode}');
      debugPrint('Uploaded photos: ${photos.length}');
      debugPrint('===========================================');

      return photos.map((photo) => ProfilePhoto.fromJson(photo)).toList();
    } catch (error) {
      debugPrint('UPLOAD PHOTOS ERROR: $error');
      rethrow;
    }
  }

  // Delete a profile photo.
  Future<void> deleteProfilePhoto(String photoId) async {
    debugPrint('========== DELETE PROFILE PHOTO ==========');
    debugPrint('Photo ID: $photoId');

    try {
      final token = await _storage.read(key: 'auth_token');

      if (token == null) {
        throw Exception('You are not logged in');
      }

      final response = await _apiService.dio.delete(
        '/users/profile-photos/$photoId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('Delete status: ${response.statusCode}');
      debugPrint('Profile photo deleted successfully');
      debugPrint('==========================================');
    } on DioException catch (error) {
      debugPrint('DELETE PHOTO ERROR');
      debugPrint('Status: ${error.response?.statusCode}');
      debugPrint('Response: ${error.response?.data}');
      rethrow;
    } catch (error) {
      debugPrint('DELETE PHOTO ERROR: $error');
      rethrow;
    }
  }

  // Build the complete image URL.
  String getProfilePhotoUrl(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }

    final baseUrl = ApiConstants.baseUrl.replaceFirst('/api', '');
    final completeUrl = '$baseUrl$imageUrl';

    debugPrint('Constructed photo URL: $completeUrl');

    return completeUrl;
  }

  // Retrieve an image using the authenticated user's JWT token.
  Future<Uint8List> fetchProfilePhotoBytes(String imageUrl) async {
    debugPrint('========== FETCH PROFILE PHOTO IMAGE ==========');

    try {
      final token = await _storage.read(key: 'auth_token');

      if (token == null) {
        throw Exception('You are not logged in');
      }

      final completeUrl = getProfilePhotoUrl(imageUrl);

      final response = await _apiService.dio.get<List<int>>(
        completeUrl,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
        ),
      );

      debugPrint('Image response status: ${response.statusCode}');
      debugPrint(
        'Image content type: ${response.headers.value('content-type')}',
      );
      debugPrint('Image bytes received: ${response.data?.length ?? 0}');

      if (response.data == null || response.data!.isEmpty) {
        throw Exception('Unable to load profile photo');
      }

      debugPrint('PHOTO IMAGE LOADED SUCCESSFULLY');
      debugPrint('================================================');

      return Uint8List.fromList(response.data!);
    } on DioException catch (error) {
      debugPrint('PHOTO DIO ERROR: ${error.message}');
      debugPrint('Response status: ${error.response?.statusCode}');
      debugPrint('Response data: ${error.response?.data}');
      rethrow;
    } catch (error) {
      debugPrint('PHOTO IMAGE ERROR: $error');
      rethrow;
    }
  }

  // Download and save a profile photo on Web and Android.
  Future<void> downloadProfilePhoto(String imageUrl) async {
    debugPrint('========== DOWNLOAD PROFILE PHOTO ==========');

    try {
      final imageBytes = await fetchProfilePhotoBytes(imageUrl);

      final uri = Uri.parse(imageUrl);
      final originalFileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : '';

      final detectedExtension = originalFileName.contains('.')
          ? originalFileName.split('.').last.toLowerCase()
          : 'jpg';

      const supportedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

      final extension = supportedExtensions.contains(detectedExtension)
          ? detectedExtension
          : 'jpg';

      final mimeType = extension == 'jpg' || extension == 'jpeg'
          ? 'image/jpeg'
          : 'image/$extension';

      final fileName = originalFileName
          .replaceAll(RegExp(r'\.[^.]+$'), '')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      await FileSaver.instance.saveToDownloads(
        name: fileName.isEmpty ? 'profile_photo' : fileName,
        bytes: imageBytes,
        fileExtension: extension,
        mimeType: MimeType.custom,
        customMimeType: mimeType,
      );

      debugPrint('Photo downloaded successfully');
      debugPrint('============================================');
    } catch (error) {
      debugPrint('DOWNLOAD PHOTO ERROR: $error');
      rethrow;
    }
  }
}
