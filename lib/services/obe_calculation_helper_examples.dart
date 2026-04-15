/// 📋 CONTOH PENGGUNAAN OBE_CALCULATION_HELPER.DART
/// 
/// ⚠️ VERSION: v3 (dengan OBEValidationConfig dan weighted CPL aggregation)
/// 
/// 🔄 PERUBAHAN DARI v2 KE v3:
/// 1. CPL mapping format berubah dari List<String> menjadi Map<String, double>
///    ❌ OLD: 'cpl1': ['cpmk1', 'cpmk2']  (simple average)
///    ✅ NEW: 'cpl1': {'cpmk1': 50.0, 'cpmk2': 50.0}  (weighted aggregation)
/// 
/// 2. Tambahan OBEValidationConfig untuk kontrol validasi
/// 3. Bobot harus dari database (tidak hardcoded)
/// 4. Error handling lebih ketat (missing values throw error)
/// 
/// File ini menunjukkan bagaimana menggunakan OBECalculationHelper
/// dengan contoh kasus nyata sesuai spesifikasi v3.

import 'package:cpl/services/obe_calculation_helper.dart';

/// ============================================================================
/// CONTOH 1: PERHITUNGAN LENGKAP (Sub-CPMK → CPMK → CPL)
/// ============================================================================
/// CATATAN: Menggunakan v3 API dengan weighted CPL aggregation
/// (bukan simple List seperti v2)
void exampleCompleteCalculation() {
  print('🎯 CONTOH 1: Perhitungan Lengkap OBE');
  print('=' * 70);

  // INPUT DATA
  final nilaiKomponen = {
    'aktivitas': 80.0,
    'proyek': 85.0,
    'kuis': 75.0,
    'tugas': 90.0,
    'uts': 88.0,
    'uas': 92.0,
  };

  final subCpmkBobotMap = {
    'sub1': {
      'aktivitas': 10.0,
      'proyek': 15.0,
      'kuis': 10.0,
      'tugas': 15.0,
      'uts': 25.0,
      'uas': 25.0,
    },
    'sub2': {
      'aktivitas': 15.0,
      'proyek': 20.0,
      'kuis': 10.0,
      'tugas': 10.0,
      'uts': 20.0,
      'uas': 25.0,
    },
    'sub3': {
      'aktivitas': 0.0,   // Bobot 0 → akan diabaikan
      'proyek': 30.0,
      'kuis': 20.0,
      'tugas': 0.0,
      'uts': 25.0,
      'uas': 25.0,
    },
  };

  final cpmkSubCpmkMap = {
    'cpmk1': {
      'sub1': 20.0,
      'sub2': 15.0,
      'sub3': 10.0,
    },
    'cpmk2': {
      'sub2': 25.0,
      'sub3': 20.0,
    },
  };

  final cplCpmkMap = {
    'cpl1': {
      'cpmk1': 50.0,  // CPMK1 weight dalam CPL1
      'cpmk2': 50.0,  // CPMK2 weight dalam CPL1
    },
    'cpl2': {
      'cpmk2': 100.0,  // CPMK2 weight dalam CPL2
    },
  };

  // MIGRASI DARI v2 KE v3:
  // ❌ OLD (v2):  'cpl1': ['cpmk1', 'cpmk2']  (simple list, simple average)
  // ✅ NEW (v3):  'cpl1': {'cpmk1': 50.0, 'cpmk2': 50.0}  (weighted aggregation)

  // HITUNG MENGGUNAKAN HELPER
  final helper = OBECalculationHelper();
  final result = helper.calculateOBEComplete(
    nilaiKomponen: nilaiKomponen,
    subCpmkBobotMap: subCpmkBobotMap,
    cpmkSubCpmkMap: cpmkSubCpmkMap,
    cplCpmkMap: cplCpmkMap,
  );

  // TAMPILKAN HASIL
  print('\n📊 HASIL PERHITUNGAN:');
  print('Status: ${result['status']}');
  
  if (result['status'] == 'success') {
    final subCpmkValues = result['sub_cpmk'] as Map<String, double>;
    final cpmkValues = result['cpmk'] as Map<String, double>;
    final cplValues = result['cpl'] as Map<String, double>;

    print('\n📈 Sub-CPMK Values:');
    subCpmkValues.forEach((id, nilai) {
      print('  $id: $nilai');
    });

    print('\n📈 CPMK Values:');
    cpmkValues.forEach((id, nilai) {
      print('  $id: $nilai');
    });

    print('\n📈 CPL Values:');
    cplValues.forEach((id, nilai) {
      print('  $id: $nilai');
    });

    // Rata-rata
    final avgSubCpmk = subCpmkValues.values
        .fold<double>(0.0, (a, b) => a + b) /
        subCpmkValues.length;
    final avgCpmk = cpmkValues.values
        .fold<double>(0.0, (a, b) => a + b) /
        cpmkValues.length;
    final avgCpl = cplValues.values
        .fold<double>(0.0, (a, b) => a + b) /
        cplValues.length;

    print('\n📊 RATA-RATA:');
    print('  Rata-rata Sub-CPMK: ${(avgSubCpmk * 100).round() / 100}');
    print('  Rata-rata CPMK: ${(avgCpmk * 100).round() / 100}');
    print('  Rata-rata CPL: ${(avgCpl * 100).round() / 100}');
  } else {
    print('❌ Error: ${result['message']}');
  }
}

