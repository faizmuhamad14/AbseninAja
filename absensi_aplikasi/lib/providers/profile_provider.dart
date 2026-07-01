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

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final fetchedProfile = await _profileService.getProfile();
      
      // Load saved photo url if server returned null/empty or is missing it
      String? localPhotoUrl;
      try {
        final prefs = await SharedPreferences.getInstance();
        localPhotoUrl = prefs.getString('profile_photo');
      } catch (prefError) {
        debugPrint('Failed to load local profile photo: $prefError');
      }

      final String? photoUrl = (fetchedProfile.profilePhoto != null && fetchedProfile.profilePhoto!.trim().isNotEmpty)
          ? fetchedProfile.profilePhoto
          : localPhotoUrl;

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
      
      // Load saved photo url from local storage
      String? localPhotoUrl;
      try {
        final prefs = await SharedPreferences.getInstance();
        localPhotoUrl = prefs.getString('profile_photo');
      } catch (prefError) {
        debugPrint('Failed to load local profile photo: $prefError');
      }

      final String? photoUrl = (_profile?.profilePhoto != null && _profile!.profilePhoto!.trim().isNotEmpty)
          ? _profile!.profilePhoto
          : localPhotoUrl;

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
      
      // Save photo url locally in SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        if (photoUrl.isNotEmpty) {
          await prefs.setString('profile_photo', photoUrl);
        }
      } catch (prefError) {
        debugPrint('Failed to save profile photo locally: $prefError');
      }

      if (_profile != null) {
        _profile = UserModel(
          id: _profile!.id,
          name: _profile!.name,
          email: _profile!.email,
          profilePhoto: photoUrl,
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

  void clearProfile() async {
    _profile = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_photo');
    } catch (prefError) {
      debugPrint('Failed to clear local profile photo: $prefError');
    }
    notifyListeners();
  }
}
