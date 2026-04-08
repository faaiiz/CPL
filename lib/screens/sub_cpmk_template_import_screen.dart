import 'package:flutter/material.dart';
import '../services/template_service.dart';
import '../widgets/import_dialog.dart';
import '../constants/app_constants.dart';

class SubCPMKTemplateImportScreen extends StatefulWidget {
  final int matakuliahId;
  final String matakuliahNama;
  final String? matakuliahKode;
  final VoidCallback? onImportSuccess;

  const SubCPMKTemplateImportScreen({
    super.key,
    required this.matakuliahId,
    required this.matakuliahNama,
    this.matakuliahKode,
    this.onImportSuccess,
  });

  @override
  State<SubCPMKTemplateImportScreen> createState() =>
      _SubCPMKTemplateImportScreenState();
}

class _SubCPMKTemplateImportScreenState
    extends State<SubCPMKTemplateImportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Template Sub CPMK'),
        backgroundColor: AppColors.primary,
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
                      '📋 Panduan Import Template Sub CPMK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Klik "Unduh Template" untuk mengunduh template Excel',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '2. Buka template dan isi data Sub CPMK untuk mata kuliah ini',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '3. Kolom yang perlu diisi: Kode Sub CPMK dan Deskripsi',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '4. Simpan file dengan format .xlsx',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '5. Klik "Pilih File" dan pilih file yang sudah diisi',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '6. Klik "Import Data" untuk mengimpor ke database',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mata Kuliah Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                border: Border.all(color: AppColors.secondary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mata Kuliah Target:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.matakuliahNama,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Download Template Button
            ElevatedButton.icon(
              onPressed: () async {
                final path = await TemplateService.downloadSubCPMKTemplate(
                  matakuliahNama: widget.matakuliahNama,
                  kodeMatakuliah: widget.matakuliahKode,
                );
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
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.download),
              label: const Text('Unduh Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
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
                    importType: 'sub_cpmk',
                    matakuliahId: widget.matakuliahId,
                    onImportSuccess: (result) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Data berhasil diimpor'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                      widget.onImportSuccess?.call();
                    },
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Import Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Pastikan format Kode Sub CPMK konsisten (contoh: SUB-CPMK.1)',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Deskripsi dapat berupa penjelasan pembelajaran yang ingin dicapai',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Bisa menambah lebih dari 5 Sub CPMK sesuai kebutuhan',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• Data yang sudah ada tidak akan dihapus saat import',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Format Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(color: Colors.amber[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📝 Format Template:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...TemplateService.getTemplateInfo('sub_cpmk')['columns']!
                      .map(
                        (col) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            col,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                      ,
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
