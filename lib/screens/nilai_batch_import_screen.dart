import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:io';
import '../constants/app_constants.dart';
import '../services/excel_import_service.dart';
import '../services/excel_template_service.dart';

class NilaiBatchImportScreen extends StatefulWidget {
  const NilaiBatchImportScreen({super.key});

  @override
  State<NilaiBatchImportScreen> createState() =>
      _NilaiBatchImportScreenState();
}

class _NilaiBatchImportScreenState extends State<NilaiBatchImportScreen> {
  final _excelImportService = ExcelImportService();

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

  /// Validasi B1 (Kode Matakuliah) dan B3 (Tahun Ajaran) dari Excel file
  Future<Map<String, dynamic>> _validateExcelHeaders(String filePath) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final excel = excel_lib.Excel.decodeBytes(bytes);
      final sheet = excel.tables.values.first;

      // Baca B1 - Kode Matakuliah
      String? kodeMatakuliahFromExcel;
      String? tahunAjaranFromExcel;

      // Cell B1 (row 0, col 1)
      if (sheet.rows.length > 0 && sheet.rows[0].length > 1) {
        final cellB1 = sheet.rows[0][1];
        kodeMatakuliahFromExcel = cellB1?.value?.toString().trim();
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

      // Validasi B3 - Tahun Ajaran
      if (tahunAjaranFromExcel == null || tahunAjaranFromExcel.isEmpty) {
        return {
          'error': 'Tahun Ajaran di B3 kosong',
          'type': 'tahun',
          'success': false,
        };
      }

      return {
        'success': true,
        'kodeMatakuliah': kodeMatakuliahFromExcel,
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
          allErrors.add('❌ $fileName: ${validationResult['error']}');
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
            allErrors.add('✓ $fileName: ${errors.length} error(s)');
          } else {
            successCount++;
          }
        } catch (e) {
          allErrors.add('❌ $fileName: Error - $e');
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
                'Error Log (Sampel):',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _importErrors
                          .take(20)
                          .map(
                            (error) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                              child: Text(
                                '• $error',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
              if (_importErrors.length > 20)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                  ),
                  child: Text(
                    'Total ${_importErrors.length} error (tampil 20)',
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
