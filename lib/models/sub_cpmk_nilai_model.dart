class SubCPMKNilai {
  final int? id;
  final int mahasiswaId;
  final int subCpmkId;
  final double nilai;
  final int tahunAjaran;
  final String? catatan;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SubCPMKNilai({
    this.id,
    required this.mahasiswaId,
    required this.subCpmkId,
    required this.nilai,
    required this.tahunAjaran,
    this.catatan,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubCPMKNilai.fromMap(Map<String, dynamic> map) {
    return SubCPMKNilai(
      id: map['id'] as int?,
      mahasiswaId: map['mahasiswa_id'] as int,
      subCpmkId: map['sub_cpmk_id'] as int,
      nilai: (map['nilai'] as num).toDouble(),
      tahunAjaran: map['tahun_ajaran'] as int,
      catatan: map['catatan'] as String?,
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
      'sub_cpmk_id': subCpmkId,
      'nilai': nilai,
      'tahun_ajaran': tahunAjaran,
      'catatan': catatan,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SubCPMKNilai copyWith({
    int? id,
    int? mahasiswaId,
    int? subCpmkId,
    double? nilai,
    int? tahunAjaran,
    String? catatan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubCPMKNilai(
      id: id ?? this.id,
      mahasiswaId: mahasiswaId ?? this.mahasiswaId,
      subCpmkId: subCpmkId ?? this.subCpmkId,
      nilai: nilai ?? this.nilai,
      tahunAjaran: tahunAjaran ?? this.tahunAjaran,
      catatan: catatan ?? this.catatan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
