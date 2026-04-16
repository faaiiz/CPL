/// 🧪 Test file untuk memverifikasi debug output CPMK calculation
/// Menggunakan data contoh dari user:
/// https://github.com/...
///
/// INPUT NILAI KOMPONEN:
///   aktivitas: 87.5
///   proyek: 87.5
///   kuis: 87.5
///   tugas: 87.5
///   uts: 60.0
///   uas: 90.0
///
/// EXPECTED HASIL:
///   Sub-CPMK 276: 76.12
///   Sub-CPMK 277: 72.50
///   Sub-CPMK 278: 77.37
///   Sub-CPMK 279: 72.50
///   Sub-CPMK 280: 88.58
///   Sub-CPMK 281: 89.11
///   Sub-CPMK 282: 89.17
///   CPMK 4: 81.25

import 'package:flutter/material.dart';
import 'lib/services/obe_calculation_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('='*80);
  print('🧪 TEST: CPMK 4 Calculation dengan Debug Output');
  print('='*80 + '\n');

  // Initialize calculation helper
  final helper = OBECalculationHelper();

  // INPUT: Nilai komponen (dari contoh user)
  final nilaiKomponen = <String, double>{
    'aktivitas': 87.5,
    'proyek': 87.5,
    'kuis': 87.5,
    'tugas': 87.5,
    'uts': 60.0,
    'uas': 90.0,
  };

  // INPUT: Bobot Sub-CPMK untuk komponen (dari RPS)
  final subCpmkBobotMap = <String, Map<String, double>>{
    '276': {'aktivitas': 6, 'proyek': 0, 'kuis': 0, 'tugas': 2.5, 'uts': 6, 'uas': 0},
    '277': {'aktivitas': 0, 'proyek': 5, 'kuis': 0, 'tugas': 0, 'uts': 6, 'uas': 0},
    '278': {'aktivitas': 0, 'proyek': 0, 'kuis': 7, 'tugas': 5, 'uts': 7, 'uas': 0},
    '279': {'aktivitas': 0, 'proyek': 5, 'kuis': 0, 'tugas': 0, 'uts': 6, 'uas': 0},
    '280': {'aktivitas': 0, 'proyek': 5, 'kuis': 3, 'tugas': 2.5, 'uts': 0, 'uas': 8},
    '281': {'aktivitas': 0, 'proyek': 5, 'kuis': 0, 'tugas': 0, 'uts': 0, 'uas': 9},
    '282': {'aktivitas': 4, 'proyek': 0, 'kuis': 0, 'tugas': 0, 'uts': 0, 'uas': 8},
  };

  // INPUT: Bobot CPMK untuk Sub-CPMK (TOTAL KOMPONEN dari RPS)
  final cpmkSubCpmkMap = <String, Map<String, double>>{
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

  print('📥 INPUT NILAI KOMPONEN:');
  nilaiKomponen.forEach((k, v) {
    print('   $k: $v');
  });

  print('\n🎯 BOBOT SUB-CPMK (dari RPS):');
  subCpmkBobotMap.forEach((subId, bobotMap) {
    final total = bobotMap.values.fold<double>(0, (a, b) => a + b);
    print('   Sub-CPMK $subId: (TOTAL = $total)');
    bobotMap.forEach((komponen, bobot) {
      if (bobot > 0) {
        print('      - $komponen: $bobot');
      }
    });
  });

  print('\n🔗 CPMK ← SUB-CPMK MAPPING:');
  cpmkSubCpmkMap.forEach((cpmkId, subCpmkMap) {
    final total = subCpmkMap.values.fold<double>(0, (a, b) => a + b);
    print('   CPMK $cpmkId: (TOTAL = $total)');
    subCpmkMap.forEach((subId, bobot) {
      print('      - Sub-CPMK $subId: $bobot');
    });
  });

  // Test dengan printDebug = true untuk melihat formula breakdown
  print('\n' + '='*80);
  print('🔍 CALCULATION WITH DEBUG OUTPUT');
  print('='*80 + '\n');

  try {
    final result = helper.calculateOBEComplete(
      nilaiKomponen: nilaiKomponen,
      subCpmkBobotMap: subCpmkBobotMap,
      cpmkSubCpmkMap: cpmkSubCpmkMap,
      printDebug: true, // ✅ Enable formula breakdown
    );

    if (result['status'] == 'success') {
      print('\n' + '='*80);
      print('✅ CALCULATION SUCCESS');
      print('='*80);

      final subCpmkValues = (result['sub_cpmk'] as Map<String, dynamic>).cast<String, double>();
      final cpmkValues = (result['cpmk'] as Map<String, dynamic>).cast<String, double>();

      print('\n📊 FINAL HASIL SUB-CPMK:');
      subCpmkValues.forEach((id, nilai) {
        print('   Sub-CPMK $id: ${nilai.toStringAsFixed(2)}');
      });

      print('\n📊 FINAL HASIL CPMK:');
      cpmkValues.forEach((id, nilai) {
        print('   CPMK $id: ${nilai.toStringAsFixed(2)}');
      });

      // Verify dengan expected values
      print('\n' + '='*80);
      print('🔬 VERIFICATION');
      print('='*80);
      
      final expected = <String, double>{
        '276': 76.12,
        '277': 72.50,
        '278': 77.37,
        '279': 72.50,
        '280': 88.58,
        '281': 89.11,
        '282': 89.17,
      };

      bool allMatch = true;
      expected.forEach((subId, expectedVal) {
        final actualVal = subCpmkValues[subId] ?? 0;
        final match = (actualVal - expectedVal).abs() < 0.1;
        final status = match ? '✅' : '❌';
        print('$status Sub-CPMK $subId: expected=${expectedVal.toStringAsFixed(2)}, actual=${actualVal.toStringAsFixed(2)}');
        if (!match) allMatch = false;
      });

      final expectedCpmk4 = 81.25;
      final actualCpmk4 = cpmkValues['4'] ?? 0;
      final cpmkMatch = (actualCpmk4 - expectedCpmk4).abs() < 0.1;
      final cpmkStatus = cpmkMatch ? '✅' : '❌';
      print('$cpmkStatus CPMK 4: expected=${expectedCpmk4.toStringAsFixed(2)}, actual=${actualCpmk4.toStringAsFixed(2)}');
      
      if (!cpmkMatch) allMatch = false;

      print('\n' + '='*80);
      if (allMatch) {
        print('🎉 ALL TESTS PASSED!');
      } else {
        print('⚠️ SOME TESTS FAILED - CHECK VALUES');
      }
      print('='*80);
    } else {
      print('❌ Calculation failed: ${result['message']}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
