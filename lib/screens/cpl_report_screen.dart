import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/mahasiswa_model.dart';
import '../models/cpl_master_model.dart';
import '../services/database_helper.dart';
import '../services/cpmk_cpl_calculation_service.dart';
import '../widgets/custom_widgets.dart';

class CPLReportScreen extends StatefulWidget {
  const CPLReportScreen({super.key});

  @override
  State<CPLReportScreen> createState() => _CPLReportScreenState();
}

class _CPLReportScreenState extends State<CPLReportScreen> {
  final _dbHelper = DatabaseHelper();
  final _calculationService = CPMKCPLCalculationService();
  late Future<List<CPLMaster>> _cplList;
  List<Mahasiswa> _filteredMahasiswaList = [];
  List<int> _angkatanList = [];
  int? _selectedAngkatan;
  Mahasiswa? _selectedMahasiswa;
  Map<int, double?> _cplScores = {};
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    setState(() {
      // _allMahasiswaList = _dbHelper.getAllMahasiswa();
      _cplList = _dbHelper.getAllCPLMaster();
    });
    
    // Load and extract unique angkatan (tahun_masuk)
    final mahasiswaList = await _dbHelper.getAllMahasiswa();
    final angkatanSet = <int>{};
    for (final mhs in mahasiswaList) {
      angkatanSet.add(mhs.tahunMasuk);
    }
    final angkatanList = angkatanSet.toList()..sort((a, b) => b.compareTo(a));
    
    setState(() {
      _angkatanList = angkatanList;
      if (angkatanList.isNotEmpty) {
        _selectedAngkatan = angkatanList.first;
        _filterMahasiswaByAngkatan(angkatanList.first);
      }
    });
  }
  
  void _filterMahasiswaByAngkatan(int angkatan) async {
    final mahasiswaList = await _dbHelper.getAllMahasiswa();
    final filtered = mahasiswaList.where((mhs) => mhs.tahunMasuk == angkatan).toList();
    setState(() {
      _filteredMahasiswaList = filtered;
      _selectedMahasiswa = null;
      _cplScores = {};
    });
  }
  
  void _onAngkatanChanged(int? angkatan) {
    if (angkatan != null) {
      setState(() => _selectedAngkatan = angkatan);
      _filterMahasiswaByAngkatan(angkatan);
    }
  }

  void _onMahasiswaChanged(Mahasiswa? mahasiswa) {
    setState(() {
      _selectedMahasiswa = mahasiswa;
      _cplScores = {};
    });
    _loadCPLScores();
  }

  void _loadCPLScores() async {
    if (_selectedMahasiswa == null) {
      return;
    }

    // 🎯 FIX BUG #4: Validate mahasiswa ID before using
    if (_selectedMahasiswa!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Mahasiswa ID tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cplList = await _dbHelper.getAllCPLMaster();
      final scores = <int, double?>{};

      for (final cpl in cplList) {
        // 🎯 FIX BUG #15: Pass mahasiswa ID untuk per-student calculation
        if (cpl.id != null) {
          final score = await _calculationService.calculateCPLForStudent(
            cpl.id!,
            _selectedMahasiswa!.id!,
          );
          scores[cpl.id!] = score;
        }
      }

      if (mounted) {
        setState(() {
          _cplScores = scores;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading CPL scores: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _getStatusLabel(double? score) {
    if (score == null) return 'N/A';
    return score >= 2.0 ? 'Tercapai' : 'Tidak Tercapai';
  }

  Color _getStatusColor(double? score) {
    if (score == null) return Colors.grey;
    return score >= 2.0 ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Nilai CPL'),
        backgroundColor: const Color(0xFF1ABC9C),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Angkatan Filter
              const Text('Pilih Angkatan'),
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
                    _onAngkatanChanged(angkatan);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Pilih Mahasiswa'),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<Mahasiswa>(
                value: _selectedMahasiswa,
                hint: const Text('Pilih Mahasiswa...'),
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
                items: _filteredMahasiswaList.map((mahasiswa) {
                  return DropdownMenuItem(
                    value: mahasiswa,
                    child: Text('${mahasiswa.nim} - ${mahasiswa.nama}'),
                  );
                }).toList(),
                onChanged: (Mahasiswa? mahasiswa) {
                  if (mahasiswa != null) {
                    _onMahasiswaChanged(mahasiswa);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_selectedMahasiswa != null) ...[
                const Text(
                  'Hasil Nilai CPL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_isLoading)
                  const LoadingWidget()
                else
                  FutureBuilder<List<CPLMaster>>(
                    future: _cplList,
                    builder: (context, snapshot) {
                      final cplList = snapshot.data ?? [];
                      if (cplList.isEmpty) {
                        return EmptyStateWidget(
                          message: 'Belum ada CPL yang didefinisikan',
                          icon: Icons.list,
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cplList.length,
                        itemBuilder: (context, index) {
                          final cpl = cplList[index];
                          final score = _cplScores[cpl.id!];
                          final status = _getStatusLabel(score);
                          final statusColor = _getStatusColor(score);

                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cpl.kodeCPL,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          SizedBox(
                                            width: 200,
                                            child: Text(
                                              cpl.deskripsi,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            score?.toStringAsFixed(2) ?? 'N/A',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: statusColor,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.md,
                                              vertical: AppSpacing.sm,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  statusColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(
                                                AppRadius.sm,
                                              ),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
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
                      );
                    },
                  ),
              ] else
                EmptyStateWidget(
                  message: 'Pilih mahasiswa untuk melihat hasil',
                  icon: Icons.person,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
