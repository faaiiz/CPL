import '../models/sub_cpmk_nilai_model.dart';
import '../models/rps_detail_model.dart';
import 'database_helper.dart';

/// 🎯 OBE (Outcome-Based Education) Calculation Engine v3 - REFACTORED
/// Menghitung Nilai Sub-CPMK, CPMK, dan CPL menggunakan pendekatan OBE
/// 
/// ALUR PERHITUNGAN:
/// 
/// 1️⃣ SUB-CPMK CALCULATION:
///    Formula: Sub-CPMK_i = Σ(nilai_komponen_j × bobot_ij) / total_bobot_i
///    
///    Contoh: Sub-CPMK 276 = (87.5×6 + 87.5×2.5 + 60×6) / 14.5 = 76.12
///    
/// 2️⃣ CPMK CALCULATION:
///    Formula: CPMK = Σ(Sub-CPMK_i × bobot_total_i) / Σ(bobot_total_i)
///    
///    Contoh: CPMK 4 = ((76.12×14.5) + (72.50×11) + ... + (89.17×12)) / 100 = 81.25
///    
/// 3️⃣ CPL CALCULATION (Optional):
///    Formula: CPL = Σ(CPMK_i × bobot_cpmk_i) / Σ(bobot_cpmk_i)
///    
/// ✅ OBE COMPLIANCE:
/// - MANDATORY: Semua perhitungan WAJIB melalui Sub-CPMK (bukan langsung ke CPMK)
/// - Hanya komponen dengan bobot > 0 yang dihitung
/// - Bobot HARUS data-driven dari database (TIDAK hardcoded)
/// - Pembulatan 2 desimal di setiap hasil
/// - Total bobot harus > 0 (throw error jika tidak)
/// - Missing values throw error (TIDAK default ke 0)
/// - Weights > 0 dan tervalidasi sebelum digunakan
///
/// ⚠️ KEY CHANGES FROM v2:
/// 1. ✅ Removed hardcoded equal weight distribution (16.67)
/// 2. ✅ Added explicit missing value validation 
/// 3. ✅ Added weight sum validation with warnings
/// 4. ✅ Changed CPL to use weighted aggregation
/// 5. ✅ Improved error messages with actionable guidance
/// 6. ✅ Added optional validation flags
/// 7. ✅ Use direct bobot formula (no intermediate normalization steps)
class OBECalculationHelper {
  final DatabaseHelper _dbHelper;
  final OBEValidationConfig _validationConfig;

  OBECalculationHelper({
    DatabaseHelper? dbHelper,
    OBEValidationConfig? validationConfig,
  })  : _dbHelper = dbHelper ?? DatabaseHelper(),
        _validationConfig = validationConfig ?? OBEValidationConfig();

