import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/app_constants.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/mahasiswa_screen.dart';
import 'screens/nilai_screen.dart';
import 'screens/excel_import_screen.dart';
import 'screens/cpl_calculation_screen.dart';
import 'screens/cpl_report_screen.dart';
import 'screens/rps_input_screen.dart';
import 'screens/rps_template_import_screen.dart';
import 'screens/mahasiswa_template_import_screen.dart';
import 'screens/matakuliah_template_import_screen.dart';
import 'screens/cpl_master_screen.dart';
import 'screens/cpmk_management_screen.dart';
import 'screens/sub_cpmk_management_screen.dart';
import 'screens/assessment_type_screen.dart';
import 'screens/cpmk_report_screen.dart';
import 'screens/assessment_outcomes_screen.dart';
import 'screens/nilai_batch_import_screen.dart';
import 'screens/translate_matakuliah_screen.dart';
import 'screens/placeholder_screens.dart';
import 'services/database_helper.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('✓ WidgetsFlutterBinding initialized');
    
    // Initialize date formatting for Indonesian locale
    await initializeDateFormatting('id_ID', null);
    print('✓ Date formatting initialized for id_ID locale');
    
    // Initialize sqflite for desktop only (not web)
    if (!kIsWeb) {
      try {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print('✓ SQLite FFI initialized');
      } catch (e) {
        print('⚠️  Warning: SQLite FFI init failed, falling back to default: $e');
      }
    } else {
      print('✓ Web platform detected - Using SQLite');
    }
    
    // Set up Flutter error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      print('❌ Flutter Error: ${details.exception}');
      print(details.stack);
    };
    
    runApp(const MyApp());
    print('✓ App started (Offline Mode)');
  } catch (e, stackTrace) {
    print('❌ Critical error during initialization: $e');
    print(stackTrace);
    runApp(ErrorApp(error: e.toString(), stackTrace: stackTrace.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('✓ MyApp.build() called');
    return MaterialApp(
      title: 'Sistem CPL',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.secondary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin_dashboard': (context) => AdminDashboardScreen(
          user: ModalRoute.of(context)!.settings.arguments as dynamic,
        ),
        '/mahasiswa_dashboard': (context) => MahasiswaDashboardScreen(
          user: ModalRoute.of(context)!.settings.arguments as dynamic,
        ),
        '/mahasiswa_list': (context) => const MahasiswaListScreen(),
        '/mahasiswa_form': (context) => MahasiswaFormScreen(
          mahasiswa: ModalRoute.of(context)!.settings.arguments as dynamic,
        ),
        '/nilai_entry': (context) => const NilaiEntryScreen(),
        '/excel_import': (context) => const ExcelImportScreen(),
        '/cpl_template_import': (context) => const ExcelImportScreen(
          initialImportType: 'cpl',
        ),
        '/cpmk_template_import': (context) => const ExcelImportScreen(
          initialImportType: 'cpmk',
        ),
        '/cpl_calculation': (context) => const CPLCalculationScreen(),
        '/cpl_report': (context) => const CPLReportScreen(),
        '/rps_input': (context) => const RPSInputScreen(),
        '/rps_template_import': (context) => const RPSTemplateImportScreen(),
        '/mahasiswa_template_import': (context) => const MahasiswaTemplateImportScreen(),
        '/matakuliah_template_import': (context) => const MatakuliahTemplateImportScreen(),
        '/cpl_master': (context) => const CPLMasterScreen(),
        '/cpmk_management': (context) => const CPMKManagementScreen(),
        '/sub_cpmk_management': (context) => SubCPMKManagementScreen(
          matakuliah: ModalRoute.of(context)!.settings.arguments as dynamic,
        ),
        '/assessment_type': (context) => AssessmentTypeScreen(
          matakuliahId: ModalRoute.of(context)!.settings.arguments as dynamic ?? 0,
        ),
        '/cpmk_report': (context) => const CPMKReportScreen(),
        '/assessment_outcomes': (context) => const AssessmentOutcomesScreen(),
        '/nilai_batch_import': (context) => const NilaiBatchImportScreen(),
        '/translate_matakuliah': (context) => TranslateMatakuliahScreen(
          dbHelper: ModalRoute.of(context)!.settings.arguments as DatabaseHelper,
        ),
        '/export_data': (context) => const ExportDataScreen(),
      },
    );
  }
}

/// Error app yang ditampilkan jika terjadi error saat initialization
class ErrorApp extends StatelessWidget {
  final String error;
  final String stackTrace;

  const ErrorApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistem CPL - Error',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Error Initialization'),
          backgroundColor: AppColors.danger,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Error Starting Application',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.danger),
              ),
              const SizedBox(height: 16),
              const Text(
                'Error Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(color: AppColors.danger, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Stack Trace:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    stackTrace,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Copy to clipboard
                  print('Error: $error\n\nStack Trace:\n$stackTrace');
                },
                child: const Text('Copy Error to Console'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}