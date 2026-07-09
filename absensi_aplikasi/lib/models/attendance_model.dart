class AttendanceModel {
  final int id;
  final int? userId;
  final String? checkInTime;
  final String? checkOutTime;
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final String? checkInAddress;
  final String? checkOutAddress;
  final String status;
  final String? alasanIzin;
  final String attendanceDate;

  AttendanceModel({
    required this.id,
    this.userId,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.checkInAddress,
    this.checkOutAddress,
    required this.status,
    this.alasanIzin,
    required this.attendanceDate,
  });

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      userId: json['user_id'] != null
          ? (json['user_id'] is int
              ? json['user_id']
              : int.tryParse(json['user_id'].toString()))
          : null,
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      checkInLat: _parseDouble(json['check_in_lat']),
      checkInLng: _parseDouble(json['check_in_lng']),
      checkOutLat: _parseDouble(json['check_out_lat']),
      checkOutLng: _parseDouble(json['check_out_lng']),
      checkInAddress: json['check_in_address'],
      checkOutAddress: json['check_out_address'],
      status: json['status'] ?? 'masuk',
      alasanIzin: json['alasan_izin'],
      attendanceDate: json['attendance_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'check_in_lat': checkInLat,
      'check_in_lng': checkInLng,
      'check_out_lat': checkOutLat,
      'check_out_lng': checkOutLng,
      'check_in_address': checkInAddress,
      'check_out_address': checkOutAddress,
      'status': status,
      'alasan_izin': alasanIzin,
      'attendance_date': attendanceDate,
    };
  }
}

class AttendanceStats {
  final int hadir;
  final int izin;
  final int sakit;
  final int alpa;

  AttendanceStats({
    required this.hadir,
    required this.izin,
    required this.sakit,
    required this.alpa,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      hadir: json['total_masuk'] is int
          ? json['total_masuk']
          : (int.tryParse(json['total_masuk']?.toString() ?? '') ??
              json['hadir'] ??
              json['present'] ??
              0),
      izin: json['total_izin'] is int
          ? json['total_izin']
          : (int.tryParse(json['total_izin']?.toString() ?? '') ??
              json['izin'] ??
              json['permit'] ??
              0),
      sakit: json['total_sakit'] is int
          ? json['total_sakit']
          : (int.tryParse(json['total_sakit']?.toString() ?? '') ??
              json['sakit'] ??
              json['sick'] ??
              0),
      alpa: json['total_alpa'] is int
          ? json['total_alpa']
          : (int.tryParse(json['total_alpa']?.toString() ?? '') ??
              json['alpa'] ??
              json['absent'] ??
              0),
    );
  }
}
