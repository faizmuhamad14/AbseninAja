# 📋 Rencana Kerja Integrasi API Absensi PPKD B6

Dokumen ini berisi panduan lengkap langkah-demi-langkah (roadmap), struktur folder, pemodelan data, serta contoh implementasi kode untuk mengintegrasikan **19 endpoint API** dari Postman Collection `ABSENSI PPKD B6.postman_collection.json` ke dalam aplikasi Flutter **absensi_aplikasi**.

---

## 🎯 1. Daftar Endpoint API (19 Endpoint)

Berikut adalah daftar endpoint yang perlu diimplementasikan, dikelompokkan berdasarkan fungsinya:

| No | Modul / Kategori | Endpoint | HTTP Method | Auth Required | Deskripsi |
| :--- | :--- | :--- | :---: | :---: | :--- |
| **1** | **Autentikasi** | `/api/register` | `POST` | ❌ | Pendaftaran akun baru peserta. |
| **2** | | `/api/login` | `POST` | ❌ | Login akun dan mendapatkan Auth Token (Bearer). |
| **3** | | `/api/forgot-password` | `POST` | ❌ | Request OTP ke email untuk lupa password. |
| **4** | | `/api/reset-password` | `POST` | ❌ | Reset password menggunakan kode OTP. |
| **5** | **Absensi** | `/api/absen/check-in` | `POST` |  | Check-in masuk (butuh lat, lng, alamat, tanggal, status). |
| **6** | | `/api/absen/check-out` | `POST` |  | Check-out pulang (butuh lat, lng, alamat, dll). |
| **7** | | `/api/absen/today` | `GET` |  | Mengambil status absen hari ini. |
| **8** | | `/api/absen/history` | `GET` |  | Mengambil riwayat absensi pengguna. |
| **9** | | `/api/absen/stats` | `GET` |  | Statistik absen dengan filter rentang tanggal. |
| **10** | | `/api/absen/{id}` | `DELETE`|  | Menghapus data absensi berdasarkan ID. |
| **11** | **Izin** | `/api/izin` | `POST` |  | Pengajuan izin sakit/keperluan penting. |
| **12** | **Profil User** | `/api/profile` | `GET` |  | Mendapatkan profil detail pengguna yang sedang login. |
| **13** | | `/api/profile` | `PUT` |  | Mengedit info data profil. |
| **14** | | `/api/profile/photo` | `PUT` |  | Mengunggah/mengubah foto profil (Multipart). |
| **15** | | `/api/users` | `GET` |  | Mengambil seluruh data user (jika diperlukan admin/list). |
| **16** | **Metadata / Umum**| `/api/trainings` | `GET` | ❌ | Mendapatkan daftar pelatihan (Public). |
| **17** | | `/api/trainings/{id}`| `GET` | ❌ | Detail pelatihan berdasarkan ID (Public). |
| **18** | | `/api/batches` | `GET` | ❌ | Mendapatkan daftar gelombang/angkatan (Public). |
| **19** | **Notifikasi** | `/api/device-token` | `POST` |  | Mendaftarkan token perangkat untuk Push Notification. |

---

## 🛠️ 2. Persiapan Package / Dependencies

