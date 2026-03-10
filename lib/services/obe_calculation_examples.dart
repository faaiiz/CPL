import 'obe_calculation_helper.dart';

/// 📚 OBE Calculation Examples dan Helper Functions
/// File ini menunjukkan cara menggunakan Academic OBE Calculation Engine
/// dengan berbagai skenario

class OBECalculationExamples {
  
  /// 📝 Contoh 1: Perhitungan Sub-CPMK & CPMK untuk Mata Kuliah Kalkulus & Vektor
  /// Mahasiswa: Vira Indra Asih & Vita juwita Sinurat
  static void exampleCalculusVector() {
    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║  CONTOH 1: Mata Kuliah Kalkulus & Vektor                   ║');
    print('╚════════════════════════════════════════════════════════════╝\n');

    final engine = OBECalculationHelper();

    // Data nilai komponen
    const mahasiswaData = {
      'Vira Indra Asih': [85.5, 85.5, 85.5, 85.5, 65.0, 75.0],
      'Vita juwita Sinurat': [87.5, 87.5, 87.5, 87.5, 60.0, 90.0],
    };

    // Matriks bobot Sub-CPMK
    // Komponen: [Aktivitas, Hasil Proyek, Kuis, Tugas, UTS, UAS]
    final bobotMatrix = {
      1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],   // Sub1: total=15
      2: [0.0, 5.0, 5.0, 0.0, 5.0, 0.0],   // Sub2: total=15
      3: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],   // Sub3: total=15
      4: [0.0, 0.0, 5.0, 0.0, 0.0, 4.0],   // Sub4: total=9
      5: [5.0, 0.0, 0.0, 5.0, 0.0, 4.0],   // Sub5: total=14
      6: [0.0, 5.0, 5.0, 0.0, 0.0, 4.0],   // Sub6: total=14
      7: [5.0, 0.0, 5.0, 5.0, 0.0, 3.0],   // Sub7: total=18
      // Total bobot keseluruhan = 100 ✅
    };

    // Bobot Sub-CPMK ke CPMK (diasumsikan 1 CPMK)
    final subCpmkBobot = {
      1: {
        1: 14.28,
        2: 14.28,
        3: 14.28,
        4: 12.87,
        5: 14.29,
        6: 14.29,
        7: 15.71,
        // Total = 100 ✅
      }
    };

    // Hitung untuk setiap mahasiswa
    mahasiswaData.forEach((namaMahasiswa, nilaiKomponen) {
      print('📊 Mahasiswa: $namaMahasiswa');
      print('   Nilai Komponen: [Aktivitas, Hasil Proyek, Kuis, Tugas, UTS, UAS]');
      print('   Nilai: $nilaiKomponen\n');

      try {
        // 1. Hitung Sub-CPMK
        final subCpmkValues = engine.calculateSubCPMKWithMatrix(
          nilaiKomponen: nilaiKomponen.cast<double>(),
          bobotMatrix: bobotMatrix,
        );

        print('   Sub-CPMK Values:');
        subCpmkValues.forEach((id, nilai) {
          print('      Sub$id: $nilai');
        });

        // 2. Hitung CPMK
        final cpmkValues = engine.calculateCPMKFromSubCPMK(
          subCpmkValues: subCpmkValues,
          subCpmkBobotToCpmk: subCpmkBobot,
        );

        print('\n   CPMK Values:');
        cpmkValues.forEach((id, nilai) {
          print('      CPMK$id: $nilai');
        });

        print('   ✅ Perhitungan Selesai\n');
      } catch (e) {
        print('   ❌ Error: $e\n');
      }
    });
  }

  /// 📝 Contoh 2: Perhitungan dengan Bobot Tidak Sesuai (Demonstrasi Error)
  static void exampleErrorHandling() {
    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║  CONTOH 2: Error Handling - Data Tidak Valid               ║');
    print('╚════════════════════════════════════════════════════════════╝\n');

    final engine = OBECalculationHelper();
    final nilaiKomponen = [85.5, 85.5, 85.5, 85.5, 65.0, 75.0];

    // ❌ Case 1: Jumlah bobot tidak sesuai dengan nilai komponen
    print('❌ Case 1: Bobot mismatch dengan nilai komponen');
    try {
      engine.calculateSubCPMKWithMatrix(
        nilaiKomponen: nilaiKomponen,
        bobotMatrix: {
          1: [5.0, 0.0, 0.0], // 3 bobot, tapi 6 nilai
        },
      );
    } catch (e) {
      print('   Error caught: $e\n');
    }

    // ❌ Case 2: Total bobot Sub-CPMK < 100
    print('❌ Case 2: Total bobot Sub-CPMK ≠ 100');
    final subCpmkValues = {
      1: 78.67,
      2: 78.67,
    };
    final invalidBobot = {
      1: {
        1: 50.0,
        2: 40.0, // Total = 90 (not 100)
      }
    };
    try {
      engine.calculateCPMKFromSubCPMK(
        subCpmkValues: subCpmkValues,
        subCpmkBobotToCpmk: invalidBobot,
      );
    } catch (e) {
      print('   Error caught: $e\n');
    }

    // ❌ Case 3: Semua bobot = 0
    print('❌ Case 3: Semua bobot = 0');
    try {
      engine.calculateSubCPMKWithMatrix(
        nilaiKomponen: nilaiKomponen,
        bobotMatrix: {
          1: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        },
      );
    } catch (e) {
      print('   Error caught: $e\n');
    }
  }

  /// 📝 Contoh 3: Custom Mata Kuliah dengan 4 Sub-CPMK
  static void exampleCustomMataKuliah() {
    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║  CONTOH 3: Mata Kuliah Custom dengan 4 Sub-CPMK            ║');
    print('╚════════════════════════════════════════════════════════════╝\n');

    final engine = OBECalculationHelper();

    // Studi kasus: Mata Kuliah Pemrograman Dasar
    // Komponen: [Tugas, Kuis, Praktek, UAS]
    const nilaiKomponen = [90.0, 85.0, 92.0, 88.0];

    final bobotMatrix = {
      1: [5.0, 0.0, 15.0, 5.0],     // Sub1: Konsep dasar, total=25
      2: [10.0, 5.0, 10.0, 0.0],    // Sub2: Variabel & tipe data, total=25
      3: [0.0, 10.0, 15.0, 0.0],    // Sub3: Control flow, total=25
      4: [10.0, 10.0, 0.0, 15.0],   // Sub4: OOP basics, total=35
      // Total bobot = 110 ???
      // ⚠️ Seharusnya = 100, ada error di setup
    };

    print('📊 Mata Kuliah: Pemrograman Dasar');
    print('   Komponen: [Tugas, Kuis, Praktek, UAS]');
    print('   Nilai: $nilaiKomponen\n');

    try {
      engine.calculateSubCPMKWithMatrix(
        nilaiKomponen: nilaiKomponen,
        bobotMatrix: bobotMatrix,
      );
    } catch (e) {
      print('❌ Terjadi error (expected - demonstrasi total bobot)');
      print('   Error: $e\n');
    }

    // Perbaiki dengan total bobot yang benar
    final bobotMatrixFixed = {
      1: [4.0, 0.0, 12.0, 4.0],     // Sub1: total=20
      2: [10.0, 5.0, 10.0, 0.0],    // Sub2: total=25
      3: [0.0, 10.0, 15.0, 0.0],    // Sub3: total=25
      4: [6.0, 10.0, 0.0, 14.0],    // Sub4: total=30
      // Total = 100 ✅
    };

    print('✅ Perhitungan dengan Total Bobot = 100:');
    try {
      final result = engine.calculateSubCPMKWithMatrix(
        nilaiKomponen: nilaiKomponen,
        bobotMatrix: bobotMatrixFixed,
      );

      print('   Sub-CPMK Values:');
      result.forEach((id, nilai) {
        print('      Sub$id: $nilai');
      });
      print('   ✅ Perhitungan Selesai\n');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }

  /// 📝 Contoh 4: Komponen dengan Bobot = 0 (Tidak Dihitung)
  static void exampleZeroWeightComponent() {
    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║  CONTOH 4: Komponen dengan Bobot = 0 (Tidak Dihitung)      ║');
    print('╚════════════════════════════════════════════════════════════╝\n');

    final engine = OBECalculationHelper();

    const nilaiKomponen = [100.0, 50.0, 75.0, 90.0, 80.0, 85.0];
    // Komponen-komponen:
    // 0: Aktivitas (100)
    // 1: Hasil Proyek (50) - BOBOT 0, diabaikan
    // 2: Kuis (75)
    // 3: Tugas (90)
    // 4: UTS (80)
    // 5: UAS (85)

    final bobotMatrix = {
      1: [10.0, 0.0, 5.0, 0.0, 0.0, 5.0], // Hanya Aktivitas(10), Kuis(5), UAS(5)
    };

    print('📊 Perhitungan Sub-CPMK dengan Selective Components');
    print('   Nilai: [Aktivitas(100), Proyek(50), Kuis(75), Tugas(90), UTS(80), UAS(85)]');
    print('   Bobot: [10, 0, 5, 0, 0, 5]');
    print('   Hanya komponen dengan bobot > 0 yang digunakan\n');

    try {
      final result = engine.calculateSubCPMKWithMatrix(
        nilaiKomponen: nilaiKomponen,
        bobotMatrix: bobotMatrix,
      );

      print('   Perhitungan:');
      print('      Total Bobot = 10 + 5 + 5 = 20');
      print('      SubCPMK = (100×10 + 75×5 + 85×5) / 20');
      print('              = (1000 + 375 + 425) / 20');
      print('              = 1800 / 20');
      print('              = 90.00\n');

      print('   Hasil:');
      result.forEach((id, nilai) {
        print('      Sub$id: $nilai ✅');
      });
      print('');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }

  /// 📝 Contoh 5: Precision & Rounding
  static void examplePrecisionAndRounding() {
    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║  CONTOH 5: Precision & Rounding ke 2 Desimal               ║');
    print('╚════════════════════════════════════════════════════════════╝\n');

    final engine = OBECalculationHelper();

    const nilaiKomponen = [85.333333, 85.666666, 85.777777, 85.888888, 65.111111, 75.222222];

    final bobotMatrix = {
      1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],
      2: [0.0, 5.0, 5.0, 0.0, 5.0, 0.0],
      3: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],
    };

    print('📊 Input dengan presisi tinggi:');
    nilaiKomponen.asMap().forEach((i, nilai) {
      print('   Komponen $i: $nilai');
    });

    try {
      final result = engine.calculateSubCPMKWithMatrix(
        nilaiKomponen: nilaiKomponen,
        bobotMatrix: bobotMatrix,
      );

      print('\n✅ Output (dibulatkan ke 2 desimal):');
      result.forEach((id, nilai) {
        print('   Sub$id: $nilai');
      });
      print('');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }

  /// 📝 Contoh 6: Multiple CPMK dari Multiple Sub-CPMK
  static void exampleMultipleCPMK() {
    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║  CONTOH 6: Multiple CPMK dari Multiple Sub-CPMK            ║');
    print('╚════════════════════════════════════════════════════════════╝\n');

    final engine = OBECalculationHelper();

    final subCpmkValues = {
      1: 85.0,
      2: 82.0,
      3: 88.0,
      4: 90.0,
    };

    // Misalnya ada 2 CPMK dengan distribusi Sub-CPMK yang berbeda
    final subCpmkBobot = {
      1: {
        // CPMK 1: Kombinasi Sub 1, 2, 3, 4
        1: 25.0,
        2: 25.0,
        3: 25.0,
        4: 25.0,
        // Total = 100 ✅
      },
      2: {
        // CPMK 2: Fokus pada Sub 3, 4
        1: 0.0,
        2: 0.0,
        3: 50.0,
        4: 50.0,
        // Total = 100 ✅
      },
    };

    print('📊 Sub-CPMK Values:');
    subCpmkValues.forEach((id, nilai) {
      print('   Sub$id: $nilai');
    });

    print('\n📊 Bobot Sub-CPMK ke Multiple CPMK:');
    subCpmkBobot.forEach((cpmkId, bobot) {
      print('   CPMK$cpmkId:');
      bobot.forEach((subId, weight) {
        if (weight > 0) {
          print('      Sub$subId: $weight%');
        }
      });
    });

    try {
      final result = engine.calculateCPMKFromSubCPMK(
        subCpmkValues: subCpmkValues,
        subCpmkBobotToCpmk: subCpmkBobot,
      );

      print('\n✅ Hasil CPMK:');
      result.forEach((id, nilai) {
        print('   CPMK$id: $nilai');
      });
      print('');
    } catch (e) {
      print('   ❌ Error: $e\n');
    }
  }
}

/// Helper function untuk menjalankan semua contoh
void runAllExamples() {
  OBECalculationExamples.exampleCalculusVector();
  OBECalculationExamples.exampleErrorHandling();
  OBECalculationExamples.exampleCustomMataKuliah();
  OBECalculationExamples.exampleZeroWeightComponent();
  OBECalculationExamples.examplePrecisionAndRounding();
  OBECalculationExamples.exampleMultipleCPMK();

  print('\n╔════════════════════════════════════════════════════════════╗');
  print('║  ✅ SEMUA CONTOH SELESAI                                    ║');
  print('╚════════════════════════════════════════════════════════════╝\n');
}
