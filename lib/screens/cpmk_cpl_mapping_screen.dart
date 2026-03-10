import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/matakuliah_model.dart';
import '../models/cpmk_model.dart';
import '../models/cpl_master_model.dart';
import '../models/cpmk_cpl_mapping_model.dart';
import '../services/database_helper.dart';
import '../widgets/custom_widgets.dart';

class CPMKCPLMappingScreen extends StatefulWidget {
  const CPMKCPLMappingScreen({super.key});

  @override
  State<CPMKCPLMappingScreen> createState() => _CPMKCPLMappingScreenState();
}

class _CPMKCPLMappingScreenState extends State<CPMKCPLMappingScreen> {
  final _dbHelper = DatabaseHelper();
  late Future<List<Matakuliah>> _matakuliahList;
  late Future<List<CPLMaster>> _cplList;
  Matakuliah? _selectedMatakuliah;
  List<CPMK> _cpmkList = [];
  List<CPMKCPLMapping> _mappingList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _matakuliahList = _dbHelper.getAllMatakuliah();
      _cplList = _dbHelper.getAllCPLMaster();
    });
  }

  void _onMatakuliahSelected(Matakuliah matakuliah) async {
    setState(() {
      _selectedMatakuliah = matakuliah;
      _isLoading = true;
      _cpmkList = [];
      _mappingList = [];
    });

    try {
      final cpmks = await _dbHelper.getCPMKByMatakuliah(matakuliah.id!);
      final mappings = <CPMKCPLMapping>[];
      
      // Load mappings for all CPMKs in this matakuliah
      for (var cpmk in cpmks) {
        final cpmkMappings = await _dbHelper.getMappingByCPMK(cpmk.id!);
        mappings.addAll(cpmkMappings);
      }
      
      setState(() {
        _cpmkList = cpmks;
        _mappingList = mappings;
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

  void _showMappingDialog({CPMKCPLMapping? existing}) async {
    final isEdit = existing != null;
    final cplList = await _dbHelper.getAllCPLMaster();
    CPLMaster? selectedCPL = existing != null
        ? cplList.firstWhere((cpl) => cpl.id == existing.cplId)
        : null;
    CPMK? selectedCPMK = existing != null
        ? _cpmkList.firstWhere((c) => c.id == existing.cpmkId)
        : null;
    final bobotController = TextEditingController(
      text: existing?.bobot.toString() ?? '100',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Pemetaan' : 'Pemetaan Matakuliah ke CPL & CPMK'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Matakuliah: ${_selectedMatakuliah!.nama}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // CPMK Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: DropdownButton<CPMK>(
                    isExpanded: true,
                    value: selectedCPMK,
                    hint: const Text('Pilih CPMK...'),
                    underline: const SizedBox.shrink(),
                    items: _cpmkList.map((cpmk) {
                      return DropdownMenuItem(
                        value: cpmk,
                        child: Text(cpmk.kodeCPMK),
                      );
                    }).toList(),
                    onChanged: (cpmk) {
                      setState(() => selectedCPMK = cpmk);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // CPL Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: DropdownButton<CPLMaster>(
                    isExpanded: true,
                    value: selectedCPL,
                    hint: const Text('Pilih CPL...'),
                    underline: const SizedBox.shrink(),
                    items: cplList.map((cpl) {
                      return DropdownMenuItem(
                        value: cpl,
                        child: Text(cpl.kodeCPL),
                      );
                    }).toList(),
                    onChanged: (cpl) {
                      setState(() => selectedCPL = cpl);
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
                if (selectedCPMK == null || selectedCPL == null || bobotController.text.isEmpty) {
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

                  final mapping = CPMKCPLMapping(
                    id: existing?.id,
                    cpmkId: selectedCPMK!.id!,
                    cplId: selectedCPL!.id!,
                    bobot: bobot,
                    createdAt: existing?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  if (isEdit) {
                    await _dbHelper.updateCPMKCPLMapping(mapping);
                  } else {
                    await _dbHelper.insertCPMKCPLMapping(mapping);
                  }

                  _onMatakuliahSelected(_selectedMatakuliah!);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(isEdit ? 'Pemetaan diperbarui' : 'Pemetaan ditambahkan'),
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

  void _deleteMapping(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus pemetaan ini?'),
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
      await _dbHelper.deleteCPMKCPLMapping(id);
      _onMatakuliahSelected(_selectedMatakuliah!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pemetaan dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemetaan Matakuliah'),
        backgroundColor: const Color(0xFF17A2B8),
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Mata Kuliah',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FutureBuilder<List<Matakuliah>>(
              future: _matakuliahList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                final matakuliahList = snapshot.data ?? [];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: DropdownButton<Matakuliah>(
                    isExpanded: true,
                    value: _selectedMatakuliah,
                    hint: const Text('Pilih Mata Kuliah...'),
                    underline: const SizedBox.shrink(),
                    items: matakuliahList.map((mk) {
                      return DropdownMenuItem(
                        value: mk,
                        child: Text('${mk.kode}: ${mk.nama}'),
                      );
                    }).toList(),
                    onChanged: (mk) {
                      if (mk != null) {
                        _onMatakuliahSelected(mk);
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_selectedMatakuliah != null) ...[
              const Text(
                'CPMK & CPL yang Terkait',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_isLoading)
                const LoadingWidget()
              else if (_mappingList.isEmpty)
                EmptyStateWidget(
                  message: 'Belum ada CPMK yang dipetakan ke CPL untuk mata kuliah ini',
                  icon: Icons.link_off,
                  onAdd: () => _showMappingDialog(),
                )
              else
                Expanded(
                  child: FutureBuilder<List<CPLMaster>>(
                    future: _cplList,
                    builder: (context, snapshot) {
                      final cplMap = {
                        for (var cpl in (snapshot.data ?? []))
                          cpl.id!: cpl.kodeCPL
                      };

                      return ListView.builder(
                        itemCount: _mappingList.length,
                        itemBuilder: (context, index) {
                          final mapping = _mappingList[index];
                          final cpmk = _cpmkList.firstWhere(
                            (c) => c.id == mapping.cpmkId,
                            orElse: () => CPMK(
                              id: -1,
                              matakuliahId: -1,
                              kodeCPMK: 'Unknown',
                              deskripsi: '',
                              createdAt: DateTime.now(),
                            ),
                          );
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: ListTile(
                              title: Text(
                                '${cpmk.kodeCPMK} → ${cplMap[mapping.cplId] ?? 'Unknown'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Bobot: ${mapping.bobot}%'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _showMappingDialog(existing: mapping),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteMapping(mapping.id!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              if (!_isLoading && _mappingList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: CustomButton(
                    label: 'Tambah Pemetaan',
                    onPressed: () => _showMappingDialog(),
                  ),
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: _selectedMatakuliah != null
          ? FloatingActionButton(
              onPressed: () => _showMappingDialog(),
              backgroundColor: AppColors.secondary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
