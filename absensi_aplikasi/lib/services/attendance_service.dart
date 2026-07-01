import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/attendance_model.dart';
import 'api_client.dart';

class AttendanceService {
  final ApiClient _client = ApiClient();

  Future<AttendanceModel> checkIn({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      final now = DateTime.now();
      final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final response = await _client.dio.post('/api/absen/check-in', data: {
        'attendance_date': date,
        'check_in': time,
        'check_in_lat': lat,
        'check_in_lng': lng,
        'check_in_address': address,
        'status': 'masuk',
      });
      return AttendanceModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to check-in';
      throw Exception(message);
    }
  }

  Future<AttendanceModel> checkOut({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      final now = DateTime.now();
      final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final response = await _client.dio.post('/api/absen/check-out', data: {
        'attendance_date': date,
        'check_out': time,
        'check_out_lat': lat,
        'check_out_lng': lng,
        'check_out_address': address,
        'check_out_location': '$lat, $lng',
      });
      return AttendanceModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to check-out';
      throw Exception(message);
    }
  }

  Future<AttendanceModel?> getTodayAttendance() async {
    try {
      final response = await _client.dio.get('/api/absen/today');
      final data = response.data['data'] ?? response.data;
      if (data == null || (data is List && data.isEmpty)) {
        return null;
      }
      if (data is Map && data.isNotEmpty) {
        return AttendanceModel.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<AttendanceModel>> getHistory() async {
    try {
      final response = await _client.dio.get('/api/absen/history');
      final dynamic rawData = response.data['data'] ?? response.data;
      if (rawData is List) {
        return rawData.map((json) => AttendanceModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch history: $e');
    }
  }

  Future<AttendanceStats> getStats() async {
    try {
      final now = DateTime.now();
      final start = '${now.year}-01-01';
      final end = '${now.year}-12-31';
      final response = await _client.dio.get(
        '/api/absen/stats',
        queryParameters: {
          'start': start,
          'end': end,
        },
      );
      final data = response.data['data'] ?? response.data ?? {};
      return AttendanceStats.fromJson(data);
    } catch (e) {
      return AttendanceStats(hadir: 0, izin: 0, sakit: 0, alpa: 0);
    }
  }

  Future<AttendanceModel> submitIzin({
    required String date,
    required String alasan,
  }) async {
    try {
      final response = await _client.dio.post('/api/izin', data: {
        'date': date,
        'alasan_izin': alasan,
      });
      return AttendanceModel.fromJson(response.data['data'] ?? response.data);
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to submit izin';
      throw Exception(message);
    }
  }

  Future<void> saveDeviceToken(String deviceToken) async {
    try {
      await _client.dio.post('/api/device-token', data: {
        'player_id': deviceToken,
      });
    } catch (e) {
      debugPrint('Failed to save device token: $e');
    }
  }

  Future<void> deleteAttendance(int id) async {
    try {
      await _client.dio.delete('/api/absen/$id');
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to delete attendance';
      throw Exception(message);
    }
  }
}
