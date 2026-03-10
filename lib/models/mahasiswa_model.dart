class Mahasiswa {
  final int? id;
  final String nim;
  final String nama;
  final int tahunMasuk;
  final String status; // 'aktif', 'lulus', 'cuti', 'drop'
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Mahasiswa({
    this.id,
    required this.nim,
    required this.nama,
    required this.tahunMasuk,
    this.status = 'aktif',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Mahasiswa.fromMap(Map<String, dynamic> map) {
    return Mahasiswa(
      id: map['id'] as int?,
      nim: map['nim'] as String,
      nama: map['nama'] as String,
      tahunMasuk: map['tahun_masuk'] as int,
      status: map['status'] as String? ?? 'aktif',
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
      'nim': nim,
      'nama': nama,
      'tahun_masuk': tahunMasuk,
      'status': status,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Mahasiswa copyWith({
    int? id,
    String? nim,
    String? nama,
    int? tahunMasuk,
    String? status,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Mahasiswa(
      id: id ?? this.id,
      nim: nim ?? this.nim,
      nama: nama ?? this.nama,
      tahunMasuk: tahunMasuk ?? this.tahunMasuk,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