  /// 🔢 Pembulatan ke 2 desimal
  double _roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }

  /// ✅ Validasi bahwa total weights ≈ target (default 100, tolerance 1%)
  void _validateTotalWeights(
    String context,
    double totalWeight, {
    double targetWeight = 100.0,
    double tolerance = 1.0,
  }) {
    final diff = (totalWeight - targetWeight).abs();
    
    if (diff > tolerance) {
      final message =
          '⚠️ $context: Total bobot = $totalWeight (harusnya $targetWeight ± $tolerance). '
          'Pertimbangkan review RPS.';
      
      if (_validationConfig.strictWeightValidation) {
        throw Exception(message);
      } else {
        print(message);
      }
    }
  }

  /// ✅ Validasi bahwa nilai komponen ada dan valid (tidak boleh default ke 0)
  double _getValidatedComponentValue(
    String context,
    Map<String, double> nilaiKomponen,
    String komponenNama,
  ) {
    if (!nilaiKomponen.containsKey(komponenNama)) {
      final message = '❌ $context: Nilai komponen "$komponenNama" tidak ditemukan '
          '(tidak boleh missing, harus ada atau 0.0 explicitly set)';
      throw Exception(message);
    }

    final value = nilaiKomponen[komponenNama] ?? 0.0;
    
    // Validasi range
    if (value < 0 || value > 100) {
      final message =
          '⚠️ $context: Nilai "$komponenNama" = $value (diluar range 0-100)';
      if (_validationConfig.strictValueValidation) {
        throw Exception(message);
      } else {
        print(message);
      }
    }

    return value;
  }

  /// ============================================================================
  /// CORE OBE CALCULATION LOGIC - SESUAI SPESIFIKASI
  /// ============================================================================

  /// 📊 STEP 1: Hitung nilai SUB-CPMK dari nilai komponen
  ///
  /// INPUT:
  /// - nilaiKomponen: {aktivitas, proyek, kuis, tugas, uts, uas} dalam skala 0-100
  ///   (MUST have all keys, tidak boleh missing!)
  /// - subCpmkBobotMap: {
  ///     "sub1": {"aktivitas": 10, "proyek": 20, "kuis": 0, ...},
  ///     "sub2": {...}
  ///   }
  ///   (Bobot HARUS dari database, TIDAK hardcoded)
  ///
  /// ALGORITMA:
  /// Sub-CPMK_i = Σ(nilai_komponen_j × bobot_ij) / total_bobot_i
  /// 
  /// Contoh:
  /// Sub-CPMK 276 = (87.5×6 + 87.5×2.5 + 60×6) / 14.5
  ///              = 1103.75 / 14.5
  ///              = 76.12
  ///
  /// OUTPUT: {"sub1": 76.12, "sub2": 72.50, ...}
  /// 
  /// ❌ THROWS if:
  /// - nilaiKomponen kosong
  /// - subCpmkBobotMap kosong
  /// - Sub-CPMK total bobot = 0
  /// - Nilai komponen missing (tidak boleh default ke 0)
  /// - Nilai komponen diluar range [0, 100]
  Map<String, double> calculateSubCPMKValues({
    required Map<String, double> nilaiKomponen,
    required Map<String, Map<String, double>> subCpmkBobotMap,
  }) {
    final result = <String, double>{};

    // Validasi input
    if (nilaiKomponen.isEmpty) {
      throw Exception('❌ Nilai komponen tidak boleh kosong');
    }
    if (subCpmkBobotMap.isEmpty) {
      throw Exception('❌ Sub-CPMK bobot map tidak boleh kosong');
    }

    // Proses setiap Sub-CPMK
    subCpmkBobotMap.forEach((subCpmkId, bobotMap) {
      final context = 'Sub-CPMK "$subCpmkId"';

      // Hitung total bobot aktif (bobot > 0)
      double totalBobot = 0.0;
      final activeBobots = <String, double>{};

      bobotMap.forEach((komponenNama, bobot) {
        if (bobot > 0) {
          activeBobots[komponenNama] = bobot;
          totalBobot += bobot;
        }
      });

      // Validasi: Total bobot harus > 0
      if (totalBobot <= 0) {
        throw Exception(
          '❌ $context: Semua bobot komponen = 0 (harus ada minimal 1 komponen dengan bobot > 0). '
          'Periksa RPS dan setup Sub-CPMK←Komponen mapping.',
        );
      }

      // ✅ Validasi total bobot mendekati 100
      if (_validationConfig.strictWeightValidation) {
        _validateTotalWeights(context, totalBobot);
      }

      // Hitung nilai Sub-CPMK menggunakan formula:
      // Sub-CPMK = Σ(nilai_komponen × bobot) / total_bobot
      double nilaiSub = 0.0;

      activeBobots.forEach((komponenNama, bobot) {
        // ✅ Validasi: Nilai komponen HARUS ADA (tidak boleh missing)
        final nilaiKomp =
            _getValidatedComponentValue(context, nilaiKomponen, komponenNama);

        // Hitung kontribusi weighted (bobot digunakan langsung)
        nilaiSub += nilaiKomp * bobot;
      });

      // Bagi dengan total bobot untuk mendapatkan nilai akhir
      final nilaiSubCpmk = nilaiSub / totalBobot;

      // Roundup ke 2 desimal
      result[subCpmkId] = _roundToTwoDecimals(nilaiSubCpmk);
    });

    return result;
  }

  /// 📊 STEP 2: Hitung nilai CPMK dari nilai Sub-CPMK
  ///
  /// INPUT:
  /// - subCpmkValues: {"sub1": 76.12, "sub2": 72.50, ...}
  ///   (Hasil dari calculateSubCPMKValues)
  /// - cpmkSubCpmkMap: {
  ///     "cpmk1": {
  ///       "sub1": 14.5,  // bobot total Sub-CPMK (dari RPS)
  ///       "sub2": 11,
  ///       "sub3": 19,
  ///       ...
  ///     }
  ///   }
  ///   (Bobot total harus sum ke 100)
  ///
  /// ALGORITMA:
  /// CPMK = Σ(nilai_sub × bobot_total_sub) / Σ(bobot_total_sub)
  /// 
  /// Contoh:
  /// CPMK 4 = ((76.12×14.5) + (72.50×11) + (77.37×19) + (72.50×11) + (88.58×18.5) + (89.11×14) + (89.17×12)) / 100
  ///        = 8125.08 / 100
  ///        = 81.25
  ///
  /// OUTPUT: {"cpmk1": 81.25}
  Map<String, double> calculateCPMKValues({
    required Map<String, double> subCpmkValues,
    required Map<String, Map<String, double>> cpmkSubCpmkMap,
  }) {
    final result = <String, double>{};

    if (subCpmkValues.isEmpty) {
      throw Exception('❌ Sub-CPMK values tidak boleh kosong');
    }
    if (cpmkSubCpmkMap.isEmpty) {
      throw Exception('❌ CPMK-SubCPMK map tidak boleh kosong');
    }

    // Proses setiap CPMK
    cpmkSubCpmkMap.forEach((cpmkId, subCpmkMap) {
      final context = 'CPMK "$cpmkId"';
      double totalWeighted = 0.0;
      double totalBobot = 0.0;

      // Hitung weighted average
      subCpmkMap.forEach((subCpmkId, bobotTotal) {
        if (bobotTotal <= 0) {
          return; // Skip bobot 0
        }

        // Validasi: Sub-CPMK harus ada dalam values
        if (!subCpmkValues.containsKey(subCpmkId)) {
          throw Exception(
            '❌ $context: Sub-CPMK "$subCpmkId" tidak ditemukan dalam calculated values. '
            'Periksa mapping atau pastikan Sub-CPMK punya nilai.',
          );
        }

        final nilaiSub = subCpmkValues[subCpmkId]!;
        totalWeighted += nilaiSub * bobotTotal;
        totalBobot += bobotTotal;
      });

      // Validasi: Total bobot harus > 0
      if (totalBobot <= 0) {
        throw Exception(
          '❌ $context: Semua bobot Sub-CPMK = 0 (harus ada minimal 1 dengan bobot > 0). '
          'Periksa CPMK←SubCPMK mapping di database.',
        );
      }

      // ✅ Validasi total bobot mendekati 100
      if (_validationConfig.strictWeightValidation) {
        _validateTotalWeights(context, totalBobot);
      }

      // Hitung nilai CPMK
      final nilaiCpmk = totalWeighted / totalBobot;
      result[cpmkId] = _roundToTwoDecimals(nilaiCpmk);
    });

    return result;
  }

  /// 📊 STEP 3: Hitung nilai CPL dari nilai CPMK
  ///
  /// INPUT:
  /// - cpmkValues: {"cpmk1": 82.75, ...}
  /// - cplCpmkMap: {
  ///     "cpl1": {"cpmk1": 30, "cpmk2": 35, ...},  // WEIGHTED aggregation (BUKAN simple avg)
  ///     "cpl2": {...}
  ///   }
  ///
  /// ALGORITMA:
  /// ✅ IMPROVED: Gunakan weighted average BUKAN simple average
  /// 1. Untuk setiap CPL:
  ///    - Hitung weighted average: Σ(nilai_cpmk × bobot_cpmk) / Σ(bobot_cpmk)
  ///    - Jika bobot tidak ada, gunakan equal weight fallback (optional)
  /// 2. Return Map<cplId, nilai>
  ///
  /// OUTPUT: {"cpl1": 80.50, "cpl2": 85.75, ...}
  Map<String, double> calculateCPLValues({
    required Map<String, double> cpmkValues,
    required Map<String, Map<String, double>> cplCpmkMap,
    bool useEqualWeightFallback = true,
  }) {
    final result = <String, double>{};

    if (cpmkValues.isEmpty) {
      return result; // CPL is optional
    }

    cplCpmkMap.forEach((cplId, cpmkWeightMap) {
      final context = 'CPL "$cplId"';
      double totalWeighted = 0.0;
      double totalBobot = 0.0;
      int validCpmkCount = 0;

      // ✅ IMPROVED: Hitung weighted average dari CPMK
      cpmkWeightMap.forEach((cpmkId, bobot) {
        if (bobot <= 0) {
          return; // Skip bobot 0
        }

        if (cpmkValues.containsKey(cpmkId)) {
          final nilaiCpmk = cpmkValues[cpmkId]!;
          totalWeighted += nilaiCpmk * bobot;
          totalBobot += bobot;
          validCpmkCount++;
        }
      });

      // Jika tidak ada bobot, gunakan equal weight fallback
      if (totalBobot <= 0 && useEqualWeightFallback) {
        // Simple average sebagai fallback (jika bobot tidak didefinisikan)
        for (final cpmkId in cpmkWeightMap.keys) {
          if (cpmkValues.containsKey(cpmkId)) {
            totalWeighted += cpmkValues[cpmkId]!;
            validCpmkCount++;
          }
        }

        if (validCpmkCount > 0) {
          final nilaiCpl = totalWeighted / validCpmkCount;
          result[cplId] = _roundToTwoDecimals(nilaiCpl);

          if (_validationConfig.warnOnFallback) {
            print('⚠️ $context: Menggunakan equal weight fallback (bobot tidak tersedia di database)');
          }
        }
      } else if (totalBobot > 0) {
        // Weighted average
        final nilaiCpl = totalWeighted / totalBobot;
        result[cplId] = _roundToTwoDecimals(nilaiCpl);

        // ✅ Validasi total bobot
        if (_validationConfig.strictWeightValidation) {
          _validateTotalWeights(context, totalBobot);
        }
      }
    });

    return result;
  }

  /// ============================================================================
  /// WRAPPER FUNCTION - Hitung semua dalam satu call
  /// ============================================================================

  /// 🎯 MAIN FUNCTION: Hitung Sub-CPMK, CPMK, CPL dalam satu call
  /// 
  /// INPUT:
  /// {
  ///   "nilaiKomponen": {"aktivitas": 80, "proyek": 85, ...},
  ///   "subCpmkBobotMap": {
  ///     "sub1": {"aktivitas": 10, "proyek": 20, ...},
  ///     ...
  ///   },
  ///   "cpmkSubCpmkMap": {
  ///     "cpmk1": {"sub1": 20, "sub2": 15, ...},
  ///     ...
  ///   },
  ///   "cplCpmkMap": {
  ///     "cpl1": {"cpmk1": 30, "cpmk2": 35, ...},  // WEIGHTED (not list)
  ///     ...
  ///   }
  /// }
  /// 
  /// OUTPUT:
  /// {
  ///   "sub_cpmk": {"sub1": 85.50, ...},
  ///   "cpmk": {"cpmk1": 82.75, ...},
  ///   "cpl": {"cpl1": 80.50, ...}
  /// }
  Map<String, dynamic> calculateOBEComplete({
    required Map<String, double> nilaiKomponen,
    required Map<String, Map<String, double>> subCpmkBobotMap,
    required Map<String, Map<String, double>> cpmkSubCpmkMap,
    Map<String, Map<String, double>>? cplCpmkMap,
  }) {
    try {
      // STEP 1: Hitung Sub-CPMK
      final subCpmkValues = calculateSubCPMKValues(
        nilaiKomponen: nilaiKomponen,
        subCpmkBobotMap: subCpmkBobotMap,
      );

      // STEP 2: Hitung CPMK
      final cpmkValues = calculateCPMKValues(
        subCpmkValues: subCpmkValues,
        cpmkSubCpmkMap: cpmkSubCpmkMap,
      );

      // STEP 3: Hitung CPL (optional) - now uses weighted aggregation
      final cplValues = cplCpmkMap != null
          ? calculateCPLValues(
              cpmkValues: cpmkValues,
              cplCpmkMap: cplCpmkMap,
            )
          : <String, double>{};

      return {
        'sub_cpmk': subCpmkValues,
        'cpmk': cpmkValues,
        'cpl': cplValues,
        'status': 'success',
      };
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  /// ✅ IMPROVED: Wrapper untuk API lama dengan List<String> untuk CPL
  /// (Backward compatibility - internally converts to Map)
  @Deprecated('Use calculateOBEComplete() with Map<String, Map<String, double>> for CPL')
  Map<String, dynamic> calculateOBECompleteWithListCPL({
    required Map<String, double> nilaiKomponen,
    required Map<String, Map<String, double>> subCpmkBobotMap,
    required Map<String, Map<String, double>> cpmkSubCpmkMap,
    Map<String, List<String>>? cplCpmkMapList,
  }) {
    // Convert List<String> to Map<String, double> with equal weights
    Map<String, Map<String, double>>? cplCpmkMap;
    if (cplCpmkMapList != null) {
      cplCpmkMap = <String, Map<String, double>>{};
      cplCpmkMapList.forEach((cplId, cpmkIdList) {
        final cpmkMap = <String, double>{};
        for (final cpmkId in cpmkIdList) {
          cpmkMap[cpmkId] = 1.0; // Equal weight fallback
        }
        cplCpmkMap?[cplId] = cpmkMap;
      });
    }

    return calculateOBEComplete(
      nilaiKomponen: nilaiKomponen,
      subCpmkBobotMap: subCpmkBobotMap,
      cpmkSubCpmkMap: cpmkSubCpmkMap,
      cplCpmkMap: cplCpmkMap,
    );
  }

  /// ============================================================================
  /// COMPATIBILITY WRAPPERS (For Old Code Using List-based API)
  /// ============================================================================

  /// ⚠️ DEPRECATED: Legacy method using List<double> instead of Map<String, double>
  /// Wrapper untuk backward compatibility dengan kode lama
  /// 
  /// Format List: [aktivitas, proyek, kuis, tugas, uts, uas]
  /// Format Map<int, List<double>>: {subCpmkId: [bobot_aktivitas, bobot_proyek, ...]}
  Map<int, double> calculateSubCPMKWithMatrix({
    required List<double> nilaiKomponen,
    required Map<int, List<double>> bobotMatrix,
  }) {
    // Konversi List ke Map dengan nama komponen
    const komponenNames = ['aktivitas', 'proyek', 'kuis', 'tugas', 'uts', 'uas'];
    
    final nilaiKomponenMap = <String, double>{};
    for (int i = 0; i < nilaiKomponen.length && i < komponenNames.length; i++) {
      nilaiKomponenMap[komponenNames[i]] = nilaiKomponen[i];
    }

    // Konversi Map<int, List<double>> ke Map<String, Map<String, double>>
    final subCpmkBobotMapNew = <String, Map<String, double>>{};
    for (final entry in bobotMatrix.entries) {
      final subCpmkId = entry.key.toString();
      final bobots = entry.value;
      
      final bobotMap = <String, double>{};
      for (int i = 0; i < bobots.length && i < komponenNames.length; i++) {
        bobotMap[komponenNames[i]] = bobots[i];
      }
      subCpmkBobotMapNew[subCpmkId] = bobotMap;
    }

    // Hitung dengan method baru
    final result = calculateSubCPMKValues(
      nilaiKomponen: nilaiKomponenMap,
      subCpmkBobotMap: subCpmkBobotMapNew,
    );

    // Konversi hasil kembali ke Map<int, double>
    final resultInt = <int, double>{};
    for (final entry in result.entries) {
      final subCpmkId = int.tryParse(entry.key) ?? 0;
      if (subCpmkId > 0) {
        resultInt[subCpmkId] = entry.value;
      }
    }

    return resultInt;
  }

  /// ⚠️ DEPRECATED: Legacy method using Map<int, double>
  /// Wrapper untuk backward compatibility dengan kode lama
  /// 
  /// Format Map<int, Map<int, double>>: {cpmkId: {subCpmkId: bobot}}
  Map<int, double> calculateCPMKFromSubCPMK({
    required Map<int, double> subCpmkValues,
    required Map<int, Map<int, double>> subCpmkBobotToCpmk,
  }) {
    // Konversi subCpmkValues dari Map<int, double> ke Map<String, double>
    final subCpmkValuesStr = <String, double>{};
    for (final entry in subCpmkValues.entries) {
      subCpmkValuesStr[entry.key.toString()] = entry.value;
    }

    // Konversi subCpmkBobotToCpmk dari Map<int, Map<int, double>> 
    // ke Map<String, Map<String, double>>
    final cpmkSubCpmkMapStr = <String, Map<String, double>>{};
    for (final cpmkEntry in subCpmkBobotToCpmk.entries) {
      final cpmkIdStr = cpmkEntry.key.toString();
      final subCpmkBobot = <String, double>{};
      
      for (final subEntry in cpmkEntry.value.entries) {
        subCpmkBobot[subEntry.key.toString()] = subEntry.value;
      }
      cpmkSubCpmkMapStr[cpmkIdStr] = subCpmkBobot;
    }

    // Hitung dengan method baru
    final result = calculateCPMKValues(
      subCpmkValues: subCpmkValuesStr,
      cpmkSubCpmkMap: cpmkSubCpmkMapStr,
    );

    // Konversi hasil kembali ke Map<int, double>
    final resultInt = <int, double>{};
    for (final entry in result.entries) {
      final cpmkId = int.tryParse(entry.key) ?? 0;
      if (cpmkId > 0) {
        resultInt[cpmkId] = entry.value;
      }
    }

    return resultInt;
  }

  /// ⚠️ DEPRECATED: Legacy method wrapper
  Map<int, double> calculateCPMKFull({
    required List<double> nilaiKomponen,
    required Map<int, List<double>> bobotMatrix,
    required Map<int, Map<int, double>> subCpmkBobot,
  }) {
    // Step 1: Hitung Sub-CPMK
    final subCpmkValues = calculateSubCPMKWithMatrix(
      nilaiKomponen: nilaiKomponen,
      bobotMatrix: bobotMatrix,
    );

    // Step 2: Hitung CPMK dari Sub-CPMK
    final cpmkValues = calculateCPMKFromSubCPMK(
      subCpmkValues: subCpmkValues,
      subCpmkBobotToCpmk: subCpmkBobot,
    );

    return cpmkValues;
  }

  /// ⚠️ DEPRECATED: Method ini sudah di-refactor
  /// Gunakan `calculateOBEComplete()` dengan data preparation manual
  /// atau `calculateSubCPMKValues()` + `calculateCPMKValues()` yang lebih fleksibel
  @Deprecated('Use calculateOBEComplete() or calculate*Values() methods instead')
  Future<List<OBECalculationResult>> calculateAllMahasiswaCPL(
    int matakuliahId,
    int tahunAjaran,
  ) async {
    // Stub implementation - tidak akan berfungsi karena tidak ada database access
    print('❌ ERROR: calculateAllMahasiswaCPL() telah di-deprecate!');
    print('   Gunakan calculateOBEComplete() atau methods lain dengan data preparation manual');
    throw UnsupportedError(
      'calculateAllMahasiswaCPL() telah di-refactor. '
      'Gunakan calculateOBEComplete() atau calculate*Values() methods dengan data preparation manual.'
    );
  }

  /// ============================================================================
  /// DATABASE INTEGRATION (OPTIONAL)
  /// ============================================================================

  /// Simpan hasil perhitungan Sub-CPMK ke database
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

  /// Hitung dan simpan semua hasil OBE untuk satu mahasiswa
  Future<bool> calculateAndSaveOBEResults({
    required int mahasiswaId,
    required int matakuliahId,
    required int tahunAjaran,
    required Map<String, double> nilaiKomponen,
    required Map<String, Map<String, double>> subCpmkBobotMap,
    required Map<String, Map<String, double>> cpmkSubCpmkMap,
  }) async {
    try {
      // Hitung semua nilai OBE
      final result = calculateOBEComplete(
        nilaiKomponen: nilaiKomponen,
        subCpmkBobotMap: subCpmkBobotMap,
        cpmkSubCpmkMap: cpmkSubCpmkMap,
      );

      if (result['status'] != 'success') {
        return false;
      }

      // Simpan hasil Sub-CPMK ke database
      final subCpmkValues = result['sub_cpmk'] as Map<String, double>;
      for (final entry in subCpmkValues.entries) {
        final subCpmkId = int.tryParse(entry.key) ?? 0;
        if (subCpmkId > 0) {
          await saveSubCPMKNilai(
            mahasiswaId,
            subCpmkId,
            entry.value,
            tahunAjaran,
          );
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// ============================================================================
  /// BATCH CALCULATION (Optimized & improved error handling)
  /// ============================================================================

  /// 🎯 Hitung OBE (Sub-CPMK, CPMK, CPL) untuk semua mahasiswa di satu mata kuliah
  ///
  /// INPUT:
  /// - matakuliahId: ID mata kuliah
  /// - tahunAjaran: Tahun akademik
  ///
  /// OUTPUT: 
  /// - List<OBECalculationResult>: Hasil untuk setiap mahasiswa
  /// - Errors aggregated dan di-report
  ///
  /// BENEFITS dari method ini:
  /// - Load bobot sekali (efficient)
  /// - Process batch dengan error collection
  /// - Report aggregated stats
  Future<List<OBECalculationResult>> calculateBatchOBEResultsForMatakuliah({
    required int matakuliahId,
    required int tahunAjaran,
    bool continueOnError = true,
  }) async {
    try {
      final results = <OBECalculationResult>[];
      final errors = <int, String>{}; // mahasiswaId -> error message

      // STEP 1: Get semua nilai_komponen untuk MK ini
      final allNilaiKomponen = await _dbHelper.getAllNilaiKomponen(
        matakuliahId: matakuliahId,
        tahunAjaran: tahunAjaran,
      );

      final nilaiKomponenByMahasiswa = <int, Map<String, dynamic>>{};
      for (final nk in allNilaiKomponen) {
        final mkId = nk['matakuliah_id'] as int?;
        final tahun = nk['tahun_ajaran'] as int?;
        final mahasiswaId = nk['mahasiswa_id'] as int;

        if (mkId == matakuliahId && tahun == tahunAjaran) {
          nilaiKomponenByMahasiswa[mahasiswaId] = nk;
        }
      }

      if (nilaiKomponenByMahasiswa.isEmpty) {
        print(
            '⚠️ Tidak ada nilai_komponen untuk MK $matakuliahId tahun $tahunAjaran');
        return results;
      }

      print(
          '📊 Found ${nilaiKomponenByMahasiswa.length} mahasiswa dengan nilai_komponen untuk MK $matakuliahId');

      // 🔍 DEBUG: Print RPS data dari database
      await debugPrintRPSDataForMatakuliah(matakuliahId);

      // STEP 2: Get bobot matrix (sama untuk semua mahasiswa)
      final subCpmkBobotMap =
          await _getSubCpmkBobotMapFromDatabase(matakuliahId);
      final cpmkSubCpmkMap =
          await _getCpmkSubCpmkMapFromDatabase(matakuliahId);

      if (subCpmkBobotMap.isEmpty || cpmkSubCpmkMap.isEmpty) {
        throw Exception(
          'Bobot matrix tidak lengkap untuk MK $matakuliahId. '
          'Pastikan RPS dan mapping sudah di-setup!',
        );
      }

      // STEP 3: Get CPL mapping (optional)
      Map<String, Map<String, double>>? cplCpmkMap;
      try {
        cplCpmkMap = await _getCPLCpmkMapFromDatabase(matakuliahId);
      } catch (e) {
        print('⚠️ CPL mapping tidak tersedia (optional): $e');
        cplCpmkMap = null;
      }

      // STEP 4: Process tiap mahasiswa
      for (final entry in nilaiKomponenByMahasiswa.entries) {
        final mahasiswaId = entry.key;
        final nkRow = entry.value;

        try {
          // 🔍 DEBUG: Print trace untuk mahasiswa pertama saja
          final isFirstMahasiswa = mahasiswaId == nilaiKomponenByMahasiswa.keys.first;
          
          if (isFirstMahasiswa) {
            print('\n' + '='*80);
            print('🔍 DEBUG TRACE - MAHASISWA ID: $mahasiswaId');
            print('='*80);
          }

          // Parse nilai komponen
          final nilaiKomponen = _parseNilaiKomponenRow(nkRow);

          if (nilaiKomponen.isEmpty) {
            errors[mahasiswaId] = 'Nilai komponen kosong';
            if (!continueOnError) throw Exception(errors[mahasiswaId]);
            continue;
          }

          if (isFirstMahasiswa) {
            print('\n📥 INPUT NILAI KOMPONEN:');
            nilaiKomponen.forEach((komponen, nilai) {
              print('   $komponen: $nilai');
            });
            
            print('\n🎯 BOBOT SUB-CPMK (dari RPS):');
            subCpmkBobotMap.forEach((subCpmkId, bobotMap) {
              print('   Sub-CPMK $subCpmkId:');
              bobotMap.forEach((komponen, bobot) {
                if (bobot > 0) {
                  print('      - $komponen: ${bobot.toStringAsFixed(2)}%');
                }
              });
            });

            print('\n🔗 CPMK ← SUB-CPMK MAPPING:');
            cpmkSubCpmkMap.forEach((cpmkId, subCpmkMap) {
              print('   CPMK $cpmkId:');
              subCpmkMap.forEach((subCpmkId, bobot) {
                print('      - Sub-CPMK $subCpmkId (bobot: ${bobot.toStringAsFixed(2)}%)');
              });
            });

            if (cplCpmkMap != null && cplCpmkMap.isNotEmpty) {
              print('\n🎓 CPL ← CPMK MAPPING:');
              cplCpmkMap.forEach((cplId, cpmkMap) {
                print('   CPL $cplId:');
                cpmkMap.forEach((cpmkId, bobot) {
                  print('      - CPMK $cpmkId (bobot: ${bobot.toStringAsFixed(2)}%)');
                });
              });
            }
          }

          // Calculate OBE
          final calculationResult = calculateOBEComplete(
            nilaiKomponen: nilaiKomponen,
            subCpmkBobotMap: subCpmkBobotMap,
            cpmkSubCpmkMap: cpmkSubCpmkMap,
            cplCpmkMap: cplCpmkMap,
          );

          if (calculationResult['status'] != 'success') {
            errors[mahasiswaId] =
                calculationResult['message'] ?? 'Unknown error';
            if (!continueOnError) {
              throw Exception(errors[mahasiswaId]);
            }
            continue;
          }

          if (isFirstMahasiswa) {
            print('\n📊 HASIL SUB-CPMK:');
            final subCpmkValues = (calculationResult['sub_cpmk'] as Map<String, dynamic>)
                .cast<String, double>();
            subCpmkValues.forEach((subCpmkId, nilai) {
              print('   Sub-CPMK $subCpmkId: ${nilai.toStringAsFixed(2)}');
            });

            print('\n📊 HASIL CPMK:');
            final cpmkValues = (calculationResult['cpmk'] as Map<String, dynamic>)
                .cast<String, double>();
            cpmkValues.forEach((cpmkId, nilai) {
              print('   CPMK $cpmkId: ${nilai.toStringAsFixed(2)}');
            });

            final cplValues = (calculationResult['cpl'] as Map<String, dynamic>?)
                ?.cast<String, double>() ?? {};
            if (cplValues.isNotEmpty) {
              print('\n📊 HASIL CPL:');
              cplValues.forEach((cplId, nilai) {
                print('   CPL $cplId: ${nilai.toStringAsFixed(2)}');
              });
            }
            
            print('='*80 + '\n');
          }

          // Create result object
          final obeResult = OBECalculationResult(
            mahasiswaId: mahasiswaId,
            matakuliahId: matakuliahId,
            tahunAjaran: tahunAjaran,
            subCpmkValues: (calculationResult['sub_cpmk'] as Map<String, dynamic>)
                .cast<String, double>(),
            cpmkValues: (calculationResult['cpmk'] as Map<String, dynamic>)
                .cast<String, double>(),
            cplValues: (calculationResult['cpl'] as Map<String, dynamic>?)
                    ?.cast<String, double>() ??
                {},
            success: true,
          );

          results.add(obeResult);
          print('✅ Processed mahasiswa $mahasiswaId');
        } catch (mahasiswaError) {
          errors[mahasiswaId] = mahasiswaError.toString();
          print('❌ Error processing mahasiswa $mahasiswaId: $mahasiswaError');
          if (!continueOnError) rethrow;
        }
      }

      // Report summary
      print('');
      print('=' * 60);
      print('📊 BATCH CALCULATION SUMMARY');
      print('=' * 60);
      print('Total Mahasiswa: ${nilaiKomponenByMahasiswa.length}');
      print('Success: ${results.length}');
      print('Failed: ${errors.length}');

      if (errors.isNotEmpty) {
        print('');
        print('❌ Failed Mahasiswa:');
        errors.forEach((mahasiswaId, message) {
          print('   $mahasiswaId: $message');
        });
      }

      print('=' * 60);
      print('');

      return results;
    } catch (e) {
      print('❌ Fatal error in batch calculation: $e');
      rethrow;
    }
  }

  /// 🔧 Helper: Parse nilai_komponen row dari database
  /// 
  /// ✅ IMPROVED: Throws error jika nilai missing (tidak default ke 0)
  /// Tolerance: Nilai null/missing bisa diterima, akan throw saat digunakan
  Map<String, double> _parseNilaiKomponenRow(
    Map<String, dynamic> row, {
    bool allowMissing = false,
  }) {
    const komponenNames = [
      'nilai_aktivitas',
      'nilai_proyek',
      'nilai_kuis',
      'nilai_tugas',
      'nilai_uts',
      'nilai_uas'
    ];

    const komponenKeys = [
      'aktivitas',
      'proyek',
      'kuis',
      'tugas',
      'uts',
      'uas'
    ];

    final result = <String, double>{};

    for (int i = 0; i < komponenNames.length; i++) {
      final fieldName = komponenNames[i];
      final keyName = komponenKeys[i];
      final value = row[fieldName];

      if (value == null) {
        if (!allowMissing) {
          throw Exception(
            'Nilai $keyName tidak ditemukan di database row untuk mahasiswa ${row['mahasiswa_id']}. '
            'Pastikan semua nilai komponen telah diisi (tidak boleh NULL).',
          );
        }
        // Jika allowMissing=true, skip nil values (akan throw saat digunakan)
      } else {
        result[keyName] = (value as num).toDouble();
      }
    }

    return result;
  }

  /// 🔧 Helper: Get Sub-CPMK bobot map dari RPS Detail
  /// 
  /// OUTPUT FORMAT: {"sub1": {"aktivitas": 15.0, "proyek": 10.0, ...}, ...}
  /// 
  /// ✅ DIRECT RPS AGGREGATION (NOT database_helper):
  /// 1. Baca RPS Detail untuk matakuliah
  /// 2. Parse jenis_penilaian dan bobot dari setiap minggu
  /// 3. Agregasi bobot per Sub-CPMK dan per komponen
  /// 4. Format: Map<subCpmkId, Map<komponenNama, bobot%>>
  /// 
  /// DATA SOURCE: RPS Details
  /// - rpsDetail.jenisNilai: aktivitas, proyek, kuis, tugas, uts, uas
  /// - rpsDetail.bobot: persentase untuk minggu tersebut
  /// - rpsDetail.subCpmkIds: Sub-CPMK yang terlibat di minggu tersebut
  Future<Map<String, Map<String, double>>> _getSubCpmkBobotMapFromDatabase(
    int matakuliahId,
  ) async {
    try {
      final result = <String, Map<String, double>>{};

      // Get semua RPS detail untuk matakuliah ini
      final rpsDetails = await _dbHelper.getRPSDetailByMatakuliah(matakuliahId);

      if (rpsDetails.isEmpty) {
        throw Exception(
          '❌ RPS Detail tidak ditemukan untuk MK $matakuliahId. '
          'Pastikan RPS sudah di-upload dan di-parse.',
        );
      }

      print('📋 RPS Details ditemukan: ${rpsDetails.length} minggu');

      // Kumpulkan semua Sub-CPMK IDs dari RPS
      final subCpmkIds = <int>{};
      for (final rpsDetail in rpsDetails) {
        if (rpsDetail.subCpmkIds != null) {
          subCpmkIds.addAll(rpsDetail.subCpmkIds!);
        }
      }

      if (subCpmkIds.isEmpty) {
        throw Exception(
          '❌ Tidak ada Sub-CPMK dalam RPS untuk MK $matakuliahId. '
          'Pastikan RPS sudah di-link dengan Sub-CPMK.',
        );
      }

      print('📌 Sub-CPMKs ditemukan: ${subCpmkIds.toList()}');

      // ✅ AGGREGATE BOBOT DARI RPS DATA LANGSUNG
      // Inisialisasi map untuk setiap Sub-CPMK dengan komponen kosong
      const komponenNames = [
        'aktivitas',
        'proyek',
        'kuis',
        'tugas',
        'uts',
        'uas'
      ];

      for (final subCpmkId in subCpmkIds) {
        final bobotMap = <String, double>{};
        for (final komponen in komponenNames) {
          bobotMap[komponen] = 0.0; // Inisialisasi dengan 0
        }
        result[subCpmkId.toString()] = bobotMap;
      }

      // ✅ Baca bobot dari RPS dan agregasi per komponen
      print('\n📊 Aggregating bobot dari RPS Details:');
      for (final rpsDetail in rpsDetails) {
        final mingguKe = rpsDetail.mingguKe;
        final jenisNilai = rpsDetail.jenisNilai?.toLowerCase().trim() ?? '';
        final bobot = rpsDetail.bobot ?? 0.0;
        final subCpmkIds_ = rpsDetail.subCpmkIds ?? [];

        if (jenisNilai.isEmpty || bobot == 0 || subCpmkIds_.isEmpty) {
          continue;
        }

        // Parse jenisNilai ke komponen index (flexible matching)
        String? komponenName;
        if (jenisNilai.contains('aktivitas') || jenisNilai.contains('activity')) {
          komponenName = 'aktivitas';
        } else if (jenisNilai.contains('proyek') || jenisNilai.contains('project')) {
          komponenName = 'proyek';
        } else if (jenisNilai.contains('kuis') || jenisNilai.contains('quiz')) {
          komponenName = 'kuis';
        } else if (jenisNilai.contains('tugas') || jenisNilai.contains('assignment')) {
          komponenName = 'tugas';
        } else if (jenisNilai.contains('uts') || jenisNilai.contains('midterm')) {
          komponenName = 'uts';
        } else if (jenisNilai.contains('uas') || jenisNilai.contains('final')) {
          komponenName = 'uas';
        }

        if (komponenName == null) {
          print(
              '⚠️  Minggu $mingguKe: jenisNilai "$jenisNilai" tidak dikenal - skipped');
          continue;
        }

        // Tambahkan bobot ke setiap Sub-CPMK yang terlibat
        for (final subCpmkId in subCpmkIds_) {
          final subCpmkIdStr = subCpmkId.toString();
          if (result.containsKey(subCpmkIdStr)) {
            result[subCpmkIdStr]![komponenName] =
                _roundToTwoDecimals(result[subCpmkIdStr]![komponenName]! + bobot);
            print(
                '   Minggu $mingguKe: Sub-CPMK $subCpmkIdStr += $bobot% untuk $komponenName');
          }
        }
      }

      if (result.values.every((bobotMap) =>
          bobotMap.values.every((bobot) => bobot == 0))) {
        // ❌ Semua bobot 0 - TIDAK boleh pakai fallback
        final errorMsg =
            '❌ Semua Sub-CPMK bobot adalah 0 dari RPS untuk MK $matakuliahId.\n'
            '⚠️ Silahkan Cek RPS Terlebih Dahulu\n\n'
            'Pastikan RPS minggu 1-16 sudah dikonfigurasi dengan:\n'
            '  • Bobot pembelajaran (%) di setiap minggu\n'
            '  • Jenis penilaian (aktivitas, proyek, kuis, tugas, uts, uas)\n'
            '  • Sub-CPMK yang terlibat';
        
        print(errorMsg);
        throw Exception(errorMsg);
      }

      print('\n📊 Bobot Matrix hasil agregasi RPS:');
      print('📝 Sub-CPMK IDs: ${subCpmkIds.toList()}');

      if (result.isEmpty) {
        throw Exception(
          '❌ Bobot matrix kosong untuk MK $matakuliahId. '
          'Debug info: '
          'subCpmkIds=${subCpmkIds.toList()}. '
          'Pastikan RPS minggu 1-16 sudah dikonfigurasi.',
        );
      }

      print('\n✅ Sub-CPMK bobot map loaded dari RPS aggregation');
      for (final entry in result.entries) {
        final totalBobot =
            entry.value.values.fold<double>(0, (a, b) => a + b);
        _validateTotalWeights('Sub-CPMK ${entry.key}', totalBobot);
        print('   Sub-CPMK ${entry.key}: ${entry.value}');
      }

      return result;
    } catch (e) {
      print('❌ Error getting Sub-CPMK bobot map: $e');
      rethrow;
    }
  }

  /// � DEBUG: Tampilkan detail RPS data dari database
  /// Gunakan method ini untuk verify apa yang tersimpan di database vs expected dari PDF
  Future<void> debugPrintRPSDataForMatakuliah(int matakuliahId) async {
    try {
      print('\n${'='*80}');
      print('🔍 DEBUG - RPS DATA FROM DATABASE FOR MK $matakuliahId');
      print('${'='*80}\n');

      final rpsDetails = await _dbHelper.getRPSDetailByMatakuliah(matakuliahId);

      if (rpsDetails.isEmpty) {
        print('⚠️  No RPS Details found for MK $matakuliahId');
        return;
      }

      print('📋 Total RPS Details: ${rpsDetails.length} minggu\n');

      // Kelompokkan per minggu
      final rpsPerMinggu = <int, List<RPSDetail>>{};
      for (final rps in rpsDetails) {
        if (rpsPerMinggu[rps.mingguKe] == null) {
          rpsPerMinggu[rps.mingguKe] = [];
        }
        rpsPerMinggu[rps.mingguKe]!.add(rps);
      }

      // Tampilkan per minggu
      for (var mingguKe = 1; mingguKe <= 16; mingguKe++) {
        final rpsForMinggu = rpsPerMinggu[mingguKe];
        
        if (rpsForMinggu == null || rpsForMinggu.isEmpty) {
          print('Minggu $mingguKe: ❌ NO DATA');
          continue;
        }

        print('Minggu $mingguKe:');
        for (final rps in rpsForMinggu) {
          print('  📊 Data RPS:');
          print('     - Topik: ${rps.topik ?? 'N/A'}');
          print('     - Metode: ${rps.metodeAjar ?? 'N/A'}');
          print('     - Jenis Penilaian: ${rps.jenisNilai ?? 'N/A'}');
          print('     - Bobot: ${rps.bobot ?? 0}%');
          
          if (rps.subCpmkIds != null && rps.subCpmkIds!.isNotEmpty) {
            print('     - Sub-CPMK: ${rps.subCpmkIds!.join(', ')}');
          } else {
            print('     - Sub-CPMK: ❌ NONE');
          }

          if (rps.cpmkIds != null && rps.cpmkIds!.isNotEmpty) {
            print('     - CPMK: ${rps.cpmkIds!.join(', ')}');
          }
        }
        print('');
      }

      // Aggregate bobot per Sub-CPMK per komponen
      print('\n${'='*80}');
      print('📊 AGGREGATED BOBOT PER SUB-CPMK PER KOMPONEN');
      print('${'='*80}\n');

      final aggregatedBobot = <int, Map<String, double>>{};
      const komponenNames = [
        'aktivitas',
        'proyek',
        'kuis',
        'tugas',
        'uts',
        'uas'
      ];

      // Collect all Sub-CPMK IDs
      final allSubCpmkIds = <int>{};
      for (final rps in rpsDetails) {
        if (rps.subCpmkIds != null) {
          allSubCpmkIds.addAll(rps.subCpmkIds!);
        }
      }

      // Initialize maps
      for (final subCpmkId in allSubCpmkIds) {
        aggregatedBobot[subCpmkId] = {};
        for (final komponen in komponenNames) {
          aggregatedBobot[subCpmkId]![komponen] = 0.0;
        }
      }

      // Aggregate
      for (final rps in rpsDetails) {
        final jenisNilai = rps.jenisNilai?.toLowerCase().trim() ?? '';
        final bobot = rps.bobot ?? 0.0;
        final subCpmkIds = rps.subCpmkIds ?? [];

        if (jenisNilai.isEmpty || bobot == 0 || subCpmkIds.isEmpty) {
          continue;
        }

        // Parse jenis_penilaian to komponen
        String? komponenName;
        if (jenisNilai.contains('aktivitas') || jenisNilai.contains('activity')) {
          komponenName = 'aktivitas';
        } else if (jenisNilai.contains('proyek') || jenisNilai.contains('project')) {
          komponenName = 'proyek';
        } else if (jenisNilai.contains('kuis') || jenisNilai.contains('quiz')) {
          komponenName = 'kuis';
        } else if (jenisNilai.contains('tugas') || jenisNilai.contains('assignment')) {
          komponenName = 'tugas';
        } else if (jenisNilai.contains('uts') || jenisNilai.contains('midterm')) {
          komponenName = 'uts';
        } else if (jenisNilai.contains('uas') || jenisNilai.contains('final')) {
          komponenName = 'uas';
        }

        if (komponenName == null) {
          print(
              '⚠️  Unknown jenis_penilaian "$jenisNilai" in minggu ${rps.mingguKe}');
          continue;
        }

        for (final subCpmkId in subCpmkIds) {
          if (aggregatedBobot.containsKey(subCpmkId)) {
            aggregatedBobot[subCpmkId]![komponenName] =
                _roundToTwoDecimals(aggregatedBobot[subCpmkId]![komponenName]! + bobot);
          }
        }
      }

      // Print aggregated bobot
      final sortedSubCpmkIds = aggregatedBobot.keys.toList()..sort();
      for (final subCpmkId in sortedSubCpmkIds) {
        final bobotMap = aggregatedBobot[subCpmkId]!;
        final totalBobot =
            bobotMap.values.fold<double>(0, (a, b) => a + b);
        
        print('Sub-CPMK $subCpmkId (Total: ${totalBobot.toStringAsFixed(2)}%):');
        
        bobotMap.forEach((komponen, bobot) {
          if (bobot > 0) {
            print('   - $komponen: ${bobot.toStringAsFixed(2)}%');
          }
        });
        print('');
      }

      print('${'='*80}\n');
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  /// �🔧 Helper: Get CPMK←SubCPMK mapping dari database
  /// 
  /// FORMAT OUTPUT: {"cpmk1": {"sub1": 15, "sub2": 15, ...}, ...}
  /// 
  /// DATA SOURCE: Table sub_cpmk_cpmk atau cpmk_sub_cpmk
  /// Expected schema:
  ///   - cpmk_id (int)
  ///   - sub_cpmk_id (int)
  ///   - bobot (double): weight of Sub-CPMK in CPMK
  Future<Map<String, Map<String, double>>> _getCpmkSubCpmkMapFromDatabase(
    int matakuliahId,
  ) async {
    try {
      final result = <String, Map<String, double>>{};

      // Get semua SubCPMK untuk matakuliah ini
      final subCpmkList = await _dbHelper.getSubCPMKByMatakuliah(matakuliahId);
      
      if (subCpmkList.isEmpty) {
        throw Exception('Sub-CPMK tidak ditemukan untuk MK $matakuliahId');
      }

      print('📋 SubCPMKs ditemukan: ${subCpmkList.length}');
      final validSubCpmkIds = <String>{};
      for (final sub in subCpmkList) {
        if (sub.id != null) {
          validSubCpmkIds.add(sub.id.toString());
        }
      }
      print('   IDs: ${validSubCpmkIds.toList()}');

      // Get semua mappings
      final allMappings = await _dbHelper.getAllSubCPMKCPMKMappings();
      
      if (allMappings.isEmpty) {
        throw Exception('Sub-CPMK←CPMK mappings tidak ditemukan di database');
      }

      print('📌 Mappings ditemukan: ${allMappings.length} records');

      // Build map dari data yang tersedia
      for (final mapping in allMappings) {
        final cpmkId = mapping['cpmk_id'].toString();
        final subCpmkId = mapping['sub_cpmk_id'].toString();
        final bobot = (mapping['bobot'] as num?)?.toDouble() ?? 0.0;

        // Check apakah sub_cpmk ini ada di MK kita
        if (!validSubCpmkIds.contains(subCpmkId)) {
          continue;
        }

        if (!result.containsKey(cpmkId)) {
          result[cpmkId] = {};
        }

        result[cpmkId]![subCpmkId] = bobot;
      }

      print('✅ CPMK←SubCPMK mapping created: ${result.length} CPMKs');
      for (final entry in result.entries) {
        print('   CPMK ${entry.key}: ${entry.value}');
      }

      if (result.isEmpty) {
        throw Exception('CPMK←SubCPMK mapping kosong untuk MK $matakuliahId. Pastikan mappings sudah tersimpan di database.');
      }

      return result;
    } catch (e) {
      print('❌ Error getting CPMK←SubCPMK mapping: $e');
      rethrow;
    }
  }

  /// 🔧 Helper: Get CPL←CPMK mapping dari database
  /// 
  /// FORMAT OUTPUT: {"cpl1": {"cpmk1": 30, "cpmk2": 35, ...}, ...}
  /// 
  /// DATA SOURCE: Table cpl_cpmk atau cpmk_cpl (weighted)
  /// Expected schema:
  ///   - cpl_id (int)
  ///   - cpmk_id (int)
  ///   - bobot (double): weight of CPMK in CPL aggregation
  /// 
  /// RETURNS: Null atau empty map jika mapping tidak ada (CPL is optional)
  Future<Map<String, Map<String, double>>> _getCPLCpmkMapFromDatabase(
    int matakuliahId,
  ) async {
    try {
      final result = <String, Map<String, double>>{};

      // Get mappings dari database - CPL is OPTIONAL
      List<Map<String, dynamic>>? allMappings;
      try {
        allMappings =
            await _dbHelper.getAllCPLCPMKMappings();
      } catch (e) {
        // Method mungkin tidak tersedia di DatabaseHelper - okay, CPL is optional
        print('⚠️ CPL←CPMK mappings tidak tersedia (optional): $e');
        return result;
      }

      if (allMappings == null || allMappings.isEmpty) {
        print('⚠️ CPL←CPMK mappings tidak ditemukan (optional - skipped)');
        return result;
      }

      print('📌 CPL←CPMK mappings ditemukan: ${allMappings.length} records');

      // Get valid CPMK IDs untuk MK ini
      final validCpmkIds = <String>{};
      final cpmkSubCpmkMap = await _getCpmkSubCpmkMapFromDatabase(matakuliahId);
      validCpmkIds.addAll(cpmkSubCpmkMap.keys);

      // Build map dari mappings
      for (final mapping in allMappings) {
        final cplId = mapping['cpl_id'].toString();
        final cpmkId = mapping['cpmk_id'].toString();
        final bobot = (mapping['bobot'] as num?)?.toDouble() ?? 0.0;

        // Check apakah CPMK ini ada di MK kita
        if (!validCpmkIds.contains(cpmkId)) {
          continue;
        }

        if (!result.containsKey(cplId)) {
          result[cplId] = {};
        }

        result[cplId]![cpmkId] = bobot;
      }

      if (result.isNotEmpty) {
        print('✅ CPL←CPMK mapping loaded: ${result.length} CPLs');
        for (final entry in result.entries) {
          print('   CPL ${entry.key}: ${entry.value}');
        }
      }

      return result;
    } catch (e) {
      print('⚠️ Warning getting CPL←CPMK mapping: $e');
      return {}; // Return empty, CPL is optional
    }
  }
}

/// ============================================================================
/// VALIDATION CONFIGURATION (NEW)
/// ============================================================================

/// Configuration untuk kontrol validasi dan fallback behavior
/// 
/// USE CASE:
/// - Production: strict=true untuk validasi ketat
/// - Development: strict=false untuk fallback lenient
class OBEValidationConfig {
  /// If true: throw error jika total bobot ≠ 100 (±1%)
  /// If false: warn only dengan print()
  final bool strictWeightValidation;

  /// If true: throw error jika nilai komponen diluar range [0, 100]
  /// If false: warn only
  final bool strictValueValidation;

  /// If true: throw error jika bobot tidak ditemukan di database
  /// If false: use fallback equal distribution (NOT RECOMMENDED)
  final bool strictBobotValidation;

  /// If true: warn ketika menggunakan fallback equal weight untuk CPL
  final bool warnOnFallback;

  /// Tolerance untuk weight validation (default: 1% dari target)
  final double weightTolerance;

  const OBEValidationConfig({
    this.strictWeightValidation = false,
    this.strictValueValidation = true,
    this.strictBobotValidation = true,
    this.warnOnFallback = true,
    this.weightTolerance = 1.0,
  });

  /// Production config: strict validation everywhere
  static const OBEValidationConfig production = OBEValidationConfig(
    strictWeightValidation: true,
    strictValueValidation: true,
    strictBobotValidation: true,
    warnOnFallback: true,
  );

  /// Development config: lenient with warnings
  static const OBEValidationConfig development = OBEValidationConfig(
    strictWeightValidation: false,
    strictValueValidation: true,
    strictBobotValidation: false,
    warnOnFallback: true,
  );
}

/// ============================================================================
/// RESPONSE MODEL
/// ============================================================================

/// Model untuk response hasil perhitungan OBE
/// 
/// COMPATIBLE DENGAN KEDUA FORMAT:
/// - Format Baru: Map<String, double> dengan String keys
/// - Format Lama: Map<int, double> dengan int keys (via compatibility getters)
class OBECalculationResult {
  final bool success;
  final String? errorMessage;
  final Map<String, double> subCpmkValues;
  final Map<String, double> cpmkValues;
  final Map<String, double> cplValues;
  
  // Legacy fields untuk backward compatibility
  final int? mahasiswaId;
  final int? matakuliahId;
  final int? tahunAjaran;
  final Map<int, double>? subCpmkBobots;

  OBECalculationResult({
    bool? success,
    this.errorMessage,
    this.subCpmkValues = const {},
    this.cpmkValues = const {},
    this.cplValues = const {},
    this.mahasiswaId,
    this.matakuliahId,
    this.tahunAjaran,
    this.subCpmkBobots,
  }) : success = success ?? true;

  /// Factory constructor untuk error response
  factory OBECalculationResult.error(String message) {
    return OBECalculationResult(
      success: false,
      errorMessage: message,
    );
  }

  /// Factory constructor untuk success response
  factory OBECalculationResult.success({
    required Map<String, double> subCpmkValues,
    required Map<String, double> cpmkValues,
    Map<String, double> cplValues = const {},
  }) {
    return OBECalculationResult(
      success: true,
      subCpmkValues: subCpmkValues,
      cpmkValues: cpmkValues,
      cplValues: cplValues,
    );
  }

  /// Convert ke JSON format sesuai spesifikasi
  Map<String, dynamic> toJson() {
    return {
      'status': success ? 'success' : 'error',
      'message': errorMessage,
      'sub_cpmk': subCpmkValues,
      'cpmk': cpmkValues,
      'cpl': cplValues,
    };
  }

  /// Rata-rata Sub-CPMK
  double get averageSubCPMK {
    if (subCpmkValues.isEmpty) return 0.0;
    final sum = subCpmkValues.values.fold<double>(0.0, (a, b) => a + b);
    return (sum / subCpmkValues.length * 100).round() / 100;
  }

  /// Rata-rata CPMK
  double get averageCPMK {
    if (cpmkValues.isEmpty) return 0.0;
    final sum = cpmkValues.values.fold<double>(0.0, (a, b) => a + b);
    return (sum / cpmkValues.length * 100).round() / 100;
  }

  /// Rata-rata CPL
  double get averageCPL {
    if (cplValues.isEmpty) return 0.0;
    final sum = cplValues.values.fold<double>(0.0, (a, b) => a + b);
    return (sum / cplValues.length * 100).round() / 100;
  }

  /// ============================================================================
  /// LEGACY COMPATIBILITY PROPERTIES (Backward Compatibility)
  /// ============================================================================

  /// Check apakah ada data (legacy property)
  bool get hasData {
    return success && (subCpmkValues.isNotEmpty || cpmkValues.isNotEmpty || cplValues.isNotEmpty);
  }

  /// Legacy: Rata-rata Sub-CPMK (dengan nama lama)
  double get averageSubCPMKNilai => averageSubCPMK;

  /// Legacy: Rata-rata CPMK (dengan nama lama)
  double get averageCPMKNilai => averageCPMK;

  /// Legacy: Rata-rata CPL (dengan nama lama)
  double get averageCPLNilai => averageCPL;

  /// Legacy: Sub-CPMK values dengan int keys (konversi dari String)
  Map<int, double> get subCPMKValues {
    final result = <int, double>{};
    for (final entry in subCpmkValues.entries) {
      final key = int.tryParse(entry.key) ?? 0;
      if (key > 0) {
        result[key] = entry.value;
      }
    }
    return result;
  }

  /// Legacy: CPMK values dengan int keys (konversi dari String)
  Map<int, double> get cPMKValues {
    final result = <int, double>{};
    for (final entry in cpmkValues.entries) {
      final key = int.tryParse(entry.key) ?? 0;
      if (key > 0) {
        result[key] = entry.value;
      }
    }
    return result;
  }

  /// Legacy: CPL values dengan int keys (konversi dari String)
  Map<int, double> get cPLValues {
    final result = <int, double>{};
    for (final entry in cplValues.entries) {
      final key = int.tryParse(entry.key) ?? 0;
      if (key > 0) {
        result[key] = entry.value;
      }
    }
    return result;
  }

  /// ============================================================================
  /// DIAGNOSTIC & DEBUGGING
  /// ============================================================================

  /// Pretty print untuk debugging
  @override
  String toString() {
    if (!success) {
      return 'OBECalculationResult[ERROR: $errorMessage]';
    }

    final buffer = StringBuffer();
    buffer.writeln('OBECalculationResult[');
    buffer.writeln('  mahasiswa: $mahasiswaId');
    buffer.writeln('  matakuliah: $matakuliahId');
    buffer.writeln('  Sub-CPMK avg: ${averageSubCPMK}');
    buffer.writeln('  CPMK avg: ${averageCPMK}');
    buffer.writeln('  CPL avg: ${averageCPL}');
    buffer.writeln('  Sub-CPMK values: $subCpmkValues');
    buffer.writeln('  CPMK values: $cpmkValues');
    buffer.writeln('  CPL values: $cplValues');
    buffer.writeln(']');
    return buffer.toString();
  }

  /// Get diagnostic report untuk validation
  String getDiagnosticReport() {
    final buffer = StringBuffer();
    buffer.writeln('═' * 60);
    buffer.writeln('OBE CALCULATION DIAGNOSTIC REPORT');
    buffer.writeln('═' * 60);

    if (!success) {
      buffer.writeln('Status: ❌ FAILED');
      buffer.writeln('Error: $errorMessage');
      return buffer.toString();
    }

    buffer.writeln('Status: ✅ SUCCESS');
    buffer.writeln('Mahasiswa: $mahasiswaId');
    buffer.writeln('Matakuliah: $matakuliahId');
    buffer.writeln('Tahun Ajaran: $tahunAjaran');
    buffer.writeln('');

    buffer.writeln('Sub-CPMK Values: (${subCpmkValues.length} items)');
    for (final entry in subCpmkValues.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    buffer.writeln('Average: ${averageSubCPMK}');
    buffer.writeln('');

    buffer.writeln('CPMK Values: (${cpmkValues.length} items)');
    for (final entry in cpmkValues.entries) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }
    buffer.writeln('Average: ${averageCPMK}');
    buffer.writeln('');

    if (cplValues.isNotEmpty) {
      buffer.writeln('CPL Values: (${cplValues.length} items)');
      for (final entry in cplValues.entries) {
        buffer.writeln('  ${entry.key}: ${entry.value}');
      }
      buffer.writeln('Average: ${averageCPL}');
    } else {
      buffer.writeln('CPL Values: (not calculated - optional)');
    }

    buffer.writeln('═' * 60);
    return buffer.toString();
  }
}
