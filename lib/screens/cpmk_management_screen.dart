import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/matakuliah_model.dart';
import '../models/cpmk_model.dart';
import '../services/database_helper.dart';
import '../widgets/custom_widgets.dart';

class CPMKManagementScreen extends StatefulWidget {
  const CPMKManagementScreen({super.key});

  @override
  State<CPMKManagementScreen> createState() => _CPMKManagementScreenState();
}

class _CPMKManagementScreenState extends State<CPMKManagementScreen> {
  final _dbHelper = DatabaseHelper();
  late Future<List<Matakuliah>> _matakuliahList;
  Matakuliah? _selectedMatakuliah;
  List<CPMK> _cpmkList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMatakuliah();
  }

  void _loadMatakuliah() {
    setState(() {
      _matakuliahList = _dbHelper.getAllMatakuliah();
    });
  }

  void _onMatakuliahSelected(Matakuliah matakuliah) async {
    setState(() {
      _selectedMatakuliah = matakuliah;
      _isLoading = true;
    });

    try {
      final cpmks = await _dbHelper.getCPMKByMatakuliah(matakuliah.id!);
      setState(() {
        _cpmkList = cpmks;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showSubCPMKDialog({CPMK? existing}) {
    if (_selectedMatakuliah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    final isEdit = existing != null;
    final deskripsiController = TextEditingController(text: existing?.deskripsi ?? '');
    final screenContext = context; // Simpan context sebelum dialog
    
    final subCPMKList = [
      'Sub CPMK 01', 'Sub CPMK 02', 'Sub CPMK 03', 'Sub CPMK 04',
      'Sub CPMK 05', 'Sub CPMK 06', 'Sub CPMK 07', 'Sub CPMK 08',
      'Sub CPMK 09', 'Sub CPMK 10', 'Sub CPMK 11', 'Sub CPMK 12',
      'Sub CPMK 13', 'Sub CPMK 14',
    ];
    
    String? selectedKode = existing?.kodeCPMK;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit CPMK' : 'Tambah CPMK'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown untuk Kode Sub CPMK
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedKode,
                    hint: const Text('Pilih Kode CPMK...'),
                    underline: const SizedBox.shrink(),
                    items: subCPMKList.map((code) {
                      return DropdownMenuItem(
                        value: code,
                        child: Text(code),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedKode = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // TextField untuk Deskripsi
                TextField(
                  controller: deskripsiController,
                  decoration: InputDecoration(
                    label: const Text('Deskripsi CPMK'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedKode == null || deskripsiController.text.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      const SnackBar(content: Text('Semua field harus diisi')),
                    );
                  }
                  return;
                }

                try {
                  final cpmk = CPMK(
                    id: existing?.id,
                    matakuliahId: _selectedMatakuliah!.id!,
                    kodeCPMK: selectedKode!,
                    deskripsi: deskripsiController.text,
                    createdAt: existing?.createdAt ?? DateTime.now(),
                  );

                  if (isEdit) {
                    await _dbHelper.updateCPMK(cpmk);
                  } else {
                    await _dbHelper.insertCPMK(cpmk);
                  }

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    // Reload data
                    _onMatakuliahSelected(_selectedMatakuliah!);
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'CPMK diperbarui' : 'CPMK ditambahkan'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(screenContext).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Ubah' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSubCPMK(int id) async {
    final screenContext = context;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus Sub CPMK ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteCPMK(id);
        if (mounted) {
          _onMatakuliahSelected(_selectedMatakuliah!);
          ScaffoldMessenger.of(screenContext).showSnackBar(
            const SnackBar(content: Text('CPMK dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(screenContext).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola CPMK'),
        backgroundColor: const Color(0xFF9B59B6),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Mata Kuliah',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FutureBuilder<List<Matakuliah>>(
              future: _matakuliahList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                final matakuliahList = snapshot.data ?? [];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: DropdownButton<Matakuliah>(
                    isExpanded: true,
                    value: _selectedMatakuliah,
                    hint: const Text('Pilih mata kuliah...'),
                    underline: const SizedBox.shrink(),
                    items: matakuliahList.map((mk) {
                      return DropdownMenuItem(
                        value: mk,
                        child: Text('${mk.kode} - ${mk.nama}'),
                      );
                    }).toList(),
                    onChanged: (mk) {
                      if (mk != null) {
                        _onMatakuliahSelected(mk);
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_selectedMatakuliah != null) ...[
              const Text(
                'Daftar CPMK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_isLoading)
                const Expanded(child: LoadingWidget())
              else if (_cpmkList.isEmpty)
                Expanded(
                  child: EmptyStateWidget(
                    message: 'Belum ada Sub CPMK untuk mata kuliah ini',
                    icon: Icons.assignment,
                    onAdd: () => _showSubCPMKDialog(),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _cpmkList.length,
                    itemBuilder: (context, index) {
                      final cpmk = _cpmkList[index];
                      // Extract number dari kode (e.g., "Sub CPMK 01" -> "01")
                      final codeNumber = cpmk.kodeCPMK.split(' ').last;

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(
                            color: AppColors.secondary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          leading: Container(
                            width: 50,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Center(
                              child: Text(
                                codeNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            cpmk.kodeCPMK,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            cpmk.deskripsi,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Text('Edit'),
                                onTap: () => _showSubCPMKDialog(existing: cpmk),
                              ),
                              PopupMenuItem(
                                child: const Text('Hapus'),
                                onTap: () => _deleteSubCPMK(cpmk.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: _selectedMatakuliah != null
          ? FloatingActionButton(
              onPressed: () => _showSubCPMKDialog(),
              backgroundColor: AppColors.secondary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
