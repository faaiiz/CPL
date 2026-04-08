import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../constants/app_constants.dart';
import '../services/excel_import_service.dart';
import '../services/template_service.dart';
import '../services/database_helper.dart';
import '../models/matakuliah_model.dart';
import '../models/nilai_model.dart';

class NilaiDetailImportScreen extends StatefulWidget {
  const NilaiDetailImportScreen({super.key});

  @override
  State<NilaiDetailImportScreen> createState() =>
      _NilaiDetailImportScreenState();
}

class _NilaiDetailImportScreenState extends State<NilaiDetailImportScreen>
    with TickerProviderStateMixin {
  final _excelService = ExcelImportService();
  final _dbHelper = DatabaseHelper();
  late TabController _tabController;

  // TAB: Dashboard
  List<Nilai> _nilaiList = [];
  List<Nilai> _filteredNilaiList = [];
  bool _isDashboardLoading = false;
  int? _dashboardSelectedMatakuliahId;
  String? _dashboardSelectedTahunAjaran;
  final Map<int, dynamic> _mahasiswaCache = {}; // Cache mahasiswa data
  final Map<int, dynamic> _matakuliahCache = {}; // Cache matakuliah data
  List<Matakuliah> _matakuliahForDashboard = [];
  List<String> _tahunAjaranForDashboard = [];

  // Daftar tahun ajaran (Ganjil 2020/2021 - Genap 2030/2031)
  final List<Map<String, String>> tahunAjaranList = [
    {'tahun': '2020/2021', 'semester': 'Ganjil'},
    {'tahun': '2020/2021', 'semester': 'Genap'},
    {'tahun': '2021/2022', 'semester': 'Ganjil'},
    {'tahun': '2021/2022', 'semester': 'Genap'},
    {'tahun': '2022/2023', 'semester': 'Ganjil'},
    {'tahun': '2022/2023', 'semester': 'Genap'},
    {'tahun': '2023/2024', 'semester': 'Ganjil'},
    {'tahun': '2023/2024', 'semester': 'Genap'},
    {'tahun': '2024/2025', 'semester': 'Ganjil'},
    {'tahun': '2024/2025', 'semester': 'Genap'},
    {'tahun': '2025/2026', 'semester': 'Ganjil'},
    {'tahun': '2025/2026', 'semester': 'Genap'},
    {'tahun': '2026/2027', 'semester': 'Ganjil'},
    {'tahun': '2026/2027', 'semester': 'Genap'},
    {'tahun': '2027/2028', 'semester': 'Ganjil'},
    {'tahun': '2027/2028', 'semester': 'Genap'},
    {'tahun': '2028/2029', 'semester': 'Ganjil'},
    {'tahun': '2028/2029', 'semester': 'Genap'},
    {'tahun': '2029/2030', 'semester': 'Ganjil'},
    {'tahun': '2029/2030', 'semester': 'Genap'},
    {'tahun': '2030/2031', 'semester': 'Ganjil'},
    {'tahun': '2030/2031', 'semester': 'Genap'},
  ];

  // Daftar Matakuliah dari database
  List<Matakuliah> _matakuliahList = [];
  
  String? _selectedTahunAjaran;
  String? _selectedSemester;
  String? _selectedMatakuliahId;
  String? _selectedMatakuliahKode;
  String? _selectedFilePath;
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isLoading = false;
  Map<String, dynamic>? _importResult;
  List<String> _importErrors = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Set default: tahun ajaran terbaru
    if (tahunAjaranList.isNotEmpty) {
      _selectedTahunAjaran = tahunAjaranList.last['tahun'];
      _selectedSemester = tahunAjaranList.last['semester'];
    }
    // Load daftar matakuliah dari database
    _loadMatakuliah();
    // Load data untuk dashboard
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatakuliah() async {
    try {
      final matakuliahList = await _dbHelper.getAllMatakuliah();
      setState(() {
        _matakuliahList = matakuliahList;
        _matakuliahForDashboard = matakuliahList;
        // Set default ke matakuliah pertama jika ada
        if (_matakuliahList.isNotEmpty) {
          _selectedMatakuliahId = _matakuliahList.first.id.toString();
          _selectedMatakuliahKode = _matakuliahList.first.kode;
          _dashboardSelectedMatakuliahId = _matakuliahList.first.id;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading matakuliah: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isDashboardLoading = true);
      
      // Load semua nilai dari database
      final nilaiList = await _dbHelper.getAllNilai();
      
      // Pre-load semua mahasiswa ke cache
      final allMahasiswa = await _dbHelper.getAllMahasiswa();
      for (final mhs in allMahasiswa) {
        _mahasiswaCache[mhs.id!] = mhs;
      }
      
      // Pre-load semua matakuliah ke cache
      final allMatakuliah = await _dbHelper.getAllMatakuliah();
      for (final mk in allMatakuliah) {
        _matakuliahCache[mk.id!] = mk;
      }
      
      // Extract unique tahun ajaran
      final tahunAjaranSet = <String>{};
      for (final nilai in nilaiList) {
        tahunAjaranSet.add(nilai.tahunAjaran.toString());
      }
      final tahunAjaranList = tahunAjaranSet.toList()..sort((a, b) => b.compareTo(a));
      
      setState(() {
        _nilaiList = nilaiList;
        _tahunAjaranForDashboard = tahunAjaranList;
        if (tahunAjaranList.isNotEmpty && _dashboardSelectedTahunAjaran == null) {
          _dashboardSelectedTahunAjaran = tahunAjaranList.first;
        }
        _applyDashboardFilters();
      });
    } catch (e) {
      // Error loading dashboard data - continue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDashboardLoading = false);
      }
    }
  }

  void _applyDashboardFilters() {
    _filteredNilaiList = _nilaiList.where((nilai) {
      final matchMatakuliah = _dashboardSelectedMatakuliahId == null ||
          nilai.matakuliahId == _dashboardSelectedMatakuliahId;
      final matchTahunAjaran = _dashboardSelectedTahunAjaran == null ||
          nilai.tahunAjaran.toString() == _dashboardSelectedTahunAjaran;
      return matchMatakuliah && matchTahunAjaran;
    }).toList();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
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

  Future<void> _importData() async {
    if (_selectedFilePath == null && _selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file Excel terlebih dahulu')),
      );
      return;
    }

    if (_selectedTahunAjaran == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tahun ajaran terlebih dahulu')),
      );
      return;
    }

    if (_selectedMatakuliahKode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _excelService.importNilaiDetailFromExcel(
        _selectedFilePath ?? '',
        matakuliahFilter: _selectedMatakuliahKode,
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
                'Import berhasil: ${result['message']}',
              ),
              backgroundColor: AppColors.success,
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      // Validasi pilihan matakuliah
      if (_selectedMatakuliahKode == null || _selectedMatakuliahId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih Mata Kuliah terlebih dahulu'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      // Ambil nama matakuliah dari list
      final selectedMatakuliah = _matakuliahList.firstWhere(
        (mk) => mk.id.toString() == _selectedMatakuliahId,
        orElse: () => _matakuliahList.first,
      );

      // Buat tahun ajaran string
      final tahunAjaranString = '$_selectedTahunAjaran $_selectedSemester';

      final path = await TemplateService.downloadNilaiDetailTemplate(
        kodeMatakuliah: _selectedMatakuliahKode,
        namaMatakuliah: selectedMatakuliah.nama,
        tahunAjaran: tahunAjaranString,
      );

      if (mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Template downloaded: $path'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal download template'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nilai Detail'),
        backgroundColor: const Color(0xFFC0392B),
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.upload_file), text: 'Import'),
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImportTab(),
          _buildDashboardTab(),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    final templateInfo = TemplateService.getTemplateInfo('nilai_detail');
    final columns = templateInfo['columns'] ?? [];

    return SingleChildScrollView(
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
                  'ℹ️ Panduan Import Nilai Detail',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Import nilai detail berdasarkan komponen (Aktivitas, Hasil Proyek, Tugas, Kuis, UTS, UAS) untuk setiap tahun ajaran menggunakan file Excel (.xlsx).',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Sistem akan otomatis menghitung nilai akhir dengan rumus:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Text(
                      'Nilai Akhir = (Aktivitas×10% + Tugas×10% + Hasil Proyek×15% + Kuis×15% + UTS×25% + UAS×25%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Courier',
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Tahun Ajaran Selection
            const Text(
              'Pilih Tahun Ajaran',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTahunAjaran,
                    decoration: InputDecoration(
                      labelText: 'Tahun Ajaran',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    items: tahunAjaranList
                        .map((item) =>
                            DropdownMenuItem(
                              value: item['tahun'],
                              child: Text(item['tahun']!),
                            ))
                        .toList()
                        .fold<List<DropdownMenuItem<String>>>([],
                            (prev, item) {
                      if (prev.isEmpty ||
                          prev.last.value != item.value) {
                        prev.add(item);
                      }
                      return prev;
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTahunAjaran = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSemester,
                    decoration: InputDecoration(
                      labelText: 'Semester',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                      prefixIcon: const Icon(Icons.school),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Ganjil',
                        child: Text('Ganjil'),
                      ),
                      DropdownMenuItem(
                        value: 'Genap',
                        child: Text('Genap'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSemester = value;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Matakuliah Selection
            const Text(
              'Pilih Mata Kuliah',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            DropdownButtonFormField<String>(
              initialValue: _selectedMatakuliahId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Mata Kuliah',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                prefixIcon: const Icon(Icons.book),
              ),
              items: _matakuliahList.map((mk) =>
                DropdownMenuItem<String>(
                  value: mk.id.toString(),
                  child: Text('${mk.kode} - ${mk.nama}'),
                )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMatakuliahId = value;
                  if (value != null) {
                    final selected = _matakuliahList.firstWhere(
                      (mk) => mk.id.toString() == value,
                      orElse: () => _matakuliahList.first,
                    );
                    _selectedMatakuliahKode = selected.kode;
                  }
                });
              },
            ),

            const SizedBox(height: AppSpacing.lg),

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
                    'Format Template Excel:',
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
                          child: Text(
                            col,
                            style: const TextStyle(fontSize: 12),
                          ),
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
                label: const Text('Download Template Excel'),
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
                fontSize: 14,
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
                          _selectedFileBytes = null;
                          _selectedFileName = null;
                          _importResult = null;
                          _importErrors = [];
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
                        'Format: .xlsx (Excel)',
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
              child: ElevatedButton(
                onPressed: _selectedFilePath != null && !_isLoading
                    ? _importData
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedFilePath != null
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
                    : const Text('Import Data'),
              ),
            ),

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

            // Error Log
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
                constraints: const BoxConstraints(maxHeight: 200),
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
                          .take(15)
                          .map(
                            (error) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
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
              if (_importErrors.length > 15)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.md,
                  ),
                  child: Text(
                    'dan ${_importErrors.length - 15} error lainnya...',
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
      );
  }

  Widget _buildDashboardTab() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Data Nilai',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        initialValue: _dashboardSelectedMatakuliahId,
                        decoration: InputDecoration(
                          labelText: 'Mata Kuliah',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          prefixIcon: const Icon(Icons.book),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Semua Mata Kuliah'),
                          ),
                          ..._matakuliahForDashboard.map((mk) =>
                              DropdownMenuItem(
                                value: mk.id,
                                child: Text(mk.nama),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _dashboardSelectedMatakuliahId = value;
                            _applyDashboardFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _dashboardSelectedTahunAjaran,
                        decoration: InputDecoration(
                          labelText: 'Tahun Ajaran',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        items: _tahunAjaranForDashboard
                            .map((ta) => DropdownMenuItem(
                                  value: ta,
                                  child: Text(ta),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _dashboardSelectedTahunAjaran = value;
                            _applyDashboardFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Data Summary
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Nilai',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _filteredNilaiList.length.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rata-rata',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _filteredNilaiList.isEmpty
                              ? '0.0'
                              : (_filteredNilaiList
                                      .fold<double>(
                                        0.0,
                                        (sum, nilai) =>
                                            sum + nilai.nilaiNumerik,
                                      ) /
                                  _filteredNilaiList.length)
                              .toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF27AE60),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Data Table
          const Text(
            'Daftar Nilai',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (_isDashboardLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_filteredNilaiList.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Tidak ada data nilai',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  columns: const [
                    DataColumn(label: Text('No')),
                    DataColumn(label: Text('NIM')),
                    DataColumn(label: Text('Nama Mahasiswa')),
                    DataColumn(label: Text('Matakuliah')),
                    DataColumn(label: Text('Grade'), numeric: true),
                    DataColumn(label: Text('Nilai'), numeric: true),
                    DataColumn(label: Text('T.A'), numeric: true),
                  ],
                  rows: List.generate(
                    _filteredNilaiList.length,
                    (index) {
                      final nilai = _filteredNilaiList[index];
                      final mhs = _mahasiswaCache[nilai.mahasiswaId];
                      final mk = _matakuliahCache[nilai.matakuliahId];
                      
                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(
                            Text(
                              mhs?.nim ?? '-',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              mhs?.nama ?? '-',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DataCell(
                            Text(
                              mk?.kode ?? '-',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          DataCell(
                            Text(
                              nilai.gradeHuruf,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              nilai.nilaiNumerik.toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Color(0xFF3498DB),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              nilai.tahunAjaran.toString(),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


