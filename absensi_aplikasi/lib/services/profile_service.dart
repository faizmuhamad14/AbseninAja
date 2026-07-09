import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/firebase_user_model.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserModel> getProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists || doc.data() == null) {
        // Buat dokumen default di Firestore jika belum ada (untuk sinkronisasi akun lama)
        final newUserDoc = FirebaseUserModel(
          uid: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          role: 'user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _db.collection('users').doc(user.uid).set(newUserDoc.toMap());
        return newUserDoc.toUserModel();
      }
      
      final firebaseUser = FirebaseUserModel.fromMap(doc.data()!, documentId: doc.id);
      return firebaseUser.toUserModel();
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<UserModel> updateProfile({required String name, required String email}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }
      
      // Update di Firestore
      await _db.collection('users').doc(user.uid).update({
        'name': name,
        'email': email,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update Display Name di Firebase Auth
      await user.updateDisplayName(name);
      
      // Jika email berubah, coba update di Firebase Auth
      if (email != user.email) {
        try {
          await user.verifyBeforeUpdateEmail(email);
        } catch (_) {
          // Abaikan jika verifikasi email baru tidak didukung atau butuh re-auth
        }
      }

      return getProfile();
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<String> uploadPhoto(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }

      final ref = _storage.ref().child('profile_photos').child('${user.uid}.jpg');
      
      // Upload ke Firebase Storage
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      // Update foto profil di Firestore
      await _db.collection('users').doc(user.uid).update({
        'profile_photo': downloadUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // Update photo URL di Firebase Auth
      await user.updatePhotoURL(downloadUrl);

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }
}
