import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'user_model.dart';

/// Model user untuk Firebase/Firestore yang dikembangkan berdasarkan [UserModel].
/// 
/// Model ini menggunakan [uid] (String) sebagai identifier utama yang sesuai
/// dengan Firebase Authentication. Model ini juga menyediakan metode helper
/// untuk konversi dari/ke FirebaseAuth [fb.User] dan aplikasi utama [UserModel].
class FirebaseUserModel {
  final String uid;
  final String name;
  final String email;
  final String? profilePhoto;
  final int? batchId;
  final int? trainingId;
  final String? batchName;
  final String? trainingTitle;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FirebaseUserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.profilePhoto,
    this.batchId,
    this.trainingId,
    this.batchName,
    this.trainingTitle,
    this.role = 'user',
    this.createdAt,
    this.updatedAt,
  });

  /// Membuat [FirebaseUserModel] dari Map/JSON (biasanya dari Firestore document)
  factory FirebaseUserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return FirebaseUserModel(
      uid: documentId ?? map['uid'] ?? map['id']?.toString() ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profilePhoto: map['profile_photo'] ?? map['profilePhoto'] ?? map['photo_url'] ?? map['photoURL'],
      batchId: map['batch_id'] is int 
          ? map['batch_id'] 
          : (map['batch_id'] != null ? int.tryParse(map['batch_id'].toString()) : null),
      trainingId: map['training_id'] is int 
          ? map['training_id'] 
          : (map['training_id'] != null ? int.tryParse(map['training_id'].toString()) : null),
      batchName: map['batch_name'] ?? map['batchName'],
      trainingTitle: map['training_title'] ?? map['trainingTitle'],
      role: map['role'] ?? 'user',
      createdAt: _parseDateTime(map['created_at'] ?? map['createdAt']),
      updatedAt: _parseDateTime(map['updated_at'] ?? map['updatedAt']),
    );
  }

  /// Membuat [FirebaseUserModel] dari Firebase Auth [fb.User]
  /// dan menggabungkannya dengan data tambahan (misalnya dari Firestore atau input registrasi)
  factory FirebaseUserModel.fromFirebaseUser(fb.User user, {Map<String, dynamic>? additionalData}) {
    final Map<String, dynamic> data = additionalData ?? {};
    return FirebaseUserModel(
      uid: user.uid,
      name: data['name'] ?? user.displayName ?? '',
      email: data['email'] ?? user.email ?? '',
      profilePhoto: data['profile_photo'] ?? data['profilePhoto'] ?? user.photoURL,
      batchId: data['batch_id'] is int 
          ? data['batch_id'] 
          : (data['batch_id'] != null ? int.tryParse(data['batch_id'].toString()) : null),
      trainingId: data['training_id'] is int 
          ? data['training_id'] 
          : (data['training_id'] != null ? int.tryParse(data['training_id'].toString()) : null),
      batchName: data['batch_name'] ?? data['batchName'],
      trainingTitle: data['training_title'] ?? data['trainingTitle'],
      role: data['role'] ?? 'user',
      createdAt: _parseDateTime(data['created_at'] ?? data['createdAt']),
      updatedAt: _parseDateTime(data['updated_at'] ?? data['updatedAt']),
    );
  }

  /// Konversi [FirebaseUserModel] ke Map/JSON untuk disimpan ke Firestore/Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'profile_photo': profilePhoto,
      'batch_id': batchId,
      'training_id': trainingId,
      'batch_name': batchName,
      'training_title': trainingTitle,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Konversi [FirebaseUserModel] ke standard [UserModel] 
  /// agar kompatibel dengan modul/halaman lain di aplikasi yang masih menggunakan [UserModel]
  UserModel toUserModel() {
    // Generate integer ID unik berdasarkan hash dari String uid
    final int numericId = uid.hashCode;

    return UserModel(
      id: numericId,
      name: name,
      email: email,
      profilePhoto: profilePhoto,
      batchId: batchId,
      trainingId: trainingId,
      batchName: batchName,
      trainingTitle: trainingTitle,
    );
  }

  /// Membuat [FirebaseUserModel] dari standard [UserModel]
  factory FirebaseUserModel.fromUserModel(
    UserModel userModel, {
    required String uid,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FirebaseUserModel(
      uid: uid,
      name: userModel.name,
      email: userModel.email,
      profilePhoto: userModel.profilePhoto,
      batchId: userModel.batchId,
      trainingId: userModel.trainingId,
      batchName: userModel.batchName,
      trainingTitle: userModel.trainingTitle,
      role: role ?? 'user',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Helper untuk memparsing DateTime dari tipe data dinamis (String, DateTime, atau Firestore Timestamp secara dinamis)
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    
    // Penanganan dinamis untuk Firestore Timestamp tanpa perlu import library cloud_firestore secara langsung
    try {
      final typeStr = value.runtimeType.toString();
      if (typeStr == 'Timestamp' || typeStr.contains('Timestamp')) {
        return (value as dynamic).toDate() as DateTime;
      }
    } catch (_) {}
    
    return null;
  }
}
