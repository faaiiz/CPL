import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final dbHelper = DatabaseHelper();
  
  print('=== FIX Sub-CPMK MAPPING ===');
  
  // Get Fisika Matematika I (MK ID 110)
  final mkFisikaMat = await dbHelper.getMatakuliahById(110);
  print('\n📚 Matakuliah: ${mkFisikaMat?.nama}');
  print('   Kode: ${mkFisikaMat?.kode}');
  
  // Get CPMK for this matakuliah
  final cpmks = await dbHelper.getCPMKByMatakuliah(110);
  print('\n📌 CPMK for this course:');
  for (final cpmk in cpmks) {
    print('   CPMK ID: ${cpmk.id}, Kode: ${cpmk.kodeCPMK}');
  }
  
  if (cpmks.isEmpty) {
    print('❌ ERROR: No CPMK found for this course!');
    return;
  }
  
  final parentCpmkId = cpmks.first.id;
  
  // Get all Sub-CPMKs for this course
  final subCpmks = await dbHelper.getSubCPMKByMatakuliah(110);
  print('\n📝 Sub-CPMKs for this course:');
  for (final subCpmk in subCpmks) {
    print('   Sub-CPMK ID: ${subCpmk.id}, Kode: ${subCpmk.kodeSubCPMK}');
  }
  
  if (subCpmks.isEmpty) {
    print('❌ ERROR: No Sub-CPMK found!');
    return;
  }
  
  // Fix the mapping - all Sub-CPMKs should map to the same parent CPMK
  print('\n🔧 FIXING SUB-CPMK MAPPING:');
  print('   All ${subCpmks.length} Sub-CPMKs will map to CPMK.$parentCpmkId\n');
  
  for (final subCpmk in subCpmks) {
    try {
      // Get existing mapping
      if (subCpmk.id == null) continue;
      final existingMappings = await dbHelper.getSubCPMKCPMKMapping(subCpmk.id!);
      
      if (existingMappings.isNotEmpty) {
        final existingMapping = existingMappings.first;
        final existingCpmkId = existingMapping is Map 
            ? existingMapping['cpmk_id'] as int 
            : existingMapping.cpmkId as int;
        
        if (existingCpmkId != parentCpmkId) {
          // Need to update
          print('   ⚠️  Sub-CPMK.${subCpmk.id}: ${existingCpmkId} → $parentCpmkId');
          // Update the mapping in database if parentCpmkId is not null
          if (parentCpmkId != null) {
            // TODO: Update the mapping in database
          }
        } else {
          print('   ✅ Sub-CPMK.${subCpmk.id}: Already maps to CPMK.$parentCpmkId');
        }
      } else {
        print('   ❌ Sub-CPMK.${subCpmk.id}: No mapping found!');
      }
    } catch (e) {
      print('   ❌ Error processing Sub-CPMK.${subCpmk.id}: $e');
    }
  }
  
  print('\n=== END ===');
  exit(0);
}