/// ============================================================================
/// CONTOH 2: PERHITUNGAN STEP-BY-STEP
/// ============================================================================
void exampleStepByStep() {
  print('\n\n🎯 CONTOH 2: Perhitungan Step-by-Step');
  print('=' * 70);

  final helper = OBECalculationHelper();

  // DATA
  final nilaiKomponen = {
    'aktivitas': 85.0,
    'proyek': 88.0,
    'kuis': 82.0,
    'tugas': 91.0,
    'uts': 89.0,
    'uas': 93.0,
  };

  final subCpmkBobotMap = {
    'sub1': {
      'aktivitas': 10.0,
      'proyek': 15.0,
      'kuis': 10.0,
      'tugas': 15.0,
      'uts': 25.0,
      'uas': 25.0,
    },
    'sub2': {
      'aktivitas': 15.0,
      'proyek': 20.0,
      'kuis': 15.0,
      'tugas': 10.0,
      'uts': 20.0,
      'uas': 20.0,
    },
  };

  final cpmkSubCpmkMap = {
    'cpmk1': {
      'sub1': 50.0,
      'sub2': 50.0,
    },
  };

  // STEP 1: Hitung Sub-CPMK
  print('\n🔢 STEP 1: Hitung Sub-CPMK');
  try {
    final subCpmkValues = helper.calculateSubCPMKValues(
      nilaiKomponen: nilaiKomponen,
      subCpmkBobotMap: subCpmkBobotMap,
    );
    print('✅ Sub-CPMK berhasil dihitung:');
    subCpmkValues.forEach((id, nilai) {
      print('   $id: $nilai');
    });

    // STEP 2: Hitung CPMK
    print('\n🔢 STEP 2: Hitung CPMK');
    final cpmkValues = helper.calculateCPMKValues(
      subCpmkValues: subCpmkValues,
      cpmkSubCpmkMap: cpmkSubCpmkMap,
    );
    print('✅ CPMK berhasil dihitung:');
    cpmkValues.forEach((id, nilai) {
      print('   $id: $nilai');
    });
  } catch (e) {
    print('❌ Error: $e');
  }
}

