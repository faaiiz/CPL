// 🔧 DIRECT DATABASE FIX: Fix Sub-CPMK → CPMK Mapping
// This script directly updates the sub_cpmk_cpmk_mapping table
// to correct the wrong mappings for Fisika Matematika I

import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactory;
  
  final dbPath = join(
    (await getDatabasesPath()),
    'cpl_app.db',
  );
  
  final db = await openDatabase(dbPath);
  
  print('╔════════════════════════════════════════════════════════════╗');
  print('║              FIXING Sub-CPMK → CPMK MAPPING                 ║');
  print('║         Fisika Matematika I (MK 110, CPMK 4)               ║');
  print('╚════════════════════════════════════════════════════════════╝\n');
  
  try {
    print('📊 CURRENT STATE (before fix):');
    final currentMappings = await db.query(
      'sub_cpmk_cpmk_mapping',
      where: 'sub_cpmk_id IN (132, 133, 134, 135)',
    );
    
    for (final mapping in currentMappings) {
      final subId = mapping['sub_cpmk_id'];
      final cpmkId = mapping['cpmk_id'];
      final status = cpmkId == 4 ? '✅' : '❌';
      print('   $status Sub-CPMK.$subId → CPMK.$cpmkId');
    }
    
    print('\n🔧 FIXING MAPPINGS:');
    
    // Update all 4 Sub-CPMKs to map to CPMK.4
    final updates = [
      {'subCpmkId': 132, 'cpmkId': 4},
      {'subCpmkId': 133, 'cpmkId': 4},
      {'subCpmkId': 134, 'cpmkId': 4},
      {'subCpmkId': 135, 'cpmkId': 4},
    ];
    
    int fixedCount = 0;
    final now = DateTime.now().toIso8601String();
    
    for (final update in updates) {
      final subCpmkId = update['subCpmkId'] as int;
      final cpmkId = update['cpmkId'] as int;
      
      // Try to find existing mapping
      final existing = await db.query(
        'sub_cpmk_cpmk_mapping',
        where: 'sub_cpmk_id = ? AND sub_cpmk_id IN (132, 133, 134, 135)',
        whereArgs: [subCpmkId],
        limit: 1,
      );
      
      if (existing.isNotEmpty) {
        // Update existing
        final count = await db.update(
          'sub_cpmk_cpmk_mapping',
          {
            'cpmk_id': cpmkId,
            'bobot': 25.0,
            'updated_at': now,
          },
          where: 'sub_cpmk_id = ? AND sub_cpmk_id IN (132, 133, 134, 135)',
          whereArgs: [subCpmkId],
        );
        if (count > 0) {
          print('   ✅ Updated Sub-CPMK.$subCpmkId → CPMK.$cpmkId');
          fixedCount++;
        }
      } else {
        // Insert new
        try {
          await db.insert(
            'sub_cpmk_cpmk_mapping',
            {
              'sub_cpmk_id': subCpmkId,
              'cpmk_id': cpmkId,
              'bobot': 25.0,
              'created_at': now,
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          print('   ✅ Inserted Sub-CPMK.$subCpmkId → CPMK.$cpmkId');
          fixedCount++;
        } catch (e) {
          print('   ⚠️  Could not insert: $e');
        }
      }
    }
    
    print('\n✅ FIX APPLIED ($fixedCount changes)\n');
    
    // Verify
    print('📊 VERIFICATION (after fix):');
    final verifyMappings = await db.query(
      'sub_cpmk_cpmk_mapping',
      where: 'sub_cpmk_id IN (132, 133, 134, 135)',
    );
    
    for (final mapping in verifyMappings) {
      final subId = mapping['sub_cpmk_id'];
      final cpmkId = mapping['cpmk_id'];
      final status = cpmkId == 4 ? '✅' : '❌';
      print('   $status Sub-CPMK.$subId → CPMK.$cpmkId');
    }
    
    print('\n✨ Database fix complete!\n');
    print('NEXT STEPS:');
    print('1. Hot restart the app (or restart the emulator)');
    print('2. Navigate to Fisika Matematika I');
    print('3. Click "Hitung CPL" again');
    print('4. Now should show 1 CPMK column instead of 4\n');
    
  } catch (e) {
    print('❌ ERROR: $e\n');
  } finally {
    await db.close();
    exit(0);
  }
}
