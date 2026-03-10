import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_constants.dart';
import '../services/excel_import_service.dart';
import '../services/template_service.dart';
import 'custom_widgets.dart';

class ImportDialog extends StatefulWidget {
  final String importType; // 'mahasiswa', 'matakuliah', 'nilai', 'cpl', 'cpmk', 'sub_cpmk'
  final int? matakuliahId; // Required untuk sub_cpmk
  final Function(Map<String, dynamic>) onImportSuccess;

  const ImportDialog({
    super.key,
    required this.importType,
    this.matakuliahId,
    required this.onImportSuccess,
  });

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  final _excelService = ExcelImportService();
  String? _selectedFilePath;
  String? _selectedFileName;
  bool _isLoading = false;
  List<String> _importErrors = [];
  Map<String, dynamic>? _importResult;

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

  Future<void> _importData() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file Excel terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (widget.importType == 'mahasiswa') {
        result =
            await _excelService.importMahasiswaFromExcel(_selectedFilePath!);
      } else if (widget.importType == 'matakuliah') {
        result =
            await _excelService.importMatakuliahFromExcel(_selectedFilePath!);
      } else if (widget.importType == 'cpl') {
        result = await _excelService.importCPLFromExcel(_selectedFilePath!);
      } else if (widget.importType == 'cpmk') {
        result = await _excelService.importCPMKFromExcel(_selectedFilePath!);
      } else if (widget.importType == 'sub_cpmk') {
        if (widget.matakuliahId == null) {
          throw Exception('Mata Kuliah ID harus diisi untuk import Sub CPMK');
        }
        result = await _excelService.importSubCPMKFromExcel(
          _selectedFilePath!,
          widget.matakuliahId!,
        );
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
          widget.onImportSuccess(result);
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

  Future<void> _downloadTemplate() async {
    try {
      String? path;
      if (widget.importType == 'mahasiswa') {
        path = await TemplateService.downloadMahasiswaTemplate();
      } else if (widget.importType == 'matakuliah') {
        path = await TemplateService.downloadMatakuliahTemplate();
      } else if (widget.importType == 'cpl') {
        path = await TemplateService.downloadCPLTemplate();
      } else if (widget.importType == 'cpmk') {
        path = await TemplateService.downloadCPMKTemplate();
      } else if (widget.importType == 'sub_cpmk') {
        path = await TemplateService.downloadSubCPMKTemplate();
      } else {
        path = await TemplateService.downloadNilaiTemplate();
      }

      if (mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Template downloaded: $path')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to download template'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final templateInfo = TemplateService.getTemplateInfo(widget.importType);
    final columns = templateInfo['columns'] ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Import ${widget.importType[0].toUpperCase()}${widget.importType.substring(1)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.md),

              // Template Info
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
                      'Format Template:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...columns
                        .map(
                          (col) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(col),
                          ),
                        )
                        ,
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Download Template Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Download Template'),
                  onPressed: _downloadTemplate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
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
                'Pilih File',
                style: TextStyle(
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
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Import Data',
                  isLoading: _isLoading,
                  onPressed:
                      _selectedFilePath != null ? () => _importData() : () {},
                  backgroundColor: _selectedFilePath != null
                      ? AppColors.secondary
                      : AppColors.subtleText,
                ),
              ),

              // Results
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
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                _importResult!['imported'].toString(),
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
                                _importResult!['failed'].toString(),
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
              ],
              if (_importErrors.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Error Log:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
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
                      ),
                    ),
                    if (_importErrors.length > 10)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
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
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
