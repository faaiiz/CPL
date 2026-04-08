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
      
      // 🎯 FIX: Ambil SEMUA nilai_komponen untuk mahasiswa (tanpa filter tahun_ajaran)
      // Karena MK bisa tersimpan dengan tahun_ajaran yang berbeda-beda
      final nilaiKomponenList = await _dbHelper.getNilaiKomponenByMahasiswaAllYears(
        mahasiswaId: mahasiswa.id!,
      );
      
      if (nilaiKomponenList.isEmpty) {
        setState(() {
          _cpmkScores = cpmkScores;
          _cplScores = cplScores;
          _cpmkDetailList = cpmkDetailList;
          _cplDetailList = cplDetailList;
          _isLoading = false;
        });
        return;
      }
      
      print('📊 Processing ${nilaiKomponenList.length} nilai komponen entries...');
      
      // Group by MK untuk melihat unique MK
      final uniqueMKs = <int>{};
      for (var nk in nilaiKomponenList) {
        final mkId = nk['matakuliah_id'] as int?;
        if (mkId != null) uniqueMKs.add(mkId);
      }
      print('🎓 Unique Mata Kuliah: ${uniqueMKs.length} = $uniqueMKs');
      
      // Proses setiap nilai_komponen
      int successCount = 0;
      for (final nilaiKomponen in nilaiKomponenList) {
        try {
          final mahasiswaId = nilaiKomponen['mahasiswa_id'] as int?;
          final matakuliahId = nilaiKomponen['matakuliah_id'] as int?;
          final tahunAjaran = nilaiKomponen['tahun_ajaran'] as int? ?? 2024;
          
          if (mahasiswaId == null || matakuliahId == null) {
            print('⚠️ Skip entry: mahasiswaId=$mahasiswaId, matakuliahId=$matakuliahId');
            continue;
          }
          
          // 🎯 FIRST: Cek apakah hasil sudah tersimpan di database (persistent)
          final savedResult = await _dbHelper.getCPLCalculationResult(
            mahasiswaId,
            matakuliahId,
            tahunAjaran,
          );
          
          OBECalculationResult? mahasiswaResult;
          
          if (savedResult != null) {
            // 🎯 Gunakan hasil yang sudah disimpan dari database (PERMANENT)
            print('📦 Memuat hasil CPL dari database untuk MK $matakuliahId');
            
            // Konvert database row ke OBECalculationResult format
            final subCpmkValues = _parseJsonMapValue(savedResult['sub_cpmk_values'] ?? '');
            final cpmkValues = _parseJsonMapValue(savedResult['cpmk_values'] ?? '');
            final cplValues = _parseJsonMapValue(savedResult['cpl_values'] ?? '');
            final subCpmkBobots = _parseJsonMapValue(savedResult['sub_cpmk_bobots'] ?? '');
            
            mahasiswaResult = OBECalculationResult(
              mahasiswaId: mahasiswaId,
              matakuliahId: matakuliahId,
              tahunAjaran: tahunAjaran,
              subCPMKValues: subCpmkValues,
              cpmkValues: cpmkValues,
              cplValues: cplValues,
              subCpmkBobots: subCpmkBobots.isNotEmpty ? subCpmkBobots : null,
            );
          } else {
            // 🎯 SECOND: Jika tidak ada di database, calculate ulang
            print('🔄 Menghitung CPL untuk MK $matakuliahId (tidak ada di database)');
            
            final results = await _obeHelper.calculateAllMahasiswaCPL(
              matakuliahId,
              tahunAjaran,
            );
            
            if (results.isEmpty) continue;
            
            // Cari hasil untuk mahasiswa ini
            try {
              mahasiswaResult = results.firstWhere(
                (r) => r.mahasiswaId == mahasiswaId,
              );
              
              // 🎯 SAVE hasil perhitungan ke database untuk next time (PERMANENT)
              await _dbHelper.saveCPLCalculationResults(results);
              print('✅ CPL hasil disimpan ke database');
            } catch (e) {
              // Tidak ditemukan hasil untuk mahasiswa ini
              print('⚠️ Tidak ada hasil untuk mahasiswa $mahasiswaId di MK $matakuliahId: $e');
              continue;
            }
          }
          
          successCount++;
          print('✅ Processed MK ID $matakuliahId (success count: $successCount)');
          
          // Get matakuliah info
          final mk = _matakuliahList.firstWhere(
            (m) => m.id == matakuliahId,
            orElse: () => Matakuliah(
              id: matakuliahId,
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
                matakuliahId: matakuliahId,
                createdAt: DateTime.now(),
              ),
            );
            
            cpmkDetailList.add({
              'mkId': matakuliahId,
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
              'mkId': matakuliahId,
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
          print('⚠️  Error processing nilai: $e');
        }
      }
      
      print('🏁 FINAL RESULT: Processed $successCount MK dari ${nilaiKomponenList.length} entries');
      print('   - CPMK scores: ${cpmkScores.length} CPMK dengan nilai');
      print('   - CPL scores: ${cplScores.length} CPL dengan nilai');
      print('   - CPMK detail rows: ${cpmkDetailList.length}');
      print('   - CPL detail rows: ${cplDetailList.length}');
      
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
    const headerColor = Color(0xFF2C3E50);
    const headerTextColor = Color(0xFFFFFFFF);
    const borderColor = Color(0xFFBDC3C7);
    const textColor = Color(0xFF2C3E50);
    const rowColor = Color(0xFFFFFFFF);

    print('📋 Displaying ${rows.length} rows in table');

    // Build header
    final headerCells = headers.map((header) {
      return TableCell(
        child: Container(
          color: headerColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.center,
          child: Text(
            header,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: headerTextColor,
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
      final isSuccess = statusValue != null && statusValue >= 2.0;

      final dataCells = List<TableCell>.generate(row.length, (colIndex) {
        final cellText = row[colIndex];
        final isStatusColumn = colIndex == row.length - 1;

        return TableCell(
          child: Container(
            color: rowColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            alignment: Alignment.center,
            child: isStatusColumn
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSuccess ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      cellText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Text(
                    cellText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: colIndex == 4 ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        );
      });

      return TableRow(children: dataCells);
    });

    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          columnWidths: {
            for (int i = 0; i < columnWidths.length; i++)
              i: FixedColumnWidth(columnWidths[i]),
          },
          border: TableBorder.all(color: borderColor, width: 1),
          children: [
            TableRow(children: headerCells),
            ...dataRows,
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section - non-scrollable, more compact
        Container(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: AppSpacing.md,
          ),
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
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '[${_selectedMahasiswa!.nim}] ${_selectedMahasiswa!.nama}',
                          style: const TextStyle(fontSize: 11),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Info Box - System Data Summary (more compact)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data Sistem',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'CPMK: ${_cpmkList.length} | CPL: ${_cplList.length} | Nilai CPMK: ${_cpmkScores.length} | Nilai CPL: ${_cplScores.length}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Tabs (more compact)
              SizedBox(
                height: 40,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(
                      child: Text('CPMK', style: TextStyle(fontSize: 12)),
                    ),
                    Tab(
                      child: Text('CPL', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab content - scrollable and expanded
        if (_isLoading)
          const Expanded(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: LoadingWidget(),
            ),
          )
        else
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCPMKPage(),
                _buildCPLPage(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCPMKPage() {
    if (_selectedMahasiswa == null) {
      return const Center(child: Text('Pilih mahasiswa'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton.icon(
            onPressed: () => _showCPMKChartDialog(),
            icon: const Icon(Icons.show_chart, size: 18),
            label: const Text('Lihat Grafik Spider Chart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF69B4),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _buildCPMKDetailTable(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCPLPage() {
    if (_selectedMahasiswa == null) {
      return const Center(child: Text('Pilih mahasiswa'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton.icon(
            onPressed: () => _showCPLChartDialog(),
            icon: const Icon(Icons.show_chart, size: 18),
            label: const Text('Lihat Grafik Spider Chart'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DB8FF),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _buildCPLDetailTable(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCPMKChartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grafik CPMK - Capaian Pembelajaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Chart
                Expanded(
                  child: Center(
                    child: _buildCPMKChartContent(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCPLChartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grafik CPL - Capaian Pembelajaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Chart
                Expanded(
                  child: Center(
                    child: _buildCPLChartContent(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    if (_cpmkDetailList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'Tidak ada data CPMK',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }

    print('📋 CPMK Detail Table: ${_cpmkDetailList.length} entries');

    // Build tabel sederhana: satu baris per mk-cpmk combination
    final rows = _cpmkDetailList.map((item) {
      final nilai = (item['nilai'] as num? ?? 0.0).toDouble();
      final status = nilai >= 2.0 ? 'Tercapai' : 'Tidak Tercapai';
      
      return [
        item['mkKode']?.toString() ?? '-',
        item['mkNama']?.toString() ?? '-',
        nilai.toStringAsFixed(2),
        item['cpmkKode']?.toString() ?? '-',
        item['cpmkDeskripsi']?.toString() ?? '-',
        status,
      ];
    }).toList();

    return _buildStyledDataTable(
      headers: const ['Kode MK', 'Nama MK', 'Nilai', 'CPMK', 'Deskripsi CPMK', 'Status'],
      rows: rows,
      columnWidths: const [120, 200, 100, 100, 350, 120],
      statusValues: _cpmkDetailList.map((item) => (item['nilai'] as num?)?.toDouble()).toList(),
    );
  }

  Widget _buildCPLDetailTable() {
    if (_cplDetailList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Text(
            'Tidak ada data CPL',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }

    print('📋 CPL Detail Table: ${_cplDetailList.length} entries');

    // Build tabel sederhana: satu baris per mk-cpl combination
    final rows = _cplDetailList.map((item) {
      final nilai = (item['nilai'] as num? ?? 0.0).toDouble();
      final status = nilai >= 2.0 ? 'Tercapai' : 'Tidak Tercapai';
      
      return [
        item['mkKode']?.toString() ?? '-',
        item['mkNama']?.toString() ?? '-',
        nilai.toStringAsFixed(2),
        item['cplKode']?.toString() ?? '-',
        item['cplDeskripsi']?.toString() ?? '-',
        status,
      ];
    }).toList();

    return _buildStyledDataTable(
      headers: const ['Kode MK', 'Nama MK', 'Nilai', 'CPL', 'Deskripsi CPL', 'Status'],
      rows: rows,
      columnWidths: const [120, 200, 100, 100, 350, 120],
      statusValues: _cplDetailList.map((item) => (item['nilai'] as num?)?.toDouble()).toList(),
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

