class CPMKCPLMapping {
  final int? id;
  final int cpmkId; // References CPMK
  final int cplId; // References CPLMaster
  final double bobot; // Kontribusi CPMK terhadap CPL (0-100)
  final DateTime createdAt;
  final DateTime? updatedAt;

  CPMKCPLMapping({
    this.id,
    required this.cpmkId,
    required this.cplId,
    required this.bobot,
    required this.createdAt,
    this.updatedAt,
  });

  factory CPMKCPLMapping.fromMap(Map<String, dynamic> map) {
    return CPMKCPLMapping(
      id: map['id'] as int?,
      cpmkId: map['cpmk_id'] as int,
      cplId: map['cpl_id'] as int,
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
      'cpmk_id': cpmkId,
      'cpl_id': cplId,
      'bobot': bobot,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CPMKCPLMapping copyWith({
    int? id,
    int? cpmkId,
    int? cplId,
    double? bobot,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CPMKCPLMapping(
      id: id ?? this.id,
      cpmkId: cpmkId ?? this.cpmkId,
      cplId: cplId ?? this.cplId,
      bobot: bobot ?? this.bobot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
