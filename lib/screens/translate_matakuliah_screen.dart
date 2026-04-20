import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/matakuliah_model.dart';

class TranslateMatakuliahScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const TranslateMatakuliahScreen({
    Key? key,
    required this.dbHelper,
  }) : super(key: key);

  @override
  State<TranslateMatakuliahScreen> createState() =>
      _TranslateMatakuliahScreenState();
}

class _TranslateMatakuliahScreenState extends State<TranslateMatakuliahScreen> {
  late DatabaseHelper _dbHelper;
  List<Matakuliah> _matakuliahList = [];
  Map<int, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.dbHelper;
    _loadMatakuliah();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMatakuliah() async {
    try {
      setState(() => _isLoading = true);
      final matakuliahList = await _dbHelper.getAllMatakuliah();
      setState(() {
        _matakuliahList = matakuliahList;
        // Initialize controllers with existing translations
        for (var mk in _matakuliahList) {
          if (mk.id != null) {
            _controllers[mk.id!] = TextEditingController(text: mk.namaEng ?? '');
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading matakuliah: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSingleTranslation(Matakuliah mk) async {
    try {
      final engName = _controllers[mk.id]?.text.trim() ?? '';
      final updatedMk = mk.copyWith(namaEng: engName.isEmpty ? null : engName);
      
      await _dbHelper.updateMatakuliah(updatedMk);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Terjemahan disimpan untuk ${mk.nama}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAllTranslations() async {
    try {
      setState(() => _isSaving = true);
      
      for (var mk in _matakuliahList) {
        if (mk.id != null) {
          final engName = _controllers[mk.id]?.text.trim() ?? '';
          if (engName.isNotEmpty || mk.namaEng != null) {
            final updatedMk = mk.copyWith(
              namaEng: engName.isEmpty ? null : engName,
            );
            await _dbHelper.updateMatakuliah(updatedMk);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Semua terjemahan berhasil disimpan'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Translate Nama Matakuliah'),
        backgroundColor: const Color(0xFF8E44AD),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _matakuliahList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tidak ada matakuliah',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Header Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: const Color(0xFF8E44AD).withOpacity(0.1),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8E44AD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.translate,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Terjemahkan Nama Matakuliah',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF8E44AD),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Isi nama matakuliah dalam bahasa inggris untuk ${_matakuliahList.length} mata kuliah',
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
                    ),
                    // List of Matakuliah
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _matakuliahList.length,
                        itemBuilder: (context, index) {
                          final mk = _matakuliahList[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Kode dan Nama (Indonesia)
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8E44AD)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          mk.kode,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF8E44AD),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Indonesian Name:',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              mk.nama,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // English Name TextField
                                  TextField(
                                    controller: _controllers[mk.id],
                                    decoration: InputDecoration(
                                      labelText: 'English Name',
                                      hintText: 'Masukkan nama dalam bahasa inggris',
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      prefixIcon: const Icon(Icons.language),
                                      contentPadding: const EdgeInsets.all(12),
                                    ),
                                    onChanged: (value) {
                                      // Auto-save on change
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  // Quick Save Button
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _saveSingleTranslation(mk),
                                      icon: const Icon(Icons.save, size: 16),
                                      label: const Text('Save'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        backgroundColor:
                                            const Color(0xFF8E44AD),
                                      ),
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
                ),
      floatingActionButton: _matakuliahList.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _saveAllTranslations,
              backgroundColor: const Color(0xFF8E44AD),
              label: _isSaving
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
                  : const Text('Save All'),
              icon: !_isSaving ? const Icon(Icons.save_alt) : null,
            )
          : null,
    );
  }
}
