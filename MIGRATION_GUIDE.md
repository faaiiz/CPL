# 📊 Panduan Migrasi SQLite ke Firestore

## Strategi Migrasi

Anda memiliki 3 pilihan:

### Opsi 1: **Hybrid Mode** (RECOMMENDED)
- Tetap pakai SQLite untuk local cache
- Sync ke Firestore untuk online access
- **Keuntungan**: Offline support, fast loading
- **Kerugian**: Kompleks, butuh sync logic

### Opsi 2: **Full Cloud** (Sederhana)
- Hapus semua SQLite code
- Gunakan hanya Firestore
- **Keuntungan**: Simple, scalable
- **Kerugian**: Perlu internet, lebih lambat

### Opsi 3: **Gradual Migration** (Safest)
- Migrate table by table
- Keep SQLite & add Firestore gradually
- **Keuntungan**: Lower risk, dapat rollback
- **Kerugian**: Longest time-to-market

## ✅ RECOMMENDED: Hybrid Mode

### Step 1: Update Mahasiswa Service

**File**: `lib/services/mahasiswa_service.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import 'database_helper.dart';
import '../models/mahasiswa_model.dart';

class MahasiswaService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirestoreService _firestoreService = FirestoreService();

  // Add mahasiswa (local + cloud)
  Future<void> addMahasiswa(Mahasiswa mahasiswa) async {
    try {
      // Save ke local SQLite
      await _dbHelper.insertMahasiswa(mahasiswa);
      
      // Sync ke Firestore (background)
      try {
        await _firestoreService.addMahasiswa(mahasiswa);
        print('✓ Mahasiswa synced to cloud: ${mahasiswa.nim}');
      } catch (e) {
        print('⚠️  Cloud sync failed (will retry): $e');
        // Lanjut meski cloud fail, nanti retry
      }
    } catch (e) {
      print('❌ Error adding mahasiswa: $e');
      rethrow;
    }
  }

  // Get all mahasiswa (local priority)
  Future<List<Mahasiswa>> getAllMahasiswa() async {
    try {
      // Try get dari local first (faster)
      final localData = await _dbHelper.getAllMahasiswa();
      if (localData.isNotEmpty) {
        return localData;
      }

      // Jika local kosong, sync dari cloud
      final cloudData = await _firestoreService.getAllMahasiswa();
      
      // Save ke local untuk cache
      for (var mhs in cloudData) {
        await _dbHelper.insertMahasiswa(mhs);
      }

      return cloudData;
    } catch (e) {
      print('❌ Error fetching mahasiswa: $e');
      return [];
    }
  }

  // Sync mahasiswa dari cloud (pull)
  Future<void> syncFromCloud() async {
    try {
      print('🔄 Starting cloud sync...');
      final cloudData = await _firestoreService.getAllMahasiswa();
      
      for (var mhs in cloudData) {
        // Upsert (insert or update)
        final existing = await _dbHelper.getMahasiswa(mhs.id!);
        if (existing != null) {
          await _dbHelper.updateMahasiswa(mhs);
        } else {
          await _dbHelper.insertMahasiswa(mhs);
        }
      }
      
      print('✓ Cloud sync completed for mahasiswa');
    } catch (e) {
      print('❌ Sync error: $e');
      throw 'Sync gagal: $e';
    }
  }

  // Push mahasiswa ke cloud (push)
  Future<void> syncToCloud() async {
    try {
      print('🔄 Pushing mahasiswa to cloud...');
      final localData = await _dbHelper.getAllMahasiswa();
      
      for (var mhs in localData) {
        await _firestoreService.addMahasiswa(mhs);
      }
      
      print('✓ Push sync completed');
    } catch (e) {
      print('❌ Push sync error: $e');
      throw 'Push sync gagal: $e';
    }
  }

  // Delete mahasiswa (local + cloud)
  Future<void> deleteMahasiswa(int id) async {
    try {
      await _dbHelper.deleteMahasiswa(id);
      
      // Soft delete di cloud (mark as deleted)
      try {
        await _firestoreService.updateDocument(
          'mahasiswa',
          id.toString(),
          {'isDeleted': true, 'deletedAt': FieldValue.serverTimestamp()},
        );
      } catch (e) {
        print('⚠️  Cloud deletion failed: $e');
      }
    } catch (e) {
      print('❌ Error deleting mahasiswa: $e');
      rethrow;
    }
  }
}
```

