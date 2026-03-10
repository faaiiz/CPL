import 'package:flutter/material.dart';
import '../services/template_service.dart';
import '../widgets/import_dialog.dart';

class CPLTemplateImportScreen extends StatefulWidget {
  const CPLTemplateImportScreen({super.key});

  @override
  State<CPLTemplateImportScreen> createState() =>
      _CPLTemplateImportScreenState();
}

class _CPLTemplateImportScreenState extends State<CPLTemplateImportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Template CPL'),
        backgroundColor: const Color(0xFF2980B9),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Panduan Import Template CPL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Klik "Unduh Template" untuk mengunduh template Excel ke folder Downloads',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '2. Buka template dan isi data CPL sesuai kolom yang tersedia (Nomor: 1-7)',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '3. Simpan file dengan format .xlsx atau .csv',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '4. Klik "Pilih File" dan pilih file yang sudah diisi',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '5. Klik "Import Data" untuk mengimpor ke database',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Download Template Button
            ElevatedButton.icon(
              onPressed: () async {
                final path = await TemplateService.downloadCPLTemplate();
                if (!mounted) return;
                
                if (path != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Template disimpan\n$path'),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gagal mengunduh template'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Unduh Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Import Button
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ImportDialog(
                    importType: 'cpl',
                    onImportSuccess: (result) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Data berhasil diimpor'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '💡 Tips:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Format file yang didukung: .xlsx, .xls, .csv',
                    style: TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Nomor CPL harus bernilai 1-7',
                    style: TextStyle(fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Template akan disimpan di folder Downloads',
                    style: TextStyle(fontSize: 11, color: Colors.blue[900]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
