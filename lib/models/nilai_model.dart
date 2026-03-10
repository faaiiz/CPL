class Nilai {
  final int? id;
  final int mahasiswaId;
  final int matakuliahId;
  final String gradeHuruf; // A, B, C, D, E
  final double nilaiNumerik; // 4.0 untuk A, 3.0 untuk B, dst
  final String? catatan;
  final int tahunAjaran;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Nilai({
    this.id,
    required this.mahasiswaId,
    required this.matakuliahId,
    required this.gradeHuruf,
    required this.nilaiNumerik,
    this.catatan,
    required this.tahunAjaran,
    required this.createdAt,
    this.updatedAt,
  });

  factory Nilai.fromMap(Map<String, dynamic> map) {
    return Nilai(
      id: map['id'] as int?,
      mahasiswaId: map['mahasiswa_id'] as int,
      matakuliahId: map['matakuliah_id'] as int,
      gradeHuruf: map['grade_huruf'] as String,
      nilaiNumerik: (map['nilai_numerik'] as num).toDouble(),
      catatan: map['catatan'] as String?,
      tahunAjaran: map['tahun_ajaran'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mahasiswa_id': mahasiswaId,
      'matakuliah_id': matakuliahId,
      'grade_huruf': gradeHuruf,
      'nilai_numerik': nilaiNumerik,
      'catatan': catatan,
      'tahun_ajaran': tahunAjaran,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Nilai copyWith({
    int? id,
    int? mahasiswaId,
    int? matakuliahId,
    String? gradeHuruf,
    double? nilaiNumerik,
    String? catatan,
    int? tahunAjaran,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Nilai(
      id: id ?? this.id,
      mahasiswaId: mahasiswaId ?? this.mahasiswaId,
      matakuliahId: matakuliahId ?? this.matakuliahId,
      gradeHuruf: gradeHuruf ?? this.gradeHuruf,
      nilaiNumerik: nilaiNumerik ?? this.nilaiNumerik,
      catatan: catatan ?? this.catatan,
      tahunAjaran: tahunAjaran ?? this.tahunAjaran,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