### Step 2: Create Similar Services untuk Lainnya

Buat file yang sama untuk:
- `matakuliah_service.dart`
- `nilai_service.dart`
- `rps_service.dart`
- `cpl_service.dart`
- `cpmk_service.dart`

Pattern-nya sama:
1. Simpan ke SQLite (local)
2. Sync ke Firestore (cloud) di background
3. Ketika get data, prioritas local (cache)
4. Jika local kosong/perlu update, ambil dari cloud

### Step 3: Add Sync Manager

**File**: `lib/services/sync_manager.dart`

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mahasiswa_service.dart';
import 'nilai_service.dart';
import 'matakuliah_service.dart';

class SyncManager {
  final MahasiswaService _mahasiswaService = MahasiswaService();
  final NilaiService _nilaiService = NilaiService();
  final MatakuliahService _matakuliahService = MatakuliahService();

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  void initialize() {
    // Monitor connection changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((result) async {
      if (result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi)) {
        // Internet connected - sync!
        await syncAll();
      }
    });
  }

  // Sync semua data
  Future<void> syncAll() async {
    try {
      print('🔄 Starting full sync...');
      
      // Pull dari cloud
      await _mahasiswaService.syncFromCloud();
      await _matakuliahService.syncFromCloud();
      
      // Push ke cloud
      await _mahasiswaService.syncToCloud();
      await _nilaiService.syncToCloud();
      
      print('✓ Full sync completed');
    } catch (e) {
      print('❌ Sync error: $e');
    }
  }

  // Sync on demand
  Future<void> syncNow() async {
    await syncAll();
  }

  void dispose() {
    _connectivitySubscription.cancel();
  }
}
```

### Step 4: Update main.dart

```dart
import 'services/sync_manager.dart';

void main() async {
  // ... Firebase init code ...
  
  // Initialize sync manager
  final syncManager = SyncManager();
  syncManager.initialize();
  
  runApp(const MyApp());
}
```

### Step 5: Update pubspec.yaml

Add untuk hybrid mode:

```yaml
dependencies:
  connectivity_plus: ^6.0.0  # Network monitoring
  offline_first: ^1.0.0      # Offline support (optional)
```

## 📱 Alternative: Full Cloud Mode

Jika ingin hanya Firestore (no local cache):

### Update Services

```dart
class MahasiswaService {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> addMahasiswa(Mahasiswa mahasiswa) async {
    await _firestoreService.addMahasiswa(mahasiswa);
  }

  Future<List<Mahasiswa>> getAllMahasiswa() async {
    return await _firestoreService.getAllMahasiswa();
  }

  // ... dll
}
```

**Pros:**
- Simpler code
- No sync complexity
- Single source of truth (cloud)

**Cons:**
- No offline support
- Slower (network latency)
- More Firebase read/write costs

## 🔄 Data Migration Script

Untuk transfer data dari SQLite ke Firestore:

**File**: `lib/utils/migration_utils.dart`

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_helper.dart';
import '../services/firestore_service.dart';

class MigrationUtils {
  static final _dbHelper = DatabaseHelper();
  static final _firestoreService = FirestoreService();

  /// Migrate semua data dari SQLite ke Firestore
  static Future<void> migrateAllData() async {
    try {
      print('🚀 Starting migration...');

      // Migrate mahasiswa
      await _migrateMahasiswa();
      await _migrateMatakuliah();
      await _migrateNilai();
      await _migrateRPS();
      await _migrateCPL();
      await _migrateCPMK();

      print('✓ Migration completed!');
    } catch (e) {
      print('❌ Migration error: $e');
      rethrow;
    }
  }

  static Future<void> _migrateMahasiswa() async {
    try {
      print('  → Migrating mahasiswa...');
      final mahasiswaList = await _dbHelper.getAllMahasiswa();
      for (var mhs in mahasiswaList) {
        await _firestoreService.addMahasiswa(mhs);
      }
      print('  ✓ Migrated ${mahasiswaList.length} mahasiswa');
    } catch (e) {
      print('  ❌ Error: $e');
      rethrow;
    }
  }

  static Future<void> _migrateMatakuliah() async {
    try {
      print('  → Migrating matakuliah...');
      final mkList = await _dbHelper.getAllMatakuliah();
      for (var mk in mkList) {
        await _firestoreService.addMatakuliah(mk);
      }
      print('  ✓ Migrated ${mkList.length} matakuliah');
    } catch (e) {
      print('  ❌ Error: $e');
      rethrow;
    }
  }

  static Future<void> _migrateNilai() async {
    try {
      print('  → Migrating nilai...');
      final nilaiList = await _dbHelper.getAllNilai();
      await _firestoreService.batchAddNilai(nilaiList);
      print('  ✓ Migrated ${nilaiList.length} nilai');
    } catch (e) {
      print('  ❌ Error: $e');
      rethrow;
    }
  }

  // ... migrate RPS, CPL, CPMK dll ...

  /// One-time setup (jalankan sekali saja)
  static Future<void> setupMigrationButton() {
    // Panggil migrateAllData() ketika user klik button "Migrate All"
    // Atau run otomatis pada first app launch
  }
}
```

