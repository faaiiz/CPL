import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  // Get database path same as app does
  final dbDir = await databaseFactory.getDatabasesPath();
  final dbPath = join(dbDir, 'cpl.db');
  
  print('Database path: $dbPath');
  print('Database exists: ${File(dbPath).existsSync()}');
  
  final db = await databaseFactory.openDatabase(dbPath);
  
  try {
    // Get Kalkulus and Vektor IDs first
    final matakuliahResult = await db.query('matakuliah');
    print('\n=== MATAKULIAH ===');
    print('Total matakuliah: ${matakuliahResult.length}');
    
    int? kalkulusId;
    int? vektorId;
    
    for (final mk in matakuliahResult) {
      final id = mk['id'] as int;
      final nama = mk['nama'] as String?;
      final kode = mk['kode'] as String?;
      print('ID: $id, Kode: $kode, Nama: $nama');
      
      if (kode?.toUpperCase().contains('KALKULUS') ?? false) kalkulusId = id;
      if (kode?.toUpperCase().contains('VEKTOR') ?? false) vektorId = id;
    }
    
    print('\nKalkulus ID: $kalkulusId');
    print('Vektor ID: $vektorId');
    
    // Check RPS detail for Kalkulus
    if (kalkulusId != null) {
      print('\n=== RPS KALKULUS (MK ID: $kalkulusId) ===');
      final rpsKalkulus = await db.query(
        'rps_detail',
        where: 'matakuliah_id = ?',
        whereArgs: [kalkulusId],
        orderBy: 'minggu_ke ASC',
      );
      
      print('Total minggu: ${rpsKalkulus.length}');
      for (final rps in rpsKalkulus) {
        final mingguKe = rps['minggu_ke'] as int?;
        final bobot = rps['bobot'] as double?;
        final cpmkIds = rps['cpmk_ids'] as String?;
        final cplIds = rps['cpl_ids'] as String?;
        final subCpmkIds = rps['sub_cpmk_ids'] as String?;
        
        print('Minggu $mingguKe: bobot=$bobot, cpmk_ids=$cpmkIds, cpl_ids=$cplIds, sub_cpmk_ids=$subCpmkIds');
      }
    }
    
    // Check RPS detail for Vektor
    if (vektorId != null) {
      print('\n=== RPS VEKTOR (MK ID: $vektorId) ===');
      final rpsVektor = await db.query(
        'rps_detail',
        where: 'matakuliah_id = ?',
        whereArgs: [vektorId],
        orderBy: 'minggu_ke ASC',
      );
      
      print('Total minggu: ${rpsVektor.length}');
      for (final rps in rpsVektor) {
        final mingguKe = rps['minggu_ke'] as int?;
        final bobot = rps['bobot'] as double?;
        final cpmkIds = rps['cpmk_ids'] as String?;
        final cplIds = rps['cpl_ids'] as String?;
        final subCpmkIds = rps['sub_cpmk_ids'] as String?;
        
        print('Minggu $mingguKe: bobot=$bobot, cpmk_ids=$cpmkIds, cpl_ids=$cplIds, sub_cpmk_ids=$subCpmkIds');
      }
    }
    
    // Check CPMK data
    print('\n=== CPMK DATA ===');
    final cpmkResult = await db.query('cpmk');
    print('Total CPMK: ${cpmkResult.length}');
    for (final cpmk in cpmkResult) {
      print('ID: ${cpmk['id']}, Kode: ${cpmk['kode_cpmk']}, MK ID: ${cpmk['matakuliah_id']}, Deskripsi: ${cpmk['deskripsi']}');
    }
    
    // Check CPL data
    print('\n=== CPL DATA ===');
    final cplResult = await db.query('cpl_master');
    print('Total CPL: ${cplResult.length}');
    for (final cpl in cplResult) {
      print('ID: ${cpl['id']}, Kode: ${cpl['kode_cpl']}, Deskripsi: ${cpl['deskripsi']}');
    }
    
  } catch (e, stackTrace) {
    print('Error: $e');
    print('StackTrace: $stackTrace');
  } finally {
    await db.close();
  }
}
