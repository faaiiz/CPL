import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/matakuliah_model.dart';
import '../models/nilai_model.dart';
import '../services/database_helper.dart';
import '../widgets/custom_widgets.dart';

class InputNilaiScreen extends StatefulWidget {
  const InputNilaiScreen({super.key});

  @override
  State<InputNilaiScreen> createState() => _InputNilaiScreenState();
}

class _InputNilaiScreenState extends State<InputNilaiScreen> {
  final _dbHelper = DatabaseHelper();
  late Future<List<Matakuliah>> _matakuliahList;
  late Future<List<Nilai>> _nilaiList;

  String _selectedTahunAjaran = '2025/2026';
  String _selectedSemester = 'Genap';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _matakuliahList = _dbHelper.getAllMatakuliah();
      _nilaiList = _dbHelper.getAllNilai();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input Nilai'),
        backgroundColor: const Color(0xFFC0392B),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Filter Section
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Data',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      // Tahun Ajaran Dropdown
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
                            contentPadding:
                                const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                              horizontal: AppSpacing.md,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '2024/2025',
                              child: Text('2024/2025'),
                            ),
                            DropdownMenuItem(
                              value: '2025/2026',
                              child: Text('2025/2026'),
                            ),
                            DropdownMenuItem(
                              value: '2026/2027',
                              child: Text('2026/2027'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedTahunAjaran = value ?? '2025/2026';
                              _loadData();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      // Semester Dropdown
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
                            contentPadding:
                                const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                              horizontal: AppSpacing.md,
                            ),
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
                              _selectedSemester = value ?? 'Genap';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari Kode MK atau Nama MK...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.md,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ],
              ),
            ),

            // Table Section
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: FutureBuilder<List<Matakuliah>>(
                future: _matakuliahList,
                builder: (context, mkSnapshot) {
                  if (mkSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const LoadingWidget();
                  }

                  if (mkSnapshot.hasError) {
                    return CustomErrorWidget(
                      message: 'Error: ${mkSnapshot.error}',
                      onRetry: _loadData,
                    );
                  }

                  final matakuliahs = mkSnapshot.data ?? [];

                  // Filter by search query
                  final filtered = matakuliahs.where((mk) {
                    return mk.kode.toLowerCase().contains(_searchQuery) ||
                        mk.nama.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const EmptyStateWidget(
                      message: 'Tidak ada data mata kuliah',
                      icon: Icons.book,
                    );
                  }

                  return FutureBuilder<List<Nilai>>(
                    future: _nilaiList,
                    builder: (context, nilaiSnapshot) {
                      if (nilaiSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }

                      final nilaiList = nilaiSnapshot.data ?? [];

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: AppSpacing.lg,
                          columns: const [
                            DataColumn(
                              label: SizedBox(
                                width: 40,
                                child: Text('No',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 100,
                                child: Text('Kode MK',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 180,
                                child: Text('Nama MK',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 50,
                                child: Text('SMT',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 80,
                                child: Text('TA',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 120,
                                child: Text('Nilai Terinput',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 130,
                                child: Text('Jumlah Mahasiswa',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 100,
                                child: Text('Aksi',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                          rows: List<DataRow>.generate(
                            filtered.length,
                            (index) {
                              final mk = filtered[index];
                              final mkId = mk.id!;

                              // Count nilai for this matakuliah
                              final nilaiCount = nilaiList
                                  .where((n) =>
                                      n.matakuliahId == mkId &&
                                      n.tahunAjaran.toString() ==
                                          _selectedTahunAjaran
                                              .split('/')[0])
                                  .length;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      (index + 1).toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(mk.kode),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        mk.nama,
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(mk.semester),
                                  ),
                                  DataCell(
                                    Text(_selectedTahunAjaran
                                        .split('/')[0]),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs,
                                      ),
                                      decoration: BoxDecoration(
                                        color: nilaiCount > 0
                                            ? AppColors.success
                                                .withOpacity(0.1)
                                            : AppColors.warning
                                                .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(
                                                AppRadius.sm),
                                      ),
                                      child: Text(
                                        nilaiCount.toString(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: nilaiCount > 0
                                              ? AppColors.success
                                              : AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text('0'), // Placeholder for jumlah mahasiswa
                                  ),
                                  DataCell(
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: AppSpacing.sm,
                                        ),
                                      ),
                                      onPressed: () {
                                        // TODO: Navigate to detail input nilai screen
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Input nilai untuk ${mk.nama}'),
                                          ),
                                        );
                                      },
                                      child: const Text('Input Nilai'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
