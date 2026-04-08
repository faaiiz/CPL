import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../constants/app_constants.dart';
import '../services/template_service.dart';
import '../services/excel_import_service.dart';
import '../services/database_helper.dart';
import '../models/matakuliah_model.dart';

class SubCPMKBatchImportScreen extends StatefulWidget {
  const SubCPMKBatchImportScreen({super.key});

  @override
  State<SubCPMKBatchImportScreen> createState() =>
      _SubCPMKBatchImportScreenState();
}

class _SubCPMKBatchImportScreenState extends State<SubCPMKBatchImportScreen> {
  final _excelImportService = ExcelImportService();
  final _dbHelper = DatabaseHelper();

  // State variables
  List<Matakuliah> _matakuliahList = [];
  int? _selectedMatakuliahId;
  Matakuliah? _selectedMatakuliah;

  String? _selectedFilePath;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  bool _isLoading = false;
  bool _isLoadingMatakuliah = false;
  
  Map<String, dynamic>? _importResult;
  List<String> _importErrors = [];
  String _progressMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMatakuliah();
  }

  Future<void> _loadMatakuliah() async {
    setState(() {
      _isLoadingMatakuliah = true;
    });
    
    try {
      final matakuliah = await _dbHelper.getAllMatakuliah();
      setState(() {
        _matakuliahList = matakuliah;
        if (_matakuliahList.isNotEmpty) {
          _selectedMatakuliahId = _matakuliahList[0].id;
          _selectedMatakuliah = _matakuliahList[0];
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading matakuliah: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingMatakuliah = false;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFileName = file.name;
          _importResult = null;
          _importErrors = [];
          
          // Handle platform-specific file access
          if (kIsWeb) {
            // On web, use bytes
            _selectedFileBytes = file.bytes;
            _selectedFilePath = ''; // Empty path for web
          } else {
            // On desktop, use path
            _selectedFilePath = file.path;
            _selectedFileBytes = null;
          }
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

  void _removeFile() {
    setState(() {
      _selectedFilePath = null;
      _selectedFileName = null;
    });
  }

  Future<void> _downloadTemplate() async {
    if (_selectedMatakuliah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih matakuliah terlebih dahulu')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mengunduh template...')),
      );

      final path = await TemplateService.downloadSubCPMKBatchTemplate(
        kodeMatakuliah: _selectedMatakuliah!.kode,
        namaMatakuliah: _selectedMatakuliah!.nama,
      );

      if (path != null && mounted) {
        final fileName = path.split('/').last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Template berhasil diunduh:\n$fileName'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        print('Template downloaded: $path');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Gagal mengunduh template.\n\nMungkin penyebab:\n'
              '• Izin folder tidak tersedia\n'
              '• Disk space tidak cukup\n'
              '• Folder download terlocked\n\n'
              'Cek console untuk detail error'
            ),
            backgroundColor: AppColors.danger,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      print('Error downloading template: $e');
    }
  }

  Future<void> _importData() async {
    if (_selectedFilePath == null && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file Excel terlebih dahulu')),
      );
      return;
    }

    if (_selectedMatakuliah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih matakuliah terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _progressMessage = 'Importing Sub CPMK untuk ${_selectedMatakuliah!.nama}...';
    });

    try {
      // Call the import service for Sub CPMK
      final result = await _excelImportService.importSubCPMKFromExcel(
        _selectedFilePath ?? '',
        _selectedMatakuliah!.id!,
        fileBytes: _selectedFileBytes,
        fileName: _selectedFileName,
      );

      setState(() {
        _importResult = result;
        _importErrors = List<String>.from(result['errors'] as List? ?? []);
      });

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ Import berhasil: ${result['imported']} Sub CPMK berhasil diimport',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Import gagal',
              ),
              backgroundColor: AppColors.danger,
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
        title: const Text('Import Sub CPMK - Per Matakuliah'),
        backgroundColor: const Color(0xFF9B59B6),
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
                    'ℹ️ Panduan Import Sub CPMK Per Matakuliah',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Fitur ini memudahkan Anda mengimport Sub CPMK (Sub Capaian Program Keahlian Mata Kuliah) untuk satu matakuliah secara spesifik dengan template yang disesuaikan.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    '✓ Pilih matakuliah\n'
                    '✓ Download template khusus matakuliah\n'
                    '✓ Isi data Sub CPMK dalam file\n'
                    '✓ Import file Excel/CSV',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Matakuliah Selection
            const Text(
              'Matakuliah',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_isLoadingMatakuliah)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_matakuliahList.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Text(
                  'Tidak ada matakuliah ditemukan. Silakan tambahkan matakuliah terlebih dahulu.',
                  style: TextStyle(color: AppColors.danger),
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: _selectedMatakuliahId,
                decoration: InputDecoration(
                  labelText: 'Pilih Matakuliah',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  prefixIcon: const Icon(Icons.book),
                ),
                items: _matakuliahList
                    .map((mk) => DropdownMenuItem(
                          value: mk.id,
                          child: Text('${mk.kode} - ${mk.nama}'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMatakuliahId = value;
                      _selectedMatakuliah = _matakuliahList
                          .firstWhere((mk) => mk.id == value);
                    });
                  }
                },
              ),

            const SizedBox(height: AppSpacing.lg),

            // Download Template Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download Template Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary.withOpacity(0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // File Selection
            const Text(
              'File Sub CPMK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_selectedFilePath != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.file_present,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        _selectedFileName!,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.danger,
                      ),
                      onPressed: _removeFile,
                    ),
                  ],
                ),
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
                        'Klik untuk memilih file',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Format: .xlsx atau .csv',
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
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Format File Yang Diharapkan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Kolom wajib ada dalam file:\n'
                    '• Kode Sub CPMK\n'
                    '• Deskripsi Sub CPMK\n'
                    '• CPMK ID (opsional)',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Import Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _importData,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.upload_file, size: 18),
                label: Text(
                  _isLoading ? _progressMessage : 'Import Data',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B59B6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Import Result
            if (_importResult != null) ...[
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
                            _importResult!['message'] ??
                                'Proses import selesai',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _importResult!['success']
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_importResult!['imported'] != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Sub CPMK berhasil diimport: ${_importResult!['imported']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (_importErrors.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        '❌ Error:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.danger,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ..._importErrors.map((error) => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Text(
                              '• $error',
                              style: const TextStyle(fontSize: 11),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
