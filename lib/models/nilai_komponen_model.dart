class NilaiKomponen {
  final int? id;
  final int mahasiswaId;
  final int matakuliahId;
  final double nilaiAktivitas;
  final double nilaiProyek;
  final double nilaiKuis;
  final double nilaiTugas;
  final double nilaiUTS;
  final double nilaiUAS;
  final int tahunAjaran;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NilaiKomponen({
    this.id,
    required this.mahasiswaId,
    required this.matakuliahId,
    required this.nilaiAktivitas,
    required this.nilaiProyek,
    required this.nilaiKuis,
    required this.nilaiTugas,
    required this.nilaiUTS,
    required this.nilaiUAS,
    required this.tahunAjaran,
    this.createdAt,
    this.updatedAt,
  });

  /// Calculate final grade from component scores
  /// Default weights (based on OBE standard):
  /// - Aktivitas: 10%
  /// - Tugas: 10%
  /// - Proyek: 15%
  /// - Kuis: 15%
  /// - UTS: 25%
  /// - UAS: 25%
  double calculateFinalGrade({
    double weightAktivitas = 0.10,
    double weightTugas = 0.10,
    double weightProyek = 0.15,
    double weightKuis = 0.15,
    double weightUTS = 0.25,
    double weightUAS = 0.25,
  }) {
    return (nilaiAktivitas * weightAktivitas +
        nilaiTugas * weightTugas +
        nilaiProyek * weightProyek +
        nilaiKuis * weightKuis +
        nilaiUTS * weightUTS +
        nilaiUAS * weightUAS);
  }

  /// Get components as a list for weighted calculations
  List<double> getComponentValues() => [
    nilaiAktivitas,
    nilaiProyek,
    nilaiKuis,
    nilaiTugas,
    nilaiUTS,
    nilaiUAS,
  ];

  /// Get component names in order
  static List<String> getComponentNames() => [
    'Aktivitas',
    'Proyek',
    'Kuis',
    'Tugas',
    'UTS',
    'UAS',
  ];

  /// Check if all components have valid values (0-100)
  bool isValid() {
    final components = getComponentValues();
    return components.every((nilai) => nilai >= 0 && nilai <= 100);
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mahasiswa_id': mahasiswaId,
      'matakuliah_id': matakuliahId,
      'nilai_aktivitas': nilaiAktivitas,
      'nilai_proyek': nilaiProyek,
      'nilai_kuis': nilaiKuis,
      'nilai_tugas': nilaiTugas,
      'nilai_uts': nilaiUTS,
      'nilai_uas': nilaiUAS,
      'tahun_ajaran': tahunAjaran,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create NilaiKomponen from Map (from database)
  factory NilaiKomponen.fromMap(Map<String, dynamic> map) {
    return NilaiKomponen(
      id: map['id'] as int?,
      mahasiswaId: map['mahasiswa_id'] as int,
      matakuliahId: map['matakuliah_id'] as int,
      nilaiAktivitas: (map['nilai_aktivitas'] as num).toDouble(),
      nilaiProyek: (map['nilai_proyek'] as num).toDouble(),
      nilaiKuis: (map['nilai_kuis'] as num).toDouble(),
      nilaiTugas: (map['nilai_tugas'] as num).toDouble(),
      nilaiUTS: (map['nilai_uts'] as num).toDouble(),
      nilaiUAS: (map['nilai_uas'] as num).toDouble(),
      tahunAjaran: map['tahun_ajaran'] as int,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  /// Create a copy with modified fields
  NilaiKomponen copyWith({
    int? id,
    int? mahasiswaId,
    int? matakuliahId,
    double? nilaiAktivitas,
    double? nilaiProyek,
    double? nilaiKuis,
    double? nilaiTugas,
    double? nilaiUTS,
    double? nilaiUAS,
    int? tahunAjaran,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NilaiKomponen(
      id: id ?? this.id,
      mahasiswaId: mahasiswaId ?? this.mahasiswaId,
      matakuliahId: matakuliahId ?? this.matakuliahId,
      nilaiAktivitas: nilaiAktivitas ?? this.nilaiAktivitas,
      nilaiProyek: nilaiProyek ?? this.nilaiProyek,
      nilaiKuis: nilaiKuis ?? this.nilaiKuis,
      nilaiTugas: nilaiTugas ?? this.nilaiTugas,
      nilaiUTS: nilaiUTS ?? this.nilaiUTS,
      nilaiUAS: nilaiUAS ?? this.nilaiUAS,
      tahunAjaran: tahunAjaran ?? this.tahunAjaran,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'NilaiKomponen(mahasiswaId: $mahasiswaId, matakuliahId: $matakuliahId, '
      'aktivitas: $nilaiAktivitas, proyek: $nilaiProyek, kuis: $nilaiKuis, '
      'tugas: $nilaiTugas, uts: $nilaiUTS, uas: $nilaiUAS)';
}
