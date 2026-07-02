import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import '../utils/location_helper.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _service = AttendanceService();
  AttendanceModel? _todayAttendance;
  List<AttendanceModel> _history = [];
  AttendanceStats _stats = AttendanceStats(hadir: 0, izin: 0, sakit: 0, alpa: 0);
  bool _isLoading = false;
  String _statusMessage = '';

  AttendanceModel? get todayAttendance => _todayAttendance;
  List<AttendanceModel> get history => _history;
  AttendanceStats get stats => _stats;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;

  Future<void> fetchTodayAttendance() async {
    _isLoading = true;
    notifyListeners();
    try {
      _todayAttendance = await _service.getTodayAttendance();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistoryAndStats() async {
    _isLoading = true;
    notifyListeners();
    try {
      _history = await _service.getHistory();
      _stats = await _service.getStats();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> performCheckIn(BuildContext context) async {
    _isLoading = true;
    _statusMessage = 'Getting GPS location...';
    notifyListeners();

    try {
      Position position = await LocationHelper.getCurrentLocation();
      _statusMessage = 'Fetching address...';
      notifyListeners();

      String address = await LocationHelper.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      _statusMessage = 'Sending Check-In to Server...';
      notifyListeners();

      _todayAttendance = await _service.checkIn(
        lat: position.latitude,
        lng: position.longitude,
        address: address,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absen Masuk Berhasil!'), backgroundColor: Colors.green),
        );
      }
      await fetchHistoryAndStats();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _isLoading = false;
      _statusMessage = '';
      notifyListeners();
    }
  }

  Future<void> performCheckOut(BuildContext context) async {
    _isLoading = true;
    _statusMessage = 'Getting GPS location...';
    notifyListeners();

    try {
      Position position = await LocationHelper.getCurrentLocation();
      _statusMessage = 'Fetching address...';
      notifyListeners();

      String address = await LocationHelper.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      _statusMessage = 'Sending Check-Out to Server...';
      notifyListeners();

      _todayAttendance = await _service.checkOut(
        lat: position.latitude,
        lng: position.longitude,
        address: address,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absen Pulang Berhasil!'), backgroundColor: Colors.green),
        );
      }
      await fetchHistoryAndStats();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _isLoading = false;
      _statusMessage = '';
      notifyListeners();
    }
  }

  Future<void> performSubmitIzin(BuildContext context, String alasan) async {
    _isLoading = true;
    _statusMessage = 'Submitting permit...';
    notifyListeners();

    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      _todayAttendance = await _service.submitIzin(
        date: dateStr,
        alasan: alasan,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin berhasil diajukan!'), backgroundColor: Colors.green),
        );
      }
      await fetchHistoryAndStats();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _isLoading = false;
      _statusMessage = '';
      notifyListeners();
    }
  }

  Future<void> deleteAttendanceItem(BuildContext context, int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deleteAttendance(id);
      _history.removeWhere((item) => item.id == id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absen berhasil dihapus.'), backgroundColor: Colors.blue),
        );
      }
      await fetchHistoryAndStats();
      await fetchTodayAttendance();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus absen: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearState() {
    _todayAttendance = null;
    _history = [];
    _stats = AttendanceStats(hadir: 0, izin: 0, sakit: 0, alpa: 0);
    _statusMessage = '';
    notifyListeners();
  }
}
