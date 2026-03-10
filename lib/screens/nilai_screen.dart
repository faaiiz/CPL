import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/nilai_model.dart';
import '../services/database_helper.dart';
import '../widgets/custom_widgets.dart';
import 'nilai_batch_import_screen.dart';

class NilaiEntryScreen extends StatefulWidget {
  const NilaiEntryScreen({super.key});

  @override
  State<NilaiEntryScreen> createState() => _NilaiEntryScreenState();
}

class _NilaiEntryScreenState extends State<NilaiEntryScreen> {
  final _dbHelper = DatabaseHelper();
  late Future<List<Nilai>> _nilaiList;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNilai();
  }

  void _loadNilai() {
    setState(() {
      _nilaiList = _dbHelper.getAllNilai();
    });
  }

  Future<void> _deleteNilai(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text(
            'Apakah Anda yakin ingin menghapus data nilai ini?'),
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
      await _dbHelper.deleteNilai(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data nilai berhasil dihapus')),
        );
        _loadNilai();
      }
    }
  }

  Map<String, int> _calculateGradeStats(List<Nilai> list) {
    Map<String, int> stats = {
      'A': 0,
      'B': 0,
      'C': 0,
      'D': 0,
      'E': 0,
    };

    for (var n in list) {
      final grade = n.gradeHuruf.toUpperCase();
      if (stats.containsKey(grade)) {
        stats[grade] = stats[grade]! + 1;
      }
    }

    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Nilai'),
        backgroundColor: const Color(0xFFC0392B),
        elevation: 4,
        actions: [
          /// BATCH IMPORT NILAI (Multiple files dalam 1 tahun ajaran)
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Batch Import Nilai (Multiple Files)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const NilaiBatchImportScreen(),
                ),
              ).then((_) => _loadNilai());
            },
          ),
        ],
      ),

      body: Column(
        children: [

          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Cari NIM / Tahun Ajaran / ID Matakuliah...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppRadius.md),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          /// LIST DATA
          Expanded(
            child: FutureBuilder<List<Nilai>>(
              future: _nilaiList,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                if (snapshot.hasError) {
                  return CustomErrorWidget(
                    message: 'Error: ${snapshot.error}',
                    onRetry: _loadNilai,
                  );
                }

                final nilaiList = snapshot.data ?? [];

                final keyword =
                    _searchController.text.toLowerCase();

                final filtered = nilaiList.where((n) {
                  return n.mahasiswaId
                          .toString()
                          .toLowerCase()
                          .contains(keyword) ||
                      n.matakuliahId
                          .toString()
                          .toLowerCase()
                          .contains(keyword) ||
                      n.tahunAjaran
                          .toString()
                          .toLowerCase()
                          .contains(keyword);
                }).toList();

                final stats =
                    _calculateGradeStats(filtered);

                if (filtered.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'Tidak ada data nilai',
                    icon: Icons.assessment,
                  );
                }

                return Column(
                  children: [

                    /// STATISTIK RINGKAS
                    Container(
                      padding:
                          const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(
                            AppRadius.md),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('Total',
                              filtered.length.toString()),
                          _buildStat(
                              'A', stats['A'].toString()),
                          _buildStat(
                              'B', stats['B'].toString()),
                          _buildStat(
                              'C', stats['C'].toString()),
                          _buildStat(
                              'D', stats['D'].toString()),
                          _buildStat(
                              'E', stats['E'].toString()),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    /// LIST VIEW
                    Expanded(
                      child: ListView.builder(
                        padding:
                            const EdgeInsets.all(AppSpacing.md),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final nilai = filtered[index];

                          return Card(
                            margin: const EdgeInsets.only(
                                bottom: AppSpacing.md),
                            child: ListTile(
                              leading: _buildGradeBox(
                                  nilai.gradeHuruf),
                              title: Text(
                                  'Mahasiswa ID: ${nilai.mahasiswaId}'),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                      height:
                                          AppSpacing.sm),
                                  Text(
                                      'Matakuliah ID: ${nilai.matakuliahId}'),
                                  Text(
                                      'Tahun Ajaran: ${nilai.tahunAjaran}'),
                                  Text(
                                      'Nilai: ${nilai.gradeHuruf} (${nilai.nilaiNumerik.toStringAsFixed(2)})'),
                                ],
                              ),
                              trailing:
                                  PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value ==
                                      'delete') {
                                    _deleteNilai(
                                        nilai.id!);
                                  }
                                },
                                itemBuilder: (context) =>
                                    const [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            color: AppColors
                                                .danger),
                                        SizedBox(
                                            width:
                                                AppSpacing
                                                    .sm),
                                        Text('Hapus',
                                            style:
                                                TextStyle(
                                                    color:
                                                        AppColors
                                                            .danger)),
                                      ],
                                    ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }

  Widget _buildGradeBox(String grade) {
    final color = _getGradeColor(grade);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Text(
          grade,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A':
        return AppColors.success;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
      case 'E':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }
}
