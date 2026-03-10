import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/mahasiswa_model.dart';
import '../models/cpmk_model.dart';
import '../models/cpl_master_model.dart';
import '../models/matakuliah_model.dart';
import '../services/database_helper.dart';
import '../services/obe_calculation_helper.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/spider_chart_widget.dart';

class AssessmentOutcomesScreen extends StatefulWidget {
  const AssessmentOutcomesScreen({super.key});

  @override
  State<AssessmentOutcomesScreen> createState() =>
      _AssessmentOutcomesScreenState();
}

class _AssessmentOutcomesScreenState extends State<AssessmentOutcomesScreen>
    with SingleTickerProviderStateMixin {
  final _dbHelper = DatabaseHelper();
  final _obeHelper = OBECalculationHelper();
  
  List<Mahasiswa> _allMahasiswa = [];
  List<Mahasiswa> _filteredMahasiswa = [];
  List<int> _angkatanList = [];
  int? _selectedAngkatan;
  Mahasiswa? _selectedMahasiswa;
  
  late TabController _tabController;
  List<CPMK> _cpmkList = [];
  List<CPLMaster> _cplList = [];
  List<Matakuliah> _matakuliahList = [];
  Map<int, double?> _cpmkScores = {};
  Map<int, double?> _cplScores = {};
  // Detail CPMK per mata kuliah: list of {mkId, mkKode, mkNama, cpmkId, cpmkDeskripsi, nilai}
  List<Map<String, dynamic>> _cpmkDetailList = [];
  // Detail CPL per mata kuliah: list of {mkId, mkKode, mkNama, cplId, cplDeskripsi, nilai}
  List<Map<String, dynamic>> _cplDetailList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() async {
    // Parallelize independent database queries
    final mahasiswaFuture = _dbHelper.getAllMahasiswa();
    final cplFuture = _dbHelper.getAllCPLMaster();
    final matakuliahFuture = _dbHelper.getAllMatakuliah();
    final cpmkFuture = _dbHelper.getCPMKByMatakuliah(0); // Try program level first
    
    try {
      // Wait untuk semua queries
      final results = await Future.wait([
        mahasiswaFuture,
        cplFuture,
        matakuliahFuture,
        cpmkFuture,
      ]);
      
      final mahasiswaList = (results[0] as List<dynamic>).cast<Mahasiswa>();
      final cplList = (results[1] as List<dynamic>).cast<CPLMaster>();
      final matakuliahList = (results[2] as List<dynamic>).cast<Matakuliah>();
      var allCPMK = (results[3] as List<dynamic>).cast<CPMK>();
      
      // If program level CPMK is empty, load from per-matakuliah (batched)
      if (allCPMK.isEmpty && matakuliahList.isNotEmpty) {
        final cpmkQueries = <Future<List<CPMK>>>[];
        for (final mk in matakuliahList) {
          if (mk.id != null) {
            cpmkQueries.add(_dbHelper.getCPMKByMatakuliah(mk.id!));
          }
        }
        
        if (cpmkQueries.isNotEmpty) {
          try {
            final cpmkResults = await Future.wait(cpmkQueries);
            final allCPMKSet = <CPMK>{};
            for (final results in cpmkResults) {
              allCPMKSet.addAll(results);
            }
            allCPMK = allCPMKSet.toList();
          } catch (e) {
            print('⚠️ Error loading CPMK per matakuliah: $e');
          }
        }
      }
      
      final angkatanSet = <int>{};
      for (final mhs in mahasiswaList) {
        angkatanSet.add(mhs.tahunMasuk);
      }
      final angkatanList = angkatanSet.toList()..sort((a, b) => b.compareTo(a));

      // 🎯 FIX BUG #2: Add mounted check before setState
      if (!mounted) return;
      
      setState(() {
        _allMahasiswa = mahasiswaList;
        _cplList = cplList;
        _matakuliahList = matakuliahList;
        _cpmkList = allCPMK;
        _angkatanList = angkatanList;
        if (angkatanList.isNotEmpty) {
          _selectedAngkatan = angkatanList.first;
          _filterMahasiswaByAngkatan(angkatanList.first);
        }
      });
    } catch (e) {
      print('❌ Error loading initial data: $e');
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
      _selectedMahasiswa = null;
      _cpmkScores = {};
      _cplScores = {};
      _cpmkDetailList = [];
      _cplDetailList = [];
    });
  }

  void _selectMahasiswa(Mahasiswa mahasiswa) {
    setState(() => _selectedMahasiswa = mahasiswa);
    // Show loading dialog
    _showLoadingDialog();
    _loadMahasiswaScores(mahasiswa);
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Memuat data mahasiswa...',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _loadMahasiswaScores(Mahasiswa mahasiswa) async {
    setState(() => _isLoading = true);

    try {
      final cpmkScores = <int, double?>{};
      final cplScores = <int, double?>{};
      final cpmkDetailList = <Map<String, dynamic>>[];
      final cplDetailList = <Map<String, dynamic>>[];
      
      // Load semua nilai untuk mahasiswa ini
      final nilaiList = await _dbHelper.getNilaiByMahasiswa(mahasiswa.id!);
      
      if (nilaiList.isEmpty) {
        setState(() {
          _cpmkScores = cpmkScores;
          _cplScores = cplScores;
          _cpmkDetailList = cpmkDetailList;
          _cplDetailList = cplDetailList;
          _isLoading = false;
        });
        return;
      }
      
      // Proses setiap nilai
      for (final nilai in nilaiList) {
        try {
          // 🎯 FIRST: Cek apakah hasil sudah tersimpan di database (persistent)
          final savedResult = await _dbHelper.getCPLCalculationResult(
            mahasiswa.id!,
            nilai.matakuliahId,
            nilai.tahunAjaran,
          );
          
          OBECalculationResult? mahasiswaResult;
          
          if (savedResult != null) {
            // 🎯 Gunakan hasil yang sudah disimpan dari database (PERMANENT)
            print('📦 Memuat hasil CPL dari database untuk MK ${nilai.matakuliahId}');
            
            // Konvert database row ke OBECalculationResult format
            final subCpmkValues = _parseJsonMapValue(savedResult['sub_cpmk_values'] ?? '');
            final cpmkValues = _parseJsonMapValue(savedResult['cpmk_values'] ?? '');
            final cplValues = _parseJsonMapValue(savedResult['cpl_values'] ?? '');
            final subCpmkBobots = _parseJsonMapValue(savedResult['sub_cpmk_bobots'] ?? '');
            
            mahasiswaResult = OBECalculationResult(
              mahasiswaId: mahasiswa.id!,
              matakuliahId: nilai.matakuliahId,
              tahunAjaran: nilai.tahunAjaran,
              subCPMKValues: subCpmkValues,
              cpmkValues: cpmkValues,
              cplValues: cplValues,
              subCpmkBobots: subCpmkBobots.isNotEmpty ? subCpmkBobots : null,
            );
          } else {
            // 🎯 SECOND: Jika tidak ada di database, calculate ulang
            print('🔄 Menghitung CPL untuk MK ${nilai.matakuliahId} (tidak ada di database)');
            
            final results = await _obeHelper.calculateAllMahasiswaCPL(
              nilai.matakuliahId,
              nilai.tahunAjaran,
            );
            
            if (results.isEmpty) continue;
            
            // Cari hasil untuk mahasiswa ini
            try {
              mahasiswaResult = results.firstWhere(
                (r) => r.mahasiswaId == mahasiswa.id!,
              );
              
              // 🎯 SAVE hasil perhitungan ke database untuk next time (PERMANENT)
              await _dbHelper.saveCPLCalculationResults(results);
              print('✅ CPL hasil disimpan ke database');
            } catch (e) {
              // Tidak ditemukan hasil untuk mahasiswa ini
              continue;
            }
          }
          
          // Get matakuliah info
          final mk = _matakuliahList.firstWhere(
            (m) => m.id == nilai.matakuliahId,
            orElse: () => Matakuliah(
              id: nilai.matakuliahId,
              kode: 'N/A',
              nama: 'Unknown',
              semester: 'N/A',
              jenis: 'wajib',
              sks: 0,
              createdAt: DateTime.now(),
            ),
          );
          
          // Process CPMK values
          final cpmkValues = mahasiswaResult.cpmkValues;
          for (final entry in cpmkValues.entries) {
            final cpmkId = entry.key;
            final nilaiCpmk = entry.value;
            
            // Aggregate values untuk average calculation
            if (!cpmkScores.containsKey(cpmkId)) {
              cpmkScores[cpmkId] = nilaiCpmk;
            } else {
              // Accumulate untuk average nanti
              cpmkScores[cpmkId] = (cpmkScores[cpmkId]! + nilaiCpmk) / 2;
            }
            
            // Add detail
            final cpmk = _cpmkList.firstWhere(
              (c) => c.id == cpmkId,
              orElse: () => CPMK(
                id: cpmkId,
                kodeCPMK: 'CPMK.$cpmkId',
                deskripsi: '',
                matakuliahId: nilai.matakuliahId,
                createdAt: DateTime.now(),
              ),
            );
            
            cpmkDetailList.add({
              'mkId': nilai.matakuliahId,
              'mkKode': mk.kode,
              'mkNama': mk.nama,
              'cpmkId': cpmkId,
              'cpmkKode': cpmk.kodeCPMK,
              'cpmkDeskripsi': cpmk.deskripsi,
              'nilai': nilaiCpmk,
            });
          }
          
          // Process CPL values
          final cplValues = mahasiswaResult.cplValues;
          for (final entry in cplValues.entries) {
            final cplId = entry.key;
            final nilaiCpl = entry.value;
            
            // Aggregate values
            if (!cplScores.containsKey(cplId)) {
              cplScores[cplId] = nilaiCpl;
            } else {
              cplScores[cplId] = (cplScores[cplId]! + nilaiCpl) / 2;
            }
            
            // Add detail
            final cpl = _cplList.firstWhere(
              (c) => c.id == cplId,
              orElse: () => CPLMaster(
                id: cplId,
                kodeCPL: 'CPL.$cplId',
                deskripsi: '',
                nomor: cplId.toString(),
                createdAt: DateTime.now(),
              ),
            );
            
            cplDetailList.add({
              'mkId': nilai.matakuliahId,
              'mkKode': mk.kode,
              'mkNama': mk.nama,
              'cplId': cplId,
              'cplKode': cpl.kodeCPL,
              'cplDeskripsi': cpl.deskripsi,
              'nilai': nilaiCpl,
            });
          }
        } catch (e) {
          // Error calculating untuk nilai ini - continue
        }
      }
      
      setState(() {
        _cpmkScores = cpmkScores;
        _cplScores = cplScores;
        _cpmkDetailList = cpmkDetailList;
        _cplDetailList = cplDetailList;
        _isLoading = false;
      });
      
      if (_cpmkScores.isEmpty && _cplScores.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Tidak ada data CPMK/CPL untuk mahasiswa ini. Pastikan telah ada nilai_komponen di database.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Error loading scores for mahasiswa: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
        Navigator.of(context).pop();
      }
      setState(() => _isLoading = false);
    }
  }

  String _getStatusLabel(double? score) {
    if (score == null) return 'N/A';
    return score >= 2.0 ? 'Tercapai' : 'Tidak Tercapai';
  }

  Widget _buildStyledDataTable({
    required List<String> headers,
    required List<List<String>> rows,
    required List<double> columnWidths,
    required List<double?> statusValues,
    double? tableWidth,
  }) {
    const headerColor = Color(0xFF2C3E50); // Dark blue-gray header
    const headerTextColor = Color(0xFFFFFFFF); // White header text
    const borderColor = Color(0xFFBDC3C7); // Light gray borders
    const textColor = Color(0xFF2C3E50); // Dark text
    const rowColor = Color(0xFFFFFFFF); // White

    // Track which IDs have been shown
    final Set<String> shownIds = {};

    // Build header
    final headerCells = headers.map((header) {
      return TableCell(
        child: Container(
          color: headerColor,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          alignment: Alignment.center,
          child: Text(
            header,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: headerTextColor,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }).toList();

    // Build data rows
    final dataRows = List<TableRow>.generate(rows.length, (rowIndex) {
      final row = rows[rowIndex];
      final statusValue = statusValues[rowIndex];
      final idValue = row[3]; // ID column index

      // Check if this ID has been shown BEFORE this row
      final isIdDuplicate = shownIds.contains(idValue);
      
      // Mark this ID as shown (for next rows)
      if (!isIdDuplicate) {
        shownIds.add(idValue);
      }

      final dataCells = List<TableCell>.generate(row.length, (colIndex) {
        final cellText = row[colIndex];
        final isStatusColumn = colIndex == row.length - 1;
        final isIdColumn = colIndex == 3;
        final isRataRataColumn = colIndex == 5; // Rata-rata column

        // For ID column: blank if duplicate, otherwise show
        if (isIdColumn) {
          if (!isIdDuplicate) {
            // Show ID normally
            return TableCell(
              child: Container(
                color: rowColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                alignment: Alignment.center,
                child: Text(
                  cellText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else {
            // Blank cell for duplicate IDs
            return TableCell(
              child: Container(
                color: rowColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                alignment: Alignment.center,
                child: const SizedBox.expand(),
              ),
            );
          }
        } else if (isRataRataColumn) {
          // Rata-rata column: blank if ID is duplicate
          if (isIdDuplicate) {
            return TableCell(
              child: Container(
                color: rowColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                alignment: Alignment.center,
                child: const SizedBox.expand(),
              ),
            );
          } else {
            return TableCell(
              child: Container(
                color: rowColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                alignment: Alignment.center,
                child: Text(
                  cellText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
        } else if (isStatusColumn) {
          // Status column: blank if ID is duplicate
          if (isIdDuplicate) {
            return TableCell(
              child: Container(
                color: rowColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                alignment: Alignment.center,
                child: const SizedBox.expand(),
              ),
            );
          } else {
            final isSuccess = statusValue != null && statusValue >= 2.0;
            return TableCell(
              child: Container(
                color: rowColor,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSuccess ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    cellText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
        } else {
          // Regular cells (Kode MK, Nama, Nilai, Deskripsi)
          return TableCell(
            child: Container(
              color: rowColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              alignment: Alignment.center,
              child: Text(
                cellText,
                style: const TextStyle(
                  fontSize: 12,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: colIndex == 4 ? 4 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }
      });

      return TableRow(children: dataCells);
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: tableWidth ?? double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Table(
            columnWidths: {
              for (int i = 0; i < columnWidths.length; i++)
                i: FixedColumnWidth(columnWidths[i]),
            },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: borderColor,
                width: 1,
              ),
              verticalInside: BorderSide(
                color: borderColor,
                width: 1,
              ),
            ),
            children: [
              TableRow(children: headerCells),
              ...dataRows,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengukuran Capaian Pembelajaran Mata Kuliah'),
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 4,
      ),
      body: _selectedMahasiswa == null
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Angkatan Filter
                    const Text(
                      'Pilih Angkatan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<int>(
                      value: _selectedAngkatan,
                      hint: const Text('Pilih Tahun Angkatan...'),
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      items: _angkatanList.map((angkatan) {
                        return DropdownMenuItem(
                          value: angkatan,
                          child: Text(angkatan.toString()),
                        );
                      }).toList(),
                      onChanged: (int? angkatan) {
                        if (angkatan != null) {
                          setState(() {
                            _selectedAngkatan = angkatan;
                          });
                          _filterMahasiswaByAngkatan(angkatan);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildMahasiswaList(),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _buildDetailView(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMahasiswaList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Mahasiswa Angkatan $_selectedAngkatan (${_filteredMahasiswa.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_filteredMahasiswa.isEmpty)
          EmptyStateWidget(
            message: 'Tidak ada mahasiswa untuk angkatan ini',
            icon: Icons.person,
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('NIM')),
                DataColumn(label: Text('Nama')),
                DataColumn(label: Text('Aksi')),
              ],
              rows: _filteredMahasiswa.map((mahasiswa) {
                return DataRow(
                  cells: [
                    DataCell(Text(mahasiswa.nim)),
                    DataCell(Text(mahasiswa.nama)),
                    DataCell(
                      ElevatedButton.icon(
                        onPressed: () => _selectMahasiswa(mahasiswa),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Lihat Detail'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Capaian Pembelajaran Mata Kuliah Mahasiswa',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '[${_selectedMahasiswa!.nim}] ${_selectedMahasiswa!.nama}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => setState(() => _selectedMahasiswa = null),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Kembali'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Info Box - System Data Summary
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.blue[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700], size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Sistem',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CPMK: ${_cpmkList.length} | CPL: ${_cplList.length} | CPMK dengan nilai: ${_cpmkScores.length} | CPL dengan nilai: ${_cplScores.length}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                child: Text('CPMK'),
              ),
              Tab(
                child: Text('CPL'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Tab content - sized container for TabBarView
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: LoadingWidget(),
            )
          else
            SizedBox(
              height: 500,
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    child: _buildCPMKPage(),
                  ),
                  SingleChildScrollView(
                    child: _buildCPLPage(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCPMKPage() {
    if (_selectedMahasiswa == null) {
      return EmptyStateWidget(
        message: 'Pilih mahasiswa untuk melihat data CPMK',
        icon: Icons.person,
      );
    }

    return Column(
      children: [
        // CPMK Chart Section
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildCPMKChartContent(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // CPMK Detail Section
        if (_cpmkScores.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildCPMKDetailTable(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Tidak ada data CPMK',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildCPLPage() {
    if (_selectedMahasiswa == null) {
      return EmptyStateWidget(
        message: 'Pilih mahasiswa untuk melihat data CPL',
        icon: Icons.person,
      );
    }

    return Column(
      children: [
        // CPL Chart Section
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildCPLChartContent(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // CPL Detail Section
        if (_cplScores.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildCPLDetailTable(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Tidak ada data CPL',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildCPMKChartContent() {
    // Prepare data for spider chart
    final chartData = <String, double>{};
    
    // Get all CPMK codes and scores
    for (final cpmk in _cpmkList) {
      if (cpmk.id != null) {
        final score = _cpmkScores[cpmk.id] ?? 0.0;
        chartData[cpmk.kodeCPMK] = score.clamp(0, 100);
      }
    }

    // If no CPMK data, show all with 0 values
    if (chartData.isEmpty && _cpmkList.isNotEmpty) {
      for (final cpmk in _cpmkList) {
        chartData[cpmk.kodeCPMK] = 0.0;
      }
    }

    if (chartData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info, size: 48, color: Colors.orange[700]),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Tidak Ada Data CPMK',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return SpiderChartWidget(
      dataPoints: chartData,
      title: 'CPMK - Capaian Setiap Mata Kuliah',
      chartColor: const Color(0xFFFF69B4),
    );
  }

  Widget _buildCPLChartContent() {
    // Prepare data for spider chart
    final chartData = <String, double>{};
    
    // Get all CPL codes and scores
    for (final cpl in _cplList) {
      if (cpl.id != null) {
        final score = _cplScores[cpl.id] ?? 0.0;
        chartData[cpl.kodeCPL] = score.clamp(0, 100);
      }
    }

    // If no CPL data, show all with 0 values
    if (chartData.isEmpty && _cplList.isNotEmpty) {
      for (final cpl in _cplList) {
        chartData[cpl.kodeCPL] = 0.0;
      }
    }

    if (chartData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info, size: 48, color: Colors.orange[700]),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Tidak Ada Data CPL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return SpiderChartWidget(
      dataPoints: chartData,
      title: 'CPL - Capaian Setiap Mata Kuliah',
      chartColor: const Color(0xFF4DB8FF),
    );
  }

  Widget _buildCPMKDetailTable() {
    // Build detail data dari _cpmkDetailList dan _cpmkScores
    // Untuk setiap CPMK, hitung rata-rata dari semua matakuliah
    final detailDataMap = <String, Map<String, dynamic>>{};
    
    // Get all matakuliah IDs yang ada di detail list
    final mkIds = <int>{};
    for (var item in _cpmkDetailList) {
      mkIds.add(item['mkId'] as int);
    }
    
    // Build data dari detail list
    for (var item in _cpmkDetailList) {
      final mkKode = item['mkKode'] as String?;
      final mkNama = item['mkNama'] as String?;
      final cpmkId = item['cpmkId'] as int;
      final cpmkKode = item['cpmkKode'] as String?;
      final cpmkDeskripsi = item['cpmkDeskripsi'] as String?;
      final nilai = item['nilai'] as double?;
      
      final key = '${mkKode}_${cpmkId}';
      if (!detailDataMap.containsKey(key)) {
        // Calculate rata-rata untuk CPMK ini dari semua MK
        final rataRata = _cpmkScores[cpmkId] ?? 0.0;
        
        detailDataMap[key] = {
          'mkKode': mkKode,
          'mkNama': mkNama,
          'nilai': nilai ?? 0.0,
          'cpmkId': cpmkId,
          'cpmkKode': cpmkKode,
          'cpmkDeskripsi': cpmkDeskripsi,
          'rataRata': rataRata,
        };
      }
    }
    
    // If no detail data, show message with option to show all MK with 0 values
    if (detailDataMap.isEmpty) {
      // Fallback: show semua matakuliah dengan score 0
      if (_matakuliahList.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Tidak ada data mata kuliah',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      }
      
      // Build table untuk semua MK dengan semua CPMK mereka, score 0
      for (final mk in _matakuliahList) {
        if (mk.id == null) continue;
        
        // Get CPMK untuk MK ini
        final mkCpmks = _cpmkList.where((c) => c.matakuliahId == mk.id).toList();
        
        for (final cpmk in mkCpmks) {
          final key = '${mk.kode}_${cpmk.id}';
          if (!detailDataMap.containsKey(key)) {
            detailDataMap[key] = {
              'mkKode': mk.kode,
              'mkNama': mk.nama,
              'nilai': 0.0,
              'cpmkId': cpmk.id,
              'cpmkKode': cpmk.kodeCPMK,
              'cpmkDeskripsi': cpmk.deskripsi,
              'rataRata': 0.0,
            };
          }
        }
      }
    }
    
    final detailData = detailDataMap.values.toList();
    
    if (detailData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'Tidak ada data CPMK untuk ditampilkan',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    // Sort by CPMK ID (1-22), then by MK Kode
    detailData.sort((a, b) {
      final cpmkIdA = a['cpmkId'] as int? ?? 0;
      final cpmkIdB = b['cpmkId'] as int? ?? 0;
      if (cpmkIdA != cpmkIdB) {
        return cpmkIdA.compareTo(cpmkIdB);
      }
      final mkKodeA = a['mkKode'] as String? ?? '';
      final mkKodeB = b['mkKode'] as String? ?? '';
      return mkKodeA.compareTo(mkKodeB);
    });

    return _buildStyledDataTable(
      headers: const ['Kode MK', 'Nama MK', 'Nilai CPMK', 'ID CPMK', 'Deskripsi CPMK', 'Rata-rata CPMK', 'Status'],
      rows: detailData.map((detail) {
        return [
          detail['mkKode']?.toString() ?? '-',
          detail['mkNama']?.toString() ?? '-',
          (detail['nilai'] as num? ?? 0.0).toStringAsFixed(2),
          detail['cpmkId']?.toString() ?? '-',
          detail['cpmkDeskripsi']?.toString() ?? '-',
          (detail['rataRata'] as num? ?? 0.0).toStringAsFixed(2),
          _getStatusLabel((detail['rataRata'] as num?)?.toDouble()),
        ];
      }).toList(),
      columnWidths: const [140, 220, 130, 100, 480, 150, 140],
      statusValues: detailData.map((detail) => (detail['rataRata'] as num?)?.toDouble()).toList(),
      tableWidth: MediaQuery.of(context).size.width - 40,
    );
  }

  Widget _buildCPLDetailTable() {
    // Build detail data dari _cplDetailList dan _cplScores
    // Untuk setiap CPL, hitung rata-rata dari semua matakuliah
    final detailDataMap = <String, Map<String, dynamic>>{};
    
    // Build data dari detail list
    for (var item in _cplDetailList) {
      final mkKode = item['mkKode'] as String?;
      final mkNama = item['mkNama'] as String?;
      final cplId = item['cplId'] as int;
      final cplKode = item['cplKode'] as String?;
      final cplDeskripsi = item['cplDeskripsi'] as String?;
      final nilai = item['nilai'] as double?;
      
      final key = '${mkKode}_${cplId}';
      if (!detailDataMap.containsKey(key)) {
        // Calculate rata-rata untuk CPL ini dari semua MK
        final rataRata = _cplScores[cplId] ?? 0.0;
        
        detailDataMap[key] = {
          'mkKode': mkKode,
          'mkNama': mkNama,
          'nilai': nilai ?? 0.0,
          'cplId': cplId,
          'cplKode': cplKode,
          'cplDeskripsi': cplDeskripsi,
          'rataRata': rataRata,
        };
      }
    }
    
    // If no detail data, show message with option to show all MK with 0 values
    if (detailDataMap.isEmpty) {
      // Fallback: show semua matakuliah dengan score 0
      if (_matakuliahList.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Tidak ada data mata kuliah',
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      }
      
      // Build table untuk semua MK dengan semua CPL, score 0
      // Note: For CPL, we show all CPLs for all MK
      for (final mk in _matakuliahList) {
        if (mk.id == null) continue;
        
        for (final cpl in _cplList) {
          final key = '${mk.kode}_${cpl.id}';
          if (!detailDataMap.containsKey(key)) {
            detailDataMap[key] = {
              'mkKode': mk.kode,
              'mkNama': mk.nama,
              'nilai': 0.0,
              'cplId': cpl.id,
              'cplKode': cpl.kodeCPL,
              'cplDeskripsi': cpl.deskripsi,
              'rataRata': 0.0,
            };
          }
        }
      }
    }
    
    final detailData = detailDataMap.values.toList();
    
    if (detailData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          'Tidak ada data CPL untuk ditampilkan',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    // Sort by CPL ID, then by MK Kode
    detailData.sort((a, b) {
      final cplIdA = a['cplId'] as int? ?? 0;
      final cplIdB = b['cplId'] as int? ?? 0;
      if (cplIdA != cplIdB) {
        return cplIdA.compareTo(cplIdB);
      }
      final mkKodeA = a['mkKode'] as String? ?? '';
      final mkKodeB = b['mkKode'] as String? ?? '';
      return mkKodeA.compareTo(mkKodeB);
    });

    return _buildStyledDataTable(
      headers: const ['Kode MK', 'Nama MK', 'Nilai CPL', 'ID CPL', 'Deskripsi CPL', 'Rata-rata CPL', 'Status'],
      rows: detailData.map((detail) {
        return [
          detail['mkKode']?.toString() ?? '-',
          detail['mkNama']?.toString() ?? '-',
          (detail['nilai'] as num? ?? 0.0).toStringAsFixed(2),
          detail['cplId']?.toString() ?? '-',
          detail['cplDeskripsi']?.toString() ?? '-',
          (detail['rataRata'] as num? ?? 0.0).toStringAsFixed(2),
          _getStatusLabel((detail['rataRata'] as num?)?.toDouble()),
        ];
      }).toList(),
      columnWidths: const [140, 220, 130, 100, 480, 150, 140],
      statusValues: detailData.map((detail) => (detail['rataRata'] as num?)?.toDouble()).toList(),
      tableWidth: MediaQuery.of(context).size.width - 40,
    );
  }

  /// Helper method untuk parse JSON string dari database ke Map<int, double>
  /// Format: "1:25.5|2:30.2|3:28.8"
  Map<int, double> _parseJsonMapValue(String jsonString) {
    if (jsonString.isEmpty) return {};
    
    try {
      final result = <int, double>{};
      final pairs = jsonString.split('|');
      
      for (final pair in pairs) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          final id = int.parse(parts[0]);
          final value = double.parse(parts[1]);
          result[id] = value;
        }
      }
      
      return result;
    } catch (e) {
      print('❌ Error parsing JSON map: $e');
      return {};
    }
  }
}

