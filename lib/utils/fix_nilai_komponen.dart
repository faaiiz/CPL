import '../services/database_helper.dart';

/// Utility untuk diagnosa dan fix nilai_komponen yang hilang
class FixNilaiKomponenHelper {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// [DIAGNOSA] Cek data untuk mahasiswa tertentu
  Future<void> diagnosticNilaiKomponen(int mahasiswaId) async {
    print('\n🔍 ===== DIAGNOSTIC HASIL NILAI KOMPONEN =====');
    print('Mahasiswa ID: $mahasiswaId\n');

    try {
      // Get mahasiswa
      final allMahasiswa = await _dbHelper.getAllMahasiswa();
      final mahasiswa = allMahasiswa.firstWhere(
        (m) => m.id == mahasiswaId,
        orElse: () => throw Exception('Mahasiswa dengan ID $mahasiswaId tidak ditemukan'),
      );
      print('✅ Mahasiswa: ${mahasiswa.nama} (NIM: ${mahasiswa.nim})');

      // Get semua nilai untuk mahasiswa ini
      final nilaiList = await _dbHelper.getNilaiByMahasiswa(mahasiswaId);
      print('📚 Total nilai: ${nilaiList.length}');

      if (nilaiList.isEmpty) {
        print('  ⚠️ Tidak ada nilai apapun untuk mahasiswa ini\n');
        return;
      }

      // Untuk setiap nilai, cek apakah ada nilai_komponen
      for (final nilai in nilaiList) {
        final matakuliah =
            await _dbHelper.getMatakuliahById(nilai.matakuliahId);
        final matakuliahNama = matakuliah?.nama ?? 'Unknown';

        // Cek nilai_komponen
        final nilaiKomponen = await _dbHelper.getNilaiKomponen(
          mahasiswaId: mahasiswaId,
          matakuliahId: nilai.matakuliahId,
          tahunAjaran: nilai.tahunAjaran,
        );

        if (nilaiKomponen == null) {
          print('\n❌ MISSING: $matakuliahNama (Tahun: ${nilai.tahunAjaran})');
          print('   - Nilai Akhir: ${nilai.nilaiNumerik}');
          print('   - Grade: ${nilai.gradeHuruf}');
          print('   ⚠️ NILAI_KOMPONEN TIDAK ADA DI DATABASE');
        } else {
          print('\n✅ OK: $matakuliahNama (Tahun: ${nilai.tahunAjaran})');
          print('   - Nilai Akhir: ${nilai.nilaiNumerik}');
          print('   - Komponennya:');
          print('     • Aktivitas: ${nilaiKomponen['nilai_aktivitas']}');
          print('     • Proyek: ${nilaiKomponen['nilai_proyek']}');
          print('     • Kuis: ${nilaiKomponen['nilai_kuis']}');
          print('     • Tugas: ${nilaiKomponen['nilai_tugas']}');
          print('     • UTS: ${nilaiKomponen['nilai_uts']}');
          print('     • UAS: ${nilaiKomponen['nilai_uas']}');
        }
      }

      print('\n========================================\n');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  /// [FIX] Auto-populate nilai_komponen berdasarkan proporsi dari nil akhir
  /// Jika nilai akhir = 70, maka bagi proporsi ke 6 komponen dengan distribusi standard
  Future<Map<String, dynamic>> populateNilaiKomponenFromNilaiAkhir(
    int mahasiswaId,
    int matakuliahId,
    int tahunAjaran, {
    bool forceOverwrite = false,
  }) async {
    try {
      // Cek apakah nilai_komponen sudah ada
      final existingNilaiKomponen = await _dbHelper.getNilaiKomponen(
        mahasiswaId: mahasiswaId,
        matakuliahId: matakuliahId,
        tahunAjaran: tahunAjaran,
      );

      if (existingNilaiKomponen != null && !forceOverwrite) {
        return {
          'success': false,
          'message': 'Nilai komponen sudah ada. Gunakan forceOverwrite=true untuk overwrite.',
        };
      }

      // Get nilai akhir
      final nilaiList = await _dbHelper.getNilaiByMahasiswa(mahasiswaId);
      final nilai = nilaiList.firstWhere(
        (n) =>
            n.matakuliahId == matakuliahId && n.tahunAjaran == tahunAjaran,
        orElse: () => throw Exception(
            'Nilai tidak ditemukan untuk mahasiswa $mahasiswaId, MK $matakuliahId'),
      );

      // Distribusi proporsi standard untuk 6 komponen
      // Proporsi: aktivitas=15%, proyek=15%, kuis=15%, tugas=15%, UTS=20%, UAS=20%
      final nilaiAkhir = nilai.nilaiNumerik;
      final aktivitas = nilaiAkhir * 0.15;
      final proyek = nilaiAkhir * 0.15;
      final kuis = nilaiAkhir * 0.15;
      final tugas = nilaiAkhir * 0.15;
      final uts = nilaiAkhir * 0.20;
      final uas = nilaiAkhir * 0.20;

      // Insert atau update
      if (existingNilaiKomponen == null) {
        await _dbHelper.insertNilaiKomponen(
          mahasiswaId: mahasiswaId,
          matakuliahId: matakuliahId,
          nilaiAktivitas: aktivitas,
          nilaiProyek: proyek,
          nilaiKuis: kuis,
          nilaiTugas: tugas,
          nilaiUTS: uts,
          nilaiUAS: uas,
          tahunAjaran: tahunAjaran,
        );
      } else {
        await _dbHelper.updateNilaiKomponen(
          mahasiswaId: mahasiswaId,
          matakuliahId: matakuliahId,
          tahunAjaran: tahunAjaran,
          nilaiAktivitas: aktivitas,
          nilaiProyek: proyek,
          nilaiKuis: kuis,
          nilaiTugas: tugas,
          nilaiUTS: uts,
          nilaiUAS: uas,
        );
      }

      return {
        'success': true,
        'message': 'Nilai komponen berhasil di-populate',
        'data': {
          'nilaiAkhir': nilaiAkhir,
          'aktivitas': aktivitas,
          'proyek': proyek,
          'kuis': kuis,
          'tugas': tugas,
          'uts': uts,
          'uas': uas,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  /// [BATCH FIX] Auto-populate semua nilai_komponen yang hilang untuk satu mahasiswa
  Future<Map<String, dynamic>> fixAllMissingNilaiKomponenForMahasiswa(
    int mahasiswaId,
  ) async {
    print('\n🔧 ===== BATCH FIX NILAI KOMPONEN =====');
    print('Mahasiswa ID: $mahasiswaId\n');

    try {
      final results = {
        'fixed': 0,
        'skipped': 0,
        'failed': 0,
        'errors': <String>[],
      } as Map<String, dynamic>;

      // Get semua nilai untuk mahasiswa
      final nilaiList = await _dbHelper.getNilaiByMahasiswa(mahasiswaId);

      for (final nilai in nilaiList) {
        // Cek apakah nilai_komponen sudah ada
        final nilaiKomponen = await _dbHelper.getNilaiKomponen(
          mahasiswaId: mahasiswaId,
          matakuliahId: nilai.matakuliahId,
          tahunAjaran: nilai.tahunAjaran,
        );

        if (nilaiKomponen != null) {
          print('⏭️  Skip: MK ${nilai.matakuliahId} sudah ada nilai komponen');
          results['skipped'] = (results['skipped'] as int) + 1;
          continue;
        }

        // Populate nilai_komponen
        final result = await populateNilaiKomponenFromNilaiAkhir(
          mahasiswaId,
          nilai.matakuliahId,
          nilai.tahunAjaran,
        );

        if (result['success'] == true) {
          print('✅ Fixed: MK ${nilai.matakuliahId} - ${result['data']}');
          results['fixed'] = (results['fixed'] as int) + 1;
        } else {
          print('❌ Failed: MK ${nilai.matakuliahId} - ${result['message']}');
          results['failed'] = (results['failed'] as int) + 1;
          (results['errors'] as List<String>).add(result['message'] as String);
        }
      }

      print('\n📊 SUMMARY:');
      print('  ✅ Fixed: ${results['fixed']}');
      print('  ⏭️  Skipped: ${results['skipped']}');
      print('  ❌ Failed: ${results['failed']}');

      return results;
    } catch (e) {
      print('❌ Error: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}