/// ============================================================================
/// CONTOH 3: ERROR HANDLING
/// ============================================================================
void exampleErrorHandling() {
  print('\n\n🎯 CONTOH 3: Error Handling');
  print('=' * 70);

  final helper = OBECalculationHelper();

  // Kasus 1: Nilai Komponen Kosong
  print('\n🔴 Kasus 1: Nilai Komponen Kosong');
  try {
    helper.calculateSubCPMKValues(
      nilaiKomponen: {}, // ❌ Kosong
      subCpmkBobotMap: {
        'sub1': {
          'aktivitas': 10.0,
          'proyek': 20.0,
        },
      },
    );
  } catch (e) {
    print('✅ Error tertangkap: $e');
  }

  // Kasus 2: Total Bobot = 0
  print('\n🔴 Kasus 2: Total Bobot = 0');
  try {
    helper.calculateSubCPMKValues(
      nilaiKomponen: {
        'aktivitas': 80.0,
        'proyek': 85.0,
      },
      subCpmkBobotMap: {
        'sub1': {
          'aktivitas': 0.0, // Semua bobot 0 → total bobot = 0
          'proyek': 0.0,
        },
      },
    );
  } catch (e) {
    print('✅ Error tertangkap: $e');
  }

  // Kasus 3: Nilai Komponen Tidak Ditemukan
  print('\n🔴 Kasus 3: Nilai Komponen Tidak Ditemukan');
  try {
    helper.calculateSubCPMKValues(
      nilaiKomponen: {
        'aktivitas': 80.0, // Hanya aktivitas, tidak ada proyek
      },
      subCpmkBobotMap: {
        'sub1': {
          'aktivitas': 10.0,
          'proyek': 20.0, // ❌ Proyek tidak ada dalam nilai
        },
      },
    );
  } catch (e) {
    print('✅ Error tertangkap: $e');
  }

  // Kasus 4: Sub-CPMK Tidak Ditemukan dalam Values
  print('\n🔴 Kasus 4: Sub-CPMK Tidak Ditemukan');
  try {
    helper.calculateCPMKValues(
      subCpmkValues: {
        'sub1': 85.0,
        // sub2 tidak ada
      },
      cpmkSubCpmkMap: {
        'cpmk1': {
          'sub1': 50.0,
          'sub2': 50.0, // ❌ sub2 tidak ada dalam values
        },
      },
    );
  } catch (e) {
    print('✅ Error tertangkap: $e');
  }
}

/// ============================================================================
/// CONTOH 4: PERHITUNGAN DENGAN BOBOT 0 (Abaikan Komponen)
/// ============================================================================
void exampleWithZeroBobot() {
  print('\n\n🎯 CONTOH 4: Perhitungan dengan Bobot 0');
  print('=' * 70);

  final helper = OBECalculationHelper();

  final nilaiKomponen = {
    'aktivitas': 80.0,
    'proyek': 85.0,
    'kuis': 75.0,
    'tugas': 90.0,
    'uts': 88.0,
    'uas': 92.0,
  };

  // Sub-CPMK dengan beberapa bobot = 0
  final subCpmkBobotMap = {
    'sub1': {
      'aktivitas': 20.0,
      'proyek': 30.0,
      'kuis': 0.0,    // ❌ Bobot 0 → akan diabaikan
      'tugas': 0.0,   // ❌ Bobot 0 → akan diabaikan
      'uts': 25.0,
      'uas': 25.0,
    },
  };

  print('\n📝 Penjelasan:');
  print('  - Komponen dengan bobot 0 akan diabaikan dari perhitungan');
  print('  - Total bobot aktif: 20 + 30 + 25 + 25 = 100');
  print('  - Bobot normal: aktivitas=0.20, proyek=0.30, uts=0.25, uas=0.25');
  print('  - Nilai Sub-CPMK = (0.20×80) + (0.30×85) + (0.25×88) + (0.25×92)');
  print('  - Nilai Sub-CPMK = 16 + 25.5 + 22 + 23 = 86.50');

  try {
    final subCpmkValues = helper.calculateSubCPMKValues(
      nilaiKomponen: nilaiKomponen,
      subCpmkBobotMap: subCpmkBobotMap,
    );
    print('\n✅ Hasil Perhitungan:');
    subCpmkValues.forEach((id, nilai) {
      print('   $id: $nilai');
    });
  } catch (e) {
    print('❌ Error: $e');
  }
}

/// ============================================================================
/// CONTOH 5: RESPONSE MODEL
/// ============================================================================
void exampleResponseModel() {
  print('\n\n🎯 CONTOH 5: Response Model');
  print('=' * 70);

  // Success Response
  print('\n✅ Success Response:');
  final successResult = OBECalculationResult.success(
    subCpmkValues: {
      'sub1': 86.75,
      'sub2': 85.50,
      'sub3': 84.20,
    },
    cpmkValues: {
      'cpmk1': 85.77,
      'cpmk2': 84.65,
    },
    cplValues: {
      'cpl1': 85.20,
      'cpl2': 84.65,
    },
  );

  print('Status: ${successResult.success}');
  print('Rata-rata Sub-CPMK: ${successResult.averageSubCPMK}');
  print('Rata-rata CPMK: ${successResult.averageCPMK}');
  print('Rata-rata CPL: ${successResult.averageCPL}');

  // Convert to JSON
  print('\n📋 JSON Format:');
  print(successResult.toJson());

  // Error Response
  print('\n\n❌ Error Response:');
  final errorResult = OBECalculationResult.error(
    'Bobot Sub-CPMK tidak valid',
  );

  print('Status: ${errorResult.success}');
  print('Error Message: ${errorResult.errorMessage}');
  print('JSON: ${errorResult.toJson()}');
}

