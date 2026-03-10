import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/mahasiswa_model.dart';
import '../services/database_helper.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/import_dialog.dart';

class MahasiswaListScreen extends StatefulWidget {
  const MahasiswaListScreen({super.key});

  @override
  State<MahasiswaListScreen> createState() => _MahasiswaListScreenState();
}

class _MahasiswaListScreenState extends State<MahasiswaListScreen> {
  final _dbHelper = DatabaseHelper();
  late Future<List<Mahasiswa>> _mahasiswaList;
  final _searchController = TextEditingController();
  int? _displayLimit = 10; // null = show all
  String _sortBy = 'nim'; // nim or tahun
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadMahasiswa();
  }

  void _loadMahasiswa() {
    setState(() {
      _mahasiswaList = _dbHelper.getAllMahasiswa();
    });
  }

  Future<void> _deleteMahasiswa(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus data mahasiswa ini?'),
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
      await _dbHelper.deleteMahasiswa(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.successDeleted)),
        );
        _loadMahasiswa();
      }
    }
  }

  Future<void> _deleteAllMahasiswa() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus Semua'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus SEMUA data mahasiswa? Tindakan ini tidak dapat dibatalkan.',
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
      await _dbHelper.deleteAllMahasiswa();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua data mahasiswa telah dihapus'),
            backgroundColor: AppColors.danger,
          ),
        );
        _loadMahasiswa();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Mahasiswa'),
        backgroundColor: const Color(0xFF8E44AD),
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
                  '/mahasiswa_template_import',
                );
              } else if (value == 'classic') {
                showDialog(
                  context: context,
                  builder: (context) => ImportDialog(
                    importType: 'mahasiswa',
                    onImportSuccess: (result) {
                      _loadMahasiswa();
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
            onPressed: _deleteAllMahasiswa,
          ),
        ],
      ),
      body: Column(
        children: [
          // Table
          Expanded(
            child: FutureBuilder<List<Mahasiswa>>(
              future: _mahasiswaList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                if (snapshot.hasError) {
                  return CustomErrorWidget(
                    message: 'Error: ${snapshot.error}',
                    onRetry: _loadMahasiswa,
                  );
                }

                final mahasiswaList = snapshot.data ?? [];

                // Filter based on search
                // Filter berdasarkan pencarian di NIM, Nama, atau Tahun
                final searchText = _searchController.text.toLowerCase();
                final filtered = mahasiswaList
                    .where((m) =>
                        searchText.isEmpty ||
                        m.nim.toLowerCase().contains(searchText) ||
                        m.nama.toLowerCase().contains(searchText) ||
                        m.tahunMasuk.toString().contains(searchText))
                    .toList();

                // Apply sorting
                final sorted = List<Mahasiswa>.from(filtered);
                if (_sortBy == 'nim') {
                  sorted.sort((a, b) => _sortAscending
                      ? a.nim.compareTo(b.nim)
                      : b.nim.compareTo(a.nim));
                } else if (_sortBy == 'tahun') {
                  sorted.sort((a, b) => _sortAscending
                      ? a.tahunMasuk.compareTo(b.tahunMasuk)
                      : b.tahunMasuk.compareTo(a.tahunMasuk));
                }

                // Apply display limit
                final displayedData = _displayLimit == null
                    ? sorted
                    : sorted.take(_displayLimit!).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    message: 'Tidak ada data mahasiswa',
                    icon: Icons.person_search,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isSmallScreen = screenWidth < 800;
                    
                    return Column(
                      children: [
                        // Filter and Display Options
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Filters Row
                              if (isSmallScreen)
                                  Column(
                                    children: [
                                      // Search Filter (unified)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                        child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText: 'Cari NIM, Nama, atau Tahun...',
                                            prefixIcon: const Icon(Icons.search, size: 18),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(AppRadius.sm),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: AppSpacing.sm,
                                            ),
                                            isDense: true,
                                          ),
                                          onChanged: (_) {
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      // Total Count and Display Limit (vertical on small screens)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppSpacing.md,
                                                vertical: AppSpacing.md,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                                border: Border.all(color: AppColors.primary, width: 1),
                                              ),
                                              child: Text(
                                                'Total: ${mahasiswaList.length}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                                                  child: const Text('10'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 100,
                                                  child: const Text('100'),
                                                ),
                                                DropdownMenuItem(
                                                  value: null,
                                                  child: const Text('Semua'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  _displayLimit = value;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          // Sort By Dropdown
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: AppColors.primary),
                                              borderRadius: BorderRadius.circular(AppRadius.sm),
                                            ),
                                            child: DropdownButton<String>(
                                              value: _sortBy,
                                              underline: const SizedBox.shrink(),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'nim',
                                                  child: Text('Sort: NIM'),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'tahun',
                                                  child: Text('Sort: Tahun'),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  _sortBy = value ?? 'nim';
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          // Sort Direction Toggle
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: AppColors.primary),
                                              borderRadius: BorderRadius.circular(AppRadius.sm),
                                            ),
                                            child: PopupMenuButton<bool>(
                                              onSelected: (ascending) {
                                                setState(() {
                                                  _sortAscending = ascending;
                                                });
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: true,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.arrow_upward,
                                                        size: 16,
                                                        color: _sortAscending
                                                            ? AppColors.secondary
                                                            : Colors.grey,
                                                      ),
                                                      const SizedBox(width: AppSpacing.sm),
                                                      const Text('Ascending'),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: false,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.arrow_downward,
                                                        size: 16,
                                                        color: !_sortAscending
                                                            ? AppColors.secondary
                                                            : Colors.grey,
                                                      ),
                                                      const SizedBox(width: AppSpacing.sm),
                                                      const Text('Descending'),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              child: Icon(
                                                _sortAscending
                                                    ? Icons.arrow_upward
                                                    : Icons.arrow_downward,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        // Search Filter (unified)
                                        SizedBox(
                                          width: 250,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: AppSpacing.md),
                                            child: TextField(
                                              controller: _searchController,
                                              decoration: InputDecoration(
                                                hintText: 'Cari NIM, Nama, atau Tahun...',
                                                prefixIcon: const Icon(Icons.search, size: 18),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(AppRadius.sm),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: AppSpacing.sm,
                                                  vertical: AppSpacing.sm,
                                                ),
                                                isDense: true,
                                              ),
                                              onChanged: (_) {
                                                setState(() {});
                                              },
                                            ),
                                          ),
                                        ),
                                        // Total Count
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.sm,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(AppRadius.sm),
                                            border: Border.all(color: AppColors.primary, width: 1),
                                          ),
                                          child: Text(
                                            'Total: ${mahasiswaList.length}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        // Display Limit Dropdown
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                                                value: 100,
                                                child: const Text('Tampilkan: 100'),
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
                                        const SizedBox(width: AppSpacing.md),
                                        // Sort By Dropdown
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: AppColors.primary),
                                            borderRadius: BorderRadius.circular(AppRadius.sm),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _sortBy,
                                            underline: const SizedBox.shrink(),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'nim',
                                                child: Text('Sort: NIM'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'tahun',
                                                child: Text('Sort: Tahun'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              setState(() {
                                                _sortBy = value ?? 'nim';
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        // Sort Direction Toggle
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: AppColors.primary),
                                            borderRadius: BorderRadius.circular(AppRadius.sm),
                                          ),
                                          child: PopupMenuButton<bool>(
                                            onSelected: (ascending) {
                                              setState(() {
                                                _sortAscending = ascending;
                                              });
                                            },
                                            itemBuilder: (context) => [
                                              PopupMenuItem(
                                                value: true,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.arrow_upward,
                                                      size: 16,
                                                      color: _sortAscending
                                                          ? AppColors.secondary
                                                          : Colors.grey,
                                                    ),
                                                    const SizedBox(width: AppSpacing.sm),
                                                    const Text('Ascending'),
                                                  ],
                                                ),
                                              ),
                                              PopupMenuItem(
                                                value: false,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.arrow_downward,
                                                      size: 16,
                                                      color: !_sortAscending
                                                          ? AppColors.secondary
                                                          : Colors.grey,
                                                    ),
                                                    const SizedBox(width: AppSpacing.sm),
                                                    const Text('Descending'),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            child: Icon(
                                              _sortAscending
                                                  ? Icons.arrow_upward
                                                  : Icons.arrow_downward,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      // Responsive List View
                      Expanded(
                        child: ListView.builder(
                          itemCount: displayedData.length,
                          itemBuilder: (context, index) {
                            final mahasiswa = displayedData[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header dengan NIM dan Status
                                    Row(
                                      children: [
                                        // NIM
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'NIM',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.subtleText,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                mahasiswa.nim,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Status Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: AppSpacing.xs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: mahasiswa.status == 'aktif'
                                                ? AppColors.success.withValues(alpha: 0.2)
                                                : AppColors.warning.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(AppRadius.sm),
                                          ),
                                          child: Text(
                                            mahasiswa.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: mahasiswa.status == 'aktif'
                                                  ? AppColors.success
                                                  : AppColors.warning,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    // Nama
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Nama',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.subtleText,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          mahasiswa.nama,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    // Tahun Masuk
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Tahun Masuk',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.subtleText,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          mahasiswa.tahunMasuk.toString(),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    // Action Buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Tooltip(
                                          message: 'Edit',
                                          child: IconButton(
                                            icon: const Icon(Icons.edit, size: 20),
                                            color: AppColors.secondary,
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/mahasiswa_form',
                                                arguments: mahasiswa,
                                              ).then((_) => _loadMahasiswa());
                                            },
                                          ),
                                        ),
                                        Tooltip(
                                          message: 'Hapus',
                                          child: IconButton(
                                            icon: const Icon(Icons.delete, size: 20),
                                            color: AppColors.danger,
                                            onPressed: () =>
                                                _deleteMahasiswa(mahasiswa.id!),
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
          '/mahasiswa_form',
        ).then((_) => _loadMahasiswa()),
        backgroundColor: AppColors.secondary,
        tooltip: 'Tambah Mahasiswa Baru\n(Atau gunakan tombol "Import Template" untuk import data masal)',
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

// Mahasiswa Form Screen
class MahasiswaFormScreen extends StatefulWidget {
  final Mahasiswa? mahasiswa;

  const MahasiswaFormScreen({
    super.key,
    this.mahasiswa,
  });

  @override
  State<MahasiswaFormScreen> createState() => _MahasiswaFormScreenState();
}

class _MahasiswaFormScreenState extends State<MahasiswaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper();
  late TextEditingController _nimController;
  late TextEditingController _namaController;
  late TextEditingController _tahunMasukController;
  String _selectedStatus = 'aktif';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nimController =
        TextEditingController(text: widget.mahasiswa?.nim ?? '');
    _namaController =
        TextEditingController(text: widget.mahasiswa?.nama ?? '');
    _tahunMasukController = TextEditingController(
        text: widget.mahasiswa?.tahunMasuk.toString() ??
            DateTime.now().year.toString());
    _selectedStatus = widget.mahasiswa?.status ?? 'aktif';
  }

  Future<void> _saveMahasiswa() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final mahasiswa = Mahasiswa(
        id: widget.mahasiswa?.id,
        nim: _nimController.text.trim(),
        nama: _namaController.text.trim(),
        tahunMasuk: int.parse(_tahunMasukController.text),
        status: _selectedStatus,
        createdAt: widget.mahasiswa?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.mahasiswa != null) {
        await _dbHelper.updateMahasiswa(mahasiswa);
      } else {
        await _dbHelper.insertMahasiswa(mahasiswa);
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
        title: Text(widget.mahasiswa == null
            ? 'Tambah Mahasiswa'
            : 'Edit Mahasiswa'),
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
                  label: 'NIM',
                  controller: _nimController,
                  hint: 'Masukkan NIM mahasiswa',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'NIM harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                  label: 'Nama',
                  controller: _namaController,
                  hint: 'Masukkan nama lengkap',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama harus diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomTextField(
                  label: 'Tahun Masuk',
                  controller: _tahunMasukController,
                  hint: DateTime.now().year.toString(),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tahun masuk harus diisi';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Tahun masuk harus berupa angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomDropdown<String>(
                  label: 'Status',
                  value: _selectedStatus,
                  items: AppConstants.statusMahasiswa,
                  itemLabelBuilder: (item) =>
                      item.replaceAll('_', ' ').toUpperCase(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                CustomButton(
                  label: AppStrings.save,
                  isLoading: _isLoading,
                  onPressed: _saveMahasiswa,
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
    _nimController.dispose();
    _namaController.dispose();
    _tahunMasukController.dispose();
    super.dispose();
  }
}
