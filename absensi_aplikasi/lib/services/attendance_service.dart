import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<AttendanceModel> checkIn({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final dateStr = _getTodayDateString();
      final docId = '${user.uid}_$dateStr';
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final data = {
        'id': docId.hashCode,
        'user_id': user.uid.hashCode,
        'uid': user.uid,
        'attendance_date': dateStr,
        'check_in_time': timeStr,
        'check_in_lat': lat,
        'check_in_lng': lng,
        'check_in_address': address,
        'status': 'masuk',
        'created_at': FieldValue.serverTimestamp(),
      };

      await _db.collection('attendances').doc(docId).set(data, SetOptions(merge: true));

      final doc = await _db.collection('attendances').doc(docId).get();
      return AttendanceModel.fromJson(doc.data() ?? data);
    } catch (e) {
      throw Exception('Failed to check-in: $e');
    }
  }

  Future<AttendanceModel> checkOut({
    required double lat,
    required double lng,
    required String address,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final dateStr = _getTodayDateString();
      final docId = '${user.uid}_$dateStr';
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      final data = {
        'check_out_time': timeStr,
        'check_out_lat': lat,
        'check_out_lng': lng,
        'check_out_address': address,
        'check_out_location': '$lat, $lng',
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _db.collection('attendances').doc(docId).update(data);

      final doc = await _db.collection('attendances').doc(docId).get();
      if (!doc.exists) {
        throw Exception('Attendance record not found for check-out');
      }
      return AttendanceModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to check-out: $e');
    }
  }

  Future<AttendanceModel?> getTodayAttendance() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final dateStr = _getTodayDateString();
      final docId = '${user.uid}_$dateStr';

      final doc = await _db.collection('attendances').doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return AttendanceModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting today attendance: $e');
      return null;
    }
  }

  Future<List<AttendanceModel>> getHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _db.collection('attendances')
          .where('uid', isEqualTo: user.uid)
          .get();

      final list = snapshot.docs.map((doc) => AttendanceModel.fromJson(doc.data())).toList();
      // Urutkan secara lokal berdasarkan tanggal absensi secara descending (terbaru di atas)
      list.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));
      return list;
    } catch (e) {
      throw Exception('Failed to fetch history: $e');
    }
  }

  Future<AttendanceStats> getStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AttendanceStats(hadir: 0, izin: 0, sakit: 0, alpa: 0);

      final snapshot = await _db.collection('attendances')
          .where('uid', isEqualTo: user.uid)
          .get();

      int hadir = 0;
      int izin = 0;
      int sakit = 0;
      int alpa = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status']?.toString().toLowerCase();
        if (status == 'masuk' || status == 'hadir') {
          hadir++;
        } else if (status == 'izin') {
          izin++;
        } else if (status == 'sakit') {
          sakit++;
        } else if (status == 'alpa') {
          alpa++;
        }
      }

      return AttendanceStats(hadir: hadir, izin: izin, sakit: sakit, alpa: alpa);
    } catch (e) {
      debugPrint('Error getting stats: $e');
      return AttendanceStats(hadir: 0, izin: 0, sakit: 0, alpa: 0);
    }
  }

  Future<AttendanceModel> submitIzin({
    required String date,
    required String alasan,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final docId = '${user.uid}_$date';

      // Identifikasi apakah sakit atau izin biasa
      String status = 'izin';
      final alasanLower = alasan.toLowerCase();
      if (alasanLower.contains('sakit') || 
          alasanLower.contains('dokter') || 
          alasanLower.contains('demam') || 
          alasanLower.contains('flu') || 
          alasanLower.contains('klinik') ||
          alasanLower.contains('pusing')) {
        status = 'sakit';
      }

      final data = {
        'id': docId.hashCode,
        'user_id': user.uid.hashCode,
        'uid': user.uid,
        'attendance_date': date,
        'status': status,
        'alasan_izin': alasan,
        'created_at': FieldValue.serverTimestamp(),
      };

      await _db.collection('attendances').doc(docId).set(data, SetOptions(merge: true));

      final doc = await _db.collection('attendances').doc(docId).get();
      return AttendanceModel.fromJson(doc.data() ?? data);
    } catch (e) {
      throw Exception('Failed to submit izin: $e');
    }
  }

  Future<void> saveDeviceToken(String deviceToken) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _db.collection('users').doc(user.uid).update({
        'device_token': deviceToken,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to save device token: $e');
    }
  }

  Future<void> deleteAttendance(int id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot = await _db.collection('attendances')
          .where('uid', isEqualTo: user.uid)
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.delete();
      } else {
        throw Exception('Attendance not found');
      }
    } catch (e) {
      throw Exception('Failed to delete attendance: $e');
    }
  }
}
