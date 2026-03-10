class RPSDetail {
  final int? id;
  final int matakuliahId;
  final int mingguKe;
  final List<int>? cpmkIds; // List of CPMK (Program Studi)
  final List<int>? subCpmkIds; // List of SUB CPMK being taught in this week
  final List<int>? cplIds; // List of CPL being addressed
  final String? topik;
  final String? metodeAjar;
  final String? jenisNilai; // Jenis Penilaian (Aktifitas Partisipatif, Hasil Proyek, Kuis, Tugas)
  final double? bobot; // Bobot pembelajaran (%)
  final DateTime createdAt;
  final DateTime? updatedAt;

  RPSDetail({
    this.id,
    required this.matakuliahId,
    required this.mingguKe,
    this.cpmkIds,
    this.subCpmkIds,
    this.cplIds,
    this.topik,
    this.metodeAjar,
    this.jenisNilai,
    this.bobot,
    required this.createdAt,
    this.updatedAt,
  });

  factory RPSDetail.fromMap(Map<String, dynamic> map) {
    return RPSDetail(
      id: map['id'] as int?,
      matakuliahId: map['matakuliah_id'] as int,
      mingguKe: map['minggu_ke'] as int,
      cpmkIds: (map['cpmk_ids'] as String?)
          ?.split(',')
          .map((id) => int.parse(id.trim()))
          .toList(),
      subCpmkIds: (map['sub_cpmk_ids'] as String?)
          ?.split(',')
          .map((id) => int.parse(id.trim()))
          .toList(),
      cplIds: (map['cpl_ids'] as String?)
          ?.split(',')
          .map((id) => int.parse(id.trim()))
          .toList(),
      topik: map['topik'] as String?,
      metodeAjar: map['metode_ajar'] as String?,
      jenisNilai: map['jenis_penilaian'] as String?,
      bobot: map['bobot'] != null ? double.parse(map['bobot'].toString()) : null,
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
      'minggu_ke': mingguKe,
      'cpmk_ids': cpmkIds?.join(','),
      'sub_cpmk_ids': subCpmkIds?.join(','),
      'cpl_ids': cplIds?.join(','),
      'topik': topik,
      'metode_ajar': metodeAjar,
      'jenis_penilaian': jenisNilai,
      'bobot': bobot,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  RPSDetail copyWith({
    int? id,
    int? matakuliahId,
    int? mingguKe,
    List<int>? cpmkIds,
    List<int>? subCpmkIds,
    List<int>? cplIds,
    String? topik,
    String? metodeAjar,
    String? jenisNilai,
    double? bobot,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RPSDetail(
      id: id ?? this.id,
      matakuliahId: matakuliahId ?? this.matakuliahId,
      mingguKe: mingguKe ?? this.mingguKe,
      cpmkIds: cpmkIds ?? this.cpmkIds,
      subCpmkIds: subCpmkIds ?? this.subCpmkIds,
      cplIds: cplIds ?? this.cplIds,
      topik: topik ?? this.topik,
      metodeAjar: metodeAjar ?? this.metodeAjar,
      jenisNilai: jenisNilai ?? this.jenisNilai,
      bobot: bobot ?? this.bobot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
