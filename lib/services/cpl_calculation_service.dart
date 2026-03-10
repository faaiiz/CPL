import '../models/nilai_model.dart';
import '../models/cpl_model.dart';
import '../models/matakuliah_model.dart';
import 'database_helper.dart';

class CPLCalculationService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Kondisi minimum untuk mencapai CPL
  static const double minIPK = 2.0; // IPK minimal 2.0
  static const double minRataNilai = 2.0; // Rata-rata nilai minimal
  static const int minTotalSKU = 144; // Total SKU minimal untuk lulus

  // Bobot untuk perhitungan CPL (contoh: 60% IPK, 40% Rata-rata nilai)
  static const double bobotIPK = 0.6;
  static const double bobotRataNilai = 0.4;

  // Hitung CPL untuk satu mahasiswa
  Future<CPL?> calculateCPLForMahasiswa(int mahasiswaId) async {
    try {
      // Get mahasiswa
      final mahasiswaList = await _dbHelper.getAllMahasiswa();
      final mahasiswa = mahasiswaList.firstWhere((m) => m.id == mahasiswaId);

      // Get semua nilai mahasiswa
      final nilaiList = await _dbHelper.getNilaiByMahasiswa(mahasiswaId);

      if (nilaiList.isEmpty) {
        return null; // Tidak ada nilai
      }

      // Get semua matakuliah
      final allMatakuliah = await _dbHelper.getAllMatakuliah();

      // Hitung total SKU dan rata-rata nilai
      double totalNilai = 0;
      int totalSKU = 0;

      for (var nilai in nilaiList) {
        final matakuliah = allMatakuliah
            .firstWhere((m) => m.id == nilai.matakuliahId);
        totalNilai += nilai.nilaiNumerik;
        totalSKU += matakuliah.sks;
      }

      final rataNilai = totalNilai / nilaiList.length;
      final ipk = _calculateIPK(nilaiList, allMatakuliah);

      // Tentukan status CPL
      String status = 'belum_lulus';
      if (totalSKU >= minTotalSKU && ipk >= minIPK && rataNilai >= minRataNilai) {
        status = 'memenuhi_cpl';
      } else {
        status = 'tidak_memenuhi_cpl';
      }

      final cpl = CPL(
        mahasiswaId: mahasiswaId,
        nipMahasiswa: mahasiswa.nim,
        namaMahasiswa: mahasiswa.nama,
        ipk: ipk,
        status: status,
        totalSku: totalSKU,
        rataNilai: rataNilai,
        tanggalHitung: DateTime.now(),
      );

      return cpl;
    } catch (e) {
      print('Error calculating CPL: $e');
      return null;
    }
  }

  // Hitung CPL untuk semua mahasiswa
  Future<List<CPL>> calculateCPLForAllMahasiswa() async {
    try {
      final allMahasiswa = await _dbHelper.getAllMahasiswa();
      final cplList = <CPL>[];

      for (var mahasiswa in allMahasiswa) {
        final cpl = await calculateCPLForMahasiswa(mahasiswa.id!);
        if (cpl != null) {
          cplList.add(cpl);
        }
      }

      // Save ke database
      for (var cpl in cplList) {
        // Check apakah sudah ada CPL untuk mahasiswa ini
        final existing = await _dbHelper.getCPLByMahasiswa(cpl.mahasiswaId);
        if (existing != null) {
          await _dbHelper.updateCPL(cpl.copyWith(id: existing.id));
        } else {
          await _dbHelper.insertCPL(cpl);
        }
      }

      return cplList;
    } catch (e) {
      print('Error calculating CPL for all: $e');
      return [];
    }
  }

  // Hitung IPK menggunakan weighted average dengan SKS
  double _calculateIPK(List<Nilai> nilaiList, List<Matakuliah> allMatakuliah) {
    double totalBobot = 0;
    double totalSKS = 0;

    for (var nilai in nilaiList) {
      final matakuliah = allMatakuliah
          .firstWhere((m) => m.id == nilai.matakuliahId);
      totalBobot += nilai.nilaiNumerik * matakuliah.sks;
      totalSKS += matakuliah.sks;
    }

    if (totalSKS == 0) return 0.0;
    return totalBobot / totalSKS;
  }

  // Hitung IPK alternatif (rata-rata sederhana)
  

  // Validasi apakah mahasiswa memenuhi CPL berdasarkan mapping RPS
  Future<bool> validateCPLWithRPS(int mahasiswaId) async {
    try {
      // Get nilai mahasiswa
      final nilaiList = await _dbHelper.getNilaiByMahasiswa(mahasiswaId);

      if (nilaiList.isEmpty) {
        return false;
      }

      // Check setiap matakuliah apakah ada RPS
      final allMatakuliah = await _dbHelper.getAllMatakuliah();
      bool allMatakuliahHasRPS = true;

      for (var nilai in nilaiList) {
        final matakuliah = allMatakuliah
            .firstWhere((m) => m.id == nilai.matakuliahId);
        final rps = await _dbHelper.getRPSByMatakuliah(matakuliah.id!);

        if (rps == null) {
          allMatakuliahHasRPS = false;
          break;
        }
      }

      return allMatakuliahHasRPS;
    } catch (e) {
      print('Error validating CPL with RPS: $e');
      return false;
    }
  }

  // Get CPL statistics
  Future<Map<String, dynamic>> getCPLStatistics() async {
    try {
      final allCPL = await _dbHelper.getAllCPL();

      if (allCPL.isEmpty) {
        return {
          'total_mahasiswa': 0,
          'memenuhi_cpl': 0,
          'tidak_memenuhi_cpl': 0,
          'belum_lulus': 0,
          'rata_rata_ipk': 0.0,
          'persentase_lulus': 0.0,
        };
      }

      final memenuhi = allCPL.where((c) => c.status == 'memenuhi_cpl').length;
      final tidakMemenuhi =
          allCPL.where((c) => c.status == 'tidak_memenuhi_cpl').length;
      final belumLulus = allCPL.where((c) => c.status == 'belum_lulus').length;
      final rataIPK = allCPL.fold<double>(0, (sum, c) => sum + c.ipk) / allCPL.length;
      final persentaseLulus = (memenuhi / allCPL.length) * 100;

      return {
        'total_mahasiswa': allCPL.length,
        'memenuhi_cpl': memenuhi,
        'tidak_memenuhi_cpl': tidakMemenuhi,
        'belum_lulus': belumLulus,
        'rata_rata_ipk': double.parse(rataIPK.toStringAsFixed(2)),
        'persentase_lulus':
            double.parse(persentaseLulus.toStringAsFixed(2)),
      };
    } catch (e) {
      print('Error getting CPL statistics: $e');
      return {};
    }
  }

  // Get CPL summary per program studi (dalam hal ini hanya ada 1)
  Future<List<Map<String, dynamic>>> getCPLSummary() async {
    try {
      final allCPL = await _dbHelper.getAllCPL();

      final summary = [
        {
          'program_studi': 'Program Studi Teknik',
          'total_mahasiswa': allCPL.length,
          'lulus': allCPL.where((c) => c.status == 'memenuhi_cpl').length,
          'tidak_lulus':
              allCPL.where((c) => c.status == 'tidak_memenuhi_cpl').length,
          'rata_rata_ipk': allCPL.isEmpty
              ? 0.0
              : allCPL.fold<double>(0, (sum, c) => sum + c.ipk) /
                  allCPL.length,
        },
      ];

      return summary;
    } catch (e) {
      print('Error getting CPL summary: $e');
      return [];
    }
  }

  // Export CPL data untuk laporan
  Future<List<Map<String, dynamic>>> getCPLForExport() async {
    try {
      final allCPL = await _dbHelper.getAllCPL();

      return allCPL
          .map((cpl) => {
                'NIP': cpl.nipMahasiswa,
                'Nama': cpl.namaMahasiswa,
                'IPK': double.parse(cpl.ipk.toStringAsFixed(2)),
                'Total SKU': cpl.totalSku,
                'Rata-rata Nilai':
                    double.parse(cpl.rataNilai.toStringAsFixed(2)),
                'Status': cpl.status == 'memenuhi_cpl' ? 'LULUS' : 'TIDAK LULUS',
              })
          .toList();
    } catch (e) {
      print('Error exporting CPL: $e');
      return [];
    }
  }
}
