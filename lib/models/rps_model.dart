class RPS {
  final int? id;
  final int matakuliahId;
  final String filePath; // path ke file RPS yang diupload
  final String fileName;
  final String? deskripsi;
  final List<String>? cplMappings; // Learning outcomes yang dipetakan
  final DateTime uploadDate;
  final DateTime? updatedAt;

  RPS({
    this.id,
    required this.matakuliahId,
    required this.filePath,
    required this.fileName,
    this.deskripsi,
    this.cplMappings,
    required this.uploadDate,
    this.updatedAt,
  });

  factory RPS.fromMap(Map<String, dynamic> map) {
    return RPS(
      id: map['id'] as int?,
      matakuliahId: map['matakuliah_id'] as int,
      filePath: map['file_path'] as String,
      fileName: map['file_name'] as String,
      deskripsi: map['deskripsi'] as String?,
      cplMappings: (map['cpl_mappings'] as String?)?.split(','),
      uploadDate: DateTime.parse(map['upload_date'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'matakuliah_id': matakuliahId,
      'file_path': filePath,
      'file_name': fileName,
      'deskripsi': deskripsi,
      'cpl_mappings': cplMappings?.join(','),
      'upload_date': uploadDate.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  RPS copyWith({
    int? id,
    int? matakuliahId,
    String? filePath,
    String? fileName,
    String? deskripsi,
    List<String>? cplMappings,
    DateTime? uploadDate,
    DateTime? updatedAt,
  }) {
    return RPS(
      id: id ?? this.id,
      matakuliahId: matakuliahId ?? this.matakuliahId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      deskripsi: deskripsi ?? this.deskripsi,
      cplMappings: cplMappings ?? this.cplMappings,
      uploadDate: uploadDate ?? this.uploadDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
