class CPMK {
  final int? id;
  final int matakuliahId;
  final String kodeCPMK; // CPMK.1, CPMK.2, etc
  final String deskripsi;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CPMK({
    this.id,
    required this.matakuliahId,
    required this.kodeCPMK,
    required this.deskripsi,
    required this.createdAt,
    this.updatedAt,
  });

  factory CPMK.fromMap(Map<String, dynamic> map) {
    return CPMK(
      id: map['id'] as int?,
      matakuliahId: map['matakuliah_id'] as int,
      kodeCPMK: map['kode_cpmk'] as String,
      deskripsi: map['deskripsi'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matakuliah_id': matakuliahId,
      'kode_cpmk': kodeCPMK,
      'deskripsi': deskripsi,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CPMK copyWith({
    int? id,
    int? matakuliahId,
    String? kodeCPMK,
    String? deskripsi,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CPMK(
      id: id ?? this.id,
      matakuliahId: matakuliahId ?? this.matakuliahId,
      kodeCPMK: kodeCPMK ?? this.kodeCPMK,
      deskripsi: deskripsi ?? this.deskripsi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