### Jalankan Migration di Admin Panel

```dart
// Di admin_dashboard_screen.dart
ElevatedButton(
  onPressed: () async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Migrate Data?'),
        content: Text('Ini akan transfer semua data dari local ke cloud'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await MigrationUtils.migrateAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✓ Migration success!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Error: $e')),
                );
              }
              Navigator.pop(context);
            },
            child: Text('Migrate'),
          ),
        ],
      ),
    );
  },
  child: Text('🔄 Migrate to Cloud'),
),
```

## 🧪 Testing Migration

1. **Test local operations**: Pastikan SQLite masih works
2. **Test cloud operations**: Verify Firestore save/read
3. **Test sync**: Check data consistency
4. **Test offline**: Unplug internet, pastikan operations masih bisa
5. **Test online**: Plug internet back, verify sync happens

## ⚠️ Gotchas & Best Practices

### 1. Document IDs
```dart
// ❌ BAD - Firestore auto-generate ID
await firestore.collection('mahasiswa').add(data);

// ✅ GOOD - Use consistent IDs (like SQLite id)
await firestore.collection('mahasiswa').doc(mhs.id.toString()).set(data);
```

### 2. Timestamps
```dart
// ❌ BAD - Client time
'createdAt': DateTime.now(),

// ✅ GOOD - Server timestamp
'createdAt': FieldValue.serverTimestamp(),
```

### 3. Transactions
```dart
// ✅ Atomic operations
WriteBatch batch = firestore.batch();
batch.set(docRef1, data1);
batch.update(docRef2, data2);
await batch.commit();
```

### 4. Indexing
- Firestore otomatis create index untuk simple queries
- Untuk complex queries (multiple where), buat composite index di Firebase Console

### 5. Costs
- Free tier: 50K reads/day, 20K writes/day
- Production: ~$6 per 1M read operations
- Monitor di Firebase Console → Firestore → Usage

---

## 📋 Migration Checklist

- [ ] Firebase project created & configured
- [ ] Firestore database initialized
- [ ] Firebase authentication enabled
- [ ] `firebase_options.dart` updated with credentials
- [ ] `FirebaseAuthService` implemented
- [ ] `FirestoreService` implemented
- [ ] Service migration files created (mahasiswa, nilai, dll)
- [ ] `SyncManager` created & initialized
- [ ] Data migration script created
- [ ] Manual migration test done
- [ ] Offline tests passed
- [ ] Production security rules applied
- [ ] Web build tested
- [ ] Firebase hosting deployed

---

## 🆘 Rollback Plan

Jika migration gagal:

1. Keep SQLite code (don't delete)
2. Revert to SQLite services
3. Investigate error
4. Fix Firestore schema/code
5. Retry migration
6. Validate data integrity

```dart
// Fallback to SQLite
class MahasiswaService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  Future<List<Mahasiswa>> getAllMahasiswa() async {
    try {
      // Try cloud first
      return await _firestoreService.getAllMahasiswa();
    } catch (e) {
      // Fallback to local
      print('⚠️  Cloud error, using local: $e');
      return await _dbHelper.getAllMahasiswa();
    }
  }
}
```

---

✅ Migration selesai! Aplikasi CPL now runs on cloud ☁️
