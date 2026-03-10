import '../models/sub_cpmk_nilai_model.dart';
import 'database_helper.dart';

/// 🎯 OBE Calculation Engine
/// Menghitung Nilai Sub-CPMK, CPMK, dan CPL berdasarkan data yang ada
/// 
/// Rule:
/// - TIDAK membuat nilai
/// - TIDAK mengubah nilai
/// - HANYA menghitung berdasarkan data yang diberikan sistem
/// - Jika nilai tidak tersedia → anggap 0
/// - Pembulatan 2 desimal
class OBECalculationHelper {
  final DatabaseHelper _dbHelper;

  // Cache untuk meningkatkan performa
  late Map<String, dynamic> _cache;

  OBECalculationHelper({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper() {
    _cache = {};
  }

  /// 🎯 PENTING: Clear cache agar tidak menggunakan data stale
  /// Call ini setelah RPS data berubah (update/insert)
  void clearCache() {
    _cache.clear();
  }

  ///  Simpan hasil perhitungan Sub-CPMK ke database
  Future<bool> saveSubCPMKNilai(
    int mahasiswaId,
    int subCpmkId,
    double nilai,
    int tahunAjaran,
  ) async {
    try {
      final subCpmkNilai = SubCPMKNilai(
        mahasiswaId: mahasiswaId,
        subCpmkId: subCpmkId,
        nilai: nilai,
        tahunAjaran: tahunAjaran,
        createdAt: DateTime.now(),
      );

      await _dbHelper.insertSubCPMKNilai(subCpmkNilai);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 🔢 Pembulatan ke 2 desimal
  double _roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }

  /// 🎯 ACADEMIC OBE CALCULATION ENGINE
  /// Menghitung Sub-CPMK dan CPMK menggunakan weighted average matrix
  /// 
  /// Sub-CPMK Formula:
  /// SubCPMK_i = (Σ nilai_komponen × bobot) / total_bobot_komponen
  ///
  /// CPMK Formula:
  /// CPMK = (Σ SubCPMK × bobot_subcpmk) / total_bobot_subcpmk
  /// 
  /// Rules:
  /// - Gunakan hanya bobot yang diberikan
  /// - Hanya komponen dengan bobot > 0 yang dihitung
  /// - Total bobot sub-CPMK harus = 100
  /// - Semua hasil dibulatkan 2 desimal
  /// - Output deterministik dan konsisten
  
  /// Hitung Sub-CPMK dengan matriks bobot komponen
  /// 
  /// Parameter:
  /// - nilaiKomponen: List nilai komponen [Aktivitas, Hasil Proyek, Kuis, Tugas, UTS, UAS]
  /// - bobotMatrix: Map<subCpmkId, List<double>> berisi bobot setiap komponen per sub-CPMK
  /// 
  /// Return: Map<subCpmkId, double> hasil perhitungan Sub-CPMK
  /// Throws: Exception jika data tidak valid
  Map<int, double> calculateSubCPMKWithMatrix({
    required List<double> nilaiKomponen,
    required Map<int, List<double>> bobotMatrix,
  }) {
    // 1. Validasi input
    if (nilaiKomponen.isEmpty) {
      throw Exception('❌ Nilai komponen tidak boleh kosong');
    }

    if (bobotMatrix.isEmpty) {
      throw Exception('❌ Bobot matrix tidak boleh kosong');
    }

    final result = <int, double>{};

    // 2. Hitung setiap Sub-CPMK
    bobotMatrix.forEach((subCpmkId, bobot) {
      if (bobot.length != nilaiKomponen.length) {
        throw Exception(
          '❌ Jumlah bobot (${bobot.length}) tidak sesuai dengan jumlah '
          'komponen nilai (${nilaiKomponen.length}) untuk Sub-CPMK $subCpmkId',
        );
      }

      // Hitung weighted sum dan total bobot aktif
      double weightedSum = 0.0;
      double totalBobot = 0.0;

      for (int i = 0; i < bobot.length; i++) {
        if (bobot[i] > 0) {
          // Hanya komponen dengan bobot > 0 yang dihitung
          weightedSum += nilaiKomponen[i] * bobot[i];
          totalBobot += bobot[i];
        }
      }

      if (totalBobot == 0) {
        throw Exception(
          '❌ Total bobot untuk Sub-CPMK $subCpmkId = 0. '
          'Minimal ada satu komponen dengan bobot > 0',
        );
      }

      // Hitung Sub-CPMK value
      final subCpmkValue = weightedSum / totalBobot;
      result[subCpmkId] = _roundToTwoDecimals(subCpmkValue);
    });

    return result;
  }

  /// Hitung CPMK dari Sub-CPMK dengan validasi total bobot = 100
  /// 
  /// Parameter:
  /// - subCpmkValues: Map<subCpmkId, nilai> hasil dari calculateSubCPMKWithMatrix
  /// - subCpmkBobotToCpmk: Map<cpmkId, Map<subCpmkId, bobot>> mapping Sub-CPMK ke CPMK dengan bobot
  /// 
  /// Return: Map<cpmkId, double> hasil perhitungan CPMK
  /// Throws: Exception jika total bobot ≠ 100
  Map<int, double> calculateCPMKFromSubCPMK({
    required Map<int, double> subCpmkValues,
    required Map<int, Map<int, double>> subCpmkBobotToCpmk,
  }) {
    if (subCpmkValues.isEmpty) {
      throw Exception('❌ Sub-CPMK values tidak boleh kosong');
    }

    if (subCpmkBobotToCpmk.isEmpty) {
      throw Exception('❌ Bobot mapping Sub-CPMK ke CPMK tidak boleh kosong');
    }

    final result = <int, double>{};

    // Hitung setiap CPMK
    subCpmkBobotToCpmk.forEach((cpmkId, subCpmkBobot) {
      double weightedSum = 0.0;
      double totalBobot = 0.0;

      // Validasi dan hitung
      subCpmkBobot.forEach((subCpmkId, bobot) {
        if (!subCpmkValues.containsKey(subCpmkId)) {
          throw Exception(
            '❌ Sub-CPMK $subCpmkId tidak ditemukan dalam values',
          );
        }

        if (bobot > 0) {
          weightedSum += subCpmkValues[subCpmkId]! * bobot;
          totalBobot += bobot;
        }
      });

      // Validasi total bobot = 100
      if ((totalBobot - 100).abs() > 0.01) {
        // Tolerance 0.01 untuk floating point
        throw Exception(
          '❌ Total bobot Sub-CPMK untuk CPMK $cpmkId = $totalBobot '
          '(harus = 100)',
        );
      }

      final cpmkValue = weightedSum / totalBobot;
      result[cpmkId] = _roundToTwoDecimals(cpmkValue);
    });

    return result;
  }

  /// Hitung CPMK langsung dari nilai komponen
  /// 
  /// Formula:
  /// CPMK = (Σ SubCPMK × bobot_sub) / 100
  /// dimana SubCPMK_i = (Σ nilai × bobot) / total_bobot_sub_i
  /// 
  /// Parameter:
  /// - nilaiKomponen: List nilai komponen
  /// - bobotMatrix: Map<subCpmkId, List<double>> bobot komponen per sub-CPMK
  /// - subCpmkBobot: Map<cpmkId, Map<subCpmkId, double>> bobot sub-CPMK per CPMK
  /// 
  /// Return: Map<cpmkId, double> nilai CPMK yang sudah divalidasi
  Map<int, double> calculateCPMKFull({
    required List<double> nilaiKomponen,
    required Map<int, List<double>> bobotMatrix,
    required Map<int, Map<int, double>> subCpmkBobot,
  }) {
    // 1. Hitung Sub-CPMK
    final subCpmkValues = calculateSubCPMKWithMatrix(
      nilaiKomponen: nilaiKomponen,
      bobotMatrix: bobotMatrix,
    );

    // 2. Hitung CPMK dari Sub-CPMK dengan validasi
    final cpmkValues = calculateCPMKFromSubCPMK(
      subCpmkValues: subCpmkValues,
      subCpmkBobotToCpmk: subCpmkBobot,
    );

    return cpmkValues;
  }

  /// Get nilai akhir per komponen untuk perhitungan detail
  /// Note: Saat ini sistem menyimpan nilai akhir. Untuk perhitungan
  /// berbasis komponen, perlu extension table untuk menyimpan
  /// nilai individu (aktivitas, tugas, kuis, uts, uas, hasil proyek)
  Future<Map<String, double>> getNilaiKomponen(
    int mahasiswaId,
    int matakuliahId,
    int tahunAjaran,
  ) async {
    try {
      // Placeholder untuk implementasi future
      // Ketika ada extension table untuk menyimpan nilai komponen
      // maka method ini akan mengambil dari database
      final result = <String, double>{};
      
      // Untuk saat ini, return empty map
      // Update ketika ada table untuk nilai komponen per mahasiswa
      return result;
    } catch (e) {
      return {};
    }
  }

  /// 🔄 Hitung CPL untuk semua mahasiswa dalam 1 tahun ajaran dan matakuliah
  Future<List<OBECalculationResult>> calculateAllMahasiswaCPL(
    int matakuliahId,
    int tahunAjaran,
  ) async {
    try {
      final results = <OBECalculationResult>[];

      // 🎯 PENTING: Clear cache sebelum batch calculation
      // Ini memastikan data terbaru digunakan (terutama jika RPS berubah)
      clearCache();

      // 🚀 OPTIMASI: Filter nilai by matakuliah dan tahun_ajaran
      // Hanya hitung mahasiswa yang memiliki nilai untuk MK ini
      final nilaiList = await _dbHelper.getNilaiByMatakuliah(matakuliahId);
      
      // Filter by tahun_ajaran
      final filteredNilai = nilaiList
          .where((n) => n.tahunAjaran == tahunAjaran)
          .toList();

      if (filteredNilai.isEmpty) {
        print('⚠️ No nilai found for matakuliah $matakuliahId, tahun_ajaran $tahunAjaran');
        return results;
      }

      // Extract unique mahasiswa IDs
      final uniqueMahasiswaIds = <int>{};
      for (final nilai in filteredNilai) {
        if (nilai.mahasiswaId > 0) {
          uniqueMahasiswaIds.add(nilai.mahasiswaId);
        }
      }

      if (uniqueMahasiswaIds.isEmpty) {
        print('⚠️ No valid mahasiswa IDs found');
        return results;
      }

      print('🎯 Processing ${uniqueMahasiswaIds.length} mahasiswa for MK $matakuliahId');

      // 🚀 OPTIMASI: Pre-load semua reference data sekali
      // Alih-alih per mahasiswa, load sekali untuk semua
      
      try {
        // Load semua data yang dibutuhkan dalam parallel
        final rpsDetailsTask = _dbHelper.getRPSDetailByMatakuliah(matakuliahId);
        final subCpmkCpmkMappingsTask = _loadAllSubCpmkCpmkMappings();
        final cpmkCplMappingsTask = _loadAllCpmkCplMappings();
        
        final rpsDetails = await rpsDetailsTask;
        final allSubCpmkCpmkMappings = await subCpmkCpmkMappingsTask;
        final allCpmkCplMappings = await cpmkCplMappingsTask;
        
        // Cache data untuk reuse
        _cache = {
          'rpsDetails': rpsDetails,
          'subCpmkCpmkMappings': allSubCpmkCpmkMappings,
          'cpmkCplMappings': allCpmkCplMappings,
        };
      } catch (e) {
        print('⚠️ Error pre-loading reference data: $e');
        // Continue dengan cache kosong - fallback akan handle
      }

      // 🚀 OPTIMASI: Process mahasiswa dalam batch
      // Hanya process mahasiswa yang punya nilai
      int successCount = 0;
      int errorCount = 0;
      
      for (final mahasiswaId in uniqueMahasiswaIds) {
        try {
          final result = await calculateAllOBEValuesOptimized(
            mahasiswaId,
            matakuliahId,
            tahunAjaran,
          );
          
          if (result.hasData) {
            results.add(result);
            successCount++;
          }
        } catch (e) {
          print('❌ Error processing mahasiswa $mahasiswaId: $e');
          errorCount++;
        }
      }

      print('✅ Batch calculation complete: $successCount success, $errorCount errors');

      return results;
    } catch (e) {
      print('❌ CRITICAL ERROR in calculateAllMahasiswaCPL: $e');
      return [];
    }
  }

  /// Load all SubCPMK-CPMK mappings in one query
  Future<Map<int, List<dynamic>>> _loadAllSubCpmkCpmkMappings() async {
    try {
      // 🚀 OPTIMASI: Load semua mappings dalam satu batch query
      final allMappings = await _dbHelper.getAllSubCPMKCPMKMappings();
      
      // Build map untuk quick access
      final mappingResult = <int, List<dynamic>>{};
      for (final mapping in allMappings) {
        final subCpmkId = mapping['sub_cpmk_id'] as int;
        if (!mappingResult.containsKey(subCpmkId)) {
          mappingResult[subCpmkId] = [];
        }
        mappingResult[subCpmkId]!.add(mapping);
      }

      return mappingResult;
    } catch (e) {
      return {};
    }
  }

  /// Load all CPMK-CPL mappings in one query
  Future<Map<int, List<dynamic>>> _loadAllCpmkCplMappings() async {
    try {
      final allMappings = await _dbHelper.getAllCPMKCPLMappings();
      
      final mappingResult = <int, List<dynamic>>{};
      for (final mapping in allMappings) {
        final cpmkId = mapping is Map ? mapping['cpmk_id'] as int : mapping.cpmkId as int;
        if (!mappingResult.containsKey(cpmkId)) {
          mappingResult[cpmkId] = [];
        }
        mappingResult[cpmkId]!.add(mapping);
      }

      return mappingResult;
    } catch (e) {
      return {};
    }
  }

  /// Hitung nilai OBE dengan cached data (lebih cepat)
  Future<OBECalculationResult> calculateAllOBEValuesOptimized(
    int mahasiswaId,
    int matakuliahId,
    int tahunAjaran,
  ) async {
    try {
      final subCpmkValues = await calculateSubCPMKValuesOptimized(
        mahasiswaId,
        matakuliahId,
        tahunAjaran,
      );

      final cpmkValues = await calculateCPMKValuesOptimized(
        mahasiswaId,
        matakuliahId,
        tahunAjaran,
        subCpmkValues,
      );

      final cplValues = await calculateCPLValuesOptimized(
        mahasiswaId,
        matakuliahId,
        tahunAjaran,
        cpmkValues,
      );

      // 🎯 PENTING: Load bobot Sub-CPMK dari bobot matrix (bukan RPS Details!)
      // Ini memastikan averageSubCPMKNilai menggunakan bobot yang sama dengan CPMK calculation
      Map<int, double>? subCpmkBobots;
      try {
        subCpmkBobots = await _getSubCpmkBobots(matakuliahId);
      } catch (e) {
        // Ignore error
      }

      return OBECalculationResult(
        mahasiswaId: mahasiswaId,
        matakuliahId: matakuliahId,
        tahunAjaran: tahunAjaran,
        subCPMKValues: subCpmkValues,
        cpmkValues: cpmkValues,
        cplValues: cplValues,
        subCpmkBobots: subCpmkBobots,
      );
    } catch (e) {

      return OBECalculationResult(
        mahasiswaId: mahasiswaId,
        matakuliahId: matakuliahId,
        tahunAjaran: tahunAjaran,
        subCPMKValues: {},
        cpmkValues: {},
        cplValues: {},
      );
    }
  }

  /// 🎯 NEW METHOD: Ambil bobot total untuk setiap Sub-CPMK dari RPS
  /// Return: Map<subCpmkId, totalBobot>
  /// Contoh: {1: 15, 2: 15, 3: 15, 4: 9, 5: 14, 6: 14, 7: 18}
  Future<Map<int, double>> _getSubCpmkBobots(int matakuliahId) async {
    try {
      final result = <int, double>{};
      
      // Get bobot matrix untuk mata kuliah ini
      final bobotMatrixRaw = await _dbHelper.getBobotMatrixForMatakuliah(
        matakuliahId: matakuliahId,
      );

      if (bobotMatrixRaw.isEmpty) {
        return result;
      }

      // Hitung total bobot untuk setiap Sub-CPMK
      for (final entry in bobotMatrixRaw.entries) {
        final subCpmkId = entry.key;
        final bobotList = entry.value;
        
        double totalBobot = 0.0;
        for (final bobot in bobotList) {
          totalBobot += bobot;
        }
        
        result[subCpmkId] = totalBobot;
      }

      return result;
    } catch (e) {
      return {};
    }
  }

  /// 🎯 NEW METHOD: Extract CPMK IDs untuk matakuliah ini dari RPS
  /// Return: Set<int> berisi unique CPMK IDs yang user input di RPS
  /// Contoh untuk Kalkulus & Vektor: {3}
  Future<Set<int>> _getCpmkIdsForMatakuliah(int matakuliahId) async {
    try {
      final cpmkIds = <int>{};
      final rpsDetails = await _dbHelper.getRPSDetailByMatakuliah(matakuliahId);
      
      for (final rpsDetail in rpsDetails) {
        if (rpsDetail.cpmkIds != null && rpsDetail.cpmkIds!.isNotEmpty) {
          cpmkIds.addAll(rpsDetail.cpmkIds!);
        }
      }
      return cpmkIds;
    } catch (e) {
      return {};
    }
  }

  /// Calculate SubCPMK dengan cached RPS Details
  /// 🎯 PRIORITAS: Gunakan component scores jika ada, fallback ke nilai akhir
  Future<Map<int, double>> calculateSubCPMKValuesOptimized(
    int mahasiswaId,
    int matakuliahId,
    int tahunAjaran,
  ) async {
    try {
      final result = <int, double>{};

      // 🎯 TRY 1: Hitung menggunakan component scores (prioritas utama)
      final nilaiKomponenMap = await _dbHelper.getNilaiKomponen(
        mahasiswaId: mahasiswaId,
        matakuliahId: matakuliahId,
        tahunAjaran: tahunAjaran,
      );

      if (nilaiKomponenMap != null && nilaiKomponenMap.isNotEmpty) {
        try {
          // Konversi ke list: [aktivitas, proyek, kuis, tugas, uts, uas]
          final nilaiComponents = [
            (nilaiKomponenMap['nilai_aktivitas'] as num).toDouble(),
            (nilaiKomponenMap['nilai_proyek'] as num).toDouble(),
            (nilaiKomponenMap['nilai_kuis'] as num).toDouble(),
            (nilaiKomponenMap['nilai_tugas'] as num).toDouble(),
            (nilaiKomponenMap['nilai_uts'] as num).toDouble(),
            (nilaiKomponenMap['nilai_uas'] as num).toDouble(),
          ];

          // Get bobot matrix untuk course ini
          // Format: Map<subCpmkId, List<bobot untuk setiap komponen>>
          final bobotMatrixRaw = await _dbHelper.getBobotMatrixForMatakuliah(
            matakuliahId: matakuliahId,
          );

          if (bobotMatrixRaw.isNotEmpty) {
            // Convert format dari database ke format yang dibutuhkan calculateSubCPMKWithMatrix
            final bobotMatrixFormatted = <int, List<double>>{};
            for (final entry in bobotMatrixRaw.entries) {
              final subCpmkId = int.parse(entry.key.toString());
              final bobots = (entry.value as List)
                  .map((b) => (b as num).toDouble())
                  .toList();
              bobotMatrixFormatted[subCpmkId] = bobots;
            }

            // Hitung Sub-CPMK menggunakan rumus OBE dengan component scores
            final subCpmkResult = calculateSubCPMKWithMatrix(
              nilaiKomponen: nilaiComponents,
              bobotMatrix: bobotMatrixFormatted,
            );

            return subCpmkResult;
          }
        } catch (e) {
          // Fallback ke grade-based
        }
      }

      // 🎯 TRY 2: Fallback ke nilai akhir jika component scores tidak ada/gagal
      
      // Get nilai akhir mata kuliah
      final nilaiMK = await _dbHelper.getNilai(
        mahasiswaId,
        matakuliahId,
        tahunAjaran,
      );

      if (nilaiMK == null) {
        return result;
      }

      // 🔧 FIX: Konversi nilai dengan mendeteksi skala yang benar
      // Jika nilaiNumerik > 4, maka sudah dalam skala 0-100
      // Jika nilaiNumerik <= 4, maka dalam skala 0-4 dan perlu dikalikan 25
      final nilaiSkala0_100 = nilaiMK.nilaiNumerik > 4 
          ? nilaiMK.nilaiNumerik  // Sudah dalam skala 0-100
          : nilaiMK.nilaiNumerik * 25;  // Konversi dari 0-4 ke 0-100

      // Use cached RPS Details
      final rpsDetails = _cache['rpsDetails'] as List? ?? [];

      // 🚀 OPTIMASI: Pre-load semua bobot untuk RPS Details ini
      final allBobotData = await _loadAllRPSDetailSubCPMKBobots(rpsDetails.cast());

      // Process dengan cached bobot data
      for (final rpsDetail in rpsDetails) {
        if (rpsDetail.subCpmkIds == null || rpsDetail.subCpmkIds!.isEmpty) {
          continue;
        }

        for (final subCpmkId in rpsDetail.subCpmkIds!) {
          final bobotKey = '${rpsDetail.id}_$subCpmkId';
          final bobotValue = allBobotData[bobotKey];

          if (bobotValue == null) {
            continue;
          }

          final nilaiSubCPMK = (nilaiSkala0_100 * bobotValue) / 100.0;

          if (result.containsKey(subCpmkId)) {
            result[subCpmkId] = result[subCpmkId]! + nilaiSubCPMK;
          } else {
            result[subCpmkId] = nilaiSubCPMK;
          }
        }
      }

      result.updateAll((key, value) => _roundToTwoDecimals(value));
      return result;
    } catch (e) {
      return {};
    }
  }

  /// Load semua bobot RPS Detail SubCPMK dalam satu batch query
  Future<Map<String, double>> _loadAllRPSDetailSubCPMKBobots(
    List<dynamic> rpsDetails,
  ) async {
    try {
      final allBobots = <String, double>{};

      // 🚀 OPTIMASI: Load semua bobot dalam satu batch query
      final allBobotRecords = await _dbHelper.getAllRPSDetailSubCPMKBobots();
      
      // Create a map untuk quick lookup
      final bobotMap = <String, double>{};
      for (final record in allBobotRecords) {
        final rpsDetailId = record['rps_detail_id'] as int;
        final subCpmkId = record['sub_cpmk_id'] as int;
        final bobot = record['bobot'] as double;
        final key = '${rpsDetailId}_$subCpmkId';
        bobotMap[key] = bobot;
      }

      // Collect all bobotData items dengan pre-loaded data
      for (final rpsDetail in rpsDetails) {
        if (rpsDetail.subCpmkIds == null || rpsDetail.subCpmkIds!.isEmpty) {
          continue;
        }

        final rpsDetailId = rpsDetail.id;
        for (final subCpmkId in rpsDetail.subCpmkIds!) {
          final key = '${rpsDetailId}_$subCpmkId';
          final bobotValue = bobotMap[key];

          if (bobotValue != null) {
            allBobots[key] = bobotValue;
          }
        }
      }

      return allBobots;
    } catch (e) {
      return {};
    }
  }

  /// Calculate CPMK dengan cached mappings
  /// 🎯 PENTING: Gunakan bobot matrix (dari 6 komponen), bukan RPS Details!
  /// Ini memastikan CPMK dan Sub-CPMK average menggunakan bobot yang sama
  Future<Map<int, double>> calculateCPMKValuesOptimized(
    int mahasiswaId,
    int matakuliahId,
    int tahunAjaran,
    Map<int, double> subCpmkValues,
  ) async {
    try {
      final result = <int, double>{};

      if (subCpmkValues.isEmpty) {
        return result;
      }

      // 🎯 PENTING: Gunakan bobot matrix (dari `_getSubCpmkBobots()`), bukan RPS Details!
      final subCpmkBobots = await _getSubCpmkBobots(matakuliahId);
      
      if (subCpmkBobots.isNotEmpty) {
        // 🎯 REVISI: Baca CPMK IDs dari RPS untuk dynamic header
        // Tapi gunakan bobot matrix untuk perhitungan (untuk consistency dengan dokumentasi)
        final cpmkIds = await _getCpmkIdsForMatakuliah(matakuliahId);
        
        // Kalkulasi setiap CPMK dengan weighted average dari Sub-CPMK
        // Menggunakan bobot dari bobot matrix (kolom Total): [15, 15, 15, 9, 14, 14, 18]
        
        for (final cpmkId in cpmkIds) {
          double totalWeighted = 0.0;
          double totalBobot = 0.0;
          
          for (final subCpmkId in subCpmkValues.keys) {
            final subCpmkValue = subCpmkValues[subCpmkId]!;
            final bobot = subCpmkBobots[subCpmkId] ?? 0.0;
            
            totalWeighted += subCpmkValue * bobot;
            totalBobot += bobot;
          }
          
          if (totalBobot > 0) {
            final cpmkValue = totalWeighted / totalBobot;
            result[cpmkId] = _roundToTwoDecimals(cpmkValue);
          }
        }
        
        if (result.isNotEmpty) {
          return result;
        }
      }

      // 🎯 TRY 2: Fallback ke database mapping
      // Use cached mappings dari database
      final subCpmkCpmkMappings = 
          _cache['subCpmkCpmkMappings'] as Map<int, List<dynamic>>? ?? {};

      // Process dengan cached data
      for (final subCpmkId in subCpmkValues.keys) {
        final cpmkMappings = subCpmkCpmkMappings[subCpmkId] ?? [];

        if (cpmkMappings.isEmpty) {
          continue;
        }

        for (final mapping in cpmkMappings) {
          final cpmkId = mapping is Map 
              ? mapping['cpmk_id'] as int 
              : mapping.cpmkId as int;
          final bobot = mapping is Map 
              ? mapping['bobot'] as double 
              : mapping.bobot as double;

          final nilaiKontribusi = (subCpmkValues[subCpmkId]! * bobot) / 100.0;

          if (result.containsKey(cpmkId)) {
            result[cpmkId] = result[cpmkId]! + nilaiKontribusi;
          } else {
            result[cpmkId] = nilaiKontribusi;
          }
        }
      }

      result.updateAll((key, value) => _roundToTwoDecimals(value));
      return result;
    } catch (e) {
      return {};
    }
  }

  /// Calculate CPL dari CPMK menggunakan RPS mapping
  /// 🎯 LOGIC: CPL value = CPMK value langsung (berdasarkan RPS CPMK→CPL mapping)
  /// Jika 1 CPMK maps ke multiple CPL, duplicate nilai ke semua CPL
  /// Jika multiple CPMK maps ke 1 CPL, aggregate dengan weighted average
  /// 
  /// Ini mengikuti obe_calculation_examples.dart yang simple dan konsisten
  Future<Map<int, double>> calculateCPLValuesOptimized(
    int mahasiswaId,
    int matakuliahId,
    int tahunAjaran,
    Map<int, double> cpmkValues,
  ) async {
    try {
      final result = <int, double>{};

      if (cpmkValues.isEmpty) {
        print('🔍 DEBUG CPL [Empty CPMK]: Mhs=$mahasiswaId, MK=$matakuliahId - No CPMK values');
        return result;
      }

      print('🔍 DEBUG CPL [RPS Direct Mapping]: Mhs=$mahasiswaId, MK=$matakuliahId');
      print('   CPMK Values: $cpmkValues');

      // 🎯 Get RPS Details untuk mendapatkan CPMK→CPL mapping
      final rpsDetails = (_cache['rpsDetails'] as List? ?? [])
          .cast<dynamic>();

      if (rpsDetails.isEmpty) {
        print('   ⚠️ No RPS details found');
        return result;
      }

      // 🎯 Build mapping: CPMK ID → List of CPL IDs (dari RPS)
      final cpmkToCplMapping = <int, List<int>>{};
      final cpmkBobotMap = <int, double>{};

      for (final rpsDetail in rpsDetails) {
        final cpmkIds = rpsDetail.cpmkIds as List<int>?;
        final cplIds = rpsDetail.cplIds as List<int>?;
        final bobot = rpsDetail.bobot as double?;

        if (cpmkIds == null || cplIds == null || bobot == null) {
          continue;
        }

        // Untuk setiap CPMK dalam RPS, track CPL yang terhubung
        for (final cpmkId in cpmkIds) {
          if (!cpmkToCplMapping.containsKey(cpmkId)) {
            cpmkToCplMapping[cpmkId] = [];
            cpmkBobotMap[cpmkId] = bobot;
          }
          cpmkToCplMapping[cpmkId]!.addAll(cplIds);
        }
      }

      print('   RPS CPMK→CPL Mapping: $cpmkToCplMapping');

      // 🎯 Process setiap CPMK dan map ke CPL
      // Logic: CPMK value = CPL value (1:1 relationship dari RPS)
      for (final cpmkId in cpmkValues.keys) {
        final cpmkValue = cpmkValues[cpmkId]!;
        final cplIds = cpmkToCplMapping[cpmkId];

        if (cplIds == null || cplIds.isEmpty) {
          print('   ⚠️ CPMK.$cpmkId tidak memiliki CPL mapping di RPS, skip');
          continue;
        }

        // Duplicate nilai CPMK ke semua CPL yang terhubung
        for (final cplId in cplIds) {
          if (result.containsKey(cplId)) {
            // Jika sudah ada (dari CPMK lain), aggregate dengan average
            result[cplId] = (result[cplId]! + cpmkValue) / 2.0;
            print('   CPMK.$cpmkId ($cpmkValue) + existing CPL.$cplId = ${result[cplId]}');
          } else {
            // First mapping untuk CPL ini
            result[cplId] = cpmkValue;
            print('   CPMK.$cpmkId ($cpmkValue) → CPL.$cplId ($cpmkValue)');
          }
        }
      }

      result.updateAll((key, value) => _roundToTwoDecimals(value));
      print('   Final CPL Values: $result');

      return result;
    } catch (e) {
      print('❌ Error in calculateCPLValuesOptimized: $e');
      return {};
    }
  }
}

/// Model untuk hasil perhitungan OBE
class OBECalculationResult {
  final int mahasiswaId;
  final int matakuliahId;
  final int tahunAjaran;
  final Map<int, double> subCPMKValues; // subCpmkId -> nilai
  final Map<int, double> cpmkValues; // cpmkId -> nilai
  final Map<int, double> cplValues; // cplId -> nilai
  final Map<int, double>? subCpmkBobots; // subCpmkId -> bobot dari bobot matrix (untuk weighted average)

  OBECalculationResult({
    required this.mahasiswaId,
    required this.matakuliahId,
    required this.tahunAjaran,
    required this.subCPMKValues,
    required this.cpmkValues,
    required this.cplValues,
    this.subCpmkBobots,
  });

  /// Rata-rata Sub-CPMK (Weighted Average dengan bobot matrix)
  /// 🎯 PENTING: Menggunakan bobot dari bobot matrix (sama dengan CPMK calculation)
  /// untuk memastikan consistency: Sub-CPMK avg ≈ CPMK
  double get averageSubCPMKNilai {
    if (subCPMKValues.isEmpty) return 0.0;
    
    // Gunakan bobot dari bobot matrix untuk weighted average
    if (subCpmkBobots != null && subCpmkBobots!.isNotEmpty) {
      double totalWeighted = 0.0;
      double totalBobot = 0.0;
      
      subCPMKValues.forEach((subCpmkId, nilai) {
        final bobot = subCpmkBobots![subCpmkId] ?? 0.0;
        totalWeighted += nilai * bobot;
        totalBobot += bobot;
      });
      
      if (totalBobot > 0) {
        final average = totalWeighted / totalBobot;
        return average.clamp(0.0, 100.0);
      }
    }
    
    // Simple average jika tidak ada bobot
    final sum = subCPMKValues.values.fold<double>(0.0, (a, b) => a + b);
    final average = sum / subCPMKValues.length;
    return average.clamp(0.0, 100.0);
  }

  /// Rata-rata CPMK (Simple Average atau Weighted jika ada multiple CPMK)
  double get averageCPMKNilai {
    if (cpmkValues.isEmpty) return 0.0;
    final sum = cpmkValues.values.fold<double>(0.0, (a, b) => a + b);
    final average = sum / cpmkValues.length;
    // Clamp nilai ke range 0-100 untuk menghindari nilai > 100
    return average.clamp(0.0, 100.0);
  }

  /// Rata-rata CPL
  double get averageCPLNilai {
    if (cplValues.isEmpty) return 0.0;
    final sum = cplValues.values.fold<double>(0.0, (a, b) => a + b);
    final average = sum / cplValues.length;
    // Clamp nilai ke range 0-100 untuk menghindari nilai > 100
    return average.clamp(0.0, 100.0);
  }

  bool get hasData =>
      subCPMKValues.isNotEmpty ||
      cpmkValues.isNotEmpty ||
      cplValues.isNotEmpty;
}
