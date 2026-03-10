import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/matakuliah_model.dart';
import '../constants/app_constants.dart';
import '../services/database_helper.dart';
import '../services/rps_excel_service.dart';
import '../services/template_service.dart';

class RPSTemplateImportScreen extends StatefulWidget {
  const RPSTemplateImportScreen({super.key});

  @override
  State<RPSTemplateImportScreen> createState() =>
      _RPSTemplateImportScreenState();
}

class _RPSTemplateImportScreenState extends State<RPSTemplateImportScreen> {
  final _dbHelper = DatabaseHelper();
  final _rpsService = RPSExcelService();

  late Future<List<Matakuliah>> _matakuliahList;
  Matakuliah? _selectedMatakuliah;
  String? _selectedFilePath;
  bool _isLoading = false;
  Map<String, dynamic>? _importResult;

  @override
  void initState() {
    super.initState();
    _matakuliahList = _dbHelper.getAllMatakuliah();
  }

  Future<void> _downloadTemplate() async {
    if (_selectedMatakuliah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    try {
      print('Downloading RPS template for: ${_selectedMatakuliah!.nama} (${_selectedMatakuliah!.kode})');
      
      // Download template RPS dengan nama file: RPS_<kode_matakuliah>.xlsx
      final filePath = await TemplateService.downloadRPSTemplate(
        matakuliahNama: _selectedMatakuliah!.nama,
        kodeMatkuliah: _selectedMatakuliah!.kode,
      );

      print('Template download result: $filePath');

      if (filePath == null) {
        throw Exception('Gagal mengunduh template RPS - Path is null');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Template RPS berhasil diunduh ke Downloads\n$filePath'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      print('Error downloading RPS template: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️  Gagal mengunduh template RPS:\n${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih file: ${e.toString()}')),
      );
    }
  }

  Future<void> _importRPS() async {
    if (_selectedMatakuliah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih mata kuliah')),
      );
      return;
    }

    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih file terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _rpsService.importRPSFromExcel(
        _selectedFilePath!,
        _selectedMatakuliah!,
      );

      if (!mounted) return;

      setState(() {
        _importResult = result;
        _isLoading = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${result['message']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import RPS dari Excel'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Import RPS Template Excel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Fitur ini memungkinkan Anda mengimpor data RPS untuk semua minggu pembelajaran dalam satu file Excel. '
                      'Template otomatis menyertakan verifikasi kode dan nama mata kuliah.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Select Matakuliah
            const Text(
              'Pilih Mata Kuliah',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FutureBuilder<List<Matakuliah>>(
              future: _matakuliahList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final matakuliahList = snapshot.data ?? [];

                return DropdownButtonFormField<Matakuliah>(
                  initialValue: _selectedMatakuliah,
                  items: matakuliahList.map((mk) {
                    return DropdownMenuItem<Matakuliah>(
                      value: mk,
                      child: Text('${mk.kode} - ${mk.nama}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMatakuliah = value;
                      _importResult = null;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Pilih mata kuliah',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Download Template Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download),
                label: const Text('Download Template Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Divider
            Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
            const SizedBox(height: AppSpacing.lg),

            // File Selection
            const Text(
              'Pilih File Excel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.attach_file,
                  color: _selectedFilePath != null
                      ? AppColors.secondary
                      : Colors.grey[400],
                ),
                title: Text(
                  _selectedFilePath ?? 'Belum ada file dipilih',
                  style: TextStyle(
                    fontSize: 13,
                    color: _selectedFilePath != null
                        ? Colors.black
                        : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: ElevatedButton.icon(
                  onPressed: _selectFile,
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('Pilih'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Import Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _importRPS,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(
                  _isLoading ? 'Sedang Mengimpor...' : 'Import RPS',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  disabledBackgroundColor: Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Results
            if (_importResult != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _importResult!['success']
                          ? Colors.green[300]!
                          : Colors.orange[300]!,
                      width: 2,
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
                                : Icons.warning,
                            color: _importResult!['success']
                                ? Colors.green
                                : Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              _importResult!['message'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Berhasil: ${_importResult!['imported']} | Gagal: ${_importResult!['failed']}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_importResult!['errors'].isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Detail Error:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: (_importResult!['errors'] as List)
                                .map(
                                  (error) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
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
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
