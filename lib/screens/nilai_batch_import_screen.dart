import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_constants.dart';
import '../services/template_service.dart';
import '../services/excel_import_service.dart';
import '../services/database_helper.dart';
import '../models/matakuliah_model.dart';

class NilaiBatchImportScreen extends StatefulWidget {
  const NilaiBatchImportScreen({super.key});

  @override
  State<NilaiBatchImportScreen> createState() =>
      _NilaiBatchImportScreenState();
}

class _NilaiBatchImportScreenState extends State<NilaiBatchImportScreen> {
  final _excelImportService = ExcelImportService();
  final _dbHelper = DatabaseHelper();

  // Tahun Ajaran list
  final List<int> tahunAjaranList = [
    2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028, 2029, 2030, 2031
  ];

  // State variables
  int? _selectedTahunAjaran;
  List<Matakuliah> _matakuliahList = [];
  int? _selectedMatakuliahId;
  Matakuliah? _selectedMatakuliah;

  String? _selectedFilePath;
  String? _selectedFileName;

  bool _isLoading = false;
  bool _isLoadingMatakuliah = false;
  
  Map<String, dynamic>? _importResult;
  List<String> _importErrors = [];
  String _progressMessage = '';

  @override
  void initState() {
    super.initState();
    // Set default: tahun ajaran terbaru
    if (tahunAjaranList.isNotEmpty) {
      _selectedTahunAjaran = tahunAjaranList.last;
    }
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
          _selectedFilePath = file.path;
          _selectedFileName = file.name;
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

      final path = await TemplateService.downloadNilaiSingleMatakuliahTemplate(
        kodeMatakuliah: _selectedMatakuliah!.kode,
        namaMatakuliah: _selectedMatakuliah!.nama,
        tahunAjaran: _selectedTahunAjaran?.toString() ?? '2024',
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
    if (_selectedFilePath == null) {
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

    if (_selectedTahunAjaran == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tahun ajaran terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _progressMessage = 'Importing nilai untuk ${_selectedMatakuliah!.nama}...';
    });

    try {
      final result = await _excelImportService.importNilaiDetailFromExcel(
        _selectedFilePath!,
        matakuliahFilter: _selectedMatakuliah!.kode,
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
                '✓ Import berhasil: ${result['imported']} nilai berhasil diimport',
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
                    '✓ Isi dataFile dan import',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Tahun Ajaran Selection
            const Text(
              'Tahun Ajaran',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<int>(
              initialValue: _selectedTahunAjaran,
              decoration: InputDecoration(
                labelText: 'Pilih Tahun Ajaran',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              items: tahunAjaranList
                  .map((tahun) => DropdownMenuItem(
                        value: tahun,
                        child: Text(tahun.toString()),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTahunAjaran = value;
                });
              },
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
              'File Nilai',
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
                onPressed: (_selectedFilePath != null &&
                        _selectedMatakuliah != null &&
                        !_isLoading)
                    ? _importData
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_selectedFilePath != null)
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
