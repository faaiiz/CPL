class AssessmentType {
  final int? id;
  final int mingguId; // References RPSDetail.id (minggu ke)
  final int cpmkId;
  final String jenisAsessmen;
  // jenisAsessmen: 'aktivitas_partisipatif', 'kuis', 'tugas', 'hasil_proyek'
  final double bobot; // Persentase kontribusi (0-100)
  final DateTime createdAt;
  final DateTime? updatedAt;

  AssessmentType({
    this.id,
    required this.mingguId,
    required this.cpmkId,
    required this.jenisAsessmen,
    required this.bobot,
    required this.createdAt,
    this.updatedAt,
  });

  factory AssessmentType.fromMap(Map<String, dynamic> map) {
    return AssessmentType(
      id: map['id'] as int?,
      mingguId: map['minggu_id'] as int,
      cpmkId: map['cpmk_id'] as int,
      jenisAsessmen: map['jenis_asessmen'] as String,
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
      'minggu_id': mingguId,
      'cpmk_id': cpmkId,
      'jenis_asessmen': jenisAsessmen,
      'bobot': bobot,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  AssessmentType copyWith({
    int? id,
    int? mingguId,
    int? cpmkId,
    String? jenisAsessmen,
    double? bobot,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssessmentType(
      id: id ?? this.id,
      mingguId: mingguId ?? this.mingguId,
      cpmkId: cpmkId ?? this.cpmkId,
      jenisAsessmen: jenisAsessmen ?? this.jenisAsessmen,
      bobot: bobot ?? this.bobot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
