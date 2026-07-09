import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/api_client.dart';
import '../services/attendance_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final AttendanceService _attendanceService = AttendanceService();
  String? _token;
  bool _isLoading = false;
  List<TrainingModel> _trainings = [];
  List<BatchModel> _batches = [];

  AuthProvider() {
    ApiClient.onUnauthorized = () {
      logout();
    };
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;
  List<TrainingModel> get trainings => _trainings;
  List<BatchModel> get batches => _batches;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('auth_token')) {
      _token = prefs.getString('auth_token');
      notifyListeners();
      _attendanceService.saveDeviceToken('dummy_flutter_device_token');
    }
  }

  Future<void> fetchTrainingsAndBatches() async {
    _isLoading = true;
    notifyListeners();
    try {
      _trainings = await _authService.getTrainings();
    } catch (e) {
      debugPrint('Failed to fetch trainings: $e');
    }
    try {
      _batches = await _authService.getBatches();
    } catch (e) {
      debugPrint('Failed to fetch batches: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _authService.login(email, password);
      _token = response['data']['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      _attendanceService.saveDeviceToken('dummy_flutter_device_token');
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required int batchId,
    required int trainingId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        batchId: batchId,
        trainingId: trainingId,
      );
      _token = response['data']['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      _attendanceService.saveDeviceToken('dummy_flutter_device_token');
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Failed to log out from Firebase: $e');
    }
    notifyListeners();
  }

  Future<void> sendOtp(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.requestOtp(email);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.resetPassword(email: email, otp: otp, password: password);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
