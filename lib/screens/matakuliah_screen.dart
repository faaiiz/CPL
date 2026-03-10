import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/matakuliah_model.dart';
import '../services/database_helper.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/import_dialog.dart';

class MatakuliahListScreen extends StatefulWidget {
  const MatakuliahListScreen({super.key});

  @override
  State<MatakuliahListScreen> createState() => _MatakuliahListScreenState();
}

class _MatakuliahListScreenState extends State<MatakuliahListScreen> {
  final _dbHelper = DatabaseHelper();
  late Future<List<Matakuliah>> _matakuliahList;
  final _searchController = TextEditingController();
  int? _displayLimit = 10; // null = show all

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

  Future<void> _deleteMatakuliah(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus data matakuliah ini?'),
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
      await _dbHelper.deleteMatakuliah(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.successDeleted)),
        );
        _loadMatakuliah();
      }
    }
  }

  Future<void> _deleteAllMatakuliah() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus Semua'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus SEMUA data matakuliah? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteAllMatakuliah();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua data matakuliah telah dihapus'),
            backgroundColor: AppColors.danger,
          ),
        );
        _loadMatakuliah();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Matakuliah'),
        backgroundColor: const Color(0xFF16A085),
        elevation: 4,
        actions: [
          // Import Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download),
            tooltip: 'Import Data',
            onSelected: (value) {
              if (value == 'template') {
                Navigator.pushNamed(
                  context,
                  '/matakuliah_template_import',
                );
              } else if (value == 'classic') {
                showDialog(
                  context: context,
                  builder: (context) => ImportDialog(
                    importType: 'matakuliah',
                    onImportSuccess: (result) {
                      _loadMatakuliah();
                      Navigator.pop(context);
                    },
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'template',
                child: Row(
                  children: [
                    Icon(Icons.cloud_download, size: 20),
                    SizedBox(width: 12),
                    Text('Import Template\n(Excel/CSV masal)'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'classic',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, size: 20),
                    SizedBox(width: 12),
                    Text('Import Classic\n(Dialog)'),
                  ],
                ),
              ),
            ],
          ),
          // Delete All Button
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Hapus Semua Data',
            onPressed: _deleteAllMatakuliah,
          ),
        ],
      ),
      body: Column(
        children: [
          // Table
          Expanded(
            child: FutureBuilder<List<Matakuliah>>(
              future: _matakuliahList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                if (snapshot.hasError) {
                  return CustomErrorWidget(
                    message: 'Error: ${snapshot.error}',
                    onRetry: _loadMatakuliah,
                  );
                }

                final matakuliahList = snapshot.data ?? [];

                // Apply display limit
                final displayedData = _displayLimit == null
                    ? matakuliahList
                    : matakuliahList.take(_displayLimit!).toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        // Filter Section - Simplified
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                  border: Border.all(color: AppColors.primary),
                                ),
                                child: Text(
                                  'Total: ${matakuliahList.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.primary),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: DropdownButton<int?>(
                                  value: _displayLimit,
                                  underline: const SizedBox.shrink(),
                                  items: [
                                    DropdownMenuItem(
                                      value: 10,
                                      child: const Text('Tampilkan: 10'),
                                    ),
                                    DropdownMenuItem(
                                      value: 25,
                                      child: const Text('Tampilkan: 25'),
                                    ),
                                    DropdownMenuItem(
                                      value: 50,
                                      child: const Text('Tampilkan: 50'),
                                    ),
                                    DropdownMenuItem(
                                      value: null,
                                      child: const Text('Tampilkan: Semua'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _displayLimit = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // List View
                        Expanded(
                          child: displayedData.isEmpty
                              ? EmptyStateWidget(
                                  message: 'Tidak ada data matakuliah',
                                  icon: Icons.library_books,
                                )
                              : ListView.builder(
                                  itemCount: displayedData.length,
                                  itemBuilder: (context, index) {
                                    final mk = displayedData[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Header: Kode, Semester, SKS
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Kode',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: AppColors.subtleText,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      Text(
                                                        mk.kode,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Semester',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: AppColors.subtleText,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: AppSpacing.sm,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary
                                                            .withValues(alpha: 0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        mk.semester,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(width: AppSpacing.md),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'SKS',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: AppColors.subtleText,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: AppSpacing.sm,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.secondary
                                                            .withValues(alpha: 0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        mk.sks.toString(),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.secondary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: AppSpacing.md),
                                            // Nama Matakuliah
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Nama Matakuliah',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.subtleText,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  mk.nama,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: AppSpacing.md),
                                            // Jenis Badge - ALWAYS VISIBLE
                                            Row(
                                              children: [
                                                Chip(
                                                  label: Text(
                                                    mk.jenis.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: mk.jenis.toLowerCase() ==
                                                              'wajib'
                                                          ? AppColors.success
                                                          : AppColors.warning,
                                                    ),
                                                  ),
                                                  backgroundColor: mk.jenis
                                                              .toLowerCase() ==
                                                          'wajib'
                                                      ? AppColors.success
                                                          .withValues(alpha: 0.1)
                                                      : AppColors.warning
                                                          .withValues(alpha: 0.1),
                                                  side: BorderSide(
                                                    color: mk.jenis.toLowerCase() ==
                                                            'wajib'
                                                        ? AppColors.success
                                                        : AppColors.warning,
                                                    width: 1,
                                                  ),
                                                ),
                                                const Spacer(),
                                                // Action Buttons
                                                Tooltip(
                                                  message: 'Edit',
                                                  child: IconButton(
                                                    icon: const Icon(Icons.edit),
                                                    color: AppColors.secondary,
                                                    onPressed: () {
                                                      Navigator.pushNamed(
                                                        context,
                                                        '/matakuliah_form',
                                                        arguments: mk,
                                                      ).then((_) =>
                                                          _loadMatakuliah());
                                                    },
                                                  ),
                                                ),
                                                Tooltip(
                                                  message: 'Hapus',
                                                  child: IconButton(
                                                    icon: const Icon(Icons.delete),
                                                    color: AppColors.danger,
                                                    onPressed: () =>
                                                        _deleteMatakuliah(mk.id!),
                                                  ),
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
                    );
                  },
                );
            },
          ),
        ),

        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(
          context,
          '/matakuliah_form',
        ).then((_) => _loadMatakuliah()),
        backgroundColor: AppColors.secondary,
        tooltip: 'Tambah Matakuliah Baru\n(Atau gunakan tombol "Import Template" untuk import data masal)',
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Matakuliah Form Screen
class MatakuliahFormScreen extends StatefulWidget {
  final Matakuliah? matakuliah;

  const MatakuliahFormScreen({
    super.key,
    this.matakuliah,
  });

  @override
  State<MatakuliahFormScreen> createState() => _MatakuliahFormScreenState();
}

class _MatakuliahFormScreenState extends State<MatakuliahFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  late TextEditingController _kodeController;
  late TextEditingController _namaController;
  late TextEditingController _semesterController;
  late TextEditingController _sksController;
  String _selectedJenis = 'wajib';
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _kodeController =
        TextEditingController(text: widget.matakuliah?.kode ?? '');
    _namaController =
        TextEditingController(text: widget.matakuliah?.nama ?? '');
    _semesterController = TextEditingController(
        text: widget.matakuliah?.semester ?? '1');
    _sksController = TextEditingController(
        text: widget.matakuliah?.sks.toString() ?? '3');
    _selectedJenis = widget.matakuliah?.jenis ?? 'wajib';
    _isActive = widget.matakuliah?.isActive ?? true;
  }

  Future<void> _saveMatakuliah() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final matakuliah = Matakuliah(
        id: widget.matakuliah?.id,
        kode: _kodeController.text.trim(),
        nama: _namaController.text.trim(),
        semester: _semesterController.text.trim(),
        jenis: _selectedJenis,
        sks: int.parse(_sksController.text),
        isActive: _isActive,
        createdAt: widget.matakuliah?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.matakuliah != null) {
        await _dbHelper.updateMatakuliah(matakuliah);
      } else {
        await _dbHelper.insertMatakuliah(matakuliah);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.successSaved)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.matakuliah == null
            ? 'Tambah Matakuliah'
            : 'Edit Matakuliah'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  label: 'Kode Matakuliah',
                  controller: _kodeController,
                  hint: 'Masukkan kode matakuliah',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kode matakuliah harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                  label: 'Nama Matakuliah',
                  controller: _namaController,
                  hint: 'Masukkan nama matakuliah',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama matakuliah harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                  label: 'Semester',
                  controller: _semesterController,
                  hint: '1',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Semester harus diisi';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Semester harus berupa angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                  label: 'SKS (Satuan Kredit Semester)',
                  controller: _sksController,
                  hint: '3',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'SKS harus diisi';
                    }
                    final sks = int.tryParse(value);
                    if (sks == null) {
                      return 'SKS harus berupa angka';
                    }
                    if (sks < 1 || sks > 6) {
                      return 'SKS harus antara 1-6';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomDropdown<String>(
                  label: 'Jenis',
                  value: _selectedJenis,
                  items: const ['wajib', 'pilihan'],
                  itemLabelBuilder: (item) =>
                      item.replaceAll('_', ' ').toUpperCase(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedJenis = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Status Aktif',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() => _isActive = value);
                      },
                      activeThumbColor: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomButton(
                  label: AppStrings.save,
                  isLoading: _isLoading,
                  onPressed: _saveMatakuliah,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _semesterController.dispose();
    _sksController.dispose();
    super.dispose();
  }
}
