// 🔧 QUICK FIX SCRIPT: Fix Sub-CPMK → CPMK Mapping
// Usage: dart run fix_subcpmk_mapping.dart
//
// This script:
// 1. Identifies the correct CPMK for Fisika Matematika I
// 2. Updates SUB-CPMK IDs 132-135 to all map to that CPMK
// 3. Prints results for verification

import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/services/database_helper.dart';
import 'lib/models/sub_cpmk_cpmk_mapping_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dbHelper = DatabaseHelper();
  
  print('╔════════════════════════════════════════════════════════════╗');
  print('║  FIX: Sub-CPMK → CPMK Mapping untuk Fisika Matematika I   ║');
  print('╚════════════════════════════════════════════════════════════╝\n');
  
  // Get Fisika Matematika I (MK ID 110)
  final mk = await dbHelper.getMatakuliahById(110);
  print('📚 MATAKULIAH:');
  print('   Kode: ${mk?.kode}');
  print('   Nama: ${mk?.nama}');
  print('   ID: 110\n');
  
  // Get all CPMK for this matakuliah
  final cpmks = await dbHelper.getCPMKByMatakuliah(110);
  print('📌 CPMK untuk matakuliah ini:');
  for (final cpmk in cpmks) {
    print('   ID: ${cpmk.id}, Kode: ${cpmk.kodeCPMK}');
  }
  
  if (cpmks.isEmpty) {
    print('❌ ERROR: Tidak ada CPMK untuk matakuliah ini!');
    exit(1);
  }
  
  // Assume the first (and should be only) CPMK is the parent
  final parentCpmkId = cpmks.first.id;
  
  // Get all Sub-CPMKs for this matakuliah
  final subCpmks = await dbHelper.getSubCPMKByMatakuliah(110);
  print('\n📝 SUB-CPMK untuk matakuliah ini:');
  for (final subCpmk in subCpmks) {
    print('   ID: ${subCpmk.id}, Kode: ${subCpmk.kodeSubCPMK}');
  }
  
  if (subCpmks.isEmpty) {
    print('❌ ERROR: Tidak ada Sub-CPMK!');
    exit(1);
  }
  
  // Check current mappings
  print('\n🔍 CURRENT MAPPINGS:');
  final currentMappings = await dbHelper.getAllSubCPMKCPMKMappings();
  for (final mapping in currentMappings) {
    final subId = mapping is Map ? mapping['sub_cpmk_id'] : mapping.subCpmkId;
    final cpmkId = mapping is Map ? mapping['cpmk_id'] : mapping.cpmkId;
    
    // Only show mappings for our Sub-CPMKs
    final isOurSubCpmk = subCpmks.any((s) => s.id == subId);
    if (isOurSubCpmk) {
      final wrongMapping = cpmkId != parentCpmkId;
      final status = wrongMapping ? '❌' : '✅';
      print('   $status Sub-CPMK.$subId → CPMK.$cpmkId (should be CPMK.$parentCpmkId)');
    }
  }
  
  // Fix the mappings
  print('\n🔧 FIXING MAPPINGS:');
  int fixedCount = 0;
  
  for (final subCpmk in subCpmks) {
    try {
      if (subCpmk.id == null) continue;
      final mappings = await dbHelper.getSubCPMKCPMKMapping(subCpmk.id!);
      
      if (mappings.isEmpty) {
        print('   ⚠️  Sub-CPMK.${subCpmk.id}: No mapping found, creating...');
        // Insert new mapping
        final newMapping = SubCPMKCPMKMapping(
          subCpmkId: subCpmk.id!,
          cpmkId: parentCpmkId!,
          bobot: 25.0, // Equal weight for each Sub-CPMK
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await dbHelper.insertSubCPMKCPMKMapping(newMapping);
        print('       → Created Sub-CPMK.${subCpmk.id} → CPMK.$parentCpmkId');
        fixedCount++;
      } else {
        final mapping = mappings.first;
        final currentCpmkId = mapping is Map 
            ? mapping['cpmk_id'] as int 
            : mapping.cpmkId as int;
        
        if (currentCpmkId != parentCpmkId) {
          // Update existing mapping
          final updatedMapping = mapping is Map
              ? SubCPMKCPMKMapping.fromMap(mapping.cast<String, dynamic>())
              : mapping;
          
          // Create updated version with correct CPMK ID and timestamp
          final fixedMapping = updatedMapping.copyWith(
            cpmkId: parentCpmkId,
            bobot: 25.0, // Equal weight for each Sub-CPMK
            updatedAt: DateTime.now(),
          );
          
          await dbHelper.updateSubCPMKCPMKMapping(fixedMapping);
          print('   ✅ Sub-CPMK.${subCpmk.id}: $currentCpmkId → $parentCpmkId');
          fixedCount++;
        } else {
          print('   ✓ Sub-CPMK.${subCpmk.id}: Already correct (→ CPMK.$parentCpmkId)');
        }
      }
    } catch (e) {
      print('   ❌ Error fixing Sub-CPMK.${subCpmk.id}: $e');
    }
  }
  
  // Verify fixes
  print('\n✨ VERIFICATION:');
  final finalMappings = await dbHelper.getAllSubCPMKCPMKMappings();
  for (final subCpmk in subCpmks) {
    final finalMapping = finalMappings.firstWhere(
      (m) => (m is Map ? m['sub_cpmk_id'] : m.subCpmkId) == subCpmk.id,
      orElse: () => null,
    );
    
    if (finalMapping != null) {
      final cpmkId = finalMapping is Map ? finalMapping['cpmk_id'] : finalMapping.cpmkId;
      final correct = cpmkId == parentCpmkId ? '✅' : '❌';
      print('   $correct Sub-CPMK.${subCpmk.id} → CPMK.$cpmkId');
    }
  }
  
  print('\n✅ Done! Fixed $fixedCount mappings.');
  print('\nSekarang jalankan aplikasi dan lihat apakah Fisika Matematika I');
  print('menampilkan 1 CPMK (bukan 4 CPMK lagi).\n');
  
  exit(0);
}
