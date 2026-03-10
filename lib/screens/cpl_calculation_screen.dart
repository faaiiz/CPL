import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/cpl_calculation_service.dart';
import '../widgets/custom_widgets.dart';

class CPLCalculationScreen extends StatefulWidget {
  const CPLCalculationScreen({super.key});

  @override
  State<CPLCalculationScreen> createState() => _CPLCalculationScreenState();
}

class _CPLCalculationScreenState extends State<CPLCalculationScreen> {
  final _cplService = CPLCalculationService();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  Future<void> _calculateAllCPL() async {
    setState(() => _isLoading = true);

    try {
      await _cplService.calculateCPLForAllMahasiswa();
      setState(() {
        _isSuccess = true;
        _message =
            'CPL berhasil dihitung untuk semua mahasiswa';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perhitungan CPL selesai'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hitung CPL'),
        backgroundColor: const Color(0xFF27AE60),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.secondary),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: AppColors.secondary,
                        ),
                        SizedBox(width: AppSpacing.md),
                        Text(
                          'Informasi Perhitungan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Sistem ini akan menghitung CPL berdasarkan:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildCriteria('IPK (Bobot 60%)',
                        'Nilai rata-rata tertimbang dengan SKS'),
                    _buildCriteria('Rata-rata Nilai (Bobot 40%)',
                        'Rata-rata nilai numerik dari semua matakuliah'),
                    _buildCriteria(
                        'Total SKU',
                        'Jumlah SKU yang diambil (minimal 144 SKU untuk lulus)'),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kriteria Lulus:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            '• IPK ≥ 2.0',
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            '• Rata-rata Nilai ≥ 2.0',
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            '• Total SKU ≥ 144',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              const Text(
                'Aksi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Calculate Button
              CustomButton(
                label: 'Hitung CPL Semua Mahasiswa',
                isLoading: _isLoading,
                onPressed: _calculateAllCPL,
                icon: const Icon(
                  Icons.calculate,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Result Message
              if (_message != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: _isSuccess
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess
                            ? Icons.check_circle
                            : Icons.error,
                        color: _isSuccess
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _isSuccess
                                ? AppColors.success
                                : AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),

              // Info Section
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        const Text(
                          'Catatan Penting',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Pastikan semua data nilai mahasiswa sudah diinput dengan benar sebelum melakukan perhitungan CPL. Proses ini akan menghitung ulang seluruh CPL untuk semua mahasiswa.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCriteria(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.subtleText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