Tambahkan dependensi berikut ke file [pubspec.yaml](file:///D:/Project_flutter/Absen/absensi_aplikasi/pubspec.yaml) untuk mempermudah pengerjaan:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # HTTP Client yang powerful (Interceptors, upload file, pembatalan request)
  dio: ^5.7.0
  
  # Untuk menyimpan token login secara lokal & aman
  shared_preferences: ^2.3.2
  
  # State Management (Rekomendasi untuk pemula & menengah)
  provider: ^6.1.2
  
  # Untuk mengambil foto profil (Galeri/Kamera) & GPS lokasi
  image_picker: ^1.1.2
  geolocator: ^13.0.1
  geocoding: ^3.0.0
```

> [!TIP]
> Jalankan perintah `flutter pub get` di terminal setelah menambahkan dependensi tersebut.

---

## 📂 3. Desain Arsitektur Folder (Clean Architecture Sederhana)

Susun direktori pada folder `lib` seperti berikut agar kode terstruktur dengan baik dan mudah dimaintain:

```text
lib/
├── constant/
│   └── app_constant.dart         # Menyimpan Base URL & konfigurasi global
├── models/
│   ├── user_model.dart           # Model data User & Auth
│   ├── attendance_model.dart     # Model data Absensi & Statistik
│   └── training_model.dart       # Model data Pelatihan & Angkatan
├── services/
│   ├── api_client.dart           # Konfigurasi Dio & Interceptor (untuk token)
│   ├── auth_service.dart         # Service untuk Register, Login, Lupa Password
│   ├── attendance_service.dart   # Service untuk Check-In, Check-Out, History, Stats
│   └── profile_service.dart      # Service untuk Get/Update Profile, Upload Foto
├── utils/
│   └── location_helper.dart      # Helper untuk mendapatkan lat, lng, dan alamat GPS
├── views/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── dashboard_screen.dart
│   └── profile/
│       └── profile_screen.dart
└── main.dart                     # Entry point program
```

---

## 💻 4. Panduan Implementasi Kode (Langkah demi Langkah)

### Langkah 4.1: Konfigurasi Base URL (`constant/app_constant.dart`)
```dart
class AppConstant {
  // Ganti dengan IP Address server Laravel Anda jika dijalankan lokal (jangan gunakan localhost / 127.0.0.1 di Emulator Android)
  static const String baseUrl = "http://192.168.1.100:8000"; 
}
```

### Langkah 4.2: Pembuatan API Client dengan Dio Interceptor (`services/api_client.dart`)
Dio Interceptor otomatis menyisipkan token Authorization Header pada setiap request yang membutuhkan autentikasi:

```dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/app_constant.dart';

class ApiClient {
  final Dio dio = Dio(BaseOptions(
    baseUrl: AppConstant.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept': 'application/json',
    },
  ));

  ApiClient() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Handle error global di sini (misal: Token expired -> Logout otomatis)
        return handler.next(e);
      },
    ));
  }
}
```

### Langkah 4.3: Implementasi Autentikasi (`services/auth_service.dart`)
```dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<bool> login(String email, String password) async {
    try {
      final response = await _client.dio.post('/api/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['data']['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
```

### Langkah 4.4: Implementasi Check-In & Absensi (`services/attendance_service.dart`)
```dart
import 'package:dio/dio.dart';
import 'api_client.dart';

class AttendanceService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> checkIn({
    required double lat,
    required double lng,
    required String address,
    required String status, // "masuk" atau "izin"
    String? alasanIzin,
  }) async {
    try {
      final response = await _client.dio.post('/api/absen/check-in', data: {
        'check_in_lat': lat,
        'check_in_lng': lng,
        'check_in_address': address,
        'status': status,
        if (alasanIzin != null) 'alasan_izin': alasanIzin,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
```

### Langkah 4.5: Mengedit Foto Profil dengan Base64 Encoding (`services/profile_service.dart`)
> [!NOTE]
> API server mengharapkan foto profil dikirim dalam format Base64 Data URI (bukan Multipart/Form-Data). Sesuaikan dengan spesifikasi Postman Collection.

```dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class ProfileService {
  final ApiClient _client = ApiClient();

  Future<String> uploadPhoto(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      String extension = imageFile.path.split('.').last.toLowerCase();
      if (extension == 'jpg') extension = 'jpeg';
      final base64String = 'data:image/$extension;base64,$base64Image';

      final response = await _client.dio.put(
        '/api/profile/photo',
        data: {
          'profile_photo': base64String,
        },
      );

      final data = response.data['data'] ?? response.data;
      return data['profile_photo'] ?? '';
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Failed to upload photo';
      throw Exception(message);
    }
  }
}
```

---

## 🚀 5. Checklist Pengerjaan Mandiri

Silakan gunakan checklist ini untuk memantau progres pengerjaan Anda:

- [ ] **Fase 1: Setup Proyek & Dependensi**
  - [ ] Tambahkan package `dio`, `provider`, `shared_preferences`, `geolocator`, `image_picker` ke `pubspec.yaml`
  - [ ] Buat struktur folder di dalam folder `lib`
- [ ] **Fase 2: Autentikasi**
  - [ ] Implementasikan API Register (`/api/register`)
  - [ ] Implementasikan API Login & Simpan Token (`/api/login`)
  - [ ] Implementasikan Lupa Password & Reset Password dengan OTP
- [ ] **Fase 3: Inti Absensi & Lokasi**
  - [ ] Buat helper GPS koordinat (`geolocator`)
  - [ ] Hubungkan API Check-In masuk (`/api/absen/check-in`)
  - [ ] Hubungkan API Check-Out pulang (`/api/absen/check-out`)
  - [ ] Ambil data Absen Hari Ini (`/api/absen/today`) dan Riwayat Absen (`/api/absen/history`)
- [ ] **Fase 4: Manajemen Profil & Umum**
  - [ ] Tampilkan data Profil (`/api/profile`)
  - [ ] Edit Profil & Upload Foto Profil (`/api/profile/photo`)
  - [ ] Load data Pelatihan (`/api/trainings`) dan Batches (`/api/batches`) untuk form Register
- [ ] **Fase 5: Pengujian & Polishing UI**
  - [ ] Uji validasi form (email wajib diisi, password minimal 8 karakter, dll)
  - [ ] Uji skenario jika GPS mati atau koneksi internet bermasalah
  - [ ] Sambungkan push notification dengan token (`/api/device-token`) jika diperlukan

---

> [!NOTE]
> Jika Anda mengalami kesulitan saat mengintegrasikan UI atau membutuhkan bantuan penulisan kode model data/view, Anda bisa langsung meminta saya untuk membantu membuatkan kodenya!
