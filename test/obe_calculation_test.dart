import 'package:flutter_test/flutter_test.dart';
import '../lib/services/obe_calculation_helper.dart';

void main() {
  group('Academic OBE Calculation Engine Tests', () {
    late OBECalculationHelper calculationEngine;

    setUp(() {
      calculationEngine = OBECalculationHelper();
    });

    test('✅ Verify Vira Indra Asih - Calculus & Vector Calculation', () {
      // Data
      const nilaiKomponen = [85.5, 85.5, 85.5, 85.5, 65.0, 75.0];
      // Komponen: [Aktivitas, Hasil Proyek, Kuis, Tugas, UTS, UAS]

      // Bobot Matrix untuk 7 Sub-CPMK
      // Urutan: [Aktivitas, Hasil Proyek, Kuis, Tugas, UTS, UAS]
      final bobotMatrix = {
        1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0], // Sub1, total=15
        2: [0.0, 5.0, 5.0, 0.0, 5.0, 0.0], // Sub2, total=15
        3: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0], // Sub3, total=15
        4: [0.0, 0.0, 5.0, 0.0, 0.0, 4.0], // Sub4, total=9
        5: [5.0, 0.0, 0.0, 5.0, 0.0, 4.0], // Sub5, total=14
        6: [0.0, 5.0, 5.0, 0.0, 0.0, 4.0], // Sub6, total=14
        7: [5.0, 0.0, 5.0, 5.0, 0.0, 3.0], // Sub7, total=18
      };

      // Expected Sub-CPMK values (corrected from OBE spec documentation)
      final expectedSubCpmk = {
        1: 78.67,
        2: 78.67,
        3: 78.67,
        4: 80.83,
        5: 82.50,
        6: 82.50,
        7: 83.75, // Corrected: 1507.5 / 18 = 83.75 (not 83.92)
      };

      // Calculate
      final subCpmkResults =
          calculationEngine.calculateSubCPMKWithMatrix(
        nilaiKomponen: nilaiKomponen,
        bobotMatrix: bobotMatrix,
      );

      // Verify Sub-CPMK
      subCpmkResults.forEach((subCpmkId, nilai) {
        expect(
          nilai,
          closeTo(expectedSubCpmk[subCpmkId]!, 0.01),
          reason: 'Sub-CPMK $subCpmkId should be ${expectedSubCpmk[subCpmkId]}',
        );
      });

      print('✅ Vira Indra Asih - Sub-CPMK Calculations Verified');
      subCpmkResults.forEach((id, nilai) {
        print('   Sub$id: $nilai (expected: ${expectedSubCpmk[id]})');
      });
    });

    test('✅ Verify Vita juwita Sinurat - Calculus & Vector Calculation', () {
      // Data
      const nilaiKomponen = [87.5, 87.5, 87.5, 87.5, 60.0, 90.0];
      // Komponen: [Aktivitas, Hasil Proyek, Kuis, Tugas, UTS, UAS]

      // Bobot Matrix untuk 7 Sub-CPMK
      final bobotMatrix = {
        1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],
        2: [0.0, 5.0, 5.0, 0.0, 5.0, 0.0],
        3: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],
        4: [0.0, 0.0, 5.0, 0.0, 0.0, 4.0],
        5: [5.0, 0.0, 0.0, 5.0, 0.0, 4.0],
        6: [0.0, 5.0, 5.0, 0.0, 0.0, 4.0],
        7: [5.0, 0.0, 5.0, 5.0, 0.0, 3.0],
      };

      // Expected Sub-CPMK values
      final expectedSubCpmk = {
        1: 78.33,
        2: 78.33,
        3: 78.33,
        4: 88.61,
        5: 88.21,
        6: 88.21,
        7: 87.92,
      };

      // Calculate
      final subCpmkResults =
          calculationEngine.calculateSubCPMKWithMatrix(
        nilaiKomponen: nilaiKomponen,
        bobotMatrix: bobotMatrix,
      );

      // Verify Sub-CPMK
      subCpmkResults.forEach((subCpmkId, nilai) {
        expect(
          nilai,
          closeTo(expectedSubCpmk[subCpmkId]!, 0.01),
          reason: 'Sub-CPMK $subCpmkId should be ${expectedSubCpmk[subCpmkId]}',
        );
      });

      print('✅ Vita juwita Sinurat - Sub-CPMK Calculations Verified');
      subCpmkResults.forEach((id, nilai) {
        print('   Sub$id: $nilai (expected: ${expectedSubCpmk[id]})');
      });
    });

    test('✅ Test CPMK Calculation with 100% Total Weight', () {
      // Sub-CPMK values (from previous calculation)
      final subCpmkValues = {
        1: 78.67,
        2: 78.67,
        3: 78.67,
        4: 80.83,
        5: 82.50,
        6: 82.50,
        7: 83.92,
      };

      // Bobot Sub-CPMK to CPMK (assuming 1 CPMK with equal weight distribution)
      // Total harus = 100
      final subCpmkBobot = {
        1: {
          1: 14.28,
          2: 14.28,
          3: 14.28,
          4: 12.87,
          5: 14.29,
          6: 14.29,
          7: 15.71,
        }
      };

      // Calculate CPMK
      final cpmkResults = calculationEngine.calculateCPMKFromSubCPMK(
        subCpmkValues: subCpmkValues,
        subCpmkBobotToCpmk: subCpmkBobot,
      );

      // Expected CPMK ≈ 80.96 for Vira
      expect(cpmkResults[1], closeTo(80.96, 0.1));

      print('✅ CPMK Calculation Verified');
      print('   CPMK: ${cpmkResults[1]}');
    });

    test('❌ Should throw error if total bobot ≠ 100', () {
      final subCpmkValues = {
        1: 78.67,
        2: 78.67,
        3: 78.67,
        4: 80.83,
        5: 82.50,
        6: 82.50,
        7: 83.92,
      };

      // Invalid bobot - total = 99 (not 100)
      final invalidBobot = {
        1: {
          1: 14.28,
          2: 14.28,
          3: 14.28,
          4: 12.87,
          5: 14.29,
          6: 14.29,
          7: 15.50, // 15.50 instead of 15.71
        }
      };

      // Should throw exception
      expect(
        () => calculationEngine.calculateCPMKFromSubCPMK(
          subCpmkValues: subCpmkValues,
          subCpmkBobotToCpmk: invalidBobot,
        ),
        throwsException,
      );

      print('✅ Validation Error Test Passed - Invalid total weight detected');
    });

    test('❌ Should throw error if nilai komponen mismatch', () {
      final nilaiKomponen = [85.5, 85.5, 85.5]; // 3 components
      final bobotMatrix = {
        1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0], // 6 components
      };

      expect(
        () => calculationEngine.calculateSubCPMKWithMatrix(
          nilaiKomponen: nilaiKomponen,
          bobotMatrix: bobotMatrix,
        ),
        throwsException,
      );

      print('✅ Data Validation Test Passed - Bobot & Nilai mismatch detected');
    });

    test('❌ Should throw error if total bobot komponen = 0', () {
      final nilaiKomponen = [85.5, 85.5, 85.5, 85.5, 65.0, 75.0];
      final bobotMatrix = {
        1: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0], // All zeros
      };

      expect(
        () => calculationEngine.calculateSubCPMKWithMatrix(
          nilaiKomponen: nilaiKomponen,
          bobotMatrix: bobotMatrix,
        ),
        throwsException,
      );

      print('✅ Zero Weight Test Passed - Invalid bobot detected');
    });

    test('✅ Only components with bobot > 0 are used in calculation', () {
      const nilaiKomponen = [100.0, 50.0, 75.0, 90.0, 80.0, 85.0];

      final bobotMatrix = {
        1: [10.0, 0.0, 0.0, 5.0, 0.0, 5.0], // Only komponen 0, 3, 5 are used
      };

      final subCpmkResults =
          calculationEngine.calculateSubCPMKWithMatrix(
        nilaiKomponen: nilaiKomponen,
        bobotMatrix: bobotMatrix,
      );

      // Calculate expected:
      // (100 * 10 + 90 * 5 + 85 * 5) / (10 + 5 + 5)
      // = (1000 + 450 + 425) / 20
      // = 1875 / 20
      // = 93.75
      expect(subCpmkResults[1], closeTo(93.75, 0.01));

      print('✅ Selective Component Test Passed');
      print('   Sub-CPMK 1: ${subCpmkResults[1]} (expected: 93.75)');
    });

    test('✅ Rounding to 2 decimal places', () {
      const nilaiKomponen = [85.333333, 85.666666, 85.777777, 85.888888, 65.111111, 75.222222];
      final bobotMatrix = {
        1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],
      };

      final subCpmkResults =
          calculationEngine.calculateSubCPMKWithMatrix(
        nilaiKomponen: nilaiKomponen,
        bobotMatrix: bobotMatrix,
      );

      // Check that result has exactly 2 decimal places (as string)
      final resultString = subCpmkResults[1].toString();
      final decimalParts = resultString.split('.');
      expect(decimalParts.length, 2);
      expect(decimalParts[1].length, lessThanOrEqualTo(2));

      print('✅ Rounding Test Passed');
      print('   Sub-CPMK 1: ${subCpmkResults[1]}');
    });
  });

  group('Full Integration Tests', () {
    late OBECalculationHelper calculationEngine;

    setUp(() {
      calculationEngine = OBECalculationHelper();
    });

    test('✅ Full calculation Vira Indra Asih with CPMK', () {
      const nilaiKomponen = [85.5, 85.5, 85.5, 85.5, 65.0, 75.0];

      final bobotMatrix = {
        1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],
        2: [0.0, 5.0, 5.0, 0.0, 5.0, 0.0],
        3: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],
        4: [0.0, 0.0, 5.0, 0.0, 0.0, 4.0],
        5: [5.0, 0.0, 0.0, 5.0, 0.0, 4.0],
        6: [0.0, 5.0, 5.0, 0.0, 0.0, 4.0],
        7: [5.0, 0.0, 5.0, 5.0, 0.0, 3.0],
      };

      // Sub-CPMK weights to CPMK
      final subCpmkBobot = {
        1: {
          1: 14.28,
          2: 14.28,
          3: 14.28,
          4: 12.87,
          5: 14.29,
          6: 14.29,
          7: 15.71,
        }
      };

      final results = calculationEngine.calculateCPMKFull(
        nilaiKomponen: nilaiKomponen,
        bobotMatrix: bobotMatrix,
        subCpmkBobot: subCpmkBobot,
      );

      // Corrected: with Sub7 = 83.75 (not 83.92), CPMK = 80.84 (not 80.96)
      expect(results[1], closeTo(80.84, 0.01));

      print('✅ Full Integration Test Passed');
      print('   CPMK Vira: ${results[1]}');
    });

    test('✅ Test CPL Calculation from RPS Bobot Aggregation', () {
      // Simulating RPS minggu data aggregation by CPL ID
      // Example: 16 minggu dengan bobot distribusi ke CPL IDs
      
      // Aggregated CPL bobot from RPS minggu (simulated)
      // Assuming: minggu 1-4 → CPL 1&2, minggu 5-8 → CPL 2&3, minggu 9-16 → CPL 1&3
      final cplBobotRaw = {
        1: 20.0 + 20.0,  // minggu 1-4 (5%) + minggu 9-16 (15%) = 20% + 20% = ...
        2: 20.0 + 25.0,  // minggu 1-4 (5%) + minggu 5-8 (25%) = ...
        3: 25.0 + 20.0,  // minggu 5-8 (25%) + minggu 9-16 (15%) = ...
      };
      
      // Normalize to total = 100
      final totalRaw = cplBobotRaw.values.fold<double>(0.0, (a, b) => a + b);
      final cplBobotNormalized = <int, double>{};
      cplBobotRaw.forEach((cplId, bobot) {
        cplBobotNormalized[cplId] = (bobot / totalRaw) * 100.0;
      });
      
      // CPMK value
      const cpmkValue = 83.75;
      
      // Calculate CPL values
      final cplResults = <int, double>{};
      cplBobotNormalized.forEach((cplId, bobot) {
        cplResults[cplId] = (cpmkValue * bobot) / 100.0;
      });
      
      // Verify CPL calculation
      print('✅ CPL Calculation from RPS Bobot Aggregation');
      print('   Total raw bobot: $totalRaw');
      print('   CPL Bobot Normalized:');
      cplBobotNormalized.forEach((cplId, bobot) {
        print('     CPL$cplId: $bobot%');
      });
      print('   CPL Values (CPMK=$cpmkValue):');
      cplResults.forEach((cplId, nilai) {
        print('     CPL$cplId: $nilai');
      });
      
      // Verify that CPL values sum approximately to CPMK
      // (because each CPL gets a portion of CPMK based on bobot)
      final totalCpl = cplResults.values.fold<double>(0.0, (a, b) => a + b);
      expect(totalCpl, closeTo(cpmkValue, 0.01));
      
      // Verify individual CPL values
      expect(cplResults[1], isNotNull);
      expect(cplResults[2], isNotNull);
      expect(cplResults[3], isNotNull);
      expect(cplResults[1]! > 0, true);
      expect(cplResults[2]! > 0, true);
      expect(cplResults[3]! > 0, true);
    });
  });
}
