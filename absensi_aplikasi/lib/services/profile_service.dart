import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class ProfileService {
  final ApiClient _client = ApiClient();

  Future<UserModel> getProfile() async {
    try {
      final response = await _client.dio.get('/api/profile');
      final data = response.data['data'] ?? response.data;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to load profile';
      throw Exception(message);
    }
  }

  Future<UserModel> updateProfile({required String name, required String email}) async {
    try {
      final response = await _client.dio.put('/api/profile', data: {
        'name': name,
        'email': email,
      });
      final data = response.data['data'] ?? response.data;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to update profile';
      throw Exception(message);
    }
  }

  Future<String> uploadPhoto(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      String extension = imageFile.path.split('.').last.toLowerCase();
      if (extension == 'jpg') extension = 'jpeg';
      final base64String = 'data:image/$extension;base64,$base64Image';

      final response = await _client.dio.put(
        '/api/profile/photo',
        data: {
          'profile_photo': base64String,
        },
      );
      final data = response.data['data'] ?? response.data;
      return data['profile_photo'] ?? '';
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to upload photo';
      throw Exception(message);
    }
  }
}
