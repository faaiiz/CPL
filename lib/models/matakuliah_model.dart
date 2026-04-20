class Matakuliah {
  final int? id;
  final String kode;
  final String nama;
  final String semester;
  final String jenis; // 'wajib' atau 'pilihan'
  final int sks;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? namaEng; // Nama matakuliah dalam bahasa inggris

  Matakuliah({
    this.id,
    required this.kode,
    required this.nama,
    required this.semester,
    required this.jenis,
    required this.sks,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.namaEng,
  });

  factory Matakuliah.fromMap(Map<String, dynamic> map) {
    return Matakuliah(
      id: map['id'] as int?,
      kode: map['kode'] as String,
      nama: map['nama'] as String,
      semester: map['semester'] as String,
      jenis: map['jenis'] as String? ?? 'wajib',
      sks: map['sks'] as int,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      namaEng: map['mk_eng'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode': kode,
      'nama': nama,
      'semester': semester,
      'jenis': jenis,
      'sks': sks,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'mk_eng': namaEng,
    };
  }

  Matakuliah copyWith({
    int? id,
    String? kode,
    String? nama,
    String? semester,
    String? jenis,
    int? sks,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? namaEng,
  }) {
    return Matakuliah(
      id: id ?? this.id,
      kode: kode ?? this.kode,
      nama: nama ?? this.nama,
      semester: semester ?? this.semester,
      jenis: jenis ?? this.jenis,
      sks: sks ?? this.sks,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      namaEng: namaEng ?? this.namaEng,
    );
  }
}
