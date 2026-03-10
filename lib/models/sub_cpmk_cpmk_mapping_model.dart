class SubCPMKCPMKMapping {
  final int? id;
  final int subCpmkId;
  final int cpmkId;
  final double bobot; // Bobot Sub-CPMK terhadap CPMK (%)
  final DateTime createdAt;
  final DateTime? updatedAt;

  SubCPMKCPMKMapping({
    this.id,
    required this.subCpmkId,
    required this.cpmkId,
    required this.bobot,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubCPMKCPMKMapping.fromMap(Map<String, dynamic> map) {
    return SubCPMKCPMKMapping(
      id: map['id'] as int?,
      subCpmkId: map['sub_cpmk_id'] as int,
      cpmkId: map['cpmk_id'] as int,
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
      'sub_cpmk_id': subCpmkId,
      'cpmk_id': cpmkId,
      'bobot': bobot,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SubCPMKCPMKMapping copyWith({
    int? id,
    int? subCpmkId,
    int? cpmkId,
    double? bobot,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubCPMKCPMKMapping(
      id: id ?? this.id,
      subCpmkId: subCpmkId ?? this.subCpmkId,
      cpmkId: cpmkId ?? this.cpmkId,
      bobot: bobot ?? this.bobot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
