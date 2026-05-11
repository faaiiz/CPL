import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:io';
import '../constants/app_constants.dart';
import '../services/excel_import_service.dart';
import '../services/excel_template_service.dart';
import '../services/database_helper.dart';

class NilaiBatchImportScreen extends StatefulWidget {
  const NilaiBatchImportScreen({super.key});

  @override
  State<NilaiBatchImportScreen> createState() =>
      _NilaiBatchImportScreenState();
}

class _NilaiBatchImportScreenState extends State<NilaiBatchImportScreen> {
  final _excelImportService = ExcelImportService();
  final _dbHelper = DatabaseHelper();

  // State variables
  List<String> _selectedFilePaths = [];
  List<String> _selectedFileNames = [];

  bool _isLoading = false;
  
  Map<String, dynamic>? _importResult;
  List<String> _importErrors = [];
  String _progressMessage = '';

  @override
  void initState() {
    super.initState();
    // No initialization needed - will read from Excel file
  }

  /// Validasi B1 (Kode Matakuliah), B2 (Nama Matakuliah), dan B3 (Tahun Ajaran) dari Excel file
  Future<Map<String, dynamic>> _validateExcelHeaders(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = excel_lib.Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;

      // Baca B1 - Kode Matakuliah
      // Baca B2 - Nama Matakuliah
      // Baca B3 - Tahun Ajaran
      String? kodeMatakuliahFromExcel;
      String? namaMatakuliahFromExcel;
      String? tahunAjaranFromExcel;

      // Cell B1 (row 0, col 1)
      if (sheet.rows.length > 0 && sheet.rows[0].length > 1) {
        final cellB1 = sheet.rows[0][1];
        kodeMatakuliahFromExcel = cellB1?.value?.toString().trim();
      }

      // Cell B2 (row 1, col 1)
      if (sheet.rows.length > 1 && sheet.rows[1].length > 1) {
        final cellB2 = sheet.rows[1][1];
        namaMatakuliahFromExcel = cellB2?.value?.toString().trim();
      }

      // Cell B3 (row 2, col 1)
      if (sheet.rows.length > 2 && sheet.rows[2].length > 1) {
        final cellB3 = sheet.rows[2][1];
        tahunAjaranFromExcel = cellB3?.value?.toString().trim();
      }

      // Validasi B1 - Kode Matakuliah
      if (kodeMatakuliahFromExcel == null || kodeMatakuliahFromExcel.isEmpty) {
        return {
          'error': 'Kode Matakuliah di B1 kosong',
          'type': 'matakuliah',
          'success': false,
        };
      }

      // 🎯 NEW: Cek apakah matakuliah dengan kode ini ada di database
      final matakuliah = await _dbHelper.getMatakuliahByKode(kodeMatakuliahFromExcel);
      if (matakuliah == null) {
        return {
          'error': '❌ ERROR: Kode Matakuliah "$kodeMatakuliahFromExcel" (B1) TIDAK DITEMUKAN di database.\n'
              'Gunakan kode matakuliah yang sudah terdaftar dalam sistem.',
          'type': 'matakuliah',
          'success': false,
        };
      }

      // 🎯 NEW: Validasi B2 - Nama Matakuliah (wajib ada di database)
      if (namaMatakuliahFromExcel == null || namaMatakuliahFromExcel.isEmpty) {
        return {
          'error': 'Nama Matakuliah di B2 kosong',
          'type': 'nama_matakuliah',
          'success': false,
        };
      }

      // 🎯 NEW: Cek apakah nama matakuliah ada di database
      // Coba cari dengan getMatakuliahByKode dulu (case B2 adalah nama yang sama dengan B1)
      // atau cari di semua matakuliah dengan flexible search
      final allMatakuliah = await _dbHelper.getAllMatakuliah();
      final searchTerm = namaMatakuliahFromExcel.toLowerCase();
      final namaMatakuliahExists = allMatakuliah.any((mk) {
        final kodeLower = mk.kode.toLowerCase();
        final namaLower = mk.nama.toLowerCase();
        return kodeLower.contains(searchTerm) || namaLower.contains(searchTerm);
      });

      if (!namaMatakuliahExists) {
        return {
          'error': '❌ ERROR: Nama/Kode Matakuliah "$namaMatakuliahFromExcel" (B2) TIDAK DITEMUKAN di database.\n'
              'Gunakan kode atau nama matakuliah yang sudah terdaftar dalam sistem.',
          'type': 'nama_matakuliah',
          'success': false,
        };
      }

      // Validasi B3 - Tahun Ajaran
      if (tahunAjaranFromExcel == null || tahunAjaranFromExcel.isEmpty) {
        return {
          'error': 'Tahun Ajaran di B3 kosong',
          'type': 'tahun',
          'success': false,
        };
      }

      // 🎯 NEW: Validasi format Tahun Ajaran - harus berupa angka 4 digit
      final tahunInt = int.tryParse(tahunAjaranFromExcel);
      if (tahunInt == null) {
        return {
          'error': '❌ ERROR: Tahun Ajaran di B3 harus berupa angka (contoh: 2024)',
          'type': 'tahun',
          'success': false,
        };
      }

      // 🎯 NEW: Validasi range tahun ajaran - wajar antara 2000-2100
      if (tahunInt < 2000 || tahunInt > 2100) {
        return {
          'error': '❌ ERROR: Tahun Ajaran di B3 harus dalam range 2000-2100. Nilai saat ini: $tahunInt',
          'type': 'tahun',
          'success': false,
        };
      }

      return {
        'success': true,
        'kodeMatakuliah': kodeMatakuliahFromExcel,
        'namaMatakuliah': namaMatakuliahFromExcel,
        'tahunAjaran': tahunAjaranFromExcel,
      };
    } catch (e) {
      return {
        'error': 'Error membaca file Excel: $e',
        'type': 'file',
        'success': false,
      };
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFilePaths = result.files.map((f) => f.path!).toList();
          _selectedFileNames = result.files.map((f) => f.name).toList();
          _importResult = null;
          _importErrors = [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFilePaths.removeAt(index);
      _selectedFileNames.removeAt(index);
    });
  }

  void _clearAllFiles() {
    setState(() {
      _selectedFilePaths = [];
      _selectedFileNames = [];
    });
  }

  Future<void> _downloadTemplate() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Membuat template...'),
          duration: Duration(seconds: 2),
        ),
      );

      final filePath = await ExcelTemplateService.generateNilaiImportTemplate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Template berhasil dibuat: $filePath'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Open the file
        try {
          await ExcelTemplateService.openFile(filePath);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Template disimpan di: $filePath'),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    if (_selectedFilePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file Excel terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _progressMessage = 'Processing ${_selectedFilePaths.length} file(s)...';
    });

    try {
      int totalImported = 0;
      int totalFailed = 0;
      List<String> allErrors = [];
      int successCount = 0;

      for (int i = 0; i < _selectedFilePaths.length; i++) {
        final filePath = _selectedFilePaths[i];
        final fileName = _selectedFileNames[i];

        setState(() {
          _progressMessage =
              'Processing file ${i + 1}/${_selectedFilePaths.length}: $fileName';
        });

        // 🔍 Validasi B1 dan B3
        final validationResult =
            await _validateExcelHeaders(filePath);

        if (!validationResult['success']) {
          allErrors.add('📄 ═══════════════════════════════════════');
          allErrors.add('   FILE: $fileName');
          allErrors.add('   Status: ❌ VALIDASI GAGAL');
          allErrors.add('═══════════════════════════════════════');
          allErrors.add('   ${validationResult['error']}');
          allErrors.add('');
          totalFailed++;
          continue;
        }

        // ✅ Validasi berhasil, lanjut dengan import
        try {
          final kodeMatakuliah = validationResult['kodeMatakuliah'] as String;
          final result =
              await _excelImportService.importNilaiDetailFromExcel(
            filePath,
            matakuliahFilter: kodeMatakuliah,
          );

          totalImported += (result['imported'] as int?) ?? 0;
          totalFailed += (result['failed'] as int?) ?? 0;

          if (result['errors'] != null) {
            final errors = result['errors'] as List<dynamic>;
            // ✅ Tampilkan header file dan SEMUA error detail
            allErrors.add('📄 ═══════════════════════════════════════');
            allErrors.add('   FILE: $fileName');
            allErrors.add('   Total Error: ${errors.length}');
            allErrors.add('═══════════════════════════════════════');
            
            // 🔍 Tambahkan semua error detail
            for (int errorIdx = 0; errorIdx < errors.length; errorIdx++) {
              final errorMsg = errors[errorIdx].toString();
              allErrors.add('   ${errorIdx + 1}. $errorMsg');
            }
            allErrors.add(''); // Spasi antar file
          } else {
            successCount++;
          }
        } catch (e) {
          allErrors.add('❌ FILE: $fileName');
          allErrors.add('   Error: $e');
          allErrors.add('');
          totalFailed++;
        }
      }

      setState(() {
        _importResult = {
          'success': totalFailed == 0,
          'imported': totalImported,
          'failed': totalFailed,
          'message':
              'Diproses: ${_selectedFilePaths.length} file, Berhasil: $successCount, Gagal: ${_selectedFilePaths.length - successCount}',
          'errors': allErrors,
        };
        _importErrors = allErrors;
      });

      if (mounted) {
        if (totalFailed == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ Import selesai: $totalImported nilai berhasil diimport dari ${_selectedFilePaths.length} file',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ Import selesai dengan beberapa error: $totalImported berhasil, $totalFailed gagal',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _progressMessage = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Nilai - Per Matakuliah'),
        backgroundColor: const Color(0xFFC0392B),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Box
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ℹ️ Panduan Import Nilai Per Matakuliah',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Fitur ini memudahkan Anda mengimport nilai untuk satu matakuliah secara spesifik dengan template yang disesuaikan.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    '✓ Pilih tahun ajaran\n'
                    '✓ Pilih matakuliah\n'
                    '✓ Download template khusus matakuliah\n'
                    '✓ Isi data file dan import',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Text(
                      '🔍 Validasi: File akan divalidasi terhadap B1 (Kode Matakuliah) dan B3 (Tahun Ajaran)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _downloadTemplate,
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Download Template'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // File Selection
            const Text(
              'File Nilai',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_selectedFilePaths.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  '${_selectedFilePaths.length} file dipilih',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            TextButton.icon(
                              onPressed: _clearAllFiles,
                              icon: const Icon(Icons.clear),
                              label: const Text('Hapus Semua'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...List.generate(
                          _selectedFilePaths.length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.insert_drive_file,
                                  size: 18,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    '${index + 1}. ${_selectedFileNames[index]}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: AppColors.danger,
                                  ),
                                  onPressed: () => _removeFile(index),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah File'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_upload,
                        size: 40,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Klik untuk memilih file(s)',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Bisa pilih multiple file (.xlsx atau .csv)',
                        style: TextStyle(
                          color: AppColors.subtleText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.lg),

            // Format Info
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.secondary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Format File yang Didukung:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Kolom: NIM | Nama Mahasiswa | Aktivitas | Hasil Proyek | Kuis | Tugas | UTS | UAS\n\nSemua nilai berupa angka (0-100)',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Import Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedFilePaths.isNotEmpty &&
                        !_isLoading)
                    ? _importData
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedFilePaths.isNotEmpty)
                      ? AppColors.secondary
                      : AppColors.subtleText,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Mulai Import'),
              ),
            ),

            // Progress Message
            if (_isLoading && _progressMessage.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                _progressMessage,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondary,
                ),
              ),
            ],

            // Import Results
            if (_importResult != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: _importResult!['success']
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: _importResult!['success']
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _importResult!['success']
                              ? Icons.check_circle
                              : Icons.error,
                          color: _importResult!['success']
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _importResult!['success']
                                ? '✓ Import Berhasil'
                                : '✗ Import Gagal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _importResult!['success']
                                  ? AppColors.success
                                  : AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.md,
                      children: [
                        Column(
                          children: [
                            Text(
                              (_importResult!['imported'] ?? 0)
                                  .toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            const Text(
                              'Berhasil',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                              ),
                            )
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              (_importResult!['failed'] ?? 0)
                                  .toString(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.danger,
                              ),
                            ),
                            const Text(
                              'Gagal',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.danger,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Error Log
            if (_importErrors.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Error Log Lengkap:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: Colors.red[200]!,
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🎯 Tampilkan SEMUA error (tidak ada .take() limit)
                        ..._importErrors.map(
                          (error) => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Text(
                              error.contains('FILE:') || error.contains('═')
                                  ? error // Header file ditampilkan bold/special
                                  : '  $error',
                              style: TextStyle(
                                fontSize: 10,
                                color: error.contains('❌') 
                                    ? Colors.red[700]
                                    : error.contains('📄')
                                        ? Colors.blue[700]
                                        : Colors.grey[700],
                                fontFamily: 'Courier', // Monospace font untuk alignment
                                fontWeight: error.contains('FILE:') || error.contains('Total Error') ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: null,
                              softWrap: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Text(
                  'Total: ${_importErrors.length} baris error ditampilkan lengkap',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.danger,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