/// ============================================================================
/// CONTOH 6: ROUND-UP PRECISION
/// ============================================================================
void exampleRoundingPrecision() {
  print('\n\n🎯 CONTOH 6: Pembulatan 2 Desimal');
  print('=' * 70);

  final helper = OBECalculationHelper();

  final nilaiKomponen = {
    'aktivitas': 83.3333,
    'proyek': 86.6666,
    'kuis': 76.9999,
    'tugas': 91.1111,
    'uts': 87.5555,
    'uas': 92.4444,
  };

  final subCpmkBobotMap = {
    'sub1': {
      'aktivitas': 20.0,
      'proyek': 20.0,
      'kuis': 20.0,
      'tugas': 20.0,
      'uts': 10.0,
      'uas': 10.0,
    },
  };

  print('\n📝 Nilai Input (banyak desimal):');
  nilaiKomponen.forEach((k, v) {
    print('  $k: $v');
  });

  try {
    final subCpmkValues = helper.calculateSubCPMKValues(
      nilaiKomponen: nilaiKomponen,
      subCpmkBobotMap: subCpmkBobotMap,
    );

    print('\n✅ Hasil Perhitungan (dibulatkan 2 desimal):');
    subCpmkValues.forEach((id, nilai) {
      print('  $id: $nilai');
    });

    print('\n💡 Catatan: Semua hasil otomatis dibulatkan ke 2 desimal');
  } catch (e) {
    print('❌ Error: $e');
  }
}

