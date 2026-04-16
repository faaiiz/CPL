import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/matakuliah_model.dart';
import '../models/rps_detail_model.dart';
import '../models/rps_detail_sub_cpmk_bobot_model.dart';
import '../models/cpmk_model.dart';
import '../models/sub_cpmk_model.dart';
import '../models/cpl_master_model.dart';
import '../constants/app_constants.dart';
import '../services/database_helper.dart';
import '../services/excel_import_service.dart';

import '../widgets/custom_widgets.dart';

class RPSInputScreen extends StatefulWidget {
  const RPSInputScreen({super.key});

  @override
  State<RPSInputScreen> createState() => _RPSInputScreenState();
}

class _RPSInputScreenState extends State<RPSInputScreen> {
  final _dbHelper = DatabaseHelper();
  final _excelImportService = ExcelImportService();
  late Future<List<Matakuliah>> _matakuliahList;
  List<CPLMaster> _allCPL = [];

  final Map<int, List<RPSDetail>> _rpsCache = {};

  @override
  void initState() {
    super.initState();
    _loadMatakuliah();
  }

  void _loadMatakuliah() async {
    try {
      final cpls = await _dbHelper.getAllCPLMaster();
      final mks = await _dbHelper.getAllMatakuliah();
      
      setState(() {
        _matakuliahList = Future.value(mks);
        _allCPL = cpls;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading CPL: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _importSubCPMKBatch() async {
    try {
      // Pilih multiple files
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        allowMultiple: true, // ALLOW MULTIPLE FILES
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final filePaths = result.files.map((f) => f.path).whereType<String>().toList();
      if (filePaths.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: File path tidak valid'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Sedang Mengimport Sub CPMK'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Mengimport ${filePaths.length} file Sub CPMK...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Text(
                'Silakan tunggu, jangan tutup aplikasi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );

      // Import all files
      final importResult = await _excelImportService.importSubCPMKBatchMultipleFiles(
        filePaths,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Tampilkan hasil
      if (importResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${importResult['message']}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );

        // Show detail dialog
        _showImportResultDialog(importResult);
        // Refresh data setelah import berhasil
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _loadMatakuliah();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠ ${importResult['message']}'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );

        // Show detail dialog
        _showImportResultDialog(importResult);
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog jika ada error
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showImportResultDialog(Map<String, dynamic> importResult) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hasil Import Sub CPMK'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ringkasan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: importResult['success']
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      importResult['message'] ?? 'Import selesai',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${importResult['totalImported']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text('Berhasil', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${importResult['totalFailed']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Text('Gagal', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Detail per file
              const Text(
                'Detail Per File:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),

              ...(importResult['fileResults'] as List<dynamic>? ?? [])
                  .map<Widget>((fileResult) {
                final result = fileResult as Map<String, dynamic>;
                final success = result['success'] as bool;
                final fileName = result['fileName'] as String;
                final matakuliah = result['matakuliah'] as String?;
                final message = result['message'] as String;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: success ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
                      border: Border.all(
                        color: success ? Colors.green : Colors.red,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              success ? Icons.check_circle : Icons.error,
                              color: success ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (matakuliah != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Matakuliah: $matakuliah',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 11,
                            color: success ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _importRPSBatch() async {
    try {
      // Pilih multiple files
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final filePaths = result.files.map((f) => f.path).whereType<String>().toList();
      if (filePaths.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: File path tidak valid'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Sedang Mengimport RPS'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Mengimport ${filePaths.length} file RPS...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Text(
                'Silakan tunggu, jangan tutup aplikasi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );

      // Import all files
      final importResult = await _excelImportService.importRPSBatchMultipleFiles(
        filePaths,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Tampilkan hasil
      if (importResult['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${importResult['message']}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );

        // Show detail dialog
        _showRPSImportResultDialog(importResult);

        // Refresh cache dan reload data
        _rpsCache.clear();
        // Refresh data setelah import berhasil
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _loadMatakuliah();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠ ${importResult['message']}'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );

        // Show detail dialog
        _showRPSImportResultDialog(importResult);
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog jika ada error
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showRPSImportResultDialog(Map<String, dynamic> importResult) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hasil Import RPS'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ringkasan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: importResult['success']
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      importResult['message'] ?? 'Import selesai',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${importResult['totalImported']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text('Berhasil', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${importResult['totalFailed']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Text('Gagal', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Detail per file
              const Text(
                'Detail Per File:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),

              ...(importResult['fileResults'] as List<dynamic>? ?? [])
                  .map<Widget>((fileResult) {
                final result = fileResult as Map<String, dynamic>;
                final success = result['success'] as bool;
                final fileName = result['fileName'] as String;
                final matakuliah = result['matakuliah'] as String?;
                final message = result['message'] as String;
                final imported = result['imported'] as int?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: success ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
                      border: Border.all(
                        color: success ? Colors.green : Colors.red,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              success ? Icons.check_circle : Icons.error,
                              color: success ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (matakuliah != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Matakuliah: $matakuliah',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                        if (imported != null && imported > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Jumlah RPS: $imported minggu',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 11,
                            color: success ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadRPSData(int matakuliahId) async {
    if (_rpsCache.containsKey(matakuliahId)) {
      return;
    }

    try {
      final rpsDetails = await _dbHelper.getRPSDetailByMatakuliah(matakuliahId);
      _rpsCache[matakuliahId] = rpsDetails;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<double> _calculateTotalBobot(int matakuliahId) async {
    final rpsDetails = _rpsCache[matakuliahId] ?? await _dbHelper.getRPSDetailByMatakuliah(matakuliahId);
    double total = 0;
    for (var rps in rpsDetails) {
      if (rps.bobot != null) {
        total += rps.bobot!;
      }
    }
    return total;
  }

  Color _getBobotIndicatorColor(double total) {
    if (total == 100) {
      return Colors.green;
    } else if (total < 100) {
      return Colors.red;
    } else {
      return Colors.orange;
    }
  }

  String _getBobotStatusText(double total) {
    if (total == 100) {
      return '✓ ${total.toStringAsFixed(1)}%';
    } else if (total < 100) {
      return '✗ ${total.toStringAsFixed(1)}%';
    } else {
      return '⚠ ${total.toStringAsFixed(1)}%';
    }
  }

  Future<void> _addOrEditRPSWeek(int mingguKe, int matakuliahId, {required List<CPMK> cpmks, required List<SubCPMK> subCpmks, RPSDetail? existing}) async {
    await showDialog(
      context: context,
      builder: (context) => RPSEditDialog(
        mingguKe: mingguKe,
        matakuliahId: matakuliahId,
        cpmkList: cpmks,
        subCpmkList: subCpmks,
        cplList: _allCPL,
        existing: existing,
        onSave: (rpsDetail, assessmentBobotMap) async {
          try {
            final currentTotal = await _calculateTotalBobot(matakuliahId);
            final newTotal = currentTotal - (existing?.bobot ?? 0) + (rpsDetail.bobot ?? 0);
            
            if (newTotal > 100) {
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('⚠️ Peringatan Bobot'),
                    content: Text(
                      'Total bobot pembelajaran melebihi 100%!\n\n'
                      'Total saat ini: ${newTotal.toStringAsFixed(1)}%\n'
                      'Maksimal: 100%\n\n'
                      'Yakin ingin menyimpan?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _saveRPSDetail(rpsDetail, existing, assessmentBobotMap);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: const Text('Simpan Tetap'),
                      ),
                    ],
                  ),
                );
              }
              return;
            }
            
            await _saveRPSDetail(rpsDetail, existing, assessmentBobotMap);
          } catch (e) {
            // Error during RPS Detail save
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _saveRPSDetail(RPSDetail rpsDetail, RPSDetail? existing, Map<int, double> assessmentBobotMap) async {
    try {
      int? rpsDetailId;
      if (existing != null) {
        await _dbHelper.updateRPSDetail(rpsDetail);
        rpsDetailId = existing.id;
      } else {
        print('DEBUG: Melakukan INSERT RPS Detail baru');
        rpsDetailId = await _dbHelper.insertRPSDetail(rpsDetail);
        print('DEBUG: INSERT result=$rpsDetailId');
      }
      
      // Save assessment bobot per SubCPMK jika UTS/UAS dan bobot map tidak kosong
      if (assessmentBobotMap.isNotEmpty && rpsDetailId != null) {
        try {
          print('DEBUG: Menyimpan assessment bobot untuk RPS Detail $rpsDetailId');
          
          // Delete existing bobot entries
          await _dbHelper.deleteRPSDetailSubCPMKBobotByRPSDetail(rpsDetailId);
          
          // Insert new bobot entries
          for (final entry in assessmentBobotMap.entries) {
            final bobotRecord = RPSDetailSubCPMKBobot(
              rpsDetailId: rpsDetailId,
              subCpmkId: entry.key,
              bobot: entry.value,
              createdAt: DateTime.now(),
            );
            await _dbHelper.insertRPSDetailSubCPMKBobot(bobotRecord);
          }
          
          print('DEBUG: Assessment bobot saved successfully');
        } catch (e) {
          print('DEBUG: Error saving assessment bobot: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Warning: Gagal menyimpan bobot per SubCPMK: $e'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
      
      _rpsCache.remove(rpsDetail.matakuliahId);
      
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data RPS disimpan dengan sukses')),
        );
      }
    } catch (e, stackTrace) {
      print('ERROR: Gagal menyimpan RPS Detail');
      print('ERROR Message: ${e.toString()}');
      print('ERROR StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error menyimpan RPS: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _manageCPMKForMatakuliah(Matakuliah matakuliah) async {
    if (!mounted) return;

    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return FutureBuilder<List<SubCPMK>>(
            future: _dbHelper.getSubCPMKByMatakuliah(matakuliah.id!),
            builder: (context, snapshot) {
              final subCpmkList = snapshot.data ?? [];
              
              return AlertDialog(
                title: Text('Kelola Sub CPMK: ${matakuliah.nama}'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, size: 16, color: AppColors.subtleText),
                          const SizedBox(width: AppSpacing.sm),
                          const Expanded(
                            child: Text(
                              'Sub CPMK = Detail pembelajaran spesifik untuk mata kuliah ini\nCPMK program level dikelola di menu "Kelola CPMK"',
                              style: TextStyle(fontSize: 11, color: AppColors.subtleText),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : subCpmkList.isEmpty
                                ? const Center(
                                    child: Text('Belum ada Sub CPMK. Tambahkan Sub CPMK baru di bawah.'),
                                  )
                                : ListView.builder(
                                    itemCount: subCpmkList.length,
                                    itemBuilder: (context, index) {
                                      final subCpmk = subCpmkList[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                        child: Padding(
                                          padding: const EdgeInsets.all(AppSpacing.md),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          subCpmk.kodeSubCPMK,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                        const SizedBox(height: AppSpacing.xs),
                                                        Text(
                                                          subCpmk.deskripsi,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Column(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.edit, size: 18),
                                                        onPressed: () async {
                                                          final result = await _showEditSubCPMKDialog(matakuliah, subCpmk);
                                                          if (result == true) {
                                                            setDialogState(() {});
                                                          }
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                                        onPressed: () async {
                                                          final result = await _deleteSubCPMKEntry(matakuliah, subCpmk.id!);
                                                          if (result == true) {
                                                            setDialogState(() {});
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Sub CPMK'),
                    onPressed: () async {
                      final result = await _showAddSubCPMKDialog(matakuliah);
                      if (result == true) {
                        setDialogState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Tutup'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
    
    // Refresh parent widget setelah dialog ditutup
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _showAddSubCPMKDialog(Matakuliah matakuliah) async {
    final deskripsiController = TextEditingController();
    String? selectedKode;
    
    // Generate list kode Sub CPMK (SUB-CPMK.1 sampai SUB-CPMK.7)
    final kodeSubCPMK = List.generate(7, (index) => 'SUB-CPMK.${index + 1}');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Tambah Sub CPMK Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kode Sub CPMK',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: selectedKode,
                  decoration: InputDecoration(
                    labelText: 'Pilih Kode Sub CPMK',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  items: kodeSubCPMK.map((kode) {
                    return DropdownMenuItem<String>(
                      value: kode,
                      child: Text(kode),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedKode = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Deskripsi Sub CPMK',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: deskripsiController,
                  decoration: InputDecoration(
                    labelText: 'Masukkan deskripsi Sub CPMK',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedKode == null || deskripsiController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field harus diisi')),
                  );
                  return;
                }

                try {
                  final subCpmk = SubCPMK(
                    matakuliahId: matakuliah.id!,
                    kodeSubCPMK: selectedKode!,
                    deskripsi: deskripsiController.text,
                    createdAt: DateTime.now(),
                  );

                  await _dbHelper.insertSubCPMK(subCpmk);
                  
                  if (mounted) {
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sub CPMK ditambahkan')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                  Navigator.pop(context, false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<bool> _showEditSubCPMKDialog(Matakuliah matakuliah, SubCPMK subCpmk) async {
    final deskripsiController = TextEditingController(text: subCpmk.deskripsi);
    String? selectedKode = subCpmk.kodeSubCPMK;
    
    // Generate list kode Sub CPMK (SUB-CPMK.1 sampai SUB-CPMK.7)
    final kodeSubCPMK = List.generate(7, (index) => 'SUB-CPMK.${index + 1}');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Sub CPMK'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kode Sub CPMK',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: selectedKode,
                  decoration: InputDecoration(
                    labelText: 'Pilih Kode Sub CPMK',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  items: kodeSubCPMK.map((kode) {
                    return DropdownMenuItem<String>(
                      value: kode,
                      child: Text(kode),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedKode = value;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Deskripsi Sub CPMK',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: deskripsiController,
                  decoration: InputDecoration(
                    labelText: 'Masukkan deskripsi Sub CPMK',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedKode == null || deskripsiController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field harus diisi')),
                  );
                  return;
                }

                try {
                  final updatedSubCpmk = subCpmk.copyWith(
                    kodeSubCPMK: selectedKode!,
                    deskripsi: deskripsiController.text,
                    updatedAt: DateTime.now(),
                  );

                  await _dbHelper.updateSubCPMK(updatedSubCpmk);
                  
                  if (mounted) {
                    Navigator.pop(context, true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sub CPMK diperbarui')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                  Navigator.pop(context, false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  Future<bool> _deleteSubCPMKEntry(Matakuliah matakuliah, int subCpmkId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus Sub CPMK ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteSubCPMK(subCpmkId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sub CPMK dihapus')),
          );
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
        return false;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input RPS (Rencana Pembelajaran Semester)'),
        backgroundColor: const Color(0xFFE67E22),
        elevation: 4,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import_subcpmk') {
                _importSubCPMKBatch();
              } else if (value == 'import_rps') {
                _importRPSBatch();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'import_subcpmk',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.green, size: 18),
                    SizedBox(width: 10),
                    Text('Import Sub CPMK Batch'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'import_rps',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.orange, size: 18),
                    SizedBox(width: 10),
                    Text('Import RPS Batch'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.more_vert, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Mata Kuliah',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: FutureBuilder<List<Matakuliah>>(
                future: _matakuliahList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final matakuliahList = snapshot.data ?? [];
                  if (matakuliahList.isEmpty) {
                    return const EmptyStateWidget(
                      message: 'Belum ada mata kuliah',
                      icon: Icons.book,
                    );
                  }

                  return ListView.builder(
                    itemCount: matakuliahList.length,
                    itemBuilder: (context, index) {
                      final mk = matakuliahList[index];
                      return FutureBuilder<double>(
                        future: _calculateTotalBobot(mk.id!),
                        builder: (context, snapshot) {
                          final totalBobot = snapshot.data ?? 0;
                          final indicatorColor = _getBobotIndicatorColor(totalBobot);
                          final bobotStatus = _getBobotStatusText(totalBobot);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              side: BorderSide(
                                color: indicatorColor.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 75,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Center(
                                  child: Text(
                                    mk.kode,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.secondary,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      mk.nama,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: indicatorColor.withOpacity(0.15),
                                      border: Border.all(
                                        color: indicatorColor,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      bobotStatus,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: indicatorColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${mk.sks} SKS • Semester ${mk.semester}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: FutureBuilder<List<SubCPMK>>(
                                future: _dbHelper.getSubCPMKByMatakuliah(mk.id!),
                                builder: (context, subCpmkSnapshot) {
                                  final hasSubCPMK = subCpmkSnapshot.data?.isNotEmpty ?? false;
                                  final subCpmkButtonColor = hasSubCPMK ? Colors.green : const Color.fromARGB(255, 202, 31, 19);

                                  return FutureBuilder<List<RPSDetail>>(
                                    future: _dbHelper.getRPSDetailByMatakuliah(mk.id!),
                                    builder: (context, rpsSnapshot) {
                                      final rpsDataList = rpsSnapshot.data ?? [];
                                      final allWeeksComplete = rpsDataList.length == 16;
                                      final rpsButtonColor = allWeeksComplete ? Colors.green : const Color.fromARGB(255, 202, 31, 19);

                                      return SizedBox(
                                        width: 260,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _manageCPMKForMatakuliah(mk),
                                                icon: const Icon(Icons.settings, size: 16),
                                                label: const Text('Input SUB CPMK'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: subCpmkButtonColor,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Expanded(
                                              child: ElevatedButton.icon(
                                                onPressed: () => _showRPSGrid(mk),
                                                icon: const Icon(Icons.edit, size: 16),
                                                label: const Text('Input RPS'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: rpsButtonColor,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRPSGrid(Matakuliah matakuliah) async {
    await _loadRPSData(matakuliah.id!);

    if (!mounted) return;

    final rpsDetailList = _rpsCache[matakuliah.id!] ?? [];
    final cpmks = await _dbHelper.getCPMKByMatakuliah(0);  // Get program-level CPMK from Kelola CPMK
    final subCpmks = await _dbHelper.getSubCPMKByMatakuliah(matakuliah.id!);
    final cpmkMap = {for (var c in cpmks) c.id!: c};
    final subCpmkMap = {for (var sc in subCpmks) sc.id!: sc};
    final cplMap = {for (var cpl in _allCPL) cpl.id!: cpl};

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Input RPS: ${matakuliah.kode} - ${matakuliah.nama}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 16,
            itemBuilder: (context, index) {
              final mingguKe = index + 1;
              final existing = rpsDetailList.firstWhere(
                (r) => r.mingguKe == mingguKe,
                orElse: () => RPSDetail(
                  matakuliahId: matakuliah.id!,
                  mingguKe: mingguKe,
                  createdAt: DateTime.now(),
                ),
              );
              final hasData = rpsDetailList.any((r) => r.mingguKe == mingguKe);
              final cpmkDisplay = existing.cpmkIds != null && existing.cpmkIds!.isNotEmpty
                  ? existing.cpmkIds!
                      .map((id) => cpmkMap[id]?.kodeCPMK ?? 'N/A')
                      .join(', ')
                  : '-';
              final subCpmkDisplay = existing.subCpmkIds != null && existing.subCpmkIds!.isNotEmpty
                  ? existing.subCpmkIds!
                      .map((id) => subCpmkMap[id]?.kodeSubCPMK ?? 'N/A')
                      .join(', ')
                  : '-';
              final cplDisplay = existing.cplIds != null && existing.cplIds!.isNotEmpty
                  ? existing.cplIds!
                      .map((id) => cplMap[id]?.kodeCPL ?? 'N/A')
                      .join(', ')
                  : '-';

              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: hasData ? AppColors.secondary : AppColors.primary.withOpacity(0.2),
                      width: hasData ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    title: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Center(
                            child: Text(
                              'M$mingguKe',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.secondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Minggu Ke-$mingguKe',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              if (hasData)
                                Text(
                                  existing.topik ?? 'Belum ada topik',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.subtleText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              else
                                Text(
                                  'Belum ada data',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    subtitle: hasData
                        ? Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (existing.metodeAjar != null && existing.metodeAjar!.isNotEmpty)
                                  Text(
                                    '📚 ${existing.metodeAjar}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.subtleText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: AppSpacing.xs),
                                if (existing.bobot != null)
                                  Text(
                                    '⚖️ Bobot: ${existing.bobot}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '✓ CPL: $cplDisplay',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '✓ CPMK: $cpmkDisplay',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '✓ Sub CPMK: $subCpmkDisplay',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.secondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          )
                        : null,
                    trailing: ElevatedButton.icon(
                      onPressed: () async {
                        _rpsCache.remove(matakuliah.id);
                        await _addOrEditRPSWeek(
                          mingguKe,
                          matakuliah.id!,
                          cpmks: cpmks,
                          subCpmks: subCpmks,
                          existing: hasData ? existing : null,
                        );
                        // After dialog closes, close grid and reopen to refresh
                        if (mounted) {
                          Navigator.pop(context);
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (mounted) {
                            _showRPSGrid(matakuliah);
                          }
                        }
                      },
                      icon: Icon(hasData ? Icons.edit : Icons.add, size: 16),
                      label: Text(hasData ? 'Edit' : 'Tambah'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class RPSEditDialog extends StatefulWidget {
  final int mingguKe;
  final int matakuliahId;
  final List<CPMK> cpmkList;
  final List<SubCPMK> subCpmkList;
  final List<CPLMaster> cplList;
  final RPSDetail? existing;
  final Future<void> Function(RPSDetail, Map<int, double>) onSave;

  const RPSEditDialog({
    super.key,
    required this.mingguKe,
    required this.matakuliahId,
    required this.cpmkList,
    required this.subCpmkList,
    required this.cplList,
    this.existing,
    required this.onSave,
  });

  @override
  State<RPSEditDialog> createState() => _RPSEditDialogState();
}

class _RPSEditDialogState extends State<RPSEditDialog> {
  late TextEditingController _topikController;
  late TextEditingController _bobotController;
  late TextEditingController _bobotUTSController;
  late TextEditingController _bobotUASController;
  String? _selectedLearningMethod;
  String? _selectedAssessmentType;
  List<int> _selectedCPMKIds = []; // CPMK Program Studi
  List<int> _selectedSubCPMKIds = []; // Sub CPMK dari Kelola CPMK
  List<int> _selectedCPLIds = [];
  bool _isUTS = false;
  bool _isUAS = false;
  
  // Map untuk menyimpan bobot UTS/UAS per SubCPMK: {subCpmkId: bobot}
  Map<int, double> _assessmentBobotMap = {};
  
  // TextEditingController untuk setiap SubCPMK
  final Map<int, TextEditingController> _bobotControllers = {};

  final List<String> _learningMethods = [
    'Case Based Learning',
    'Project Based Learning',
    'Small Group Discussion',
    'Discovery Learning',
    'Contextual Learning',
    'Contextual Instruction',
    'Cooperative Learning',
    'Collaborative Learning',
  ];

  final List<String> _assessmentTypes = [
    'Aktifitas Partisipatif',
    'Hasil Proyek',
    'Kuis',
    'Tugas',
    'UTS',
    'UAS',
  ];

  @override
  void initState() {
    super.initState();
    _topikController = TextEditingController(text: widget.existing?.topik ?? '');
    _bobotController = TextEditingController(text: widget.existing?.bobot?.toString() ?? '');
    _bobotUTSController = TextEditingController(text: widget.existing?.bobot?.toString() ?? '');
    _bobotUASController = TextEditingController(text: widget.existing?.bobot?.toString() ?? '');
    _selectedLearningMethod = widget.existing?.metodeAjar;
    _selectedAssessmentType = widget.existing?.jenisNilai;
    _selectedCPMKIds = List.from(widget.existing?.cpmkIds ?? []);
    _selectedSubCPMKIds = List.from(widget.existing?.subCpmkIds ?? []);
    _selectedCPLIds = List.from(widget.existing?.cplIds ?? []);
    
    // Detect UTS/UAS berdasarkan minggu dan assessment type
    _updateUTSUASFlags();
    
    // Load bobot per SubCPMK jika ada dari editing
    _loadAssessmentBobot();
  }
  
  void _updateUTSUASFlags() {
    setState(() {
      _isUTS = widget.mingguKe == 8 && _selectedAssessmentType == 'UTS';
      _isUAS = widget.mingguKe == 16 && _selectedAssessmentType == 'UAS';
    });
  }
  
  Future<void> _loadAssessmentBobot() async {
    // Load bobot per SubCPMK dari database jika edit existing
    if (widget.existing?.id != null) {
      try {
        final dbHelper = DatabaseHelper();
        final result = await dbHelper.getRPSDetailSubCPMKBobot(widget.existing!.id!);
        if (result.isNotEmpty) {
          setState(() {
            _assessmentBobotMap = {
              for (var row in result) 
                row['sub_cpmk_id'] as int: (row['bobot'] as num).toDouble()
            };
            
            // Update atau create controllers dengan nilai yang dimuat dari database
            for (final subCpmk in widget.subCpmkList) {
              final currentBobot = _assessmentBobotMap[subCpmk.id!] ?? 0.0;
              
              if (_bobotControllers.containsKey(subCpmk.id!)) {
                // Update controller yang sudah ada
                _bobotControllers[subCpmk.id!]!.text = currentBobot > 0 ? currentBobot.toString() : '';
              } else {
                // Buat controller baru
                _bobotControllers[subCpmk.id!] = TextEditingController(
                  text: currentBobot > 0 ? currentBobot.toString() : '',
                );
              }
            }
          });
        } else {
          // Jika tidak ada data dari database, tetap inisialisasi controllers
          setState(() {
            for (final subCpmk in widget.subCpmkList) {
              if (!_bobotControllers.containsKey(subCpmk.id!)) {
                _bobotControllers[subCpmk.id!] = TextEditingController();
              }
            }
          });
        }
      } catch (e) {
        print('DEBUG: Error loading assessment bobot: $e');
        // Inisialisasi controllers meski error
        setState(() {
          for (final subCpmk in widget.subCpmkList) {
            if (!_bobotControllers.containsKey(subCpmk.id!)) {
              _bobotControllers[subCpmk.id!] = TextEditingController();
            }
          }
        });
      }
    } else {
      // Untuk data baru, langsung inisialisasi controllers
      setState(() {
        for (final subCpmk in widget.subCpmkList) {
          if (!_bobotControllers.containsKey(subCpmk.id!)) {
            _bobotControllers[subCpmk.id!] = TextEditingController();
          }
        }
      });
    }
  }
  
  Widget _buildAssessmentBobotTable() {
    final assessmentName = _isUTS ? 'UTS (Minggu 8)' : (_isUAS ? 'UAS (Minggu 16)' : '');
    final subCpmkList = widget.subCpmkList;
    
    if (subCpmkList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text(
          'Belum ada Sub CPMK. Tambahkan melalui Kelola CPMK terlebih dahulu.',
          style: TextStyle(color: AppColors.danger, fontStyle: FontStyle.italic),
        ),
      );
    }
    
    double totalBobot = _assessmentBobotMap.values.fold(0, (sum, val) => sum + val);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Konfigurasi Bobot $assessmentName per Sub CPMK',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.md),
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Row(
            children: [
              const Expanded(flex: 2, child: Text('Sub CPMK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Expanded(
                flex: 2,
                child: Text('Bobot %', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Table rows
        ...subCpmkList.map((subCpmk) {
          // Ensure controller exists
          if (!_bobotControllers.containsKey(subCpmk.id!)) {
            _bobotControllers[subCpmk.id!] = TextEditingController();
          }
          
          final controller = _bobotControllers[subCpmk.id!]!;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(subCpmk.kodeSubCPMK, style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                    onChanged: (value) {
                      setState(() {
                        if (value.isEmpty) {
                          _assessmentBobotMap.remove(subCpmk.id!);
                          _selectedSubCPMKIds.remove(subCpmk.id);
                        } else {
                          final bobot = double.tryParse(value) ?? 0;
                          _assessmentBobotMap[subCpmk.id!] = bobot;
                          
                          // Auto-add SubCPMK if bobot > 0, remove if bobot = 0
                          if (bobot > 0 && !_selectedSubCPMKIds.contains(subCpmk.id!)) {
                            _selectedSubCPMKIds.add(subCpmk.id!);
                          } else if (bobot == 0 && _selectedSubCPMKIds.contains(subCpmk.id!)) {
                            _selectedSubCPMKIds.remove(subCpmk.id);
                          }
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: AppSpacing.md),
        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text('Total: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$totalBobot %',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _topikController.dispose();
    _bobotController.dispose();
    _bobotUTSController.dispose();
    _bobotUASController.dispose();
    
    // Dispose all bobot controllers untuk SubCPMK
    for (final controller in _bobotControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }

  Future<void> _save() async {
    print('DEBUG: Method _save() dipanggil');
    print('DEBUG: _isUTS=$_isUTS, _isUAS=$_isUAS');
    print('DEBUG: _topikController.text="${_topikController.text}"');
    
    if (!_isUTS && !_isUAS && _topikController.text.isEmpty) {
      print('DEBUG: Validasi gagal - topik kosong dan bukan UTS/UAS');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Topik pembelajaran harus diisi')),
      );
      return;
    }

    // Validasi bobot UTS/UAS (tidak wajib 100%, karena 100% adalah total minggu 1-16)
    if ((_isUTS || _isUAS) && _assessmentBobotMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal ada satu Sub CPMK yang harus diisi bobotnya'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double? bobot;
    if (_isUTS || _isUAS) {
      // Untuk UTS/UAS, gunakan total bobot dari tabel
      bobot = _assessmentBobotMap.values.fold<double>(0, (sum, val) => sum + val);
    } else {
      if (_bobotController.text.isNotEmpty) {
        bobot = double.tryParse(_bobotController.text);
      }
    }

    print('DEBUG: Data yang akan disimpan:');
    print('  - mingguKe: ${widget.mingguKe}');
    print('  - topik: ${_topikController.text}');
    print('  - metodeAjar: $_selectedLearningMethod');
    print('  - jenisNilai: $_selectedAssessmentType');
    print('  - bobot: $bobot');
    print('  - cpmkIds: $_selectedCPMKIds');
    print('  - subCpmkIds: $_selectedSubCPMKIds');
    print('  - cplIds: $_selectedCPLIds');

    final rpsDetail = RPSDetail(
      id: widget.existing?.id,
      matakuliahId: widget.matakuliahId,
      mingguKe: widget.mingguKe,
      topik: _topikController.text.isEmpty ? null : _topikController.text,
      metodeAjar: _selectedLearningMethod,
      jenisNilai: _selectedAssessmentType,
      bobot: bobot,
      cpmkIds: _selectedCPMKIds.isNotEmpty ? _selectedCPMKIds : null,
      subCpmkIds: _selectedSubCPMKIds.isNotEmpty ? _selectedSubCPMKIds : null,
      cplIds: _selectedCPLIds.isNotEmpty ? _selectedCPLIds : null,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      print('DEBUG: Memanggil onSave callback');
      await widget.onSave(rpsDetail, _assessmentBobotMap);
      
      if (mounted) {
        print('DEBUG: Menutup dialog');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        print('DEBUG: Error di onSave callback: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isUTS
            ? 'Input UTS (Minggu Ke-8)'
            : _isUAS
                ? 'Input UAS (Minggu Ke-16)'
                : 'Input RPS Minggu Ke-${widget.mingguKe}',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ⚠️ Info banner jika update data
            if (widget.existing != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[300]!),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[700], size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Klik "Simpan" untuk mengganti data minggu ini di database',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Topik Pembelajaran (hanya untuk minggu normal, bukan UTS/UAS)
            if (!_isUTS && !_isUAS) ...[
              const Text(
                'Topik Pembelajaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _topikController,
                decoration: InputDecoration(
                  hintText: 'Masukkan topik pembelajaran...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Metode Pembelajaran (hanya untuk minggu normal)
              const Text(
                'Metode Pembelajaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: _learningMethods.map((method) {
                  final isSelected = _selectedLearningMethod == method;
                  return FilterChip(
                    label: Text(method),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedLearningMethod = selected ? method : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            
            // Jenis Penilaian (untuk semua minggu)
            if (widget.mingguKe == 8)
              const Text(
                'Jenis Penilaian (UTS)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              )
            else if (widget.mingguKe == 16)
              const Text(
                'Jenis Penilaian (UAS)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              )
            else
              const Text(
                'Jenis Penilaian',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: _assessmentTypes.map((type) {
                // Filter assessment types based on minggu
                bool canSelect = true;
                if (widget.mingguKe == 8) {
                  canSelect = type == 'UTS';
                } else if (widget.mingguKe == 16) {
                  canSelect = type == 'UAS';
                }
                
                if (!canSelect) {
                  return SizedBox.shrink();
                }
                
                final isSelected = _selectedAssessmentType == type;
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedAssessmentType = selected ? type : null;
                      _updateUTSUASFlags();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Bobot atau Tabel Bobot Assessment
            if (_isUTS || _isUAS) ...[
              _buildAssessmentBobotTable(),
            ] else ...[
              const Text(
                'Bobot (%)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _bobotController,
                decoration: InputDecoration(
                  hintText: 'Masukkan bobot (0-100)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            
            // CPL
            const Text(
              'Pilih CPL',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: widget.cplList.map((cpl) {
                final isSelected = _selectedCPLIds.contains(cpl.id);
                return FilterChip(
                  label: Text(cpl.kodeCPL),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCPLIds.add(cpl.id!);
                      } else {
                        _selectedCPLIds.remove(cpl.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // CPMK
            const Text(
              'Pilih CPMK Program Studi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (widget.cpmkList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Belum ada CPMK.',
                  style: TextStyle(color: AppColors.subtleText, fontStyle: FontStyle.italic),
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: widget.cpmkList.map((cpmk) {
                  final isSelected = _selectedCPMKIds.contains(cpmk.id);
                  return Tooltip(
                    message: cpmk.deskripsi,
                    child: FilterChip(
                      label: Text(cpmk.kodeCPMK),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCPMKIds.add(cpmk.id!);
                          } else {
                            _selectedCPMKIds.remove(cpmk.id);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.lg),
            
            // Sub CPMK
            const Text(
              'Pilih Sub CPMK',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (widget.subCpmkList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Belum ada Sub CPMK. Tambahkan melalui Kelola CPMK terlebih dahulu.',
                  style: TextStyle(color: AppColors.danger, fontStyle: FontStyle.italic),
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: widget.subCpmkList.map((subCpmk) {
                  final isSelected = _selectedSubCPMKIds.contains(subCpmk.id);
                  return Tooltip(
                    message: subCpmk.deskripsi,
                    child: FilterChip(
                      label: Text(subCpmk.kodeSubCPMK),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSubCPMKIds.add(subCpmk.id!);
                          } else {
                            _selectedSubCPMKIds.remove(subCpmk.id);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          label: const Text('Batal'),
        ),
        ElevatedButton.icon(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
          icon: const Icon(Icons.save),
          label: const Text(
            'Simpan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
