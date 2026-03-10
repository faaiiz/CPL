import 'database_helper.dart';
import 'obe_calculation_helper.dart';
import '../models/cpmk_model.dart';

class CPMKCPLCalculationService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Helper method: Konversi nilai ke skala 0-100 dengan deteksi otomatis
  /// Jika nilai > 4, dianggap sudah dalam skala 0-100
  /// Jika nilai <= 4, dianggap dalam skala 0-4 dan dikonversi jadi 0-100
  double _normalizeToScale0_100(double nilai) {
    return nilai > 4 ? nilai : nilai * 25;
  }

  /// 🎯 Helper: Get Sub-CPMK bobot untuk CPMK calculation (default untuk Kalkulus: [15,15,15,9,14,14,18])
  Future<Map<int, double>> _getSubCpmkToCpmkBobot(int matakuliahId) async {
    try {
      final result = <int, double>{};
      
      // Hardcoded default untuk Kalkulus (semua matakuliah untuk saat ini)
      // TODO: Extend ini untuk support multiple matakuliah dengan bobot berbeda
      result[1] = 15.0;
      result[2] = 15.0;
      result[3] = 15.0;
      result[4] = 9.0;
      result[5] = 14.0;
      result[6] = 14.0;
      result[7] = 18.0;
      
      print('DEBUG: Using Sub-CPMK to CPMK bobot: $result');
      return result;
    } catch (e) {
      print('ERROR: Could not get Sub-CPMK to CPMK bobot: $e');
      return {};
    }
  }

  // Hitung nilai CPMK untuk satu mata kuliah berdasarkan nilai yang diperoleh
  Future<double?> calculateCPMKScoreForCourse(int cpmkId, int matakuliahId) async {
    try {
      // Get semua nilai untuk mata kuliah ini
      final nilaiList = await _dbHelper.getNilaiByMatakuliah(matakuliahId);
      
      if (nilaiList.isEmpty) {
        return null;
      }

      // Rata-rata nilai numerik dari semua mahasiswa untuk mata kuliah ini
      // yang berkontribusi pada CPMK ini
      double totalNilai = 0;
      for (var nilai in nilaiList) {
        // Normalisasi setiap nilai ke skala 0-100
        totalNilai += _normalizeToScale0_100(nilai.nilaiNumerik);
      }
      
      // Return rata-rata dalam skala 0-100
      return totalNilai / nilaiList.length;
    } catch (e) {
      print('Error calculating CPMK score for course: $e');
      return null;
    }
  }

  // Hitung nilai CPMK keseluruhan (weighted average dari semua mata kuliah yang berkontribusi)
  Future<double?> calculateOverallCPMKScore(int cpmkId) async {
    try {
      // Get CPMK details
      final cpmk = await _dbHelper.getCPMKById(cpmkId);
      if (cpmk == null) return null;

      // Get semua nilai dari mata kuliah ini
      final allNilai = await _dbHelper.getNilaiByMatakuliah(cpmk.matakuliahId);
      if (allNilai.isEmpty) return null;

      // Get matakuliah details untuk SKS
      final matakuliah = await _dbHelper.getMatakuliahById(cpmk.matakuliahId);
      if (matakuliah == null) return null;

      // Hitung rata-rata nilai untuk CPMK ini dari mata kuliah
      double totalNilai = 0;
      for (var nilai in allNilai) {
        // Normalisasi setiap nilai ke skala 0-100
        totalNilai += _normalizeToScale0_100(nilai.nilaiNumerik);
      }
      double avgNilai = totalNilai / allNilai.length;

      // Return dalam skala 0-100 (sudah dinormalisasi)
      return avgNilai;
    } catch (e) {
      print('Error calculating overall CPMK score: $e');
      return null;
    }
  }

  // 🎯 Hitung nilai CPMK untuk SATU MAHASISWA (fix bug: per-student, not global)
  Future<double?> calculateCPMKForStudent(int cpmkId, int mahasiswaId) async {
    try {
      final cpmk = await _dbHelper.getCPMKById(cpmkId);
      if (cpmk == null) return null;

      // 🎯 PENTING: Ambil nilai HANYA untuk mahasiswa ini
      final nilaiMahasiswa = await _dbHelper.getNilaiByMahasiswa(mahasiswaId);
      
      // Filter nilai yang relevan dengan CPMK dan matakuliah
      final relevantNilai = nilaiMahasiswa
          .where((n) => n.matakuliahId == cpmk.matakuliahId)
          .toList();
      
      if (relevantNilai.isEmpty) return null;

      // Dapatkan matakuliah untuk SKS
      final matakuliah = await _dbHelper.getMatakuliahById(cpmk.matakuliahId);
      if (matakuliah == null) return null;

      // Hitung rata-rata nilai mahasiswa ini untuk CPMK
      double totalNilai = 0;
      for (var nilai in relevantNilai) {
        totalNilai += _normalizeToScale0_100(nilai.nilaiNumerik);
      }

      // Return rata-rata dalam skala 0-100 (sudah dinormalisasi)
      return totalNilai / relevantNilai.length;
    } catch (e) {
      print('Error calculating CPMK for student: $e');
      return null;
    }
  }

  // Hitung nilai CPMK dengan metode weighted SKS dari multiple mata kuliah
  Future<double?> calculateCPMKWithWeightedSKS(int cpmkId) async {
    try {
      final cpmk = await _dbHelper.getCPMKById(cpmkId);
      if (cpmk == null) return null;

      // Dapatkan semua nilai mata kuliah
      final nilaiList = await _dbHelper.getNilaiByMatakuliah(cpmk.matakuliahId);
      if (nilaiList.isEmpty) return null;

      // Dapatkan matakuliah untuk SKS
      final matakuliah = await _dbHelper.getMatakuliahById(cpmk.matakuliahId);
      if (matakuliah == null) return null;

      // Hitung weighted score: (Sigma NilaiCPMK × SKS) / Sigma SKS
      double totalWeightedScore = 0;
      double totalSKS = 0;

      for (var nilai in nilaiList) {
        // Normalisasi nilai ke skala 0-100 terlebih dahulu
        final nilaiNormalized = _normalizeToScale0_100(nilai.nilaiNumerik);
        totalWeightedScore += nilaiNormalized * matakuliah.sks;
        totalSKS += matakuliah.sks;
      }

      if (totalSKS == 0) return null;
      // Return dalam skala 0-100 (sudah dinormalisasi)
      return totalWeightedScore / totalSKS;
    } catch (e) {
      print('Error calculating CPMK with weighted SKS: $e');
      return null;
    }
  }

  // Hitung nilai CPL berdasarkan CPMK yang berkontribusi
  Future<double?> calculateCPLScore(int cplId) async {
    try {
      // Get semua CPMK yang berkontribusi ke CPL ini
      final mappings = await _dbHelper.getMappingByCPL(cplId);
      if (mappings.isEmpty) return null;

      double totalWeightedCPMKScore = 0;
      double totalBobot = 0;

      // Untuk setiap CPMK yang berkontribusi
      for (var mapping in mappings) {
        final cpmkScore = await calculateCPMKWithWeightedSKS(mapping.cpmkId);
        if (cpmkScore != null) {
          // Weighted score: CPMK score × bobot CPMK terhadap CPL
          totalWeightedCPMKScore += cpmkScore * (mapping.bobot / 100);
          totalBobot += mapping.bobot;
        }
      }

      if (totalBobot == 0) return null;
      
      // CPL score = Sigma(CPMKScore × BobotCPMK) / SigmaBobotCPMK
      // Jika bobot sudah 100%, langsung return weighted score
      return totalWeightedCPMKScore / (totalBobot / 100);
    } catch (e) {
      print('Error calculating CPL score: $e');
      return null;
    }
  }

  // 🎯 Hitung nilai CPL untuk SATU MAHASISWA (fix bug: per-student, not global)
  Future<double?> calculateCPLForStudent(int cplId, int mahasiswaId) async {
    try {
      final mappings = await _dbHelper.getMappingByCPL(cplId);
      if (mappings.isEmpty) return null;

      double totalWeightedScore = 0;
      double totalSKS = 0;

      // Untuk setiap CPMK yang berkontribusi ke CPL
      for (var mapping in mappings) {
        final cpmk = await _dbHelper.getCPMKById(mapping.cpmkId);
        if (cpmk != null) {
          final matakuliah = await _dbHelper.getMatakuliahById(cpmk.matakuliahId);
          if (matakuliah != null) {
            // 🎯 FIX: Pass mahasiswa ID ke calculation
            final cpmkScore = await calculateCPMKForStudent(mapping.cpmkId, mahasiswaId);
            if (cpmkScore != null) {
              // Weighted dengan SKS mata kuliah
              totalWeightedScore += cpmkScore * matakuliah.sks;
              totalSKS += matakuliah.sks;
            }
          }
        }
      }

      if (totalSKS == 0) return null;
      
      // CPL Score = (Sigma NilaiCPL × SKS) / Sigma SKS
      return totalWeightedScore / totalSKS;
    } catch (e) {
      print('Error calculating CPL for student: $e');
      return null;
    }
  }

  // Hitung CPL dengan weighting dari SKS total CPMK
  Future<double?> calculateCPLWithSKSWeighting(int cplId) async {
    try {
      final mappings = await _dbHelper.getMappingByCPL(cplId);
      if (mappings.isEmpty) return null;

      double totalWeightedScore = 0;
      double totalSKS = 0;

      // Untuk setiap CPMK yang berkontribusi ke CPL
      for (var mapping in mappings) {
        final cpmk = await _dbHelper.getCPMKById(mapping.cpmkId);
        if (cpmk != null) {
          final matakuliah = await _dbHelper.getMatakuliahById(cpmk.matakuliahId);
          if (matakuliah != null) {
            final cpmkScore = await calculateCPMKWithWeightedSKS(mapping.cpmkId);
            if (cpmkScore != null) {
              // Weighted dengan SKS mata kuliah
              totalWeightedScore += cpmkScore * matakuliah.sks;
              totalSKS += matakuliah.sks;
            }
          }
        }
      }

      if (totalSKS == 0) return null;
      
      // CPL Score = (Sigma NilaiCPL × SKS) / Sigma SKS
      // Convert dari skala 0-4 ke 0-100
      return (totalWeightedScore / totalSKS) * 25;
    } catch (e) {
      print('Error calculating CPL with SKS weighting: $e');
      return null;
    }
  }

  // Hitung semua CPL scores sekaligus
  Future<Map<int, double>> calculateAllCPLScores() async {
    try {
      final allCPLs = await _dbHelper.getAllCPLMaster();
      final results = <int, double>{};

      for (var cpl in allCPLs) {
        if (cpl.id != null) {
          final score = await calculateCPLWithSKSWeighting(cpl.id!);
          if (score != null) {
            results[cpl.id!] = score;
          }
        }
      }

      return results;
    } catch (e) {
      print('Error calculating all CPL scores: $e');
      return {};
    }
  }

  // Hitung semua CPMK scores sekaligus
  Future<Map<int, double>> calculateAllCPMKScores() async {
    try {
      final allCPMKs = await _dbHelper.getAllCPMK();
      final results = <int, double>{};

      for (var cpmk in allCPMKs) {
        if (cpmk.id != null) {
          final score = await calculateCPMKWithWeightedSKS(cpmk.id!);
          if (score != null) {
            results[cpmk.id!] = score;
          }
        }
      }

      return results;
    } catch (e) {
      print('Error calculating all CPMK scores: $e');
      return {};
    }
  }

  // ========== METHODS UNTUK MAHASISWA SPESIFIK ==========

  /// 🎯 NEW: Hitung CPMK score untuk mahasiswa spesifik MENGGUNAKAN COMPONENT SCORES & RPS BOBOT
  /// Alih-alih hanya ambil nilai numerik, gunakan OBE calculation dengan component scores
  Future<double?> calculateCPMKForMahasiswa(int cpmkId, int mahasiswaId) async {
    try {
      final cpmk = await _dbHelper.getCPMKById(cpmkId);
      if (cpmk == null) {
        print('DEBUG: CPMK dengan ID $cpmkId tidak ditemukan');
        return null;
      }

      print('DEBUG [OBE]: Calculating CPMK $cpmkId (${cpmk.kodeCPMK}) for mahasiswa $mahasiswaId using component scores');

      // 🎯 Step 1: Find latest tahun_ajaran for this mahasiswa
      final allNilai = await _dbHelper.getNilaiByMahasiswa(mahasiswaId);
      print('DEBUG [Step 1]: Found ${allNilai.length} total nilai records for mahasiswa $mahasiswaId');
      
      final nilaiForMK = allNilai
          .where((n) => n.matakuliahId == cpmk.matakuliahId)
          .toList();
      
      if (nilaiForMK.isEmpty) {
        print('DEBUG [Step 1] ❌: No nilai found for mahasiswa $mahasiswaId in MK ${cpmk.matakuliahId} (${cpmk.matakuliahId})');
        return null;
      }
      
      // Get latest tahun_ajaran
      nilaiForMK.sort((a, b) => b.tahunAjaran.compareTo(a.tahunAjaran));
      final tahunAjaran = nilaiForMK.first.tahunAjaran;
      
      print('DEBUG [Step 1] ✅: Using tahun_ajaran: $tahunAjaran (latest from ${nilaiForMK.length} records)');

      // 🎯 Step 2: Get component scores for this mahasiswa-mk-tahun combination
      final nilaiKomponen = await _dbHelper.getNilaiKomponen(
        mahasiswaId: mahasiswaId,
        matakuliahId: cpmk.matakuliahId,
        tahunAjaran: tahunAjaran,
      );

      if (nilaiKomponen == null) {
        print('DEBUG [Step 2] ❌: No component scores found for mahasiswa $mahasiswaId, MK ${cpmk.matakuliahId}, tahun $tahunAjaran');
        print('⚠️ ISSUE: nilai_komponen table does not have record. Did you import component score details?');
        return null;
      }

      print('DEBUG [Step 2] ✅: Component scores found: ${nilaiKomponen.keys.toList()}');

      // 🎯 Step 3: Extract component values array
      final nilaiArray = [
        nilaiKomponen['aktivitas'] ?? 0.0,
        nilaiKomponen['hasil_proyek'] ?? 0.0,
        nilaiKomponen['kuis'] ?? 0.0,
        nilaiKomponen['tugas'] ?? 0.0,
        nilaiKomponen['uts'] ?? 0.0,
        nilaiKomponen['uas'] ?? 0.0,
      ].map((x) => x is int ? (x).toDouble() : x).toList();

      print('DEBUG [Step 3] ✅: Component values: [aktivitas=${nilaiArray[0]}, proyek=${nilaiArray[1]}, kuis=${nilaiArray[2]}, tugas=${nilaiArray[3]}, uts=${nilaiArray[4]}, uas=${nilaiArray[5]}]');

      // 🎯 Step 4: Get bobot matrix untuk Sub-CPMK
      final bobotMatrix = await _dbHelper.getBobotMatrixForMatakuliah(
        matakuliahId: cpmk.matakuliahId,
      );
      
      if (bobotMatrix.isEmpty) {
        print('DEBUG [Step 4] ❌: No bobot matrix found for MK ${cpmk.matakuliahId}');
        print('⚠️ ISSUE: Bobot matrix not setup in database. Admin needs to setup bobot.');
        return null;
      }

      print('DEBUG [Step 4] ✅: Bobot matrix found with ${bobotMatrix.length} Sub-CPMK entries');

      // 🎯 Step 5: Calculate Sub-CPMK values using OBE formula
      final subCpmkValues = <int, double>{};
      for (final subCpmkId in bobotMatrix.keys) {
        final bobot = bobotMatrix[subCpmkId];
        if (bobot != null && bobot.isNotEmpty) {
          double totalWeighted = 0;
          double totalBobot = 0;
          
          for (int i = 0; i < bobot.length && i < nilaiArray.length; i++) {
            if (bobot[i] > 0) {
              totalWeighted += nilaiArray[i] * bobot[i];
              totalBobot += bobot[i];
            }
          }
          
          if (totalBobot > 0) {
            subCpmkValues[subCpmkId] = totalWeighted / totalBobot;
          }
        }
      }

      print('DEBUG [Step 5] ✅: Sub-CPMK values calculated: ${subCpmkValues.map((k, v) => MapEntry(k, v.toStringAsFixed(2)))}');

      // 🎯 Step 6: Calculate CPMK using Sub-CPMK bobot
      final subCpmkBobot = await _getSubCpmkToCpmkBobot(cpmk.matakuliahId);
      print('DEBUG [Step 6]: Sub-CPMK to CPMK bobot: ${subCpmkBobot.map((k, v) => MapEntry(k, v))}');
      
      double totalWeightedCpmk = 0;
      double totalBobotCpmk = 0;
      
      subCpmkBobot.forEach((subCpmkId, bobot) {
        if (subCpmkValues.containsKey(subCpmkId)) {
          totalWeightedCpmk += (subCpmkValues[subCpmkId] ?? 0) * bobot;
          totalBobotCpmk += bobot;
        }
      });

      if (totalBobotCpmk == 0) {
        print('DEBUG [Step 6] ❌: No valid Sub-CPMK weighted sum (totalBobotCpmk = 0)');
        return null;
      }

      final cpmkScore = totalWeightedCpmk / totalBobotCpmk;
      print('DEBUG [Step 6] ✅: CPMK $cpmkId (${cpmk.kodeCPMK}) calculated: ${cpmkScore.toStringAsFixed(2)} (using component scores & RPS bobot)');
      
      return cpmkScore;
    } catch (e, stack) {
      print('ERROR calculating CPMK for mahasiswa using OBE: $e');
      print('Stack trace: $stack');
      return null;
    }
  }

  /// OLD METHOD (kept for reference/fallback)
  Future<double?> calculateCPMKForMahasiswaSimple(int cpmkId, int mahasiswaId) async {
    try {
      final cpmk = await _dbHelper.getCPMKById(cpmkId);
      if (cpmk == null) return null;

      final allNilai = await _dbHelper.getNilaiByMahasiswa(mahasiswaId);
      final nilaiForMK = allNilai
          .where((n) => n.matakuliahId == cpmk.matakuliahId)
          .toList();
      
      if (nilaiForMK.isEmpty) return null;
      
      nilaiForMK.sort((a, b) => b.tahunAjaran.compareTo(a.tahunAjaran));
      final result = nilaiForMK.first.nilaiNumerik;
      return _normalizeToScale0_100(result);
    } catch (e) {
      print('Error in calculateCPMKForMahasiswaSimple: $e');
      return null;
    }
  }

  /// 🎯 NEW: Hitung CPL score untuk mahasiswa spesifik MENGGUNAKAN OBE-calculated CPMK VALUES
  /// Alih-alih raw nilai numerik, gunakan CPMK yang sudah dihitung dengan component scores & RPS bobot
  Future<double?> calculateCPLForMahasiswa(int cplId, int mahasiswaId) async {
    try {
      final mappings = await _dbHelper.getMappingByCPL(cplId);
      print('DEBUG [OBE-CPL]: CPL ID $cplId punya ${mappings.length} CPMK yang berkontribusi');
      
      if (mappings.isEmpty) {
        print('DEBUG: CPL $cplId tidak punya mapping CPMK');
        return null;
      }

      double totalWeightedCPMK = 0;
      double totalBobot = 0;
      int countValidCPMK = 0;

      // Untuk setiap CPMK yang berkontribusi ke CPL
      for (var mapping in mappings) {
        // 🎯 Calculate CPMK using component scores & RPS bobot (new method)
        final cpmkScore = await calculateCPMKForMahasiswa(mapping.cpmkId, mahasiswaId);
        
        if (cpmkScore != null) {
          print('DEBUG [OBE-CPL]: CPMK ${mapping.cpmkId} untuk mahasiswa $mahasiswaId: $cpmkScore, bobot: ${mapping.bobot}%');
          // Weighted sum: CPMK value × bobot CPMK terhadap CPL
          totalWeightedCPMK += cpmkScore * (mapping.bobot / 100.0);
          totalBobot += mapping.bobot;
          countValidCPMK++;
        }
      }

      if (totalBobot == 0 || countValidCPMK == 0) {
        print('DEBUG: CPL $cplId tidak bisa dihitung (totalBobot: $totalBobot, countValidCPMK: $countValidCPMK)');
        return null;
      }
      
      // CPL Score = (Sigma CPMKScore × BobotCPMK) / TotalBobot
      final result = totalWeightedCPMK / (totalBobot / 100.0);
      print('DEBUG [OBE-CPL]: ✅ CPL $cplId untuk mahasiswa $mahasiswaId: $result (menggunakan OBE-calculated CPMK)');
      
      return result;
    } catch (e) {
      print('Error calculating CPL for mahasiswa using OBE: $e');
      return null;
    }
  }

  /// OLD METHOD (kept for reference/fallback)
  Future<double?> calculateCPLForMahasiswaSimple(int cplId, int mahasiswaId) async {
    try {
      final mappings = await _dbHelper.getMappingByCPL(cplId);
      
      if (mappings.isEmpty) return null;

      double totalWeightedScore = 0;
      double totalSKS = 0;

      final allNilai = await _dbHelper.getNilaiByMahasiswa(mahasiswaId);

      for (var mapping in mappings) {
        final cpmk = await _dbHelper.getCPMKById(mapping.cpmkId);
        if (cpmk != null) {
          final nilaiForMK = allNilai
              .where((n) => n.matakuliahId == cpmk.matakuliahId)
              .toList();
          
          if (nilaiForMK.isNotEmpty) {
            nilaiForMK.sort((a, b) => b.tahunAjaran.compareTo(a.tahunAjaran));
            final nilai = nilaiForMK.first;
            
            final matakuliah = await _dbHelper.getMatakuliahById(cpmk.matakuliahId);
            if (matakuliah != null) {
              final nilaiNormalized = _normalizeToScale0_100(nilai.nilaiNumerik);
              totalWeightedScore += nilaiNormalized * matakuliah.sks;
              totalSKS += matakuliah.sks;
            }
          }
        }
      }

      if (totalSKS == 0) return null;
      
      return totalWeightedScore / totalSKS;
    } catch (e) {
      print('Error in calculateCPLForMahasiswaSimple: $e');
      return null;
    }
  }

  /// Load semua CPMK dengan scores untuk mahasiswa spesifik
  Future<List<Map<String, dynamic>>> loadCPMKForMahasiswa(int mahasiswaId) async {
    try {
      print('\n' + '='*80);
      print('🔍 LOADING CPMK DATA FOR MAHASISWA $mahasiswaId');
      print('='*80);
      
      final matakuliahList = await _dbHelper.getAllMatakuliah();
      print('DEBUG [loadCPMKForMahasiswa]: Total MK dalam sistem: ${matakuliahList.length}');
      final results = <Map<String, dynamic>>[];

      if (matakuliahList.isEmpty) {
        print('⚠️ WARNING: Tidak ada matakuliah terdaftar di database!');
      }

      // DEBUG: Show all matakuliah
      for (final mk in matakuliahList) {
        print('  └─ MK ID ${mk.id}: ${mk.nama} (Kode: ${mk.kode})');
      }

      final allCPMK = <CPMK>{};
      for (final mk in matakuliahList) {
        final cpmkList = await _dbHelper.getCPMKByMatakuliah(mk.id!);
        print('\nDEBUG: MK ID ${mk.id} (${mk.nama}) punya ${cpmkList.length} CPMK');
        if (cpmkList.isNotEmpty) {
          for (var cpmk in cpmkList) {
            print('  ├─ CPMK ${cpmk.kodeCPMK} (ID: ${cpmk.id}, Deskripsi: ${cpmk.deskripsi})');
          }
        } else {
          print('  └─ ⚠️ No CPMK registered for this MK');
        }
        allCPMK.addAll(cpmkList);
      }

      print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('DEBUG: Total UNIQUE CPMK dalam sistem: ${allCPMK.length}');
      if (allCPMK.isEmpty) {
        print('❌ CRITICAL: TIDAK ADA CPMK YANG TERDAFTAR DI DATABASE!');
        print('   ACTION: Setup CPMK untuk semua matakuliah di admin dashboard');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      for (final cpmk in allCPMK) {
        print('    Calculating score for CPMK ${cpmk.kodeCPMK} (ID: ${cpmk.id})...');
        final score = await calculateCPMKForMahasiswa(cpmk.id!, mahasiswaId);
        
        if (score != null) {
          print('    ✅ CPMK ${cpmk.kodeCPMK} (ID: ${cpmk.id}) -> Score: ${score.toStringAsFixed(2)}');
          results.add({
            'id': cpmk.id,
            'kode': cpmk.kodeCPMK,
            'deskripsi': cpmk.deskripsi,
            'score': score,
          });
        } else {
          print('    ❌ CPMK ${cpmk.kodeCPMK} (ID: ${cpmk.id}) -> No Score (missing data)');
        }
      }

      print('\n' + '='*80);
      print('📊 SUMMARY: Total CPMK dengan nilai untuk mahasiswa $mahasiswaId: ${results.length}');
      if (results.isEmpty) {
        print('❌ TIDAK ADA CPMK DENGAN NILAI UNTUK MAHASISWA INI!');
        print('   POSSIBLE CAUSES:');
        print('   1. No CPMK registered for any MK');
        print('   2. Mahasiswa tidak punya nilai untuk course(s)');
        print('   3. Nilai komponen (breakdown) tidak ter-import');
        print('   4. Bobot matrix tidak ter-setup');
        print('   Check debug output above for specific issue');
      } else {
        print('✅ SUCCESS: ${results.length} CPMK values calculated');
      }
      print('='*80 + '\n');
      
      return results;
    } catch (e, stack) {
      print('ERROR loading CPMK for mahasiswa: $e');
      print('Stack trace: $stack');
      return [];
    }
  }

  /// Load semua CPL dengan scores untuk mahasiswa spesifik
  Future<List<Map<String, dynamic>>> loadCPLForMahasiswa(int mahasiswaId) async {
    try {
      final cplList = await _dbHelper.getAllCPLMaster();
      print('\nDEBUG [loadCPLForMahasiswa]: Total CPL dalam sistem: ${cplList.length}');
      final results = <Map<String, dynamic>>[];

      for (final cpl in cplList) {
        print('\nDEBUG: CPL ${cpl.kodeCPL} (ID: ${cpl.id})');
        
        // Check mapping untuk CPL ini
        final mappings = await _dbHelper.getMappingByCPL(cpl.id!);
        print('  - Punya ${mappings.length} CPMK yang berkontribusi');
        if (mappings.isNotEmpty) {
          for (var m in mappings) {
            final cpmk = await _dbHelper.getCPMKById(m.cpmkId);
            print('    - CPMK ${cpmk?.kodeCPMK} (ID: ${m.cpmkId}) dengan bobot ${m.bobot}%');
          }
        }
        
        final score = await calculateCPLForMahasiswa(cpl.id!, mahasiswaId);
        print('  - Score untuk mahasiswa $mahasiswaId: $score');
        
        if (score != null) {  // ← Only add if score is valid
          results.add({
            'id': cpl.id,
            'kodeCPL': cpl.kodeCPL,
            'deskripsi': cpl.deskripsi,
            'score': score,
          });
        }
      }

      print('\nDEBUG: Total CPL dengan nilai untuk mahasiswa $mahasiswaId: ${results.length}');
      if (results.isEmpty) {
        print('DEBUG: ⚠️ TIDAK ADA CPL DENGAN NILAI UNTUK MAHASISWA INI!');
      }
      return results;
    } catch (e) {
      print('Error loading CPL for mahasiswa: $e');
      return [];
    }
  }

  // 📊 OBE Specification-Based Calculation Methods (Using Component Scores)

  /// Calculate CPMK for a student using component scores from nilai_komponen table
  /// Uses OBE calculation engine with bobot matrix
  Future<double?> calculateCPMKUsingComponentScores({
    required int mahasiswaId,
    required int matakuliahId,
    required int tahunAjaran,
  }) async {
    try {
      // ✅ Step 1: Get component scores for this student-course combination
      final nilaiKomponen = await _dbHelper.getNilaiKomponen(
        mahasiswaId: mahasiswaId,
        matakuliahId: matakuliahId,
        tahunAjaran: tahunAjaran,
      );

      if (nilaiKomponen == null) {
        print('DEBUG: No component scores found for student $mahasiswaId');
        return null;
      }

      // Convert to list: [aktivitas, proyek, kuis, tugas, uts, uas]
      final nilaiComponents = [
        nilaiKomponen['nilai_aktivitas'] as double,
        nilaiKomponen['nilai_proyek'] as double,
        nilaiKomponen['nilai_kuis'] as double,
        nilaiKomponen['nilai_tugas'] as double,
        nilaiKomponen['nilai_uts'] as double,
        nilaiKomponen['nilai_uas'] as double,
      ];

      print('DEBUG: Component scores for student $mahasiswaId: $nilaiComponents');

      // ✅ Step 2: Get bobot matrix for this course
      final bobotMatrix = await _dbHelper.getBobotMatrixForMatakuliah(
        matakuliahId: matakuliahId,
      );

      if (bobotMatrix.isEmpty) {
        print('DEBUG: No bobot matrix found for matakuliah $matakuliahId');
        return null;
      }

      print('DEBUG: Bobot matrix: $bobotMatrix');

      // ✅ Step 3: Get Sub-CPMK to CPMK mapping
      final subCpmkToCpmkBobot = await _dbHelper.getSubCPMKToCPMKBobotMapping(
        matakuliahId: matakuliahId,
      );

      if (subCpmkToCpmkBobot.isEmpty) {
        print('DEBUG: No Sub-CPMK to CPMK mapping found');
        return null;
      }

      print('DEBUG: Sub-CPMK to CPMK mapping: $subCpmkToCpmkBobot');

      // ✅ Step 4: Calculate using OBE calculation engine
      final obeEngine = OBECalculationHelper();

      try {
        // Calculate Sub-CPMK values from component scores
        final subCpmkValues = obeEngine.calculateSubCPMKWithMatrix(
          nilaiKomponen: nilaiComponents,
          bobotMatrix: bobotMatrix,
        );

        print('DEBUG: Sub-CPMK values: $subCpmkValues');

        // Calculate CPMK from Sub-CPMK values
        final cpmkValues = obeEngine.calculateCPMKFromSubCPMK(
          subCpmkValues: subCpmkValues,
          subCpmkBobotToCpmk: subCpmkToCpmkBobot,
        );

        print('DEBUG: CPMK values: $cpmkValues');

        // Return average CPMK (or first CPMK if only one exists)
        if (cpmkValues.isNotEmpty) {
          final values = cpmkValues.values.toList();
          final avgCPMK = values.fold(0.0, (a, b) => a + b) / values.length;
          return avgCPMK;
        }

        return null;
      } catch (e) {
        print('❌ OBE calculation error: $e');
        return null;
      }
    } catch (e) {
      print('Error calculating CPMK using component scores: $e');
      return null;
    }
  }

  /// Calculate CPL for a student using component scores
  /// Combines component scores → Sub-CPMK → CPMK → CPL
  Future<List<Map<String, dynamic>>> calculateCPLUsingComponentScores({
    required int mahasiswaId,
    required int tahunAjaran,
  }) async {
    try {
      final results = <Map<String, dynamic>>[];

      // ✅ Step 1: Get all matakuliah dengan nilai komponen untuk mahasiswa ini
      final nilaiKomponenList = await _dbHelper.getNilaiKomponenByMahasiswa(
        mahasiswaId: mahasiswaId,
        tahunAjaran: tahunAjaran,
      );

      if (nilaiKomponenList.isEmpty) {
        print('DEBUG: No component scores found for student $mahasiswaId');
        return results;
      }

      print('DEBUG: Found ${nilaiKomponenList.length} matakuliah with component scores');

      // ✅ Step 2: Calculate CPMK for each matakuliah
      final cpmkScoresByMatakuliah = <int, double>{};

      for (final nk in nilaiKomponenList) {
        final matakuliahId = nk['matakuliah_id'] as int;
        
        final cpmkScore = await calculateCPMKUsingComponentScores(
          mahasiswaId: mahasiswaId,
          matakuliahId: matakuliahId,
          tahunAjaran: tahunAjaran,
        );

        if (cpmkScore != null) {
          cpmkScoresByMatakuliah[matakuliahId] = cpmkScore;
        }
      }

      print('DEBUG: CPMK scores by matakuliah: $cpmkScoresByMatakuliah');

      // ✅ Step 3: Get all CPL dan hitung dari CPMK scores
      final allCPL = await _dbHelper.getAllCPLMaster();

      for (final cpl in allCPL) {
        // Get mapping dari CPMK ke CPL
        final cpmkMappings = await _dbHelper.getMappingByCPL(cpl.id!);

        double totalWeightedScore = 0;
        double totalBobot = 0;

        for (final mapping in cpmkMappings) {
          final cpmkId = mapping.cpmkId;
          final cpmkBobot = mapping.bobot;

          // Get CPMK details to find matakuliah
          final cpmk = await _dbHelper.getCPMKById(cpmkId);
          if (cpmk == null) continue;

          // Get CPMK score for this matakuliah
          final cpmkScore = cpmkScoresByMatakuliah[cpmk.matakuliahId];

          if (cpmkScore != null && cpmkBobot > 0) {
            totalWeightedScore += cpmkScore * cpmkBobot;
            totalBobot += cpmkBobot;
          }
        }

        if (totalBobot > 0) {
          final cplScore = totalWeightedScore / totalBobot;
          results.add({
            'id': cpl.id,
            'kodeCPL': cpl.kodeCPL,
            'deskripsi': cpl.deskripsi,
            'score': cplScore,
          });
        }
      }

      print('DEBUG: Calculated ${results.length} CPL scores using component scores');
      return results;
    } catch (e) {
      print('Error calculating CPL using component scores: $e');
      return [];
    }
  }
}