import 'database_helper.dart';

/// Service untuk menghitung nilai Sub-CPMK, CPMK, dan CPL
/// 
/// Rumus:
/// - Nilai_SubCPMK = nilai dari table sub_cpmk_nilai
/// - Nilai_CPMK = Σ (Nilai_SubCPMK × bobot_SubCPMK_to_CPMK) / Σ bobot
/// - Nilai_MK_Weighted = Σ (Nilai_SubCPMK × bobot_RPS_to_SubCPMK)
/// - Nilai_CPL = Σ (Nilai_MK × SKS) / Σ SKS
class AcademicCalculationService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Hitung nilai Sub-CPMK untuk satu mahasiswa pada satu Sub-CPMK
  /// 
  /// Returns: nilai Sub-CPMK atau null jika tidak ada data
  Future<double?> calculateSubCPMKValue(
    int mahasiswaId,
    int subCpmkId,
    int tahunAjaran,
  ) async {
    try {
      // Get nilai dari table sub_cpmk_nilai
      final nilaiData = await _dbHelper.getSubCPMKNilai(
        mahasiswaId,
        subCpmkId,
        tahunAjaran,
      );

      if (nilaiData == null) {
        return null;
      }

      // Nilai Sub-CPMK adalah nilai langsung dari table
      return (nilaiData['nilai'] as num?)?.toDouble();
    } catch (e) {
      print('Error calculating Sub-CPMK value: $e');
      return null;
    }
  }

  /// Hitung nilai CPMK berdasarkan agregasi Sub-CPMK
  /// 
  /// Rumus: Nilai_CPMK = Σ (Nilai_SubCPMK × bobot_SubCPMK_to_CPMK) / Σ bobot
  /// 
  /// Returns: nilai CPMK atau null jika tidak ada data
  Future<double?> calculateCPMKValue(
    int mahasiswaId,
    int cpmkId,
    int tahunAjaran,
  ) async {
    try {
      // Get semua Sub-CPMK yang berkontribusi ke CPMK ini
      // menggunakan table sub_cpmk_cpmk_mapping
      final subCpmkMappings = await _dbHelper.getCPMKSubCPMKMapping(cpmkId);

      if (subCpmkMappings.isEmpty) {
        return null;
      }

      double totalWeightedValue = 0;
      double totalBobot = 0;
      int validCount = 0;

      for (var mapping in subCpmkMappings) {
        final subCpmkId = mapping['sub_cpmk_id'] as int;
        final bobot = (mapping['bobot'] as num?)?.toDouble() ?? 0.0;

        // Get nilai Sub-CPMK ini
        final subCpmkValue = await calculateSubCPMKValue(
          mahasiswaId,
          subCpmkId,
          tahunAjaran,
        );

        if (subCpmkValue != null) {
          totalWeightedValue += subCpmkValue * bobot;
          totalBobot += bobot;
          validCount++;
        }
      }

      // Return null jika tidak ada Sub-CPMK dengan nilai
      if (validCount == 0) {
        return null;
      }

      // Hitung bobot yang valid
      if (totalBobot == 0) {
        return null;
      }

      return totalWeightedValue / totalBobot;
    } catch (e) {
      print('Error calculating CPMK value: $e');
      return null;
    }
  }

  /// Hitung nilai Mata Kuliah berdasarkan agregasi Sub-CPMK dengan bobot RPS
  /// 
  /// Rumus: Nilai_MK = Σ (Nilai_SubCPMK × bobot_RPS_minggu_ke_SubCPMK)
  /// 
  /// Returns: nilai MK atau null jika tidak ada data
  Future<double?> calculateMatakuliahValue(
    int mahasiswaId,
    int matakuliahId,
    int tahunAjaran,
  ) async {
    try {
      // Get semua RPS Detail untuk MK ini
      final rpsDetailList = await _dbHelper.getRPSDetailByMatakuliah(matakuliahId);

      if (rpsDetailList.isEmpty) {
        return null;
      }

      double totalWeightedValue = 0;
      int validCount = 0;

      // Iterate setiap minggu
      for (var rpsDetail in rpsDetailList) {
        // Get bobot Sub-CPMK untuk minggu ini
        final subCpmkBobots = await _dbHelper.getRPSDetailSubCPMKBobot(rpsDetail.id!);

        if (subCpmkBobots.isEmpty) {
          continue;
        }

        // Untuk setiap Sub-CPMK di minggu ini
        for (var bobotData in subCpmkBobots) {
          final subCpmkId = bobotData['sub_cpmk_id'] as int;
          final bobot = (bobotData['bobot'] as num?)?.toDouble() ?? 0.0;

          // Get nilai Sub-CPMK
          final subCpmkValue = await calculateSubCPMKValue(
            mahasiswaId,
            subCpmkId,
            tahunAjaran,
          );

          if (subCpmkValue != null) {
            totalWeightedValue += subCpmkValue * bobot;
            validCount++;
          }
        }
      }

      // Return null jika tidak ada Sub-CPMK dengan nilai
      if (validCount == 0) {
        return null;
      }

      // Jika total bobot tidak 100%, normalisasi
      // (sesuai bobot RPS yang sudah ditetapkan dari 16 minggu)
      return totalWeightedValue / 100.0; // Karena bobot sudah dalam % dari 16 minggu
    } catch (e) {
      print('Error calculating Matakuliah value: $e');
      return null;
    }
  }

  /// Hitung nilai CPL menggunakan weighted average berdasarkan SKS
  /// 
  /// Rumus: Nilai_CPL = Σ (Nilai_MK × SKS) / Σ SKS
  /// 
  /// Untuk semua MK yang berkontribusi ke CPL tertentu
  /// 
  /// Returns: nilai CPL atau null jika tidak ada data
  Future<double?> calculateCPLValue(
    int mahasiswaId,
    int cplId,
    int tahunAjaran,
  ) async {
    try {
      // Get semua CPMK yang berkontribusi ke CPL ini
      final cpmkMappings = await _dbHelper.getMappingByCPL(cplId);

      if (cpmkMappings.isEmpty) {
        return null;
      }

      // Kumpulkan semua MK yang berkontribusi
      final mkMap = <int, (double, int)>{}; // Map<matakuliahId, (totalCPMKValue, totalSKS)>

      for (var cpmkMapping in cpmkMappings) {
        final cpmkId = cpmkMapping.cpmkId;
        
        // Get detail CPMK untuk tahu matakuliahId
        final cpmkDetail = await _dbHelper.getCPMKById(cpmkId);
        if (cpmkDetail == null) continue;

        final matakuliahId = cpmkDetail.matakuliahId;

        // Get nilai CPMK
        final cpmkValue = await calculateCPMKValue(
          mahasiswaId,
          cpmkId,
          tahunAjaran,
        );

        if (cpmkValue != null) {
          // Get SKS dari matakuliah
          final matakuliah = await _dbHelper.getMatakuliahById(matakuliahId);
          if (matakuliah != null) {
            if (mkMap.containsKey(matakuliahId)) {
              final (_, sks) = mkMap[matakuliahId]!;
              mkMap[matakuliahId] = (cpmkValue, sks);
            } else {
              mkMap[matakuliahId] = (cpmkValue, matakuliah.sks);
            }
          }
        }
      }

      if (mkMap.isEmpty) {
        return null;
      }

      // Hitung weighted average berdasarkan SKS
      double totalWeightedValue = 0;
      int totalSKS = 0;

      mkMap.forEach((_, record) {
        final (value, sks) = record;
        totalWeightedValue += value * sks;
        totalSKS += sks;
      });

      if (totalSKS == 0) {
        return null;
      }

      return totalWeightedValue / totalSKS;
    } catch (e) {
      print('Error calculating CPL value: $e');
      return null;
    }
  }

  /// Generate comprehensive report untuk satu mahasiswa
  Future<Map<String, dynamic>> generateStudentReport(
    int mahasiswaId,
    int tahunAjaran,
  ) async {
    try {
      // Get data mahasiswa
      final mahasiswaList = await _dbHelper.getAllMahasiswa();
      final mahasiswa = mahasiswaList.firstWhere(
        (m) => m.id == mahasiswaId,
        orElse: () => throw Exception('Mahasiswa tidak ditemukan'),
      );

      // Get semua nilai Sub-CPMK
      final subCpmkNilaiList = await _dbHelper.getSubCPMKNilaiByMahasiswa(
        mahasiswaId,
        tahunAjaran,
      );

      // Get semua CPMK
      final allCPMK = await _dbHelper.getAllCPMK();

      // Get semua CPL
      final allCPL = await _dbHelper.getAllCPLMaster();

      // Build report
      final report = <String, dynamic>{
        'mahasiswa': {
          'id': mahasiswa.id,
          'nim': mahasiswa.nim,
          'nama': mahasiswa.nama,
        },
        'tahunAjaran': tahunAjaran,
        'subCPMK': <dynamic>[],
        'cpmk': <dynamic>[],
        'cpl': <dynamic>[],
        'summary': <String, double>{},
      };

      // Calculate Sub-CPMK values
      for (var nilaiData in subCpmkNilaiList) {
        final subCpmkId = nilaiData['sub_cpmk_id'] as int;
        final nilai = (nilaiData['nilai'] as num).toDouble();

        report['subCPMK'].add({
          'id': subCpmkId,
          'nilai': nilai,
        });
      }

      // Calculate CPMK values
      for (var cpmk in allCPMK) {
        final cpmkValue = await calculateCPMKValue(
          mahasiswaId,
          cpmk.id!,
          tahunAjaran,
        );

        if (cpmkValue != null) {
          report['cpmk'].add({
            'id': cpmk.id,
            'kode': cpmk.kodeCPMK,
            'nilai': cpmkValue,
          });
        }
      }

      // Calculate CPL values
      for (var cpl in allCPL) {
        final cplValue = await calculateCPLValue(
          mahasiswaId,
          cpl.id!,
          tahunAjaran,
        );

        if (cplValue != null) {
          report['cpl'].add({
            'id': cpl.id,
            'kode': cpl.kodeCPL,
            'nilai': cplValue,
          });
        }
      }

      // Calculate summary
      final cpmkValues = (report['cpmk'] as List).map<double>(
        (c) => c['nilai'] as double,
      );
      if (cpmkValues.isNotEmpty) {
        final avgCPMK = cpmkValues.reduce((a, b) => a + b) / cpmkValues.length;
        report['summary']['averageCPMK'] = avgCPMK;
      }

      final cplValues = (report['cpl'] as List).map<double>(
        (c) => c['nilai'] as double,
      );
      if (cplValues.isNotEmpty) {
        final avgCPL = cplValues.reduce((a, b) => a + b) / cplValues.length;
        report['summary']['averageCPL'] = avgCPL;
      }

      return report;
    } catch (e) {
      print('Error generating student report: $e');
      rethrow;
    }
  }

  /// Check apakah data lengkap untuk kalkulasi
  Future<Map<String, dynamic>> checkDataCompleteness(
    int mahasiswaId,
    int tahunAjaran,
  ) async {
    try {
      final completeness = <String, dynamic>{
        'mahasiswa': true,
        'subCPMK': false,
        'cpmk': false,
        'cpl': false,
        'issues': <String>[],
      };

      // Check mahasiswa
      final mahasiswaList = await _dbHelper.getAllMahasiswa();
      if (!mahasiswaList.any((m) => m.id == mahasiswaId)) {
        completeness['mahasiswa'] = false;
        completeness['issues'].add('Mahasiswa tidak ditemukan');
      }

      // Check Sub-CPMK nilai
      final subCpmkNilai = await _dbHelper.getSubCPMKNilaiByMahasiswa(
        mahasiswaId,
        tahunAjaran,
      );
      completeness['subCPMK'] = subCpmkNilai.isNotEmpty;
      if (subCpmkNilai.isEmpty) {
        completeness['issues'].add('Nilai Sub-CPMK tidak ada');
      }

      // Check CPMK mapping
      final allCPMK = await _dbHelper.getAllCPMK();
      if (allCPMK.isEmpty) {
        completeness['issues'].add('CPMK tidak ada');
      } else {
        final cpmkMappings = <bool>[];
        for (var cpmk in allCPMK) {
          final mapping = await _dbHelper.getCPMKSubCPMKMapping(cpmk.id!);
          cpmkMappings.add(mapping.isNotEmpty);
        }
        completeness['cpmk'] = cpmkMappings.isNotEmpty && cpmkMappings.every((m) => m);
        if (!completeness['cpmk']) {
          completeness['issues'].add('Mapping Sub-CPMK ke CPMK belum lengkap');
        }
      }

      // Check CPL mapping
      final allCPL = await _dbHelper.getAllCPLMaster();
      if (allCPL.isEmpty) {
        completeness['issues'].add('CPL tidak ada');
      } else {
        final cplMappings = <bool>[];
        for (var cpl in allCPL) {
          final mapping = await _dbHelper.getMappingByCPL(cpl.id!);
          cplMappings.add(mapping.isNotEmpty);
        }
        completeness['cpl'] = cplMappings.isNotEmpty && cplMappings.every((m) => m);
        if (!completeness['cpl']) {
          completeness['issues'].add('Mapping CPMK ke CPL belum lengkap');
        }
      }

      return completeness;
    } catch (e) {
      print('Error checking data completeness: $e');
      rethrow;
    }
  }
}
