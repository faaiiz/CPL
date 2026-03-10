import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2C3E50);
  static const Color secondary = Color(0xFF3498DB);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color danger = Color(0xFFE74C3C);
  static const Color light = Color(0xFFECF0F1);
  static const Color dark = Color(0xFF2C3E50);
  static const Color background = Color(0xFFF5F7FA);
  static const Color text = Color(0xFF2C3E50);
  static const Color subtleText = Color(0xFF7F8C8D);
  static const Color white = Color(0xFFFFFFFF);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 16;
}

class AppStrings {
  // Authentication
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String username = 'Username';
  static const String password = 'Password';
  static const String forgotPassword = 'Lupa Password?';
  static const String invalidCredentials = 'Username atau password salah';
  static const String loginSuccess = 'Login berhasil';

  // Common
  static const String save = 'Simpan';
  static const String cancel = 'Batal';
  static const String edit = 'Edit';
  static const String delete = 'Hapus';
  static const String add = 'Tambah';
  static const String back = 'Kembali';
  static const String close = 'Tutup';
  static const String search = 'Cari';
  static const String loading = 'Loading...';

  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String adminDashboard = 'Dashboard Admin';
  static const String mahasiswaDashboard = 'Dashboard Mahasiswa';

  // Mahasiswa
  static const String mahasiswa = 'Mahasiswa';
  static const String nim = 'NIM';
  static const String nama = 'Nama';
  static const String email = 'Email';
  static const String nomorHp = 'Nomor HP';
  static const String alamat = 'Alamat';
  static const String tahunMasuk = 'Tahun Masuk';
  static const String status = 'Status';

  // Matakuliah
  static const String matakuliah = 'Matakuliah';
  static const String kode = 'Kode';
  static const String sks = 'SKS';
  static const String semester = 'Semester';
  static const String dosen = 'Dosen';

  // Nilai
  static const String nilai = 'Nilai';
  static const String grade = 'Grade';
  static const String gradeHuruf = 'Grade Huruf';
  static const String nilaiNumerik = 'Nilai Numerik';
  static const String tahunAjaran = 'Tahun Ajaran';
  static const String inputNilai = 'Input Nilai';
  static const String editNilai = 'Edit Nilai';
  static const String daftarNilai = 'Daftar Nilai';

  // CPL
  static const String cpl = 'CPL (Capaian Pembelajaran Lulusan)';
  static const String ipk = 'IPK';
  static const String totalSku = 'Total SKU';
  static const String rataNilai = 'Rata-rata Nilai';
  static const String hitungCPL = 'Hitung CPL';
  static const String laporanCPL = 'Laporan CPL';
  static const String exportCPL = 'Export CPL';

  // RPS
  static const String rps = 'RPS (Rencana Pembelajaran Semester)';
  static const String uploadRPS = 'Upload RPS';
  static const String cplMappings = 'CPL Mappings';

  // Excel
  static const String uploadExcel = 'Upload Excel';
  static const String importNilai = 'Import Nilai';
  static const String importMahasiswa = 'Import Mahasiswa';
  static const String importSuccess = 'Import berhasil';
  static const String importFailed = 'Import gagal';

  // Messages
  static const String successSaved = 'Data berhasil disimpan';
  static const String successDeleted = 'Data berhasil dihapus';
  static const String successUpdated = 'Data berhasil diperbarui';
  static const String errorOccurred = 'Terjadi kesalahan';
  static const String confirmDelete = 'Apakah Anda yakin ingin menghapus?';
  static const String noData = 'Tidak ada data';
}

class AppConstants {
  // Grades
  static const List<String> grades = ['A', 'B', 'C', 'D', 'E'];
  
  static const Map<String, double> gradeValues = {
    'A': 4.0,
    'B': 3.0,
    'C': 2.0,
    'D': 1.0,
    'E': 0.0,
  };

  // Status Mahasiswa
  static const List<String> statusMahasiswa = ['aktif', 'lulus', 'cuti', 'drop'];

  // Semesters
  static const List<String> semesters = [
    '1', '2', '3', '4', '5', '6', '7', '8'
  ];

  // CPL Status
  static const List<String> cplStatus = [
    'belum_lulus',
    'memenuhi_cpl',
    'tidak_memenuhi_cpl'
  ];

  // Minimum values for CPL
  static const double minIPK = 2.0;
  static const double minRataNilai = 2.0;
  static const int minTotalSKU = 144;
}
