import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../services/excel_import_service.dart';
import '../services/template_service.dart';
import '../services/database_helper.dart';
import '../widgets/custom_widgets.dart';

class ExcelImportScreen extends StatefulWidget {
  final String? initialImportType;
  
  const ExcelImportScreen({
    super.key,
    this.initialImportType,
  });

  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> {
  final _excelService = ExcelImportService();
  final _dbHelper = DatabaseHelper();
  String? _selectedFilePath;
  String? _selectedFileName;
  String _importType = 'mahasiswa';
  int? _selectedMatakuliahId; // Untuk Sub CPMK import
  String? _selectedMatakuliahNama; // Untuk Sub CPMK import
  bool _isLoading = false;
  bool _isDownloadingTemplate = false;
  List<String> _importErrors = [];
  Map<String, dynamic>? _importResult;

  @override
  void initState() {
    super.initState();
    // Set initial import type if provided
    if (widget.initialImportType != null) {
      _importType = widget.initialImportType!;
      // If Sub CPMK is selected, show mata kuliah selector after frame
      if (_importType == 'sub_cpmk') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showMatakuliahSelector();
        });
      }
    }
  }

  Future<void> _downloadTemplate() async {
    setState(() => _isDownloadingTemplate = true);
    
    try {
      String? filePath;
      String typeLabel = '';
      
      if (_importType == 'mahasiswa') {
        filePath = await TemplateService.downloadMahasiswaTemplate();
        typeLabel = 'Mahasiswa';
      } else if (_importType == 'matakuliah') {
        filePath = await TemplateService.downloadMatakuliahTemplate();
        typeLabel = 'Matakuliah';
      } else if (_importType == 'cpl') {
        filePath = await TemplateService.downloadCPLTemplate();
        typeLabel = 'CPL';
      } else if (_importType == 'cpmk') {
        filePath = await TemplateService.downloadCPMKTemplate();
        typeLabel = 'CPMK';
      } else if (_importType == 'sub_cpmk') {
        filePath = await TemplateService.downloadSubCPMKTemplate(
          matakuliahNama: _selectedMatakuliahNama ?? 'Mata Kuliah',
        );
        typeLabel = 'Sub CPMK';
      } else {
        filePath = await TemplateService.downloadNilaiTemplate();
        typeLabel = 'Nilai';
      }
      
      if (filePath != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Template $typeLabel berhasil diunduh ke Downloads'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception('Gagal mengunduh template');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️  ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingTemplate = false);
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFilePath = result.files.first.path;
          _selectedFileName = result.files.first.name;
          _importResult = null;
          _importErrors = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  String _getTemplateButtonLabel() {
    switch (_importType) {
      case 'mahasiswa':
        return 'Unduh Template Mahasiswa';
      case 'matakuliah':
        return 'Unduh Template Matakuliah';
      case 'cpl':
        return 'Unduh Template CPL';
      case 'cpmk':
        return 'Unduh Template CPMK';
      case 'sub_cpmk':
        return 'Unduh Template Sub CPMK';
      case 'nilai':
        return 'Unduh Template Nilai';
      default:
        return 'Unduh Template';
    }
  }

  String _getTypeLabel() {
    switch (_importType) {
      case 'mahasiswa':
        return 'Mahasiswa';
      case 'matakuliah':
        return 'Matakuliah';
      case 'cpl':
        return 'CPL';
      case 'cpmk':
        return 'CPMK';
      case 'sub_cpmk':
        return 'Sub CPMK';
      case 'nilai':
        return 'Nilai';
      default:
        return 'Data';
    }
  }

  Color _getAppBarColor() {
    switch (_importType) {
      case 'cpl':
        return const Color(0xFF2980B9);
      case 'cpmk':
        return const Color(0xFFE74C3C);
      case 'sub_cpmk':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFF5DADE2);
    }
  }

  String _getAppBarTitle() {
    if (widget.initialImportType != null) {
      return 'Import Template ${_getTypeLabel()}';
    }
    return 'Import Data dari Excel';
  }

  String _getGuidanceText() {
    switch (_importType) {
      case 'cpl':
        return '📋 Panduan Import Template CPL\n\n'
            '1. Klik "Unduh Template" untuk mengunduh template Excel ke folder Downloads\n'
            '2. Buka template dan isi data CPL sesuai kolom yang tersedia (Nomor: 1-7)\n'
            '3. Simpan file dengan format .xlsx atau .csv\n'
            '4. Klik "Pilih File" dan pilih file yang sudah diisi\n'
            '5. Klik "Import Data" untuk mengimpor ke database';
      case 'cpmk':
        return '📋 Panduan Import Template CPMK\n\n'
            '1. Klik "Unduh Template" untuk mengunduh template Excel ke folder Downloads\n'
            '2. Buka template dan isi data CPMK sesuai kolom yang tersedia\n'
            '3. Simpan file dengan format .xlsx atau .csv\n'
            '4. Klik "Pilih File" dan pilih file yang sudah diisi\n'
            '5. Klik "Import Data" untuk mengimpor ke database';
      case 'sub_cpmk':
        return '📋 Panduan Import Template Sub CPMK\n\n'
            '1. Pilih Mata Kuliah terlebih dahulu\n'
            '2. Klik "Unduh Template" untuk mengunduh template Excel ke folder Downloads\n'
            '3. Buka template dan isi data Sub CPMK sesuai kolom yang tersedia\n'
            '4. Simpan file dengan format .xlsx atau .csv\n'
            '5. Klik "Pilih File" dan pilih file yang sudah diisi\n'
            '6. Klik "Import Data" untuk mengimpor ke database';
      default:
        return 'Pilih jenis data yang ingin diimpor, unduh template, isi data, dan upload file untuk melakukan import.';
    }
  }

  Future<void> _importData() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file Excel terlebih dahulu')),
      );
      return;
    }

    if (_importType == 'sub_cpmk' && _selectedMatakuliahId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (_importType == 'mahasiswa') {
        result =
            await _excelService.importMahasiswaFromExcel(_selectedFilePath!);
      } else if (_importType == 'matakuliah') {
        result =
            await _excelService.importMatakuliahFromExcel(_selectedFilePath!);
      } else if (_importType == 'cpl') {
        result = await _excelService.importCPLFromExcel(_selectedFilePath!);
      } else if (_importType == 'cpmk') {
        result = await _excelService.importCPMKFromExcel(_selectedFilePath!);
      } else if (_importType == 'sub_cpmk') {
        result = await _excelService.importSubCPMKFromExcel(_selectedFilePath!, _selectedMatakuliahId!);
      } else {
        result = await _excelService.importNilaiFromExcel(_selectedFilePath!);
      }

      setState(() {
        _importResult = result;
        _importErrors = List<String>.from(result['errors'] as List? ?? []);
      });

      if (mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Import berhasil')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Import gagal'),
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showMatakuliahSelector() async {
    try {
      final matakuliahList = await _dbHelper.getAllMatakuliah();
      
      if (!mounted) return;
      
      if (matakuliahList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada mata kuliah yang tersedia')),
        );
        return;
      }
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Pilih Mata Kuliah'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: matakuliahList.length,
                itemBuilder: (context, index) {
                  final mk = matakuliahList[index];
                  final mkId = mk.id;
                  final mkNama = mk.nama;
                  
                  return ListTile(
                    title: Text(mkNama),
                    onTap: () {
                      setState(() {
                        _selectedMatakuliahId = mkId;
                        _selectedMatakuliahNama = mkNama;
                      });
                      Navigator.of(context).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Mata Kuliah: $mkNama dipilih')),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading mata kuliah: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: _getAppBarColor(),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guidance Card - tampil jika ada initialImportType atau di general view
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    _getGuidanceText(),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Type Selection - hanya tampil jika initialImportType tidak di-set
              if (widget.initialImportType == null) ...[
                const Text(
                  'Tipe Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.md,
                  children: [
                    SizedBox(
                      width: 140,
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Mahasiswa'),
                        value: 'mahasiswa',
                        groupValue: _importType,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _importType = value);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Matakuliah'),
                        value: 'matakuliah',
                        groupValue: _importType,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _importType = value);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('CPL'),
                        value: 'cpl',
                        groupValue: _importType,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _importType = value);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sub CPMK'),
                        value: 'sub_cpmk',
                        groupValue: _importType,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _importType = value;
                              _selectedMatakuliahId = null;
                              _selectedMatakuliahNama = null;
                            });
                            _showMatakuliahSelector();
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('CPMK'),
                        value: 'cpmk',
                        groupValue: _importType,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _importType = value);
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Nilai'),
                        value: 'nilai',
                        groupValue: _importType,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _importType = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // No type selection UI needed when initialImportType is pre-set
              ],

              // Mata Kuliah selection info for Sub CPMK
              if (_importType == 'sub_cpmk')
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mata Kuliah yang Dipilih:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.subtleText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _selectedMatakuliahNama ?? 'Belum dipilih',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GestureDetector(
                          onTap: _showMatakuliahSelector,
                          child: const Text(
                            'Ubah Pilihan',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),

              // Download Template Button
              ElevatedButton.icon(
                onPressed: (_isDownloadingTemplate || (_importType == 'sub_cpmk' && _selectedMatakuliahId == null)) ? null : _downloadTemplate,
                icon: _isDownloadingTemplate
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                label: Text(
                  _isDownloadingTemplate
                      ? 'Mengunduh...'
                      : (_importType == 'sub_cpmk' && _selectedMatakuliahId == null)
                          ? 'Pilih Mata Kuliah Terlebih Dahulu'
                          : _getTemplateButtonLabel(),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Template Info
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.secondary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Format Template Excel:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_importType == 'mahasiswa') ...[
                      const Text('Kolom A: NIM'),
                      const Text('Kolom B: Nama'),
                      const Text('Kolom C: Tahun Masuk'),
                    ] else if (_importType == 'matakuliah') ...[
                      const Text('Kolom A: Kode Matakuliah'),
                      const Text('Kolom B: Nama Matakuliah'),
                      const Text('Kolom C: Semester'),
                      const Text('Kolom D: Jenis (wajib/pilihan)'),
                      const Text('Kolom E: SKS (1-6)'),
                    ] else if (_importType == 'cpl') ...[
                      const Text('Kolom A: Nomor CPL'),
                      const Text('Kolom B: Deskripsi CPL'),
                    ] else if (_importType == 'cpmk') ...[
                      const Text('Kolom A: Nomor CPMK'),
                      const Text('Kolom B: Deskripsi CPMK'),
                    ] else if (_importType == 'sub_cpmk') ...[
                      const Text('Baris 1: Nama Mata Kuliah'),
                      const Text('Kolom A: Kode Sub CPMK'),
                      const Text('Kolom B: Deskripsi Sub CPMK'),
                    ] else if (_importType == 'nilai') ...[
                      const Text('Kolom A: NIM Mahasiswa'),
                      const Text('Kolom B: Nama Mahasiswa'),
                      const Text('Kolom C: Kode Matakuliah'),
                      const Text('Kolom D: Nama Matakuliah'),
                      const Text('Kolom E: Grade (A/B/C/D/E)'),
                      const Text('Kolom F: Tahun Ajaran'),
                    ] else ...[
                      const Text('Pilih tipe data untuk melihat format template'),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // File Selection
              const Text(
                'Pilih File',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (_selectedFileName != null)
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'File terpilih:',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              _selectedFileName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.danger,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedFilePath = null;
                            _selectedFileName = null;
                          });
                        },
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: _pickFile,
                  child: Container(
                    padding:
                        const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.secondary,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_upload,
                          size: 48,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(
                            height: AppSpacing.md),
                        const Text(
                          'Klik untuk memilih file Excel atau CSV',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(
                            height: AppSpacing.sm),
                        const Text(
                          'Format: .xlsx, .xls, atau .csv',
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

              // Import Button
              CustomButton(
                label: 'Import Data',
                isLoading: _isLoading,
                onPressed:
                    _selectedFilePath != null ? () => _importData() : () {},
                backgroundColor: _selectedFilePath != null
                    ? AppColors.secondary
                    : AppColors.subtleText,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Results
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
                          const SizedBox(
                              width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              _importResult!['message'] ??
                                  'Import completed',
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
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                _importResult!['imported']
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
                                  fontSize: 12,
                                  color: AppColors.success,
                                ),
                              )
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                _importResult!['failed']
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
                                  fontSize: 12,
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
                const SizedBox(height: AppSpacing.lg),
                if (_importErrors.isNotEmpty) ...[
                  const Text(
                    'Error Log:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _importErrors
                          .take(10)
                          .map(
                            (error) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm),
                              child: Text(
                                '• $error',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  if (_importErrors.length > 10)
                    Padding(
                      padding: const EdgeInsets.only(
                          top: AppSpacing.md),
                      child: Text(
                        'dan ${_importErrors.length - 10} error lainnya...',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
