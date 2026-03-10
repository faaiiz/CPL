import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/cpl_master_model.dart';
import '../services/database_helper.dart';
import '../widgets/custom_widgets.dart';

class CPLMasterScreen extends StatefulWidget {
  const CPLMasterScreen({super.key});

  @override
  State<CPLMasterScreen> createState() => _CPLMasterScreenState();
}

class _CPLMasterScreenState extends State<CPLMasterScreen> {
  final _dbHelper = DatabaseHelper();
  late Future<List<CPLMaster>> _cplList;

  @override
  void initState() {
    super.initState();
    _loadCPL();
  }

  void _loadCPL() {
    setState(() {
      _cplList = _dbHelper.getAllCPLMaster();
    });
  }

  void _showCPLDialog({CPLMaster? existing}) {
    final isEdit = existing != null;
    final nomorController = TextEditingController(text: existing?.nomor ?? '');
    final deskripsiController = TextEditingController(text: existing?.deskripsi ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit CPL' : 'Tambah CPL'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomorController,
                decoration: InputDecoration(
                  label: const Text('Nomor CPL (1-7)'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: deskripsiController,
                decoration: InputDecoration(
                  label: const Text('Deskripsi CPL'),
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
                final cpl = CPLMaster(
                  id: existing?.id,
                  kodeCPL: 'CPL.${nomorController.text}',
                  deskripsi: deskripsiController.text,
                  nomor: nomorController.text,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                if (isEdit) {
                  await _dbHelper.updateCPLMaster(cpl);
                } else {
                  await _dbHelper.insertCPLMaster(cpl);
                }

                _loadCPL();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEdit ? 'CPL diperbarui' : 'CPL ditambahkan'),
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

  void _deleteCPL(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus CPL ini?'),
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
      await _dbHelper.deleteCPLMaster(id);
      _loadCPL();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CPL dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola CPL'),
        backgroundColor: const Color(0xFF3498DB),
        elevation: 4,
      ),
      body: FutureBuilder<List<CPLMaster>>(
        future: _cplList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return CustomErrorWidget(
              message: 'Error: ${snapshot.error}',
              onRetry: _loadCPL,
            );
          }

          final cplList = snapshot.data ?? [];

          if (cplList.isEmpty) {
            return EmptyStateWidget(
              message: 'Belum ada CPL',
              icon: Icons.school,
              onAdd: () => _showCPLDialog(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: cplList.length,
            itemBuilder: (context, index) {
              final cpl = cplList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                child: ListTile(
                  title: Text(
                    cpl.kodeCPL,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(cpl.deskripsi),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showCPLDialog(existing: cpl),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteCPL(cpl.id!),
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
        onPressed: () => _showCPLDialog(),
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
