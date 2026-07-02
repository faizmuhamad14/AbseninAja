import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  UserModel? _profile;
  bool _isLoading = false;

  UserModel? get profile => _profile;
  bool get isLoading => _isLoading;

  /// Helper: membaca URL foto profil dari SharedPreferences sebagai fallback
  Future<String?> _getLocalPhotoUrl(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('profile_photo_$email');
    } catch (e) {
      debugPrint('Failed to load local profile photo: $e');
      return null;
    }
  }

  /// Helper: menyimpan URL foto profil ke SharedPreferences
  Future<void> _saveLocalPhotoUrl(String? url, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url != null && url.isNotEmpty) {
        await prefs.setString('profile_photo_$email', url);
      }
    } catch (e) {
      debugPrint('Failed to save local profile photo: $e');
    }
  }

  /// Memilih URL foto terbaik: prioritaskan server, fallback ke lokal, lalu in-memory
  String? _resolvePhotoUrl(String? serverPhoto, String? localPhoto) {
    if (serverPhoto != null && serverPhoto.trim().isNotEmpty) {
      return serverPhoto;
    }
    // Gunakan foto yang sudah ada di memory (dari upload sebelumnya)
    if (_profile?.profilePhoto != null && _profile!.profilePhoto!.trim().isNotEmpty) {
      return _profile!.profilePhoto;
    }
    // Terakhir, fallback ke SharedPreferences
    return localPhoto;
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final fetchedProfile = await _profileService.getProfile();

      // Load saved photo url jika server mengembalikan null/kosong
      final localPhotoUrl = await _getLocalPhotoUrl(fetchedProfile.email);
      final photoUrl = _resolvePhotoUrl(fetchedProfile.profilePhoto, localPhotoUrl);

      // Jika foto ditemukan dari server, simpan ke lokal untuk backup
      if (fetchedProfile.profilePhoto != null && fetchedProfile.profilePhoto!.trim().isNotEmpty) {
        await _saveLocalPhotoUrl(fetchedProfile.profilePhoto, fetchedProfile.email);
      }

      _profile = UserModel(
        id: fetchedProfile.id,
        name: fetchedProfile.name,
        email: fetchedProfile.email,
        profilePhoto: photoUrl,
        batchId: fetchedProfile.batchId,
        trainingId: fetchedProfile.trainingId,
        batchName: fetchedProfile.batchName,
        trainingTitle: fetchedProfile.trainingTitle,
      );
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({required String name, required String email}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updatedProfile = await _profileService.updateProfile(name: name, email: email);

      // Foto tidak diubah di endpoint ini (hanya nama & email),
      // jadi prioritaskan foto yang sudah ada di memori → lokal → server
      final localPhotoUrl = await _getLocalPhotoUrl(updatedProfile.email);
      final photoUrl = _profile?.profilePhoto
          ?? localPhotoUrl
          ?? updatedProfile.profilePhoto;

      _profile = UserModel(
        id: updatedProfile.id,
        name: updatedProfile.name,
        email: updatedProfile.email,
        profilePhoto: photoUrl,
        batchId: _profile?.batchId ?? updatedProfile.batchId,
        trainingId: _profile?.trainingId ?? updatedProfile.trainingId,
        batchName: _profile?.batchName ?? updatedProfile.batchName,
        trainingTitle: _profile?.trainingTitle ?? updatedProfile.trainingTitle,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadProfilePhoto(File file) async {
    _isLoading = true;
    notifyListeners();
    try {
      final photoUrl = await _profileService.uploadPhoto(file);

      // Simpan URL foto ke SharedPreferences sebagai backup
      if (_profile != null) {
        await _saveLocalPhotoUrl(photoUrl, _profile!.email);
      }

      if (_profile != null) {
        // Jika server mengembalikan URL kosong, pertahankan foto sebelumnya
        final effectiveUrl = (photoUrl.isNotEmpty) ? photoUrl : _profile!.profilePhoto;

        _profile = UserModel(
          id: _profile!.id,
          name: _profile!.name,
          email: _profile!.email,
          profilePhoto: effectiveUrl,
          batchId: _profile!.batchId,
          trainingId: _profile!.trainingId,
          batchName: _profile!.batchName,
          trainingTitle: _profile!.trainingTitle,
        );
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}
