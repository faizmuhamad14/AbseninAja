import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/firebase_user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw Exception('User not found after sign in.');
      }
      final token = await user.getIdToken();
      return {
        'data': {'token': token},
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please check your credentials.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.message != null) {
        message = e.message!;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Registration failed.');
      }

      // Update display name di Firebase Auth
      await user.updateDisplayName(name);

      // Cari Batch Name dan Training Title untuk disimpan ke Firestore
      String batchName = 'Angkatan $batchId';
      String trainingTitle = 'Pelatihan $trainingId';

      try {
        final batchDoc = await _db.collection('batches').doc(batchId.toString()).get();
        if (batchDoc.exists) {
          batchName = batchDoc.data()?['name'] ?? batchName;
        }
        final trainingDoc = await _db.collection('trainings').doc(trainingId.toString()).get();
        if (trainingDoc.exists) {
          trainingTitle = trainingDoc.data()?['title'] ?? trainingDoc.data()?['name'] ?? trainingTitle;
        }
      } catch (e) {
        // Abaikan dan gunakan nama default jika query gagal
      }

      // Simpan profile user ke Firestore
      final firebaseUser = FirebaseUserModel(
        uid: user.uid,
        name: name,
        email: email,
        batchId: batchId,
        trainingId: trainingId,
        batchName: batchName,
        trainingTitle: trainingTitle,
        role: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _db.collection('users').doc(user.uid).set(firebaseUser.toMap());

      final token = await user.getIdToken();
      return {
        'data': {'token': token},
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.message != null) {
        message = e.message!;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<TrainingModel>> getTrainings() async {
    try {
      final snapshot = await _db.collection('trainings').get();
      if (snapshot.docs.isEmpty) {
        // Seeding awal jika data kosong
        final initialTrainings = [
          {'id': 1, 'title': 'Mobile Programming (Flutter)'},
          {'id': 2, 'title': 'Web Programming (React & Node.js)'},
          {'id': 3, 'title': 'UI/UX Design'},
          {'id': 4, 'title': 'Data Science & AI'},
        ];
        for (var t in initialTrainings) {
          await _db.collection('trainings').doc(t['id'].toString()).set(t);
        }
        return initialTrainings.map((json) => TrainingModel.fromJson(json)).toList();
      }
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TrainingModel(
          id: data['id'] is int ? data['id'] : (int.tryParse(doc.id) ?? 0),
          title: data['title'] ?? data['name'] ?? '',
        );
      }).toList();
    } catch (e) {
      // Fallback lokal jika terjadi masalah dengan koneksi Firebase
      return [
        TrainingModel(id: 1, title: 'Mobile Programming (Flutter)'),
        TrainingModel(id: 2, title: 'Web Programming (React & Node.js)'),
        TrainingModel(id: 3, title: 'UI/UX Design'),
      ];
    }
  }

  Future<List<BatchModel>> getBatches() async {
    try {
      final snapshot = await _db.collection('batches').get();
      if (snapshot.docs.isEmpty) {
        // Seeding awal jika data kosong
        final initialBatches = [
          {'id': 1, 'name': 'Angkatan I'},
          {'id': 2, 'name': 'Angkatan II'},
          {'id': 3, 'name': 'Angkatan III'},
        ];
        for (var b in initialBatches) {
          await _db.collection('batches').doc(b['id'].toString()).set(b);
        }
        return initialBatches.map((json) => BatchModel.fromJson(json)).toList();
      }
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BatchModel(
          id: data['id'] is int ? data['id'] : (int.tryParse(doc.id) ?? 0),
          name: data['name'] ?? '',
        );
      }).toList();
    } catch (e) {
      // Fallback lokal jika terjadi masalah dengan koneksi Firebase
      return [
        BatchModel(id: 1, name: 'Angkatan I'),
        BatchModel(id: 2, name: 'Angkatan II'),
        BatchModel(id: 3, name: 'Angkatan III'),
      ];
    }
  }

  Future<Map<String, dynamic>> requestOtp(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'message': 'Password reset link sent to your email.',
        'status': 'success',
      };
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to send password reset email.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: otp, newPassword: password);
      return {'message': 'Password reset successfully.', 'status': 'success'};
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to reset password.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}
