class SubCPMK {
  final int? id;
  final int matakuliahId;
  final String kodeSubCPMK; // SUB-CPMK.1, SUB-CPMK.2, etc
  final String deskripsi;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SubCPMK({
    this.id,
    required this.matakuliahId,
    required this.kodeSubCPMK,
    required this.deskripsi,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubCPMK.fromMap(Map<String, dynamic> map) {
    return SubCPMK(
      id: map['id'] as int?,
      matakuliahId: map['matakuliah_id'] as int,
      kodeSubCPMK: map['kode_sub_cpmk'] as String,
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
      'kode_sub_cpmk': kodeSubCPMK,
      'deskripsi': deskripsi,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SubCPMK copyWith({
    int? id,
    int? matakuliahId,
    String? kodeSubCPMK,
    String? deskripsi,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubCPMK(
      id: id ?? this.id,
      matakuliahId: matakuliahId ?? this.matakuliahId,
      kodeSubCPMK: kodeSubCPMK ?? this.kodeSubCPMK,
      deskripsi: deskripsi ?? this.deskripsi,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'SubCPMK(id: $id, matakuliahId: $matakuliahId, kodeSubCPMK: $kodeSubCPMK, deskripsi: $deskripsi)';
}
