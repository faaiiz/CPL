class RPSDetailSubCPMKBobot {
  final int? id;
  final int rpsDetailId;
  final int subCpmkId;
  final double bobot; // Bobot dalam minggu ini (%)
  final DateTime createdAt;
  final DateTime? updatedAt;

  RPSDetailSubCPMKBobot({
    this.id,
    required this.rpsDetailId,
    required this.subCpmkId,
    required this.bobot,
    required this.createdAt,
    this.updatedAt,
  });

  factory RPSDetailSubCPMKBobot.fromMap(Map<String, dynamic> map) {
    return RPSDetailSubCPMKBobot(
      id: map['id'] as int?,
      rpsDetailId: map['rps_detail_id'] as int,
      subCpmkId: map['sub_cpmk_id'] as int,
      bobot: (map['bobot'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rps_detail_id': rpsDetailId,
      'sub_cpmk_id': subCpmkId,
      'bobot': bobot,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  RPSDetailSubCPMKBobot copyWith({
    int? id,
    int? rpsDetailId,
    int? subCpmkId,
    double? bobot,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RPSDetailSubCPMKBobot(
      id: id ?? this.id,
      rpsDetailId: rpsDetailId ?? this.rpsDetailId,
      subCpmkId: subCpmkId ?? this.subCpmkId,
      bobot: bobot ?? this.bobot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
