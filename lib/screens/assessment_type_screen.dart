import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/assessment_type_model.dart';
import '../models/rps_detail_model.dart';
import '../services/database_helper.dart';
import '../widgets/custom_widgets.dart';

class AssessmentTypeScreen extends StatefulWidget {
  final int matakuliahId;

  const AssessmentTypeScreen({
    super.key,
    required this.matakuliahId,
  });

  @override
  State<AssessmentTypeScreen> createState() => _AssessmentTypeScreenState();
}

class _AssessmentTypeScreenState extends State<AssessmentTypeScreen> {
  final _dbHelper = DatabaseHelper();
  late Future<List<RPSDetail>> _rpsList;
  RPSDetail? _selectedRPS;
  List<AssessmentType> _assessmentList = [];
  bool _isLoading = false;

  final assessmentTypes = [
    'Aktivitas Partisipatif',
    'Kuis',
    'Tugas',
    'Hasil Proyek',
  ];

  @override
  void initState() {
    super.initState();
    _loadRPSData();
  }

  void _loadRPSData() {
    setState(() {
      _rpsList = _dbHelper.getRPSDetailByMatakuliah(widget.matakuliahId);
    });
  }

  void _onRPSSelected(RPSDetail rps) async {
    setState(() {
      _selectedRPS = rps;
      _isLoading = true;
    });

    try {
      final assessments = await _dbHelper.getAssessmentByMinggu(rps.id!);
      setState(() {
        _assessmentList = assessments;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showAssessmentDialog({AssessmentType? existing}) async {
    final isEdit = existing != null;
    String? selectedType = existing?.jenisAsessmen;
    final bobotController = TextEditingController(
      text: existing?.bobot.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Penilaian' : 'Tambah Penilaian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Minggu ke-${_selectedRPS!.mingguKe}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedType,
                    hint: const Text('Pilih Jenis Penilaian...'),
                    underline: const SizedBox.shrink(),
                    items: assessmentTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (type) {
                      setState(() => selectedType = type);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: bobotController,
                  decoration: InputDecoration(
                    label: const Text('Bobot (%): 0-100'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Total bobot minggu ini: ${_assessmentList.fold<double>(0, (sum, a) => sum + a.bobot)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedType == null || bobotController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Semua field harus diisi')),
                  );
                  return;
                }

                try {
                  final bobot = double.parse(bobotController.text);
                  if (bobot < 0 || bobot > 100) {
                    throw Exception('Bobot harus antara 0-100');
                  }

                  // Calculate total if adding new (excluding current if editing)
                  double totalBobot = _assessmentList.fold<double>(0, (sum, a) {
                    if (isEdit && a.id == existing.id) {
                      return sum;
                    }
                    return sum + a.bobot;
                  });
                  
                  totalBobot += bobot;
                  if (totalBobot > 100) {
                    throw Exception(
                      'Total bobot tidak boleh melebihi 100% (sekarang: ${totalBobot.toStringAsFixed(1)}%)',
                    );
                  }

                  final assessment = AssessmentType(
                    id: existing?.id,
                    mingguId: _selectedRPS!.id!,
                    cpmkId: 0,
                    jenisAsessmen: selectedType!,
                    bobot: bobot,
                    createdAt: existing?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  if (isEdit) {
                    await _dbHelper.updateAssessmentType(assessment);
                  } else {
                    await _dbHelper.insertAssessmentType(assessment);
                  }

                  _onRPSSelected(_selectedRPS!);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEdit ? 'Penilaian diperbarui' : 'Penilaian ditambahkan',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Perbarui' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteAssessment(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus penilaian ini?'),
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
      await _dbHelper.deleteAssessmentType(id);
      _onRPSSelected(_selectedRPS!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Penilaian dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfigurasi Jenis Penilaian'),
        backgroundColor: const Color(0xFFE75480),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Minggu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FutureBuilder<List<RPSDetail>>(
              future: _rpsList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                final rpsList = snapshot.data ?? [];
                if (rpsList.isEmpty) {
                  return EmptyStateWidget(
                    message: 'Belum ada RPS untuk mata kuliah ini',
                    icon: Icons.schedule,
                  );
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: DropdownButton<RPSDetail>(
                    isExpanded: true,
                    value: _selectedRPS,
                    hint: const Text('Pilih Minggu...'),
                    underline: const SizedBox.shrink(),
                    items: rpsList.map((rps) {
                      return DropdownMenuItem(
                        value: rps,
                        child: Text('Minggu ke-${rps.mingguKe}: ${rps.topik}'),
                      );
                    }).toList(),
                    onChanged: (rps) {
                      if (rps != null) {
                        _onRPSSelected(rps);
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_selectedRPS != null) ...[
              const Text(
                'Jenis Penilaian',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_isLoading)
                const LoadingWidget()
              else if (_assessmentList.isEmpty)
                EmptyStateWidget(
                  message: 'Belum ada jenis penilaian untuk minggu ini',
                  icon: Icons.assessment,
                  onAdd: () => _showAssessmentDialog(),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _assessmentList.length,
                    itemBuilder: (context, index) {
                      final assessment = _assessmentList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ListTile(
                          title: Text(
                            assessment.jenisAsessmen,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text('Bobot: ${assessment.bobot}%'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showAssessmentDialog(existing: assessment),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _deleteAssessment(assessment.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (!_isLoading && _assessmentList.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    'Total Bobot: ${_assessmentList.fold<double>(0, (sum, a) => sum + a.bobot).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _assessmentList.fold<double>(0, (sum, a) => sum + a.bobot) == 100
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CustomButton(
                  label: 'Tambah Penilaian',
                  onPressed: () => _showAssessmentDialog(),
                ),
              ],
            ],
          ],
        ),
      ),
      floatingActionButton: _selectedRPS != null
          ? FloatingActionButton(
              onPressed: () => _showAssessmentDialog(),
              backgroundColor: AppColors.secondary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
