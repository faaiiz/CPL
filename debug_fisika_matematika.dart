import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  // Initialize FFI for desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'cpl_app.db');
  
  print('🔍 Opening database: $path\n');
  
  final db = await openDatabase(path);
  
  try {
    // 1️⃣ Cari Fisika Matematika I
    print('=' * 80);
    print('1️⃣ MENCARI MATA KULIAH "Fisika Matematika"');
    print('=' * 80);
    
    final matakuliahResult = await db.query(
      'matakuliah',
      where: 'nama LIKE ?',
      whereArgs: ['%Fisika Matematika%'],
    );
    
    if (matakuliahResult.isEmpty) {
      print('❌ Mata kuliah tidak ditemukan');
      await db.close();
      return;
    }
    
    for (final mk in matakuliahResult) {
      print('\n✅ Mata Kuliah Ditemukan:');
      print('   ID: ${mk['id']}');
      print('   Nama: ${mk['nama']}');
      print('   Kode: ${mk['kode']}');
      print('   SKU: ${mk['sks']}');
    }
    
    final matakuliahId = matakuliahResult.first['id'] as int;
    
    // 2️⃣ Cari CPMK untuk mata kuliah ini
    print('\n' + '=' * 80);
    print('2️⃣ CPMK UNTUK MATA KULIAH ID=$matakuliahId');
    print('=' * 80);
    
    final cpmkResult = await db.query(
      'cpmk',
      where: 'matakuliah_id = ?',
      whereArgs: [matakuliahId],
    );
    
    if (cpmkResult.isEmpty) {
      print('❌ Tidak ada CPMK untuk mata kuliah ini');
    } else {
      print('\n✅ CPMK Ditemukan (${cpmkResult.length} item):');
      for (final cpmk in cpmkResult) {
        print('\n   CPMK ID: ${cpmk['id']}');
        print('   Kode: ${cpmk['kode_cpmk'] ?? cpmk['kodeCPMK'] ?? '-'}');
        print('   Deskripsi: ${cpmk['deskripsi']}');
        print('   Urutan: ${cpmk['urutan']}');
      }
    }
    
    final cpmkIds = cpmkResult.map((c) => c['id'] as int).toList();
    print('\n   📋 CPMK IDs: $cpmkIds');
    
    // 3️⃣ Cari Sub-CPMK untuk mata kuliah ini
    print('\n' + '=' * 80);
    print('3️⃣ SUB-CPMK UNTUK MATA KULIAH ID=$matakuliahId');
    print('=' * 80);
    
    final subCpmkResult = await db.query(
      'sub_cpmk',
      where: 'matakuliah_id = ?',
      whereArgs: [matakuliahId],
    );
    
    if (subCpmkResult.isEmpty) {
      print('❌ Tidak ada Sub-CPMK untuk mata kuliah ini');
    } else {
      print('\n✅ Sub-CPMK Ditemukan (${subCpmkResult.length} item):');
      for (final sub in subCpmkResult) {
        print('\n   Sub-CPMK ID: ${sub['id']}');
        print('   Kode: ${sub['kode_sub_cpmk'] ?? sub['kodeSubCPMK'] ?? '-'}');
        print('   Deskripsi: ${sub['deskripsi']}');
        print('   CPMK Parent: ${sub['cpmk_id']}');
      }
    }
    
    final subCpmkIds = subCpmkResult.map((c) => c['id'] as int).toList();
    print('\n   📋 Sub-CPMK IDs: $subCpmkIds');
    
    // 4️⃣ Cari RPS untuk mata kuliah ini
    print('\n' + '=' * 80);
    print('4️⃣ RPS UNTUK MATA KULIAH ID=$matakuliahId');
    print('=' * 80);
    
    final rpsResult = await db.query(
      'rps',
      where: 'matakuliah_id = ?',
      whereArgs: [matakuliahId],
    );
    
    if (rpsResult.isEmpty) {
      print('❌ Tidak ada RPS untuk mata kuliah ini');
    } else {
      print('\n✅ RPS Ditemukan (${rpsResult.length} item):');
      for (final rps in rpsResult) {
        print('\n   RPS ID: ${rps['id']}');
        print('   File: ${rps['file_name']}');
        print('   Upload: ${rps['upload_date']}');
      }
    }
    
    // final rpsId = rpsResult.isNotEmpty ? rpsResult.first['id'] as int : null;
    
    // 5️⃣ Cari RPS Detail untuk mata kuliah ini
    print('\n' + '=' * 80);
    print('5️⃣ RPS DETAIL UNTUK MATA KULIAH ID=$matakuliahId');
    print('=' * 80);
    
    final rpsDetailResult = await db.query(
      'rps_detail',
      where: 'matakuliah_id = ?',
      whereArgs: [matakuliahId],
      orderBy: 'minggu_ke ASC',
    );
    
    if (rpsDetailResult.isEmpty) {
      print('❌ Tidak ada RPS Detail untuk mata kuliah ini');
    } else {
      print('\n✅ RPS Detail Ditemukan (${rpsDetailResult.length} item):');
      for (final detail in rpsDetailResult) {
        print('\n   Minggu: ${detail['minggu_ke']}');
        print('   cpmk_ids: ${detail['cpmk_ids']}');
        print('   sub_cpmk_ids: ${detail['sub_cpmk_ids']}');
        print('   cpl_ids: ${detail['cpl_ids']}');
      }
    }
    
    // 6️⃣ Analisis masalah
    print('\n' + '=' * 80);
    print('6️⃣ ANALISIS MASALAH');
    print('=' * 80);
    
    if (rpsDetailResult.isNotEmpty) {
      final firstDetail = rpsDetailResult.first;
      final cpmkIdsStr = firstDetail['cpmk_ids'] as String?;
      final subCpmkIdsStr = firstDetail['sub_cpmk_ids'] as String?;
      
      print('\nCPMK IDs yang seharusnya: $cpmkIds');
      print('CPMK IDs di RPS Detail: $cpmkIdsStr');
      print('Sub-CPMK IDs yang ada: $subCpmkIds');
      print('Sub-CPMK IDs di RPS Detail: $subCpmkIdsStr');
      
      // Parse IDs
      final cpmkIdsInRPS = cpmkIdsStr?.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList() ?? [];
      // final subCpmkIdsInRPS = subCpmkIdsStr?.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList() ?? [];
      
      print('\n🔍 DETEKSI:');
      if (cpmkIdsInRPS.isEmpty) {
        print('❌ TIDAK ADA CPMK IDs di RPS Detail!');
      } else if (cpmkIdsInRPS == subCpmkIds) {
        print('🚨 BUG TERDETEKSI: RPS cpmk_ids berisi Sub-CPMK IDs!');
        print('   ❌ Seharusnya: Single CPMK ID = ${cpmkIds.first}');
        print('   ❌ Aktual: Sub-CPMK IDs = $cpmkIdsInRPS');
        print('\n   ✅ SOLUSI:');
        print('   Jalankan perbaikan database dengan:');
        print('   ```dart');
        print('   await dbHelper.fixRPSCpmkIds(');
        print('     matakuliahId: $matakuliahId,');
        print('     correctCpmkId: ${cpmkIds.first},');
        print('   );');
        print('   ```');
      } else if (cpmkIdsInRPS.length == 1 && cpmkIdsInRPS.first == cpmkIds.first) {
        print('✅ OK: RPS Detail sudah memiliki CPMK ID yang benar');
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    await db.close();
  }
}
