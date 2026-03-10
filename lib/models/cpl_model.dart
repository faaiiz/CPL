class CPL {
  final int? id;
  final int mahasiswaId;
  final String nipMahasiswa;
  final String namaMahasiswa;
  final double ipk; // 0.0 - 4.0
  final String status; // 'belum_lulus', 'memenuhi_cpl', 'tidak_memenuhi_cpl'
  final int totalSku; // Total SKU yang diambil
  final double rataNilai; // Rata-rata nilai
  final String? catatan;
  final DateTime tanggalHitung;
  final DateTime? updatedAt;

  CPL({
    this.id,
    required this.mahasiswaId,
    required this.nipMahasiswa,
    required this.namaMahasiswa,
    required this.ipk,
    required this.status,
    required this.totalSku,
    required this.rataNilai,
    this.catatan,
    required this.tanggalHitung,
    this.updatedAt,
  });

  factory CPL.fromMap(Map<String, dynamic> map) {
    return CPL(
      id: map['id'] as int?,
      mahasiswaId: map['mahasiswa_id'] as int,
      nipMahasiswa: map['nip_mahasiswa'] as String,
      namaMahasiswa: map['nama_mahasiswa'] as String,
      ipk: (map['ipk'] as num).toDouble(),
      status: map['status'] as String,
      totalSku: map['total_sku'] as int,
      rataNilai: (map['rata_nilai'] as num).toDouble(),
      catatan: map['catatan'] as String?,
      tanggalHitung: DateTime.parse(map['tanggal_hitung'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mahasiswa_id': mahasiswaId,
      'nip_mahasiswa': nipMahasiswa,
      'nama_mahasiswa': namaMahasiswa,
      'ipk': ipk,
      'status': status,
      'total_sku': totalSku,
      'rata_nilai': rataNilai,
      'catatan': catatan,
      'tanggal_hitung': tanggalHitung.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CPL copyWith({
    int? id,
    int? mahasiswaId,
    String? nipMahasiswa,
    String? namaMahasiswa,
    double? ipk,
    String? status,
    int? totalSku,
    double? rataNilai,
    String? catatan,
    DateTime? tanggalHitung,
    DateTime? updatedAt,
  }) {
    return CPL(
      id: id ?? this.id,
      mahasiswaId: mahasiswaId ?? this.mahasiswaId,
      nipMahasiswa: nipMahasiswa ?? this.nipMahasiswa,
      namaMahasiswa: namaMahasiswa ?? this.namaMahasiswa,
      ipk: ipk ?? this.ipk,
      status: status ?? this.status,
      totalSku: totalSku ?? this.totalSku,
      rataNilai: rataNilai ?? this.rataNilai,
      catatan: catatan ?? this.catatan,
      tanggalHitung: tanggalHitung ?? this.tanggalHitung,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