/// ============================================================================
/// CONTOH 7: FISIKA MATEMATIKA I - REAL CASE STUDY
/// ============================================================================
/// Contoh lengkap sesuai dengan workflow yang ditunjukkan user
void exampleFisikaMatematikaI() {
  print('\n\n🎯 CONTOH 7: Fisika Matematika I (Real Case Study)');
  print('=' * 70);

  // 📥 INPUT NILAI KOMPONEN (dari database)
  final nilaiKomponen = {
    'aktivitas': 87.5,
    'proyek': 87.5,
    'kuis': 87.5,
    'tugas': 87.5,
    'uts': 60.0,
    'uas': 90.0,
  };

  print('\n📥 INPUT NILAI KOMPONEN:');
  nilaiKomponen.forEach((k, v) => print('   $k: $v'));

  // 🎯 BOBOT SUB-CPMK (dari RPS)
  final subCpmkBobotMap = {
    '276': {
      'aktivitas': 6.0,
      'proyek': 0.0,
      'kuis': 0.0,
      'tugas': 2.5,
      'uts': 6.0,
      'uas': 0.0,
    },
    '277': {
      'aktivitas': 0.0,
      'proyek': 5.0,
      'kuis': 0.0,
      'tugas': 0.0,
      'uts': 6.0,
      'uas': 0.0,
    },
    '278': {
      'aktivitas': 0.0,
      'proyek': 0.0,
      'kuis': 7.0,
      'tugas': 5.0,
      'uts': 7.0,
      'uas': 0.0,
    },
    '279': {
      'aktivitas': 0.0,
      'proyek': 5.0,
      'kuis': 0.0,
      'tugas': 0.0,
      'uts': 6.0,
      'uas': 0.0,
    },
    '280': {
      'aktivitas': 0.0,
      'proyek': 5.0,
      'kuis': 3.0,
      'tugas': 2.5,
      'uts': 0.0,
      'uas': 8.0,
    },
    '281': {
      'aktivitas': 0.0,
      'proyek': 5.0,
      'kuis': 0.0,
      'tugas': 0.0,
      'uts': 0.0,
      'uas': 9.0,
    },
    '282': {
      'aktivitas': 4.0,
      'proyek': 0.0,
      'kuis': 0.0,
      'tugas': 0.0,
      'uts': 0.0,
      'uas': 8.0,
    },
  };

  print('\n🎯 BOBOT SUB-CPMK (dari RPS):');
  print('   Sub-CPMK 276: Total=14.5');
  print('   Sub-CPMK 277: Total=11');
  print('   Sub-CPMK 278: Total=19');
  print('   Sub-CPMK 279: Total=11');
  print('   Sub-CPMK 280: Total=18.5');
  print('   Sub-CPMK 281: Total=14');
  print('   Sub-CPMK 282: Total=12');

  // CPMK ← SUB-CPMK MAPPING
  final cpmkSubCpmkMap = {
    '4': {
      '276': 14.5,
      '277': 11.0,
      '278': 19.0,
      '279': 11.0,
      '280': 18.5,
      '281': 14.0,
      '282': 12.0,
    },
  };

  print('\n🔗 CPMK ← SUB-CPMK MAPPING:');
  print('   CPMK 4:');
  print('      - Sub-CPMK 276 (bobot: 14.5)');
  print('      - Sub-CPMK 277 (bobot: 11.0)');
  print('      - Sub-CPMK 278 (bobot: 19.0)');
  print('      - Sub-CPMK 279 (bobot: 11.0)');
  print('      - Sub-CPMK 280 (bobot: 18.5)');
  print('      - Sub-CPMK 281 (bobot: 14.0)');
  print('      - Sub-CPMK 282 (bobot: 12.0)');
  print('      Total bobot = 100.0');

  // CALCULATE
  final helper = OBECalculationHelper();
  
  try {
    // Step 1: Hitung Sub-CPMK
    print('\n🔢 STEP 1: Hitung Sub-CPMK');
    print('-' * 70);
    
    final subCpmkValues = helper.calculateSubCPMKValues(
      nilaiKomponen: nilaiKomponen,
      subCpmkBobotMap: subCpmkBobotMap,
    );

    print('✅ Hasil Sub-CPMK:');
    subCpmkValues.forEach((id, nilai) {
      print('   Sub-CPMK $id: $nilai');
    });

    // Step 2: Hitung CPMK
    print('\n🔢 STEP 2: Hitung CPMK');
    print('-' * 70);
    
    final cpmkValues = helper.calculateCPMKValues(
      subCpmkValues: subCpmkValues,
      cpmkSubCpmkMap: cpmkSubCpmkMap,
    );

    print('✅ Hasil CPMK:');
    cpmkValues.forEach((id, nilai) {
      print('   CPMK $id: $nilai');
    });

    // Verify calculation
    print('\n📊 VERIFIKASI PERHITUNGAN:');
    print('-' * 70);
    
    final expectedValues = {
      '276': 76.12,
      '277': 72.50,
      '278': 77.37,
      '279': 72.50,
      '280': 88.58,
      '281': 89.11,
      '282': 89.17,
    };

    print('Expected vs Actual Sub-CPMK:');
    expectedValues.forEach((id, expected) {
      final actual = subCpmkValues[id] ?? 0.0;
      final match = (expected - actual).abs() < 0.01 ? '✅' : '❌';
      print('   $match Sub-CPMK $id: Expected=$expected, Actual=$actual');
    });

    final expectedCpmk = 81.25;
    final actualCpmk = cpmkValues['4'] ?? 0.0;
    final cpmkMatch = (expectedCpmk - actualCpmk).abs() < 0.01 ? '✅' : '❌';
    print('   $cpmkMatch CPMK 4: Expected=$expectedCpmk, Actual=$actualCpmk');

  } catch (e) {
    print('❌ Error: $e');
  }
}

/// ============================================================================
/// MAIN FUNCTION - JALANKAN SEMUA CONTOH
/// ============================================================================
void main() {
  print('\n');
  print('╔════════════════════════════════════════════════════════════════════╗');
  print('║   CONTOH PENGGUNAAN OBE_CALCULATION_HELPER.DART                   ║');
  print('╚════════════════════════════════════════════════════════════════════╝');

  exampleCompleteCalculation();
  exampleStepByStep();
  exampleErrorHandling();
  exampleWithZeroBobot();
  exampleResponseModel();
  exampleRoundingPrecision();
  exampleFisikaMatematikaI();

  print('\n\n✅ Semua contoh selesai!');
}
