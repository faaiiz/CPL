import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_widgets.dart';

// Placeholder untuk fitur-fitur yang belum lengkap

class RPSListScreen extends StatelessWidget {
  const RPSListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola RPS'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text('Fitur RPS - Coming Soon'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ExportDataScreen extends StatelessWidget {
  const ExportDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text('Fitur Export - Coming Soon'),
      ),
    );
  }
}

class MahasiswaDashboardScreen extends StatelessWidget {
  final dynamic user;

  const MahasiswaDashboardScreen({
    super.key,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Mahasiswa'),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school,
              size: 64,
              color: AppColors.secondary,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Dashboard Mahasiswa',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Selamat datang',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.subtleText,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            CustomButton(
              label: 'Logout',
              width: 150,
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
