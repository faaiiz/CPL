import 'package:flutter/material.dart';
import '../models/matakuliah_model.dart';
import '../models/sub_cpmk_model.dart';
import '../services/database_helper.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_widgets.dart';

class SubCPMKManagementScreen extends StatefulWidget {
  final Matakuliah matakuliah;

  const SubCPMKManagementScreen({
    super.key,
    required this.matakuliah,
  });

  @override
  State<SubCPMKManagementScreen> createState() =>
      _SubCPMKManagementScreenState();
}

class _SubCPMKManagementScreenState extends State<SubCPMKManagementScreen> {
  late DatabaseHelper _dbHelper;
  List<SubCPMK> _subCpmkList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dbHelper = DatabaseHelper();
    _loadSubCPMK();
  }

  Future<void> _loadSubCPMK() async {
    setState(() => _isLoading = true);
    try {
      final subCpmks =
          await _dbHelper.getSubCPMKByMatakuliah(widget.matakuliah.id!);
      setState(() => _subCpmkList = subCpmks);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading SUB CPMK: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addOrEditSubCPMK({SubCPMK? existing}) async {
    final result = await showDialog<SubCPMK>(
      context: context,
      builder: (context) => _SubCPMKDialog(
        matakuliah: widget.matakuliah,
        existing: existing,
      ),
    );

    if (result != null) {
      try {
        if (existing != null) {
          await _dbHelper.updateSubCPMK(result);
        } else {
          await _dbHelper.insertSubCPMK(result);
        }
        await _loadSubCPMK();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _deleteSubCPMK(SubCPMK subCpmk) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Hapus SUB CPMK: ${subCpmk.kodeSubCPMK}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteSubCPMK(subCpmk.id!);
        await _loadSubCPMK();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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
        title: Text('SUB CPMK - ${widget.matakuliah.nama}'),
        backgroundColor: const Color(0xFFAF7AC5),
        elevation: 4,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _subCpmkList.isEmpty
              ? EmptyStateWidget(
                  message: 'Belum ada SUB CPMK - Tambahkan Sub CPMK untuk mata kuliah ini dengan tombol di bawah',
                )
              : ListView.builder(
                  padding: EdgeInsets.all(AppSpacing.md),
                  itemCount: _subCpmkList.length,
                  itemBuilder: (context, index) {
                    final subCpmk = _subCpmkList[index];
                    return Card(
                      margin:
                          EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subCpmk.kodeSubCPMK,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(
                                          height:
                                              AppSpacing.sm / 2),
                                      Text(
                                        subCpmk.deskripsi,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _addOrEditSubCPMK(existing: subCpmk);
                                    } else if (value == 'delete') {
                                      _deleteSubCPMK(subCpmk);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Hapus'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditSubCPMK(),
        label: const Text('Tambah SUB CPMK'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class _SubCPMKDialog extends StatefulWidget {
  final Matakuliah matakuliah;
  final SubCPMK? existing;

  const _SubCPMKDialog({
    required this.matakuliah,
    this.existing,
  });

  @override
  State<_SubCPMKDialog> createState() => _SubCPMKDialogState();
}

class _SubCPMKDialogState extends State<_SubCPMKDialog> {
  late TextEditingController _kodeController;
  late TextEditingController _deskripsiController;

  @override
  void initState() {
    super.initState();
    _kodeController = TextEditingController(
      text: widget.existing?.kodeSubCPMK ?? '',
    );
    _deskripsiController = TextEditingController(
      text: widget.existing?.deskripsi ?? '',
    );
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _save() {
    if (_kodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode SUB CPMK tidak boleh kosong')),
      );
      return;
    }
    if (_deskripsiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi tidak boleh kosong')),
      );
      return;
    }

    final subCpmk = SubCPMK(
      id: widget.existing?.id,
      matakuliahId: widget.matakuliah.id!,
      kodeSubCPMK: _kodeController.text.trim(),
      deskripsi: _deskripsiController.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, subCpmk);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing != null ? 'Edit SUB CPMK' : 'Tambah SUB CPMK',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _kodeController,
                decoration: InputDecoration(
                  labelText: 'Kode SUB CPMK',
                  hintText: 'e.g., SUB-CPMK.1',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              TextField(
                controller: _deskripsiController,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Deskripsi SUB CPMK...',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  SizedBox(width: AppSpacing.md),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
