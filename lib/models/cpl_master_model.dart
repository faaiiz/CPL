class CPLMaster {
  final int? id;
  final String kodeCPL; // CPL.1, CPL.2, ... CPL.7
  final String deskripsi;
  final String nomor; // 1-7
  final DateTime createdAt;
  final DateTime? updatedAt;

  CPLMaster({
    this.id,
    required this.kodeCPL,
    required this.deskripsi,
    required this.nomor,
    required this.createdAt,
    this.updatedAt,
  });

  factory CPLMaster.fromMap(Map<String, dynamic> map) {
    return CPLMaster(
      id: map['id'] as int?,
      kodeCPL: map['kode_cpl'] as String,
      deskripsi: map['deskripsi'] as String,
      nomor: map['nomor'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kode_cpl': kodeCPL,
      'deskripsi': deskripsi,
      'nomor': nomor,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CPLMaster copyWith({
    int? id,
    String? kodeCPL,
    String? deskripsi,
    String? nomor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CPLMaster(
      id: id ?? this.id,
      kodeCPL: kodeCPL ?? this.kodeCPL,
      deskripsi: deskripsi ?? this.deskripsi,
      nomor: nomor ?? this.nomor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
