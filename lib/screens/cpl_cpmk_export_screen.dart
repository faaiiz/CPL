import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/obe_calculation_helper.dart';
import '../services/cpl_cpmk_pdf_generator.dart';
import '../models/matakuliah_model.dart';
import '../models/mahasiswa_model.dart';
import '../models/nilai_model.dart';

class CPLCPMKExportScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const CPLCPMKExportScreen({
    Key? key,
    required this.dbHelper,
  }) : super(key: key);

  @override
  State<CPLCPMKExportScreen> createState() => _CPLCPMKExportScreenState();
}

class _CPLCPMKExportScreenState extends State<CPLCPMKExportScreen>
    with SingleTickerProviderStateMixin {
  late DatabaseHelper _dbHelper;
  late OBECalculationHelper _obeHelper;
  late TabController _tabController;

  // Common data
  List<Matakuliah> _matakuliahList = [];
  List<String> _tahunAjaranList = [];
  List<int> _angkatanList = [];
  List<Mahasiswa> _allMahasiswa = [];
  List<Mahasiswa> _filteredMahasiswa = [];
  
  // Tab 1: Export per mata kuliah
  Matakuliah? _selectedMatakuliah;
  String? _selectedTahunAjaran;
  
  // Tab 2: Export per mahasiswa
  int? _selectedAngkatan2;
  Mahasiswa? _selectedMahasiswa;
  
  // Tab 3: Export per angkatan
  int? _selectedAngkatan3;
  
  bool _isLoading = true;
  bool _isExporting = false;

  // Daftar tahun ajaran yang tersedia
  final List<String> _availableTahunAjaran = [
    '2020/2021',
    '2021/2022',
    '2022/2023',
    '2023/2024',
    '2024/2025',
    '2025/2026',
    '2026/2027',
    '2027/2028',
    '2028/2029',
    '2029/2030',
    '2030/2031',
  ];

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.dbHelper;
    _obeHelper = OBECalculationHelper(dbHelper: _dbHelper);
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load common data in parallel
      final matakuliahFuture = _dbHelper.getAllMatakuliah();
      final mahasiswaFuture = _dbHelper.getAllMahasiswa();
      final nilaiListFuture = _dbHelper.getAllNilai();

      final results = await Future.wait([
        matakuliahFuture,
        mahasiswaFuture,
        nilaiListFuture,
      ]);

      final matakuliahList = (results[0] as List<dynamic>).cast<Matakuliah>();
      final mahasiswaList = (results[1] as List<dynamic>).cast<Mahasiswa>();
      final nilaiList = (results[2] as List<dynamic>).cast<Nilai>();

      // Get available academic years
      final tahunAjaranSet = <String>{};
      for (final nilai in nilaiList) {
        tahunAjaranSet.add(nilai.tahunAjaran.toString());
      }

      var tahunAjaranList = tahunAjaranSet.toList()..sort((a, b) => b.compareTo(a));

      // If no years in database, use predefined list
      if (tahunAjaranList.isEmpty) {
        tahunAjaranList = _availableTahunAjaran.toList()..sort((a, b) => b.compareTo(a));
      }

      // Get available years cohort (tahun angkatan)
      final angkatanSet = <int>{};
      for (final mhs in mahasiswaList) {
        angkatanSet.add(mhs.tahunMasuk);
      }
      final angkatanList = angkatanSet.toList()..sort((a, b) => b.compareTo(a));

      setState(() {
        _matakuliahList = matakuliahList.where((mk) => mk.id != null).toList();
        _tahunAjaranList = tahunAjaranList;
        _allMahasiswa = mahasiswaList;
        _angkatanList = angkatanList;
        
        // Auto-select first items for Tab 1
        if (_matakuliahList.isNotEmpty) {
          _selectedMatakuliah = _matakuliahList.first;
        }
        if (_tahunAjaranList.isNotEmpty) {
          _selectedTahunAjaran = _tahunAjaranList.first;
        }
        
        // Auto-select first angkatan for Tab 2 and 3
        if (_angkatanList.isNotEmpty) {
          _selectedAngkatan2 = _angkatanList.first;
          _selectedAngkatan3 = _angkatanList.first;
          _filterMahasiswaByAngkatan(_selectedAngkatan2!);
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterMahasiswaByAngkatan(int angkatan) {
    final filtered = _allMahasiswa
        .where((mhs) => mhs.tahunMasuk == angkatan)
        .toList()
      ..sort((a, b) => a.nim.compareTo(b.nim));

    setState(() {
      _filteredMahasiswa = filtered;
    });
  }

  Future<void> _exportReport() async {
    if (_selectedMatakuliah == null || _selectedTahunAjaran == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih mata kuliah dan tahun ajaran terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isExporting = true);

      final matakuliahId = _selectedMatakuliah!.id!;
      final tahunAjaranStr = _selectedTahunAjaran!;
      
      // Extract year from tahun ajaran (e.g., "2020/2021" -> 2020)
      final tahunAjaranInt = int.tryParse(tahunAjaranStr.split('/').first) ?? 2024;

      // Show progress
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sedang membuat laporan PDF...'),
          duration: Duration(seconds: 10),
        ),
      );

      // Load course data
      final matakuliah = _selectedMatakuliah!;

      // Load all nilai records for this course and year
      final allNilai = await _dbHelper.getAllNilai();
      final nilaiForThisCourse = allNilai
          .where((nilai) =>
              nilai.matakuliahId == matakuliahId &&
              nilai.tahunAjaran == tahunAjaranInt)
          .toList();

      print('[Export] Found ${nilaiForThisCourse.length} nilai records for course/year');

      if (nilaiForThisCourse.isEmpty) {
        throw Exception('Tidak ada data nilai untuk diunduh. '
            'Silakan pastikan ada data nilai untuk mata kuliah dan tahun ajaran ini.');
      }

      // Get unique mahasiswa IDs from nilai records
      final mahasiswaIds = nilaiForThisCourse
          .map((nilai) => nilai.mahasiswaId)
          .toSet()
          .toList();

      // Load mahasiswa data
      final allMahasiswa = await _dbHelper.getAllMahasiswa();
      final mahasiswaList = allMahasiswa
          .where((mhs) => mhs.id != null && mahasiswaIds.contains(mhs.id))
          .toList();

      print('[Export] Found ${mahasiswaList.length} mahasiswa');

      if (mahasiswaList.isEmpty) {
        throw Exception(
            'Tidak ada data mahasiswa untuk diunduh.');
      }

      // Load CPMK and CPL
      final cpmkList = await _dbHelper.getCPMKByMatakuliah(matakuliahId);
      final cplList = await _dbHelper.getAllCPLMaster();

      // Load bobot maps (needed for calculation)
      print('[Export] Loading bobot maps for calculation...');
      final subCpmkBobotMap = <String, Map<String, double>>{};
      final cpmkSubCpmkMap = <String, Map<String, double>>{};
      final cplCpmkMap = <String, Map<String, double>>{};

      // Get RPS details for this course to load bobot
      final rpsDetails = await _dbHelper.getRPSDetailByMatakuliah(matakuliahId);
      print('[Export] Found ${rpsDetails.length} RPS details');

      // Build bobot maps from RPS
      for (final rps in rpsDetails) {
        if (rps.subCpmkIds != null && rps.subCpmkIds!.isNotEmpty) {
          // Load bobot for each Sub-CPMK
          for (final subCpmkId in rps.subCpmkIds!) {
            final bobot = await _dbHelper.getRPSDetailSubCPMKBobot(rps.id ?? 0);
            if (bobot.isNotEmpty) {
              // Get jenis_penilaian bobot
              final bobotMap = <String, double>{};
              if (rps.bobot != null && rps.bobot! > 0) {
                // Distribute bobot across components proportionally
                bobotMap['aktivitas'] = (rps.bobot ?? 0) * 0.2;
                bobotMap['proyek'] = (rps.bobot ?? 0) * 0.3;
                bobotMap['kuis'] = (rps.bobot ?? 0) * 0.15;
                bobotMap['tugas'] = (rps.bobot ?? 0) * 0.15;
                bobotMap['uts'] = (rps.bobot ?? 0) * 0.1;
                bobotMap['uas'] = (rps.bobot ?? 0) * 0.1;
              }
              if (bobotMap.isNotEmpty) {
                subCpmkBobotMap[subCpmkId.toString()] = bobotMap;
              }
            }
          }
        }

        // Build CPMK-SubCPMK map
        if (rps.cpmkIds != null && rps.cpmkIds!.isNotEmpty) {
          for (final cpmkId in rps.cpmkIds!) {
            if (!cpmkSubCpmkMap.containsKey(cpmkId.toString())) {
              cpmkSubCpmkMap[cpmkId.toString()] = {};
            }
            if (rps.subCpmkIds != null) {
              for (final subCpmkId in rps.subCpmkIds!) {
                cpmkSubCpmkMap[cpmkId.toString()]![subCpmkId.toString()] =
                    (rps.bobot ?? 14.29); // Distribute equally
              }
            }
          }
        }

        // Build CPL-CPMK map
        if (rps.cplIds != null && rps.cplIds!.isNotEmpty) {
          for (final cplId in rps.cplIds!) {
            if (!cplCpmkMap.containsKey(cplId.toString())) {
              cplCpmkMap[cplId.toString()] = {};
            }
            if (rps.cpmkIds != null) {
              for (final cpmkId in rps.cpmkIds!) {
                cplCpmkMap[cplId.toString()]![cpmkId.toString()] =
                    (100.0 / (rps.cpmkIds!.length)); // Distribute equally
              }
            }
          }
        }
      }

      print('[Export] Sub-CPMK bobot map entries: ${subCpmkBobotMap.length}');
      print('[Export] CPMK-SubCPMK map entries: ${cpmkSubCpmkMap.length}');
      print('[Export] CPL-CPMK map entries: ${cplCpmkMap.length}');

      final calculationResults = <int, OBECalculationResult>{};

      // Calculate OBE for each student
      for (final mahasiswa in mahasiswaList) {
        if (mahasiswa.id == null) continue;

        try {
          // Load nilai_komponen for this student
          final nilaiKomponen = await _dbHelper.getNilaiKomponen(
            mahasiswaId: mahasiswa.id!,
            matakuliahId: matakuliahId,
            tahunAjaran: tahunAjaranInt,
          );

          if (nilaiKomponen == null) {
            print('[Export] No nilai_komponen for mahasiswa ${mahasiswa.id}');
            continue;
          }

          // Convert to Map<String, double> - database returns keys with underscores
          final nilaiMap = <String, double>{
            'aktivitas': ((nilaiKomponen['nilai_aktivitas'] ?? 0) as num).toDouble(),
            'proyek': ((nilaiKomponen['nilai_proyek'] ?? 0) as num).toDouble(),
            'kuis': ((nilaiKomponen['nilai_kuis'] ?? 0) as num).toDouble(),
            'tugas': ((nilaiKomponen['nilai_tugas'] ?? 0) as num).toDouble(),
            'uts': ((nilaiKomponen['nilai_uts'] ?? 0) as num).toDouble(),
            'uas': ((nilaiKomponen['nilai_uas'] ?? 0) as num).toDouble(),
          };

          print('[Export] Calculating OBE for mahasiswa ${mahasiswa.id}...');

          // Calculate using OBECalculationHelper
          if (subCpmkBobotMap.isNotEmpty && cpmkSubCpmkMap.isNotEmpty) {
            final result = _obeHelper.calculateOBEComplete(
              nilaiKomponen: nilaiMap,
              subCpmkBobotMap: subCpmkBobotMap,
              cpmkSubCpmkMap: cpmkSubCpmkMap,
              cplCpmkMap: cplCpmkMap.isNotEmpty ? cplCpmkMap : null,
              printDebug: false,
            );

            if (result['status'] == 'success') {
              calculationResults[mahasiswa.id!] = OBECalculationResult(
                success: true,
                subCpmkValues: Map<String, double>.from(result['sub_cpmk'] ?? {}),
                cpmkValues: Map<String, double>.from(result['cpmk'] ?? {}),
                cplValues: Map<String, double>.from(result['cpl'] ?? {}),
              );
              print('[Export] ✓ Calculated for mahasiswa ${mahasiswa.id}: '
                  'CPMK count = ${result['cpmk'].length}, CPL count = ${result['cpl'].length}');
            } else {
              print('[Export] ✗ Error: ${result['message']}');
            }
          } else {
            print('[Export] ✗ Bobot maps are empty');
          }
        } catch (e) {
          print('[Export] Error calculating OBE for mahasiswa ${mahasiswa.id}: $e');
        }
      }

      // If no calculated results, create empty results so report still shows student names
      if (calculationResults.isEmpty) {
        print('[Export] No calculated results, creating empty results for all students');
        for (final mahasiswa in mahasiswaList) {
          if (mahasiswa.id != null) {
            calculationResults[mahasiswa.id!] = OBECalculationResult(
              success: true,
              subCpmkValues: {},
              cpmkValues: {},
              cplValues: {},
            );
          }
        }
      }

      print('[Export] Total calculation results: ${calculationResults.length}');

      // Generate PDF
      final pdfFile = await CPLCPMKPDFGenerator.generateCPLCPMKReport(
        matakuliah: matakuliah,
        mahasiswaList: mahasiswaList,
        cpmkList: cpmkList,
        cplList: cplList,
        calculationResults: calculationResults,
        tahunAjaran: _selectedTahunAjaran ?? '2024/2025',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ PDF berhasil dibuat'),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () async {
                try {
                  await CPLCPMKPDFGenerator.openPDF(pdfFile);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error membuka PDF: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportPerMahasiswa() async {
    if (_selectedMahasiswa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih mahasiswa terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isExporting = true);

      final mahasiswa = _selectedMahasiswa!;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sedang membuat laporan PDF...'),
          duration: Duration(seconds: 10),
        ),
      );

      // Load all data for calculation
      final nilaiKomponenList = await _dbHelper.getNilaiKomponenByMahasiswaAllYears(
        mahasiswaId: mahasiswa.id!,
      );

      if (nilaiKomponenList.isEmpty) {
        throw Exception('Tidak ada data nilai untuk mahasiswa ini');
      }

      final allMatakuliah = await _dbHelper.getAllMatakuliah();
      final cplList = await _dbHelper.getAllCPLMaster();

      print('[Export Mahasiswa] Found ${nilaiKomponenList.length} nilai komponen entries');

      // Group nilai komponen by mata kuliah
      final Map<int, Map<String, dynamic>> mkDataMap = {};

      for (final nilaiKomponen in nilaiKomponenList) {
        final mkId = nilaiKomponen['matakuliah_id'] as int?;
        if (mkId == null) continue;

        mkDataMap[mkId] = nilaiKomponen;
      }

      print('[Export Mahasiswa] Unique mata kuliah: ${mkDataMap.keys.length}');

      // Get CPMK and CPL for each mata kuliah
      final Map<int, Map<String, dynamic>> mkScoresMap = {}; // mkId -> {cpmk: {...}, cpl: {...}}

      for (final mkId in mkDataMap.keys) {
        final mk = allMatakuliah.firstWhere(
          (m) => m.id == mkId,
          orElse: () => Matakuliah(
            id: mkId,
            kode: 'UNK',
            nama: 'Unknown',
            semester: '0',
            jenis: 'wajib',
            sks: 0,
            createdAt: DateTime.now(),
          ),
        );

        final nilaiKomponen = mkDataMap[mkId]!;

        // Get RPS details
        final rpsDetails = await _dbHelper.getRPSDetailByMatakuliah(mkId);

        // Build calculation maps
        final subCpmkBobotMap = <String, Map<String, double>>{};
        final cpmkSubCpmkMap = <String, Map<String, double>>{};
        final cplCpmkMap = <String, Map<String, double>>{};

        for (final rps in rpsDetails) {
          if (rps.subCpmkIds != null && rps.subCpmkIds!.isNotEmpty) {
            for (final subCpmkId in rps.subCpmkIds!) {
              final bobotMap = <String, double>{};
              if (rps.bobot != null && rps.bobot! > 0) {
                bobotMap['aktivitas'] = (rps.bobot ?? 0) * 0.2;
                bobotMap['proyek'] = (rps.bobot ?? 0) * 0.3;
                bobotMap['kuis'] = (rps.bobot ?? 0) * 0.15;
                bobotMap['tugas'] = (rps.bobot ?? 0) * 0.15;
                bobotMap['uts'] = (rps.bobot ?? 0) * 0.1;
                bobotMap['uas'] = (rps.bobot ?? 0) * 0.1;
              }
              if (bobotMap.isNotEmpty) {
                subCpmkBobotMap[subCpmkId.toString()] = bobotMap;
              }
            }
          }

          if (rps.cpmkIds != null && rps.cpmkIds!.isNotEmpty) {
            for (final cpmkId in rps.cpmkIds!) {
              if (!cpmkSubCpmkMap.containsKey(cpmkId.toString())) {
                cpmkSubCpmkMap[cpmkId.toString()] = {};
              }
              if (rps.subCpmkIds != null) {
                for (final subCpmkId in rps.subCpmkIds!) {
                  cpmkSubCpmkMap[cpmkId.toString()]![subCpmkId.toString()] = 14.29;
                }
              }
            }
          }

          if (rps.cplIds != null && rps.cplIds!.isNotEmpty) {
            for (final cplId in rps.cplIds!) {
              if (!cplCpmkMap.containsKey(cplId.toString())) {
                cplCpmkMap[cplId.toString()] = {};
              }
              if (rps.cpmkIds != null) {
                for (final cpmkId in rps.cpmkIds!) {
                  cplCpmkMap[cplId.toString()]![cpmkId.toString()] =
                      100.0 / (rps.cpmkIds!.length);
                }
              }
            }
          }
        }

        // Calculate OBE for this course
        if (subCpmkBobotMap.isNotEmpty && cpmkSubCpmkMap.isNotEmpty) {
          final nilaiMap = <String, double>{
            'aktivitas': ((nilaiKomponen['nilai_aktivitas'] ?? 0) as num).toDouble(),
            'proyek': ((nilaiKomponen['nilai_proyek'] ?? 0) as num).toDouble(),
            'kuis': ((nilaiKomponen['nilai_kuis'] ?? 0) as num).toDouble(),
            'tugas': ((nilaiKomponen['nilai_tugas'] ?? 0) as num).toDouble(),
            'uts': ((nilaiKomponen['nilai_uts'] ?? 0) as num).toDouble(),
            'uas': ((nilaiKomponen['nilai_uas'] ?? 0) as num).toDouble(),
          };

          final result = _obeHelper.calculateOBEComplete(
            nilaiKomponen: nilaiMap,
            subCpmkBobotMap: subCpmkBobotMap,
            cpmkSubCpmkMap: cpmkSubCpmkMap,
            cplCpmkMap: cplCpmkMap.isNotEmpty ? cplCpmkMap : null,
            printDebug: false,
          );

          if (result['status'] == 'success') {
            mkScoresMap[mkId] = {
              'matakuliah': mk,
              'cpmk': Map<String, double>.from(result['cpmk'] ?? {}),
              'cpl': Map<String, double>.from(result['cpl'] ?? {}),
            };
          }
        }
      }

      // Generate PDF using the existing method (adapted for single student)
      final pdfFile = await CPLCPMKPDFGenerator.generatePerMahasiswaReport(
        mahasiswa: mahasiswa,
        mkScoresMap: mkScoresMap,
        cplList: cplList,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ PDF berhasil dibuat'),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () async {
                try {
                  await CPLCPMKPDFGenerator.openPDF(pdfFile);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error membuka PDF: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportPerAngkatan() async {
    if (_selectedAngkatan3 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih tahun angkatan terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isExporting = true);

      final angkatan = _selectedAngkatan3!;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sedang membuat laporan PDF...'),
          duration: Duration(seconds: 10),
        ),
      );

      // Get all mahasiswa in this cohort
      final mahasiswaList = _allMahasiswa
          .where((mhs) => mhs.tahunMasuk == angkatan)
          .toList()
        ..sort((a, b) => a.nim.compareTo(b.nim));

      print('[Export Angkatan] Selected angkatan: $angkatan');
      print('[Export Angkatan] Total mahasiswa in system: ${_allMahasiswa.length}');
      print('[Export Angkatan] Mahasiswa with tahunMasuk=$angkatan: ${mahasiswaList.length}');
      
      if (mahasiswaList.isNotEmpty) {
        for (final mhs in mahasiswaList.take(3)) {
          print('[Export Angkatan]   - ${mhs.nim} | ${mhs.nama} | tahunMasuk=${mhs.tahunMasuk}');
        }
      }

      if (mahasiswaList.isEmpty) {
        throw Exception('Tidak ada mahasiswa untuk tahun angkatan ini. '
            'Total mahasiswa di sistem: ${_allMahasiswa.length}');
      }

      final cplList = await _dbHelper.getAllCPLMaster();

      // Get all CPL calculation results for this angkatan directly from database
      final cplResults = await _dbHelper.getCPLResultsByAngkatan(angkatan);

      print('[Export Angkatan] Found ${cplResults.length} CPL results records');
      
      if (cplResults.isNotEmpty) {
        for (final result in cplResults.take(3)) {
          print('[Export Angkatan]   - ${result['nim']} | ${result['nama']} | mahasiswa_id=${result['mahasiswa_id']}');
        }
      }

      if (cplResults.isEmpty) {
        throw Exception(
          'Tidak ada data CPL untuk angkatan $angkatan. '
          'Silakan pastikan CPL sudah dihitung terlebih dahulu untuk angkatan tahun masuk $angkatan.',
        );
      }

      // Map to collect CPL values per student
      final Map<int, Map<String, dynamic>> studentScoresMap = {};

      for (final result in cplResults) {
        final mahasiswaId = result['mahasiswa_id'] as int?;
        final nim = result['nim'] as String?;
        final nama = result['nama'] as String?;
        final cplValuesJson = result['cpl_values'] as String?;

        if (mahasiswaId == null || nim == null || nama == null) continue;

        try {
          // Parse CPL values from pipe-separated format
          final cplValuesMap = <String, double>{};
          if (cplValuesJson != null && cplValuesJson.isNotEmpty) {
            // cpl_values is stored as pipe-separated pairs: "1:85.5|2:88.2|3:80.1"
            final pairs = cplValuesJson.split('|');
            for (final pair in pairs) {
              final parts = pair.trim().split(':');
              if (parts.length == 2) {
                final code = parts[0].trim();
                final value = double.tryParse(parts[1].trim()) ?? 0.0;
                cplValuesMap[code] = value;
              }
            }
          }

          if (cplValuesMap.isNotEmpty) {
            // Store each record
            if (!studentScoresMap.containsKey(mahasiswaId)) {
              studentScoresMap[mahasiswaId] = {
                'nim': nim,
                'nama': nama,
                'cpl_values': [],
              };
            }
            // Add this record's CPL values to aggregate
            (studentScoresMap[mahasiswaId]!['cpl_values'] as List).add(cplValuesMap);
          }
        } catch (e) {
          print('[Export Angkatan] Error parsing CPL values for $nim: $e');
        }
      }

      // Calculate averages for each student
      final Map<int, Map<String, dynamic>> finalStudentScoresMap = {};
      for (final entry in studentScoresMap.entries) {
        final mahasiswaId = entry.key;
        final data = entry.value;
        final nim = data['nim'] as String;
        final nama = data['nama'] as String;
        final cplValuesList = (data['cpl_values'] as List).cast<Map<String, double>>();

        // Average CPL across all courses
        final Map<String, List<double>> cplAggregates = {};
        for (final cplMap in cplValuesList) {
          for (final entry in cplMap.entries) {
            cplAggregates.putIfAbsent(entry.key, () => []).add(entry.value);
          }
        }

        final avgCplValues = <String, double>{};
        for (final entry in cplAggregates.entries) {
          final values = entry.value;
          avgCplValues[entry.key] = values.reduce((a, b) => a + b) / values.length;
        }

        finalStudentScoresMap[mahasiswaId] = {
          'mahasiswa': Mahasiswa(
            id: mahasiswaId,
            nim: nim,
            nama: nama,
            tahunMasuk: angkatan,
            createdAt: DateTime.now(),
          ),
          'cpl': avgCplValues,
        };

        print('[Export Angkatan] ✓ $nim: ${avgCplValues.length} CPL codes, avg = ${(avgCplValues.values.reduce((a, b) => a + b) / avgCplValues.length).toStringAsFixed(2)}');
      }

      print('[Export Angkatan] Total students processed: ${finalStudentScoresMap.length}');

      // Generate PDF
      final pdfFile = await CPLCPMKPDFGenerator.generatePerAngkatanReport(
        angkatan: angkatan,
        studentScoresMap: finalStudentScoresMap,
        cplList: cplList,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ PDF berhasil dibuat'),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () async {
                try {
                  await CPLCPMKPDFGenerator.openPDF(pdfFile);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error membuka PDF: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Laporan CPL & CPMK'),
        backgroundColor: const Color(0xFF8E44AD),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Per Mata Kuliah'),
            Tab(text: 'Per Mahasiswa'),
            Tab(text: 'Per Angkatan'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPerMatakuliahTab(),
                _buildPerMahasiswaTab(),
                _buildPerAngkatanTab(),
              ],
            ),
    );
  }

  Widget _buildPerMatakuliahTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E44AD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description,
                          color: Color(0xFF8E44AD),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unduh Laporan per Mata Kuliah',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Laporan CPL & CPMK untuk semua mahasiswa',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Selection Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilihan Laporan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Mata Kuliah Dropdown
                const Text(
                  'Mata Kuliah',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Matakuliah>(
                  value: _selectedMatakuliah,
                  items: _matakuliahList.map((mk) {
                    return DropdownMenuItem<Matakuliah>(
                      value: mk,
                      child: Text(
                        '${mk.kode} - ${mk.nama}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (Matakuliah? value) {
                    setState(() => _selectedMatakuliah = value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    prefixIcon: const Icon(Icons.book),
                  ),
                ),

                const SizedBox(height: 16),

                // Tahun Ajaran Dropdown
                const Text(
                  'Tahun Ajaran',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTahunAjaran,
                  items: _tahunAjaranList.map((tahun) {
                    return DropdownMenuItem<String>(
                      value: tahun,
                      child: Text(tahun),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() => _selectedTahunAjaran = value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8E44AD).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF8E44AD).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: const Color(0xFF8E44AD),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Laporan akan berisi nilai CPL dan CPMK untuk semua mahasiswa terdaftar pada mata kuliah.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Export Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E44AD),
                disabledBackgroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.download, color: Colors.white),
              label: Text(
                _isExporting ? 'Sedang membuat laporan...' : 'Unduh Laporan PDF',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerMahasiswaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E44AD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFF8E44AD),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unduh Laporan per Mahasiswa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nilai CPL & CPMK per mata kuliah dan rata-rata',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Selection Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilihan Laporan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Tahun Angkatan Dropdown
                const Text(
                  'Tahun Angkatan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedAngkatan2,
                  items: _angkatanList.map((tahun) {
                    return DropdownMenuItem<int>(
                      value: tahun,
                      child: Text('$tahun'),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    if (value != null) {
                      setState(() {
                        _selectedAngkatan2 = value;
                        _filterMahasiswaByAngkatan(value);
                        _selectedMahasiswa = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                ),

                const SizedBox(height: 16),

                // Mahasiswa Dropdown
                const Text(
                  'Mahasiswa',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Mahasiswa>(
                  value: _selectedMahasiswa,
                  items: _filteredMahasiswa.map((mhs) {
                    return DropdownMenuItem<Mahasiswa>(
                      value: mhs,
                      child: Text(
                        '${mhs.nim} - ${mhs.nama}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (Mahasiswa? value) {
                    setState(() => _selectedMahasiswa = value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8E44AD).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF8E44AD).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: const Color(0xFF8E44AD),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Laporan menampilkan nilai CPMK/CPL per mata kuliah dan rata-rata nilai.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Export Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportPerMahasiswa,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E44AD),
                disabledBackgroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.download, color: Colors.white),
              label: Text(
                _isExporting ? 'Sedang membuat laporan...' : 'Unduh Laporan PDF',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerAngkatanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E44AD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.people,
                          color: Color(0xFF8E44AD),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unduh Laporan per Angkatan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rata-rata nilai CPL & CPMK semua mahasiswa',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Selection Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilihan Laporan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Tahun Angkatan Dropdown
                const Text(
                  'Tahun Angkatan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedAngkatan3,
                  items: _angkatanList.map((tahun) {
                    return DropdownMenuItem<int>(
                      value: tahun,
                      child: Text('$tahun'),
                    );
                  }).toList(),
                  onChanged: (int? value) {
                    setState(() => _selectedAngkatan3 = value);
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8E44AD).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF8E44AD).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: const Color(0xFF8E44AD),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Laporan menampilkan semua mahasiswa dengan rata-rata nilai CPMK/CPL mereka.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Export Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportPerAngkatan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E44AD),
                disabledBackgroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Icon(Icons.download, color: Colors.white),
              label: Text(
                _isExporting ? 'Sedang membuat laporan...' : 'Unduh Laporan PDF',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
