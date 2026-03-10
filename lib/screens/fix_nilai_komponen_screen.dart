import 'package:flutter/material.dart';
import '../models/mahasiswa_model.dart';
import '../services/database_helper.dart';
import '../utils/fix_nilai_komponen.dart';

/// Screen untuk diagnosa dan fix nilai_komponen yang hilang
class FixNilaiKomponenScreen extends StatefulWidget {
  const FixNilaiKomponenScreen({Key? key}) : super(key: key);

  @override
  State<FixNilaiKomponenScreen> createState() => _FixNilaiKomponenScreenState();
}

class _FixNilaiKomponenScreenState extends State<FixNilaiKomponenScreen> {
  final _dbHelper = DatabaseHelper();
  final _fixHelper = FixNilaiKomponenHelper();

  late Future<List<Mahasiswa>> _mahasiswaList;
  int? _selectedMahasiswaId;
  String _diagnosticOutput = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mahasiswaList = _dbHelper.getAllMahasiswa();
  }

  void _runDiagnostic() async {
    if (_selectedMahasiswaId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih mahasiswa terlebih dahulu')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Jalankan diagnostic
      await _fixHelper.diagnosticNilaiKomponen(_selectedMahasiswaId!);
      
      setState(() {
        _diagnosticOutput = 'Diagnostic selesai. Lihat console untuk detail output.';
      });
    } catch (e) {
      setState(() {
        _diagnosticOutput = 'ERROR: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _fixAllMissing() async {
    if (_selectedMahasiswaId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih mahasiswa terlebih dahulu')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Fix'),
        content: const Text(
            'Ini akan auto-populate nilai_komponen yang hilang dengan proporsi standard.\n\n'
            'Proporsi: Aktivitas 15%, Proyek 15%, Kuis 15%, Tugas 15%, UTS 20%, UAS 20%\n\n'
            'Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final result =
          await _fixHelper.fixAllMissingNilaiKomponenForMahasiswa(_selectedMahasiswaId!);

      setState(() {
        _diagnosticOutput = '''
🔧 FIX SELESAI!

✅ Fixed: ${result['fixed']}
⏭️  Skipped: ${result['skipped']}
❌ Failed: ${result['failed']}

${result['errors'].isNotEmpty ? 'Errors: ${result['errors'].join(', ')}' : ''}
      ''';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result['fixed']} nilai_komponen berhasil diperbaiki!')),
      );
    } catch (e) {
      setState(() {
        _diagnosticOutput = 'ERROR: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Fix Nilai Komponen'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '📋 Diagnostic & Fix Tool\n\n'
                'Gunakan tool ini untuk:\n'
                '1. Diagnosa nilai_komponen yang hilang\n'
                '2. Auto-populate dengan proporsi standard\n\n'
                'Masalah Umum: Nilai diimport hanya sebagai nilai akhir (tanpa breakdown komponen), sehingga tabel nilai_komponen kosong.\n\n'
                'Solusi: Populate otomatis dengan proporsi standard atau re-import dengan detail komponen.',
              ),
            ),
            const SizedBox(height: 20),

            // Mahasiswa selector
            const Text('Pilih Mahasiswa:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List<Mahasiswa>>(
              future: _mahasiswaList,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                return DropdownButton<int>(
                  isExpanded: true,
                  hint: const Text('Pilih mahasiswa...'),
                  value: _selectedMahasiswaId,
                  items: snapshot.data!
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text('${m.nama} (${m.nim})'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedMahasiswaId = value);
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _runDiagnostic,
                    icon: const Icon(Icons.search),
                    label: const Text('Diagnosa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fixAllMissing,
                    icon: const Icon(Icons.build),
                    label: const Text('Fix All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Output
            if (_diagnosticOutput.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              const Text('Output:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(minHeight: 200),
                child: SelectableText(
                  _diagnosticOutput,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
