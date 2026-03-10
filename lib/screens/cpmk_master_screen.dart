import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/cpmk_model.dart';
import '../services/database_helper.dart';
import '../widgets/custom_widgets.dart';

class CPMKMasterScreen extends StatefulWidget {
  const CPMKMasterScreen({super.key});

  @override
  State<CPMKMasterScreen> createState() => _CPMKMasterScreenState();
}

class _CPMKMasterScreenState extends State<CPMKMasterScreen> {
  final _dbHelper = DatabaseHelper();
  late Future<List<CPMK>> _cpmkList;

  @override
  void initState() {
    super.initState();
    _loadCPMK();
  }

  void _loadCPMK() {
    setState(() {
      _cpmkList = _dbHelper.getAllCPMK().then((list) {
        // Filter hanya CPMK program studi (matakuliah_id = 0)
        return list.where((cpmk) => cpmk.matakuliahId == 0).toList();
      });
    });
  }

  void _showCPMKDialog({CPMK? existing}) {
    final isEdit = existing != null;
    final nomorController = TextEditingController(text: existing?.kodeCPMK.replaceAll('CPMK.', '') ?? '');
    final deskripsiController = TextEditingController(text: existing?.deskripsi ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit CPMK Program Studi' : 'Tambah CPMK Program Studi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomorController,
                decoration: InputDecoration(
                  label: const Text('Nomor CPMK (misal: 1, 2, 3)'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  prefixText: 'CPMK.',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: deskripsiController,
                decoration: InputDecoration(
                  label: const Text('Deskripsi CPMK Program Studi'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                maxLines: 4,
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
              if (nomorController.text.isEmpty || deskripsiController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua field harus diisi')),
                );
                return;
              }

              try {
                final cpmk = CPMK(
                  id: existing?.id,
                  matakuliahId: 0, // 0 untuk CPMK Program Studi level
                  kodeCPMK: 'CPMK.${nomorController.text}',
                  deskripsi: deskripsiController.text,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (isEdit) {
                  await _dbHelper.updateCPMK(cpmk);
                } else {
                  await _dbHelper.insertCPMK(cpmk);
                }

                _loadCPMK();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'CPMK diperbarui' : 'CPMK ditambahkan'),
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
    );
  }

  void _deleteCPMK(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus CPMK ini?'),
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
      await _dbHelper.deleteCPMK(id);
      _loadCPMK();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CPMK dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola CPMK Program Studi'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: FutureBuilder<List<CPMK>>(
        future: _cpmkList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return CustomErrorWidget(
              message: 'Error: ${snapshot.error}',
              onRetry: _loadCPMK,
            );
          }

          final cpmkList = snapshot.data ?? [];

          if (cpmkList.isEmpty) {
            return EmptyStateWidget(
              message: 'Belum ada CPMK Program Studi',
              icon: Icons.flag_outlined,
              onAdd: () => _showCPMKDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: cpmkList.length,
            itemBuilder: (context, index) {
              final cpmk = cpmkList[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ListTile(
                  title: Text(
                    cpmk.kodeCPMK,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(cpmk.deskripsi),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showCPMKDialog(existing: cpmk),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCPMK(cpmk.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCPMKDialog(),
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
