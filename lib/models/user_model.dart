class User {
  final int? id;
  final String username;
  final String password; // hashed
  final String role; // 'admin' or 'mahasiswa'
  final String nama;
  final String? nim; // NULL untuk admin, filled untuk mahasiswa
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.nama,
    this.nim,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      role: map['role'] as String,
      nama: map['nama'] as String,
      nim: map['nim'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'nama': nama,
      'nim': nim,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? password,
    String? role,
    String? nama,
    String? nim,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      nama: nama ?? this.nama,
      nim: nim ?? this.nim,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
