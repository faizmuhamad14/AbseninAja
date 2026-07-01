import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _client.dio.post('/api/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Login failed. Please check your credentials.';
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int batchId,
    required int trainingId,
    String jenisKelamin = 'L',
  }) async {
    try {
      final response = await _client.dio.post('/api/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'batch_id': batchId,
        'training_id': trainingId,
        'jenis_kelamin': jenisKelamin,
      });
      return response.data;
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Registration failed.';
      throw Exception(message);
    }
  }

  Future<List<TrainingModel>> getTrainings() async {
    try {
      final response = await _client.dio.get('/api/trainings');
      final List data = response.data['data'] ?? [];
      return data.map((json) => TrainingModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch trainings: $e');
    }
  }

  Future<List<BatchModel>> getBatches() async {
    try {
      final response = await _client.dio.get('/api/batches');
      final List data = response.data['data'] ?? response.data ?? [];
      // Handle either wrapped in 'data' or direct list
      return data.map((json) => BatchModel.fromJson(json)).toList();
    } catch (e) {
      // Return fallback batches if endpoint fails
      return [
        BatchModel(id: 1, name: 'Angkatan I'),
        BatchModel(id: 2, name: 'Angkatan II'),
        BatchModel(id: 3, name: 'Angkatan III'),
      ];
    }
  }

  Future<Map<String, dynamic>> requestOtp(String email) async {
    try {
      final response = await _client.dio.post('/api/forgot-password', data: {
        'email': email,
      });
      return response.data;
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to send OTP.';
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post('/api/reset-password', data: {
        'email': email,
        'otp': otp,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to reset password.';
      throw Exception(message);
    }
  }
}
