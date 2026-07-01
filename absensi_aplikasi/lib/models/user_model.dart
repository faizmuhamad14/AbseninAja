class UserModel {
  final int id;
  final String name;
  final String email;
  final String? profilePhoto;
  final int? batchId;
  final int? trainingId;
  final String? batchName;
  final String? trainingTitle;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    String? profilePhoto,
    this.batchId,
    this.trainingId,
    this.batchName,
    this.trainingTitle,
  }) : profilePhoto = _sanitizePhotoUrl(profilePhoto);

  static String? _sanitizePhotoUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    
    String trimmed = url.trim();
    
    if (trimmed.contains('127.0.0.1:8000')) {
      trimmed = trimmed.replaceAll('http://127.0.0.1:8000', 'https://appabsensi.mobileprojp.com');
    } else if (trimmed.contains('localhost:8000')) {
      trimmed = trimmed.replaceAll('http://localhost:8000', 'https://appabsensi.mobileprojp.com');
    } else if (trimmed.startsWith('/')) {
      trimmed = 'https://appabsensi.mobileprojp.com$trimmed';
    }
    
    return trimmed;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // If the json has nested 'batch' or 'training' map
    Map<String, dynamic>? batchJson = json['batch'] is Map ? json['batch'] : null;
    Map<String, dynamic>? trainingJson = json['training'] is Map ? json['training'] : null;

    return UserModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profilePhoto: json['profile_photo'] ?? json['photo_url'],
      batchId: json['batch_id'] is int ? json['batch_id'] : (json['batch_id'] != null ? int.tryParse(json['batch_id'].toString()) : null),
      trainingId: json['training_id'] is int ? json['training_id'] : (json['training_id'] != null ? int.tryParse(json['training_id'].toString()) : null),
      batchName: batchJson != null ? batchJson['name'] : json['batch_name'],
      trainingTitle: trainingJson != null ? (trainingJson['title'] ?? trainingJson['name']) : json['training_title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_photo': profilePhoto,
      'batch_id': batchId,
      'training_id': trainingId,
      'batch_name': batchName,
      'training_title': trainingTitle,
    };
  }
}

class TrainingModel {
  final int id;
  final String title;

  TrainingModel({required this.id, required this.title});

  factory TrainingModel.fromJson(Map<String, dynamic> json) {
    return TrainingModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      title: json['title'] ?? json['name'] ?? '',
    );
  }
}

class BatchModel {
  final int id;
  final String name;

  BatchModel({required this.id, required this.name});

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    // API returns 'batch_ke' (e.g. "2") instead of 'name'
    String batchName = json['name'] ?? '';
    if (batchName.isEmpty && json['batch_ke'] != null) {
      batchName = 'Angkatan ${json['batch_ke']}';
    }
    return BatchModel(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      name: batchName,
    );
  }
}
