import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/mahasiswa_model.dart';
import '../models/matakuliah_model.dart';
import '../models/nilai_model.dart';
import '../models/rps_model.dart';
import '../models/cpl_model.dart';
import '../models/cpmk_model.dart';
import '../models/sub_cpmk_model.dart';
import '../models/cpl_master_model.dart';
import '../models/rps_detail_model.dart';
import '../models/assessment_type_model.dart';
import '../models/cpmk_cpl_mapping_model.dart';

class DatabaseHelper {
  static const String _dbName = 'cpl_app.db';
  static const int _dbVersion = 8;

  // Table names
  static const String tableUsers = 'users';
  static const String tableMahasiswa = 'mahasiswa';
  static const String tableMatakuliah = 'matakuliah';
  static const String tableNilai = 'nilai';
  static const String tableNilaiKomponen = 'nilai_komponen';
  static const String tableRPS = 'rps';
  static const String tableCPL = 'cpl';
  static const String tableCPMK = 'cpmk';
  static const String tableSubCPMK = 'sub_cpmk';
  static const String tableCPLMaster = 'cpl_master';
  static const String tableRPSDetail = 'rps_detail';
  static const String tableAssessmentType = 'assessment_type';
  static const String tableCPMKCPLMapping = 'cpmk_cpl_mapping';
  static const String tableSubCPMKNilai = 'sub_cpmk_nilai';
  static const String tableRPSDetailSubCPMKBobot = 'rps_detail_sub_cpmk_bobot';
  static const String tableSubCPMKCPMKMapping = 'sub_cpmk_cpmk_mapping';
  static const String tableCPLCalculationTracking = 'cpl_calculation_tracking';
  static const String tableCPLResults = 'cpl_hasil_perhitungan';

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      print('📦 Starting database initialization...');
      
      // Ensure databaseFactory is initialized for FFI
      // This is a safety check in case the main.dart initialization didn't complete
      try {
        // Try to initialize FFI if not already done
        if (databaseFactory.toString().contains('sqflite')) {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
          print('📦 SQLite FFI initialized in database_helper');
        }
      } catch (e) {
        print('⚠️  Note: Using current database factory: $e');
      }
      
      final dbPath = await getDatabasesPath();
      print('📦 Database path: $dbPath');
      
      final path = join(dbPath, _dbName);
      print('📦 Database file path: $path');
      
      final db = await openDatabase(
        path,
        version: _dbVersion,
        onCreate: _createTables,
        onUpgrade: _onUpgrade,
      );
      
      print('✓ Database opened successfully');
      
      // Pastikan semua kolom ada
      await _ensureRPSDetailColumns(db);
      
      // 🎯 PENTING: Ensure CPL results table exists (untuk prevent error saat save)
      await _ensureCPLResultsTable(db);
      
      print('✓ Database initialization complete');
      return db;
    } catch (e, stackTrace) {
      print('❌ Database initialization error: $e');
      print(stackTrace);
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE $tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        nama TEXT NOT NULL,
        nim TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Mahasiswa table
    await db.execute('''
      CREATE TABLE $tableMahasiswa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nim TEXT UNIQUE NOT NULL,
        nama TEXT NOT NULL,
        tahun_masuk INTEGER NOT NULL,
        status TEXT DEFAULT 'aktif',
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Matakuliah table
    await db.execute('''
      CREATE TABLE $tableMatakuliah (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode TEXT UNIQUE NOT NULL,
        nama TEXT NOT NULL,
        semester TEXT NOT NULL,
        jenis TEXT DEFAULT 'wajib',
        sks INTEGER NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Nilai table
    await db.execute('''
      CREATE TABLE $tableNilai (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mahasiswa_id INTEGER NOT NULL,
        matakuliah_id INTEGER NOT NULL,
        grade_huruf TEXT NOT NULL,
        nilai_numerik REAL NOT NULL,
        catatan TEXT,
        tahun_ajaran INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(mahasiswa_id) REFERENCES $tableMahasiswa(id),
        FOREIGN KEY(matakuliah_id) REFERENCES $tableMatakuliah(id),
        UNIQUE(mahasiswa_id, matakuliah_id, tahun_ajaran)
      )
    ''');

    // Nilai Komponen table (Individual component scores)
    await db.execute('''
      CREATE TABLE $tableNilaiKomponen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mahasiswa_id INTEGER NOT NULL,
        matakuliah_id INTEGER NOT NULL,
        nilai_aktivitas REAL DEFAULT 0,
        nilai_proyek REAL DEFAULT 0,
        nilai_kuis REAL DEFAULT 0,
        nilai_tugas REAL DEFAULT 0,
        nilai_uts REAL DEFAULT 0,
        nilai_uas REAL DEFAULT 0,
        tahun_ajaran INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(mahasiswa_id) REFERENCES $tableMahasiswa(id),
        FOREIGN KEY(matakuliah_id) REFERENCES $tableMatakuliah(id),
        UNIQUE(mahasiswa_id, matakuliah_id, tahun_ajaran)
      )
    ''');

    // RPS table
    await db.execute('''
      CREATE TABLE $tableRPS (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matakuliah_id INTEGER NOT NULL,
        file_path TEXT NOT NULL,
        file_name TEXT NOT NULL,
        deskripsi TEXT,
        cpl_mappings TEXT,
        upload_date TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(matakuliah_id) REFERENCES $tableMatakuliah(id)
      )
    ''');

    // CPL table
    await db.execute('''
      CREATE TABLE $tableCPL (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mahasiswa_id INTEGER NOT NULL,
        nip_mahasiswa TEXT NOT NULL,
        nama_mahasiswa TEXT NOT NULL,
        ipk REAL NOT NULL,
        status TEXT NOT NULL,
        total_sku INTEGER NOT NULL,
        rata_nilai REAL NOT NULL,
        catatan TEXT,
        tanggal_hitung TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(mahasiswa_id) REFERENCES $tableMahasiswa(id)
      )
    ''');

    // CPL Master table (7 CPLs)
    await db.execute('''
      CREATE TABLE $tableCPLMaster (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kode_cpl TEXT UNIQUE NOT NULL,
        deskripsi TEXT NOT NULL,
        nomor TEXT UNIQUE NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // CPMK table (Capaian Pembelajaran Mata Kuliah - Program Level)
    await db.execute('''
      CREATE TABLE $tableCPMK (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matakuliah_id INTEGER NOT NULL,
        kode_cpmk TEXT NOT NULL,
        deskripsi TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(matakuliah_id) REFERENCES $tableMatakuliah(id),
        UNIQUE(matakuliah_id, kode_cpmk)
      )
    ''');

    // SUB CPMK table (Sub Capaian Pembelajaran Mata Kuliah - Course Level)
    await db.execute('''
      CREATE TABLE $tableSubCPMK (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matakuliah_id INTEGER NOT NULL,
        kode_sub_cpmk TEXT NOT NULL,
        deskripsi TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(matakuliah_id) REFERENCES $tableMatakuliah(id),
        UNIQUE(matakuliah_id, kode_sub_cpmk)
      )
    ''');

    // RPS Detail table (Weekly learning plan)
    await db.execute('''
      CREATE TABLE $tableRPSDetail (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matakuliah_id INTEGER NOT NULL,
        minggu_ke INTEGER NOT NULL,
        cpmk_ids TEXT,
        sub_cpmk_ids TEXT,
        cpl_ids TEXT,
        topik TEXT,
        metode_ajar TEXT,
        jenis_penilaian TEXT,
        bobot REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(matakuliah_id) REFERENCES $tableMatakuliah(id),
        UNIQUE(matakuliah_id, minggu_ke)
      )
    ''');

    // Assessment Type table
    await db.execute('''
      CREATE TABLE $tableAssessmentType (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        minggu_id INTEGER NOT NULL,
        cpmk_id INTEGER NOT NULL,
        jenis_asessmen TEXT NOT NULL,
        bobot REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(minggu_id) REFERENCES $tableRPSDetail(id),
        FOREIGN KEY(cpmk_id) REFERENCES $tableCPMK(id)
      )
    ''');

    // CPMK-CPL Mapping table
    await db.execute('''
      CREATE TABLE $tableCPMKCPLMapping (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cpmk_id INTEGER NOT NULL,
        cpl_id INTEGER NOT NULL,
        bobot REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(cpmk_id) REFERENCES $tableCPMK(id),
        FOREIGN KEY(cpl_id) REFERENCES $tableCPLMaster(id),
        UNIQUE(cpmk_id, cpl_id)
      )
    ''');

    // Sub CPMK Nilai table (Track nilai per Sub-CPMK)
    await db.execute('''
      CREATE TABLE $tableSubCPMKNilai (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mahasiswa_id INTEGER NOT NULL,
        sub_cpmk_id INTEGER NOT NULL,
        nilai REAL NOT NULL,
        tahun_ajaran INTEGER NOT NULL,
        catatan TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(mahasiswa_id) REFERENCES $tableMahasiswa(id),
        FOREIGN KEY(sub_cpmk_id) REFERENCES $tableSubCPMK(id),
        UNIQUE(mahasiswa_id, sub_cpmk_id, tahun_ajaran)
      )
    ''');

    // RPS Detail Sub-CPMK Bobot table (Link RPS Detail -> Sub-CPMK dengan bobot)
    await db.execute('''
      CREATE TABLE $tableRPSDetailSubCPMKBobot (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        rps_detail_id INTEGER NOT NULL,
        sub_cpmk_id INTEGER NOT NULL,
        bobot REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(rps_detail_id) REFERENCES $tableRPSDetail(id),
        FOREIGN KEY(sub_cpmk_id) REFERENCES $tableSubCPMK(id),
        UNIQUE(rps_detail_id, sub_cpmk_id)
      )
    ''');

    // Sub-CPMK CPMK Mapping table (Link Sub-CPMK -> CPMK dengan bobot)
    await db.execute('''
      CREATE TABLE $tableSubCPMKCPMKMapping (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sub_cpmk_id INTEGER NOT NULL,
        cpmk_id INTEGER NOT NULL,
        bobot REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(sub_cpmk_id) REFERENCES $tableSubCPMK(id),
        FOREIGN KEY(cpmk_id) REFERENCES $tableCPMK(id),
        UNIQUE(sub_cpmk_id, cpmk_id)
      )
    ''');

    // CPL Calculation Tracking table (Track yang sudah dihitung)
    await db.execute('''
      CREATE TABLE $tableCPLCalculationTracking (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        matakuliah_id INTEGER NOT NULL,
        tahun_ajaran INTEGER NOT NULL,
        calculated_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(matakuliah_id) REFERENCES $tableMatakuliah(id),
        UNIQUE(matakuliah_id, tahun_ajaran)
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX idx_nilai_mahasiswa ON $tableNilai(mahasiswa_id)');
    await db.execute('CREATE INDEX idx_nilai_matakuliah ON $tableNilai(matakuliah_id)');
    await db.execute('CREATE INDEX idx_nilai_komponen_mahasiswa ON $tableNilaiKomponen(mahasiswa_id)');
    await db.execute('CREATE INDEX idx_nilai_komponen_matakuliah ON $tableNilaiKomponen(matakuliah_id)');
    await db.execute('CREATE INDEX idx_rps_matakuliah ON $tableRPS(matakuliah_id)');
    await db.execute('CREATE INDEX idx_cpl_mahasiswa ON $tableCPL(mahasiswa_id)');
    await db.execute('CREATE INDEX idx_cpmk_matakuliah ON $tableCPMK(matakuliah_id)');
    await db.execute('CREATE INDEX idx_sub_cpmk_matakuliah ON $tableSubCPMK(matakuliah_id)');
    await db.execute('CREATE INDEX idx_rps_detail_matakuliah ON $tableRPSDetail(matakuliah_id)');
    await db.execute('CREATE INDEX idx_assessment_minggu ON $tableAssessmentType(minggu_id)');
    await db.execute('CREATE INDEX idx_cpmk_cpl_mapping_cpmk ON $tableCPMKCPLMapping(cpmk_id)');
    await db.execute('CREATE INDEX idx_cpmk_cpl_mapping_cpl ON $tableCPMKCPLMapping(cpl_id)');
    await db.execute('CREATE INDEX idx_sub_cpmk_nilai_mahasiswa ON $tableSubCPMKNilai(mahasiswa_id)');
    await db.execute('CREATE INDEX idx_sub_cpmk_nilai_sub_cpmk ON $tableSubCPMKNilai(sub_cpmk_id)');
    await db.execute('CREATE INDEX idx_rps_detail_sub_cpmk_bobot_rps ON $tableRPSDetailSubCPMKBobot(rps_detail_id)');
    await db.execute('CREATE INDEX idx_rps_detail_sub_cpmk_bobot_sub ON $tableRPSDetailSubCPMKBobot(sub_cpmk_id)');
    await db.execute('CREATE INDEX idx_sub_cpmk_cpmk_mapping_sub ON $tableSubCPMKCPMKMapping(sub_cpmk_id)');
    await db.execute('CREATE INDEX idx_sub_cpmk_cpmk_mapping_cpmk ON $tableSubCPMKCPMKMapping(cpmk_id)');
    await db.execute('CREATE INDEX idx_cpl_calculation_tracking ON $tableCPLCalculationTracking(matakuliah_id, tahun_ajaran)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Add bobot column to rps_detail table
      try {
        await db.execute('ALTER TABLE $tableRPSDetail ADD COLUMN bobot REAL');
      } catch (e) {
        // Column might already exist
        print('Note: Column bobot might already exist: $e');
      }
    }
    if (oldVersion < 3) {
      // Create sub_cpmk table
      try {
        await db.execute('''
          CREATE TABLE $tableSubCPMK (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            matakuliah_id INTEGER NOT NULL,
            kode_sub_cpmk TEXT NOT NULL,
            deskripsi TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY(matakuliah_id) REFERENCES $tableMatakuliah(id),
            UNIQUE(matakuliah_id, kode_sub_cpmk)
          )
        ''');
        await db.execute('CREATE INDEX idx_sub_cpmk_matakuliah ON $tableSubCPMK(matakuliah_id)');
      } catch (e) {
        print('Note: SUB CPMK table might already exist: $e');
      }
      // Rename cpmk_ids to sub_cpmk_ids in rps_detail table
      try {
        await db.execute('ALTER TABLE $tableRPSDetail RENAME COLUMN cpmk_ids TO sub_cpmk_ids');
      } catch (e) {
        print('Note: Column renaming not supported, skipping: $e');
      }
    }
    if (oldVersion < 4) {
      // Create Sub CPMK Nilai table
      try {
        await db.execute('''
          CREATE TABLE $tableSubCPMKNilai (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mahasiswa_id INTEGER NOT NULL,
            sub_cpmk_id INTEGER NOT NULL,
            nilai REAL NOT NULL,
            tahun_ajaran INTEGER NOT NULL,
            catatan TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY(mahasiswa_id) REFERENCES $tableMahasiswa(id),
            FOREIGN KEY(sub_cpmk_id) REFERENCES $tableSubCPMK(id),
            UNIQUE(mahasiswa_id, sub_cpmk_id, tahun_ajaran)
          )
        ''');
        await db.execute('CREATE INDEX idx_sub_cpmk_nilai_mahasiswa ON $tableSubCPMKNilai(mahasiswa_id)');
        await db.execute('CREATE INDEX idx_sub_cpmk_nilai_sub_cpmk ON $tableSubCPMKNilai(sub_cpmk_id)');
      } catch (e) {
        print('Note: Sub CPMK Nilai table might already exist: $e');
      }

      // Create RPS Detail Sub-CPMK Bobot table
      try {
        await db.execute('''
          CREATE TABLE $tableRPSDetailSubCPMKBobot (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rps_detail_id INTEGER NOT NULL,
            sub_cpmk_id INTEGER NOT NULL,
            bobot REAL NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY(rps_detail_id) REFERENCES $tableRPSDetail(id),
            FOREIGN KEY(sub_cpmk_id) REFERENCES $tableSubCPMK(id),
            UNIQUE(rps_detail_id, sub_cpmk_id)
          )
        ''');
        await db.execute('CREATE INDEX idx_rps_detail_sub_cpmk_bobot_rps ON $tableRPSDetailSubCPMKBobot(rps_detail_id)');
        await db.execute('CREATE INDEX idx_rps_detail_sub_cpmk_bobot_sub ON $tableRPSDetailSubCPMKBobot(sub_cpmk_id)');
      } catch (e) {
        print('Note: RPS Detail Sub-CPMK Bobot table might already exist: $e');
      }

      // Create Sub-CPMK CPMK Mapping table
      try {
        await db.execute('''
          CREATE TABLE $tableSubCPMKCPMKMapping (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sub_cpmk_id INTEGER NOT NULL,
            cpmk_id INTEGER NOT NULL,
            bobot REAL NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY(sub_cpmk_id) REFERENCES $tableSubCPMK(id),
            FOREIGN KEY(cpmk_id) REFERENCES $tableCPMK(id),
            UNIQUE(sub_cpmk_id, cpmk_id)
          )
        ''');
        await db.execute('CREATE INDEX idx_sub_cpmk_cpmk_mapping_sub ON $tableSubCPMKCPMKMapping(sub_cpmk_id)');
        await db.execute('CREATE INDEX idx_sub_cpmk_cpmk_mapping_cpmk ON $tableSubCPMKCPMKMapping(cpmk_id)');
      } catch (e) {
        print('Note: Sub-CPMK CPMK Mapping table might already exist: $e');
      }
    }
    if (oldVersion < 5) {
      // Add jenis_penilaian column to rps_detail table
      try {
        await db.execute('ALTER TABLE $tableRPSDetail ADD COLUMN jenis_penilaian TEXT');
        print('INFO: Kolom jenis_penilaian berhasil ditambahkan');
      } catch (e) {
        // Column might already exist
        print('Note: Column jenis_penilaian mungkin sudah ada: $e');
      }
    }
    if (oldVersion < 6) {
      // Create CPL Calculation Tracking table
      try {
        await db.execute('''
          CREATE TABLE $tableCPLCalculationTracking (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            matakuliah_id INTEGER NOT NULL,
            tahun_ajaran INTEGER NOT NULL,
            calculated_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY(matakuliah_id) REFERENCES $tableMatakuliah(id),
            UNIQUE(matakuliah_id, tahun_ajaran)
          )
        ''');
        await db.execute('CREATE INDEX idx_cpl_calculation_tracking ON $tableCPLCalculationTracking(matakuliah_id, tahun_ajaran)');
        print('INFO: Tabel cpl_calculation_tracking berhasil dibuat');
      } catch (e) {
        print('Note: CPL calculation tracking table might already exist: $e');
      }
    }
    if (oldVersion < 7) {
      // Create Nilai Komponen table (individual component scores)
      try {
        await db.execute('''
          CREATE TABLE $tableNilaiKomponen (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mahasiswa_id INTEGER NOT NULL,
            matakuliah_id INTEGER NOT NULL,
            nilai_aktivitas REAL DEFAULT 0,
            nilai_proyek REAL DEFAULT 0,
            nilai_kuis REAL DEFAULT 0,
            nilai_tugas REAL DEFAULT 0,
            nilai_uts REAL DEFAULT 0,
            nilai_uas REAL DEFAULT 0,
            tahun_ajaran INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY(mahasiswa_id) REFERENCES $tableMahasiswa(id),
            FOREIGN KEY(matakuliah_id) REFERENCES $tableMatakuliah(id),
            UNIQUE(mahasiswa_id, matakuliah_id, tahun_ajaran)
          )
        ''');
        await db.execute('CREATE INDEX idx_nilai_komponen_mahasiswa ON $tableNilaiKomponen(mahasiswa_id)');
        await db.execute('CREATE INDEX idx_nilai_komponen_matakuliah ON $tableNilaiKomponen(matakuliah_id)');
        print('INFO: Tabel nilai_komponen berhasil dibuat');
      } catch (e) {
        print('Note: Nilai komponen table might already exist: $e');
      }
    }
    if (oldVersion < 8) {
      // Create CPL Results table (persistent storage untuk hasil perhitungan)
      try {
        await db.execute('''
          CREATE TABLE $tableCPLResults (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mahasiswa_id INTEGER NOT NULL,
            matakuliah_id INTEGER NOT NULL,
            tahun_ajaran INTEGER NOT NULL,
            sub_cpmk_values TEXT NOT NULL,
            cpmk_values TEXT NOT NULL,
            cpl_values TEXT NOT NULL,
            sub_cpmk_bobots TEXT,
            average_sub_cpmk_nilai REAL NOT NULL,
            average_cpmk_nilai REAL NOT NULL,
            average_cpl_nilai REAL NOT NULL,
            calculated_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY(mahasiswa_id) REFERENCES $tableMahasiswa(id),
            FOREIGN KEY(matakuliah_id) REFERENCES $tableMatakuliah(id),
            UNIQUE(mahasiswa_id, matakuliah_id, tahun_ajaran)
          )
        ''');
        await db.execute('CREATE INDEX idx_cpl_results_mk ON $tableCPLResults(matakuliah_id, tahun_ajaran)');
        await db.execute('CREATE INDEX idx_cpl_results_mhs ON $tableCPLResults(mahasiswa_id)');
        print('INFO: Tabel cpl_hasil_perhitungan berhasil dibuat');
      } catch (e) {
        print('Note: CPL results table might already exist: $e');
      }
    }
  }

  // Helper method untuk memastikan kolom jenis_penilaian ada
  Future<void> _ensureRPSDetailColumns(Database db) async {
    try {
      // Cek apakah kolom sudah ada
      final tableInfo = await db.rawQuery('PRAGMA table_info($tableRPSDetail)');
      final hasJenisPenilaianColumn = 
          tableInfo.any((col) => col['name'] == 'jenis_penilaian');
      
      if (!hasJenisPenilaianColumn) {
        print('INFO: Kolom jenis_penilaian tidak ditemukan, menambahkan...');
        await db.execute('ALTER TABLE $tableRPSDetail ADD COLUMN jenis_penilaian TEXT');
        print('INFO: Kolom jenis_penilaian berhasil ditambahkan via helper');
      } else {
        print('INFO: Kolom jenis_penilaian sudah ada di tabel');
      }
    } catch (e) {
      print('WARNING: Error checking table columns: $e');
    }
  }

  /// 🎯 PENTING: Ensure CPL results table exists
  /// Ini menangani case ketika database belum di-upgrade ke v8
  /// atau migration gagal
  Future<void> _ensureCPLResultsTable(Database db) async {
    try {
      // Cek apakah table sudah ada
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableCPLResults'"
      );
      
      if (tables.isEmpty) {
        print('⚠️ INFO: Tabel $tableCPLResults tidak ditemukan, membuat...');
        
        // Create table jika belum ada
        await db.execute('''
          CREATE TABLE $tableCPLResults (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mahasiswa_id INTEGER NOT NULL,
            matakuliah_id INTEGER NOT NULL,
            tahun_ajaran INTEGER NOT NULL,
            sub_cpmk_values TEXT NOT NULL,
            cpmk_values TEXT NOT NULL,
            cpl_values TEXT NOT NULL,
            sub_cpmk_bobots TEXT,
            average_sub_cpmk_nilai REAL NOT NULL,
            average_cpmk_nilai REAL NOT NULL,
            average_cpl_nilai REAL NOT NULL,
            calculated_at TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY(mahasiswa_id) REFERENCES $tableMahasiswa(id),
            FOREIGN KEY(matakuliah_id) REFERENCES $tableMatakuliah(id),
            UNIQUE(mahasiswa_id, matakuliah_id, tahun_ajaran)
          )
        ''');
        
        // Create indexes
        await db.execute('CREATE INDEX idx_cpl_results_mk ON $tableCPLResults(matakuliah_id, tahun_ajaran)');
        await db.execute('CREATE INDEX idx_cpl_results_mhs ON $tableCPLResults(mahasiswa_id)');
        
        print('✅ INFO: Tabel $tableCPLResults berhasil dibuat via helper');
      } else {
        print('✅ INFO: Tabel $tableCPLResults sudah ada');
      }
    } catch (e) {
      print('❌ WARNING: Error ensuring CPL results table: $e');
      // Don't rethrow - continue jika ada error, tapi log warning
    }
  }

  // ===== USER OPERATIONS =====
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(tableUsers, user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final result = await db.query(
      tableUsers,
      where: 'username = ?',
      whereArgs: [username],
    );
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query(tableUsers);
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      tableUsers,
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== MAHASISWA OPERATIONS =====
  Future<int> insertMahasiswa(Mahasiswa mahasiswa) async {
    final db = await database;
    return await db.insert(tableMahasiswa, mahasiswa.toMap());
  }

  Future<Mahasiswa?> getMahasiswaByNim(String nim) async {
    final db = await database;
    final result = await db.query(
      tableMahasiswa,
      where: 'nim = ?',
      whereArgs: [nim],
    );
    if (result.isEmpty) return null;
    return Mahasiswa.fromMap(result.first);
  }

  Future<List<Mahasiswa>> getAllMahasiswa() async {
    final db = await database;
    final result = await db.query(tableMahasiswa, orderBy: 'nim ASC');
    return result.map((map) => Mahasiswa.fromMap(map)).toList();
  }

  Future<List<Mahasiswa>> searchMahasiswa(String query) async {
    final db = await database;
    final result = await db.query(
      tableMahasiswa,
      where: 'nim LIKE ? OR nama LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'nama ASC',
    );
    return result.map((map) => Mahasiswa.fromMap(map)).toList();
  }

  Future<int> updateMahasiswa(Mahasiswa mahasiswa) async {
    final db = await database;
    return await db.update(
      tableMahasiswa,
      mahasiswa.toMap(),
      where: 'id = ?',
      whereArgs: [mahasiswa.id],
    );
  }

  Future<int> deleteMahasiswa(int id) async {
    final db = await database;
    return await db.delete(
      tableMahasiswa,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== MATAKULIAH OPERATIONS =====
  Future<int> insertMatakuliah(Matakuliah matakuliah) async {
    final db = await database;
    return await db.insert(tableMatakuliah, matakuliah.toMap());
  }

  Future<Matakuliah?> getMatakuliahByKode(String kode) async {
    final db = await database;
    final result = await db.query(
      tableMatakuliah,
      where: 'kode = ?',
      whereArgs: [kode],
    );
    if (result.isEmpty) return null;
    return Matakuliah.fromMap(result.first);
  }

  Future<Matakuliah?> getMatakuliahByNama(String nama) async {
    final db = await database;
    final result = await db.query(
      tableMatakuliah,
      where: 'nama = ?',
      whereArgs: [nama],
    );
    if (result.isEmpty) return null;
    return Matakuliah.fromMap(result.first);
  }

  Future<List<Matakuliah>> getAllMatakuliah() async {
    final db = await database;
    final result = await db.query(tableMatakuliah, orderBy: 'semester ASC, nama ASC');
    return result.map((map) => Matakuliah.fromMap(map)).toList();
  }

  Future<Matakuliah?> getMatakuliahById(int id) async {
    final db = await database;
    final result = await db.query(
      tableMatakuliah,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Matakuliah.fromMap(result.first);
    }
    return null;
  }

  Future<int> updateMatakuliah(Matakuliah matakuliah) async {
    final db = await database;
    return await db.update(
      tableMatakuliah,
      matakuliah.toMap(),
      where: 'id = ?',
      whereArgs: [matakuliah.id],
    );
  }

  Future<int> deleteMatakuliah(int id) async {
    final db = await database;
    return await db.delete(
      tableMatakuliah,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllMahasiswa() async {
    final db = await database;
    return await db.delete(tableMahasiswa);
  }

  Future<int> deleteAllMatakuliah() async {
    final db = await database;
    return await db.delete(tableMatakuliah);
  }

  // ===== NILAI OPERATIONS =====
  Future<int> insertNilai(Nilai nilai) async {
    final db = await database;
    return await db.insert(
      tableNilai,
      nilai.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Nilai>> getNilaiByMahasiswa(int mahasiswaId) async {
    final db = await database;
    final result = await db.query(
      tableNilai,
      where: 'mahasiswa_id = ?',
      whereArgs: [mahasiswaId],
    );
    return result.map((map) => Nilai.fromMap(map)).toList();
  }

  Future<List<Nilai>> getNilaiByMatakuliah(int matakuliahId) async {
    final db = await database;
    final result = await db.query(
      tableNilai,
      where: 'matakuliah_id = ?',
      whereArgs: [matakuliahId],
    );
    return result.map((map) => Nilai.fromMap(map)).toList();
  }

  Future<Nilai?> getNilai(int mahasiswaId, int matakuliahId, int tahunAjaran) async {
    final db = await database;
    final result = await db.query(
      tableNilai,
      where: 'mahasiswa_id = ? AND matakuliah_id = ? AND tahun_ajaran = ?',
      whereArgs: [mahasiswaId, matakuliahId, tahunAjaran],
    );
    if (result.isEmpty) return null;
    return Nilai.fromMap(result.first);
  }

  Future<int> updateNilai(Nilai nilai) async {
    final db = await database;
    return await db.update(
      tableNilai,
      nilai.toMap(),
      where: 'id = ?',
      whereArgs: [nilai.id],
    );
  }

  Future<int> deleteNilai(int id) async {
    final db = await database;
    return await db.delete(
      tableNilai,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Nilai>> getAllNilai() async {
    final db = await database;
    final result = await db.query(tableNilai);
    return result.map((map) => Nilai.fromMap(map)).toList();
  }

  // ===== NILAI KOMPONEN OPERATIONS =====

  // ===== RPS OPERATIONS =====
  Future<int> insertRPS(RPS rps) async {
    final db = await database;
    return await db.insert(tableRPS, rps.toMap());
  }

  Future<RPS?> getRPSByMatakuliah(int matakuliahId) async {
    final db = await database;
    final result = await db.query(
      tableRPS,
      where: 'matakuliah_id = ?',
      whereArgs: [matakuliahId],
    );
    if (result.isEmpty) return null;
    return RPS.fromMap(result.first);
  }

  Future<List<RPS>> getAllRPS() async {
    final db = await database;
    final result = await db.query(tableRPS);
    return result.map((map) => RPS.fromMap(map)).toList();
  }

  Future<int> updateRPS(RPS rps) async {
    final db = await database;
    return await db.update(
      tableRPS,
      rps.toMap(),
      where: 'id = ?',
      whereArgs: [rps.id],
    );
  }

  Future<int> deleteRPS(int id) async {
    final db = await database;
    return await db.delete(
      tableRPS,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== CPL OPERATIONS =====
  Future<int> insertCPL(CPL cpl) async {
    final db = await database;
    return await db.insert(tableCPL, cpl.toMap());
  }

  Future<CPL?> getCPLByMahasiswa(int mahasiswaId) async {
    final db = await database;
    final result = await db.query(
      tableCPL,
      where: 'mahasiswa_id = ?',
      whereArgs: [mahasiswaId],
    );
    if (result.isEmpty) return null;
    return CPL.fromMap(result.first);
  }

  Future<List<CPL>> getAllCPL() async {
    final db = await database;
    final result = await db.query(tableCPL, orderBy: 'nip_mahasiswa ASC');
    return result.map((map) => CPL.fromMap(map)).toList();
  }

  Future<int> updateCPL(CPL cpl) async {
    final db = await database;
    return await db.update(
      tableCPL,
      cpl.toMap(),
      where: 'id = ?',
      whereArgs: [cpl.id],
    );
  }

  Future<int> deleteCPL(int id) async {
    final db = await database;
    return await db.delete(
      tableCPL,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== BULK OPERATIONS =====
  Future<void> insertNilaiBatch(List<Nilai> nilaiList) async {
    final db = await database;
    final batch = db.batch();
    for (var nilai in nilaiList) {
      batch.insert(
        tableNilai,
        nilai.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  Future<void> insertMahasiswaBatch(List<Mahasiswa> mahasiswaList) async {
    final db = await database;
    final batch = db.batch();
    for (var mahasiswa in mahasiswaList) {
      batch.insert(
        tableMahasiswa,
        mahasiswa.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  Future<void> insertMatakuliahBatch(List<Matakuliah> matakuliahList) async {
    final db = await database;
    final batch = db.batch();
    for (var matakuliah in matakuliahList) {
      batch.insert(
        tableMatakuliah,
        matakuliah.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  // ===== UTILITY =====
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(tableNilai);
    await db.delete(tableMahasiswa);
    await db.delete(tableRPS);
    await db.delete(tableCPL);
    await db.delete(tableMatakuliah);
    await db.delete(tableUsers);
  }

  // ===== CPL MASTER OPERATIONS =====
  Future<int> insertCPLMaster(CPLMaster cpl) async {
    final db = await database;
    return await db.insert(tableCPLMaster, cpl.toMap());
  }

  Future<List<CPLMaster>> getAllCPLMaster() async {
    final db = await database;
    final maps = await db.query(tableCPLMaster);
    return List.generate(maps.length, (i) => CPLMaster.fromMap(maps[i]));
  }

  Future<CPLMaster?> getCPLMasterById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableCPLMaster,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CPLMaster.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCPLMaster(CPLMaster cpl) async {
    final db = await database;
    return await db.update(
      tableCPLMaster,
      cpl.toMap(),
      where: 'id = ?',
      whereArgs: [cpl.id],
    );
  }

  Future<int> deleteCPLMaster(int id) async {
    final db = await database;
    return await db.delete(
      tableCPLMaster,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== CPMK OPERATIONS =====
  Future<int> insertCPMK(CPMK cpmk) async {
    final db = await database;
    return await db.insert(tableCPMK, cpmk.toMap());
  }

  Future<List<CPMK>> getAllCPMK() async {
    final db = await database;
    final maps = await db.query(tableCPMK);
    return List.generate(maps.length, (i) => CPMK.fromMap(maps[i]));
  }

  Future<List<CPMK>> getCPMKByMatakuliah(int matakuliahId) async {
    final db = await database;
    final maps = await db.query(
      tableCPMK,
      where: 'matakuliah_id = ?',
      whereArgs: [matakuliahId],
    );
    return List.generate(maps.length, (i) => CPMK.fromMap(maps[i]));
  }

  Future<CPMK?> getCPMKById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableCPMK,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return CPMK.fromMap(maps.first);
    }
    return null;
  }

  Future<CPMK?> getCPMKByKode(String kode) async {
    final db = await database;
    final maps = await db.query(
      tableCPMK,
      where: 'kode_cpmk = ?',
      whereArgs: [kode],
    );
    if (maps.isNotEmpty) {
      return CPMK.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCPMK(CPMK cpmk) async {
    final db = await database;
    return await db.update(
      tableCPMK,
      cpmk.toMap(),
      where: 'id = ?',
      whereArgs: [cpmk.id],
    );
  }

  Future<int> deleteCPMK(int id) async {
    final db = await database;
    return await db.delete(
      tableCPMK,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== SUB CPMK OPERATIONS =====
  Future<int> insertSubCPMK(SubCPMK subCPMK) async {
    final db = await database;
    return await db.insert(tableSubCPMK, subCPMK.toMap());
  }

  Future<List<SubCPMK>> getAllSubCPMK() async {
    final db = await database;
    final maps = await db.query(tableSubCPMK);
    return List.generate(maps.length, (i) => SubCPMK.fromMap(maps[i]));
  }

  Future<List<SubCPMK>> getSubCPMKByMatakuliah(int matakuliahId) async {
    final db = await database;
    final maps = await db.query(
      tableSubCPMK,
      where: 'matakuliah_id = ?',
      whereArgs: [matakuliahId],
      orderBy: 'kode_sub_cpmk ASC',
    );
    return List.generate(maps.length, (i) => SubCPMK.fromMap(maps[i]));
  }

  Future<SubCPMK?> getSubCPMKByKodeAndMatakuliah(int matakuliahId, String kodeSubCPMK) async {
    final db = await database;
    final maps = await db.query(
      tableSubCPMK,
      where: 'matakuliah_id = ? AND kode_sub_cpmk = ?',
      whereArgs: [matakuliahId, kodeSubCPMK],
    );
    if (maps.isNotEmpty) {
      return SubCPMK.fromMap(maps.first);
    }
    return null;
  }

  Future<SubCPMK?> getSubCPMKById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableSubCPMK,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SubCPMK.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSubCPMK(SubCPMK subCPMK) async {
    final db = await database;
    return await db.update(
      tableSubCPMK,
      subCPMK.toMap(),
      where: 'id = ?',
      whereArgs: [subCPMK.id],
    );
  }

  Future<int> deleteSubCPMK(int id) async {
    final db = await database;
    return await db.delete(
      tableSubCPMK,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSubCPMKByMatakuliah(int matakuliahId) async {
    final db = await database;
    return await db.delete(
      tableSubCPMK,
      where: 'matakuliah_id = ?',
      whereArgs: [matakuliahId],
    );
  }

  // ===== RPS DETAIL OPERATIONS =====
  Future<int> insertRPSDetail(RPSDetail rpsDetail) async {
    try {
      final db = await database;
      final mapData = rpsDetail.toMap();
      print('DEBUG DB: insertRPSDetail - data: $mapData');
      final result = await db.insert(tableRPSDetail, mapData);
      print('DEBUG DB: insertRPSDetail berhasil - id=$result');
      return result;
    } catch (e, stackTrace) {
      print('ERROR DB: insertRPSDetail gagal - $e');
      print('ERROR DB StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<List<RPSDetail>> getRPSDetailByMatakuliah(int matakuliahId) async {
    final db = await database;
    final maps = await db.query(
      tableRPSDetail,
      where: 'matakuliah_id = ?',
      whereArgs: [matakuliahId],
      orderBy: 'minggu_ke ASC',
    );
    return List.generate(maps.length, (i) => RPSDetail.fromMap(maps[i]));
  }

  Future<RPSDetail?> getRPSDetailById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableRPSDetail,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return RPSDetail.fromMap(maps.first);
    }
    return null;
  }

  Future<RPSDetail?> getRPSDetail(int matakuliahId, int mingguKe) async {
    final db = await database;
    final maps = await db.query(
      tableRPSDetail,
      where: 'matakuliah_id = ? AND minggu_ke = ?',
      whereArgs: [matakuliahId, mingguKe],
    );
    if (maps.isNotEmpty) {
      return RPSDetail.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateRPSDetail(RPSDetail rpsDetail) async {
    try {
      final db = await database;
      final mapData = rpsDetail.toMap();
      print('DEBUG DB: updateRPSDetail - id=${rpsDetail.id}, data: $mapData');
      final result = await db.update(
        tableRPSDetail,
        mapData,
        where: 'id = ?',
        whereArgs: [rpsDetail.id],
      );
      print('DEBUG DB: updateRPSDetail berhasil - rows affected=$result');
      return result;
    } catch (e, stackTrace) {
      print('ERROR DB: updateRPSDetail gagal - $e');
      print('ERROR DB StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<int> deleteRPSDetail(int id) async {
    final db = await database;
    return await db.delete(
      tableRPSDetail,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteRPSDetailByMatakuliah(int matakuliahId) async {
    final db = await database;
    return await db.delete(
      tableRPSDetail,
      where: 'matakuliah_id = ?',
      whereArgs: [matakuliahId],
    );
  }

  // ===== ASSESSMENT TYPE OPERATIONS =====
  Future<int> insertAssessmentType(AssessmentType assessment) async {
    final db = await database;
    return await db.insert(tableAssessmentType, assessment.toMap());
  }

  Future<List<AssessmentType>> getAssessmentByMinggu(int mingguId) async {
    final db = await database;
    final maps = await db.query(
      tableAssessmentType,
      where: 'minggu_id = ?',
      whereArgs: [mingguId],
    );
    return List.generate(maps.length, (i) => AssessmentType.fromMap(maps[i]));
  }

  Future<List<AssessmentType>> getAssessmentByCPMK(int cpmkId) async {
    final db = await database;
    final maps = await db.query(
      tableAssessmentType,
      where: 'cpmk_id = ?',
      whereArgs: [cpmkId],
    );
    return List.generate(maps.length, (i) => AssessmentType.fromMap(maps[i]));
  }

  Future<int> updateAssessmentType(AssessmentType assessment) async {
    final db = await database;
    return await db.update(
      tableAssessmentType,
      assessment.toMap(),
      where: 'id = ?',
      whereArgs: [assessment.id],
    );
  }

  Future<int> deleteAssessmentType(int id) async {
    final db = await database;
    return await db.delete(
      tableAssessmentType,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== CPMK-CPL MAPPING OPERATIONS =====
  Future<int> insertCPMKCPLMapping(CPMKCPLMapping mapping) async {
    final db = await database;
    return await db.insert(tableCPMKCPLMapping, mapping.toMap());
  }

  Future<List<CPMKCPLMapping>> getMappingByCPMK(int cpmkId) async {
    final db = await database;
    final maps = await db.query(
      tableCPMKCPLMapping,
      where: 'cpmk_id = ?',
      whereArgs: [cpmkId],
    );
    return List.generate(maps.length, (i) => CPMKCPLMapping.fromMap(maps[i]));
  }

  Future<List<CPMKCPLMapping>> getMappingByCPL(int cplId) async {
    final db = await database;
    final maps = await db.query(
      tableCPMKCPLMapping,
      where: 'cpl_id = ?',
      whereArgs: [cplId],
    );
    return List.generate(maps.length, (i) => CPMKCPLMapping.fromMap(maps[i]));
  }

  // 🚀 OPTIMASI: Get all CPMK-CPL mappings untuk batch processing
  Future<List<dynamic>> getAllCPMKCPLMappings() async {
    final db = await database;
    final maps = await db.query(tableCPMKCPLMapping);
    return maps;
  }

  Future<CPMKCPLMapping?> getMappingByCPMKAndCPL(int cpmkId, int cplId) async {
    final db = await database;
    final maps = await db.query(
      tableCPMKCPLMapping,
      where: 'cpmk_id = ? AND cpl_id = ?',
      whereArgs: [cpmkId, cplId],
    );
    if (maps.isNotEmpty) {
      return CPMKCPLMapping.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCPMKCPLMapping(CPMKCPLMapping mapping) async {
    final db = await database;
    return await db.update(
      tableCPMKCPLMapping,
      mapping.toMap(),
      where: 'id = ?',
      whereArgs: [mapping.id],
    );
  }

  Future<int> deleteCPMKCPLMapping(int id) async {
    final db = await database;
    return await db.delete(
      tableCPMKCPLMapping,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== SUB CPMK NILAI OPERATIONS =====
  Future<int> insertSubCPMKNilai(dynamic nilai) async {
    final db = await database;
    return await db.insert(
      tableSubCPMKNilai,
      nilai.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<dynamic> getSubCPMKNilai(int mahasiswaId, int subCpmkId, int tahunAjaran) async {
    final db = await database;
    final result = await db.query(
      tableSubCPMKNilai,
      where: 'mahasiswa_id = ? AND sub_cpmk_id = ? AND tahun_ajaran = ?',
      whereArgs: [mahasiswaId, subCpmkId, tahunAjaran],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<List<dynamic>> getSubCPMKNilaiByMahasiswa(int mahasiswaId, int tahunAjaran) async {
    final db = await database;
    return await db.query(
      tableSubCPMKNilai,
      where: 'mahasiswa_id = ? AND tahun_ajaran = ?',
      whereArgs: [mahasiswaId, tahunAjaran],
    );
  }

  Future<List<dynamic>> getSubCPMKNilaiBySubCPMK(int subCpmkId, int tahunAjaran) async {
    final db = await database;
    return await db.query(
      tableSubCPMKNilai,
      where: 'sub_cpmk_id = ? AND tahun_ajaran = ?',
      whereArgs: [subCpmkId, tahunAjaran],
    );
  }

  Future<int> updateSubCPMKNilai(dynamic nilai) async {
    final db = await database;
    return await db.update(
      tableSubCPMKNilai,
      nilai.toMap(),
      where: 'id = ?',
      whereArgs: [nilai.id],
    );
  }

  Future<int> deleteSubCPMKNilai(int id) async {
    final db = await database;
    return await db.delete(
      tableSubCPMKNilai,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ===== RPS DETAIL SUB CPMK BOBOT OPERATIONS =====
  Future<int> insertRPSDetailSubCPMKBobot(dynamic bobot) async {
    final db = await database;
    return await db.insert(tableRPSDetailSubCPMKBobot, bobot.toMap());
  }

  Future<List<dynamic>> getRPSDetailSubCPMKBobot(int rpsDetailId) async {
    final db = await database;
    return await db.query(
      tableRPSDetailSubCPMKBobot,
      where: 'rps_detail_id = ?',
      whereArgs: [rpsDetailId],
    );
  }

  // 🚀 OPTIMASI: Get all RPS Detail SubCPMK Bobot untuk batch processing
  Future<List<dynamic>> getAllRPSDetailSubCPMKBobots() async {
    final db = await database;
    return await db.query(tableRPSDetailSubCPMKBobot);
  }

  Future<dynamic> getRPSDetailSubCPMKBobotSingle(int rpsDetailId, int subCpmkId) async {
    final db = await database;
    final result = await db.query(
      tableRPSDetailSubCPMKBobot,
      where: 'rps_detail_id = ? AND sub_cpmk_id = ?',
      whereArgs: [rpsDetailId, subCpmkId],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<int> updateRPSDetailSubCPMKBobot(dynamic bobot) async {
    final db = await database;
    return await db.update(
      tableRPSDetailSubCPMKBobot,
      bobot.toMap(),
      where: 'id = ?',
      whereArgs: [bobot.id],
    );
  }

  Future<int> deleteRPSDetailSubCPMKBobot(int id) async {
    final db = await database;
    return await db.delete(
      tableRPSDetailSubCPMKBobot,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteRPSDetailSubCPMKBobotByRPSDetail(int rpsDetailId) async {
    final db = await database;
    await db.delete(
      tableRPSDetailSubCPMKBobot,
      where: 'rps_detail_id = ?',
      whereArgs: [rpsDetailId],
    );
  }

  // ===== SUB CPMK CPMK MAPPING OPERATIONS =====
  Future<int> insertSubCPMKCPMKMapping(dynamic mapping) async {
    final db = await database;
    return await db.insert(tableSubCPMKCPMKMapping, mapping.toMap());
  }

  Future<List<dynamic>> getSubCPMKCPMKMapping(int subCpmkId) async {
    final db = await database;
    return await db.query(
      tableSubCPMKCPMKMapping,
      where: 'sub_cpmk_id = ?',
      whereArgs: [subCpmkId],
    );
  }

  // 🚀 OPTIMASI: Get all SubCPMK-CPMK mappings untuk batch processing
  Future<List<dynamic>> getAllSubCPMKCPMKMappings() async {
    final db = await database;
    return await db.query(tableSubCPMKCPMKMapping);
  }

  Future<List<dynamic>> getCPMKSubCPMKMapping(int cpmkId) async {
    final db = await database;
    return await db.query(
      tableSubCPMKCPMKMapping,
      where: 'cpmk_id = ?',
      whereArgs: [cpmkId],
    );
  }

  Future<dynamic> getSubCPMKCPMKMappingSingle(int subCpmkId, int cpmkId) async {
    final db = await database;
    final result = await db.query(
      tableSubCPMKCPMKMapping,
      where: 'sub_cpmk_id = ? AND cpmk_id = ?',
      whereArgs: [subCpmkId, cpmkId],
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<int> updateSubCPMKCPMKMapping(dynamic mapping) async {
    final db = await database;
    return await db.update(
      tableSubCPMKCPMKMapping,
      mapping.toMap(),
      where: 'id = ?',
      whereArgs: [mapping.id],
    );
  }

  Future<int> deleteSubCPMKCPMKMapping(int id) async {
    final db = await database;
    return await db.delete(
      tableSubCPMKCPMKMapping,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🎯 CPL Calculation Tracking methods
  /// Record that CPL has been calculated for a specific matakuliah and tahun_ajaran
  Future<int> recordCPLCalculation(int matakuliahId, int tahunAjaran) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    try {
      return await db.insert(
        tableCPLCalculationTracking,
        {
          'matakuliah_id': matakuliahId,
          'tahun_ajaran': tahunAjaran,
          'calculated_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error recording CPL calculation: $e');
      rethrow;
    }
  }

  /// Get all calculated matakuliah-tahun_ajaran combinations
  Future<Set<String>> getCalculatedMatakuliahSet() async {
    final db = await database;
    final result = await db.query(tableCPLCalculationTracking);
    
    final calculatedSet = <String>{};
    for (final row in result) {
      final mkId = row['matakuliah_id'] as int;
      final tahunAjaran = row['tahun_ajaran'] as int;
      calculatedSet.add('${mkId}_$tahunAjaran');
    }
    
    return calculatedSet;
  }

  /// Check if CPL has been calculated for specific matakuliah and tahun_ajaran
  Future<bool> isCPLCalculated(int matakuliahId, int tahunAjaran) async {
    final db = await database;
    final result = await db.query(
      tableCPLCalculationTracking,
      where: 'matakuliah_id = ? AND tahun_ajaran = ?',
      whereArgs: [matakuliahId, tahunAjaran],
    );
    
    return result.isNotEmpty;
  }

  /// Get all matakuliah-tahun_ajaran combinations that have been calculated with their years
  Future<List<Map<String, dynamic>>> getCalculatedMatakuliahWithYears() async {
    final db = await database;
    final result = await db.query(
      tableCPLCalculationTracking,
      distinct: true,
      columns: ['matakuliah_id', 'tahun_ajaran'],
    );
    
    return result;
  }

  // � CPL Results Storage Methods (Permanent persistence untuk hasil perhitungan)
  
  /// Import json package helper untuk serialisasi Map
  String _mapToJson(Map<int, double> data) {
    return data.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  /// Save hasil perhitungan CPL untuk batch mahasiswa ke database (PERSISTENT)
  /// Digunakan saat user klik "Hitung CPL" untuk menyimpan hasil permanen
  Future<void> saveCPLCalculationResults(List<dynamic> results) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    try {
      for (final result in results) {
        // result adalah OBECalculationResult
        // Konversi Map ke String format untuk disimpan
        // 🎯 FIX: Gunakan legacy getters (uppercase) yang return Map<int, double>
        // result.subCPMKValues, result.cPMKValues, result.cPLValues
        final subCpmkValuesJson = _mapToJson(result.subCPMKValues);
        final cpmkValuesJson = _mapToJson(result.cPMKValues);
        final cplValuesJson = _mapToJson(result.cPLValues);
        final subCpmkBobotcsJson = result.subCpmkBobots != null 
            ? _mapToJson(result.subCpmkBobots!) 
            : '';

        batch.insert(
          tableCPLResults,
          {
            'mahasiswa_id': result.mahasiswaId,
            'matakuliah_id': result.matakuliahId,
            'tahun_ajaran': result.tahunAjaran,
            'sub_cpmk_values': subCpmkValuesJson,
            'cpmk_values': cpmkValuesJson,
            'cpl_values': cplValuesJson,
            'sub_cpmk_bobots': subCpmkBobotcsJson,
            'average_sub_cpmk_nilai': result.averageSubCPMKNilai,
            'average_cpmk_nilai': result.averageCPMKNilai,
            'average_cpl_nilai': result.averageCPLNilai,
            'calculated_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit();
      print('✅ CPL results saved for ${results.length} mahasiswa');
    } catch (e) {
      print('❌ Error saving CPL results: $e');
      rethrow;
    }
  }

  /// Get hasil perhitungan CPL untuk semua mahasiswa di matakuliah tertentu
  /// Returns List<Map> dari database (tanpa recalculate)
  Future<List<Map<String, dynamic>>> getCPLCalculationResults(int matakuliahId, int tahunAjaran) async {
    final db = await database;
    
    try {
      final results = await db.query(
        tableCPLResults,
        where: 'matakuliah_id = ? AND tahun_ajaran = ?',
        whereArgs: [matakuliahId, tahunAjaran],
        orderBy: 'mahasiswa_id ASC',
      );
      
      return results;
    } catch (e) {
      print('Error getting CPL results: $e');
      return [];
    }
  }

  /// Get individual CPL result untuk satu mahasiswa
  Future<Map<String, dynamic>?> getCPLCalculationResult(
    int mahasiswaId, 
    int matakuliahId, 
    int tahunAjaran
  ) async {
    final db = await database;
    
    try {
      final results = await db.query(
        tableCPLResults,
        where: 'mahasiswa_id = ? AND matakuliah_id = ? AND tahun_ajaran = ?',
        whereArgs: [mahasiswaId, matakuliahId, tahunAjaran],
      );
      
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      print('Error getting individual CPL result: $e');
      return null;
    }
  }

  /// Get CPL calculation results for all mahasiswa in a specific angkatan (tahun_masuk)
  Future<List<Map<String, dynamic>>> getCPLResultsByAngkatan(int tahunMasuk) async {
    final db = await database;
    
    try {
      print('[DB] Querying CPL results for tahun_masuk = $tahunMasuk');
      print('[DB] Using tables: $tableCPLResults, $tableMahasiswa');
      
      final results = await db.rawQuery('''
        SELECT cr.*, m.nim, m.nama, m.tahun_masuk
        FROM $tableCPLResults cr
        INNER JOIN $tableMahasiswa m ON cr.mahasiswa_id = m.id
        WHERE m.tahun_masuk = ?
        ORDER BY m.nim ASC
      ''', [tahunMasuk]);
      
      print('[DB] Query returned ${results.length} rows');
      
      // Also check if table exists and has data
      if (results.isEmpty) {
        final tableCheck = await db.rawQuery('SELECT COUNT(*) as cnt FROM $tableCPLResults');
        print('[DB] Total rows in $tableCPLResults: ${tableCheck.first['cnt']}');
        
        final mahasiswaCheck = await db.rawQuery('SELECT COUNT(*) as cnt FROM $tableMahasiswa WHERE tahun_masuk = ?', [tahunMasuk]);
        print('[DB] Mahasiswa with tahun_masuk=$tahunMasuk in $tableMahasiswa: ${mahasiswaCheck.first['cnt']}');
      }
      
      return results;
    } catch (e) {
      print('[DB] Error getting CPL results by angkatan: $e');
      return [];
    }
  }

  /// Delete hasil perhitungan CPL untuk matakuliah tertentu
  Future<int> deleteCPLCalculationResults(int matakuliahId, int tahunAjaran) async {
    final db = await database;
    
    try {
      return await db.delete(
        tableCPLResults,
        where: 'matakuliah_id = ? AND tahun_ajaran = ?',
        whereArgs: [matakuliahId, tahunAjaran],
      );
    } catch (e) {
      print('Error deleting CPL results: $e');
      rethrow;
    }
  }

  // �📊 Nilai Komponen Methods (Component Scores)
  /// Insert or update component scores for a student in a course
  Future<int> insertNilaiKomponen({
    required int mahasiswaId,
    required int matakuliahId,
    required double nilaiAktivitas,
    required double nilaiProyek,
    required double nilaiKuis,
    required double nilaiTugas,
    required double nilaiUTS,
    required double nilaiUAS,
    required int tahunAjaran,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    try {
      return await db.insert(
        tableNilaiKomponen,
        {
          'mahasiswa_id': mahasiswaId,
          'matakuliah_id': matakuliahId,
          'nilai_aktivitas': nilaiAktivitas,
          'nilai_proyek': nilaiProyek,
          'nilai_kuis': nilaiKuis,
          'nilai_tugas': nilaiTugas,
          'nilai_uts': nilaiUTS,
          'nilai_uas': nilaiUAS,
          'tahun_ajaran': tahunAjaran,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting nilai komponen: $e');
      rethrow;
    }
  }

  /// Get component scores for a specific student-course combination
  Future<Map<String, dynamic>?> getNilaiKomponen({
    required int mahasiswaId,
    required int matakuliahId,
    required int tahunAjaran,
  }) async {
    final db = await database;
    
    try {
      final result = await db.query(
        tableNilaiKomponen,
        where: 'mahasiswa_id = ? AND matakuliah_id = ? AND tahun_ajaran = ?',
        whereArgs: [mahasiswaId, matakuliahId, tahunAjaran],
      );
      
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Error getting nilai komponen: $e');
      rethrow;
    }
  }

  /// Update component scores for a student-course combination
  Future<int> updateNilaiKomponen({
    required int mahasiswaId,
    required int matakuliahId,
    required int tahunAjaran,
    required double nilaiAktivitas,
    required double nilaiProyek,
    required double nilaiKuis,
    required double nilaiTugas,
    required double nilaiUTS,
    required double nilaiUAS,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    try {
      return await db.update(
        tableNilaiKomponen,
        {
          'nilai_aktivitas': nilaiAktivitas,
          'nilai_proyek': nilaiProyek,
          'nilai_kuis': nilaiKuis,
          'nilai_tugas': nilaiTugas,
          'nilai_uts': nilaiUTS,
          'nilai_uas': nilaiUAS,
          'updated_at': now,
        },
        where: 'mahasiswa_id = ? AND matakuliah_id = ? AND tahun_ajaran = ?',
        whereArgs: [mahasiswaId, matakuliahId, tahunAjaran],
      );
    } catch (e) {
      print('Error updating nilai komponen: $e');
      rethrow;
    }
  }

  /// Get all component scores for a specific matakuliah and tahun_ajaran
  Future<List<Map<String, dynamic>>> getAllNilaiKomponen({
    required int matakuliahId,
    required int tahunAjaran,
  }) async {
    final db = await database;
    
    try {
      return await db.query(
        tableNilaiKomponen,
        where: 'matakuliah_id = ? AND tahun_ajaran = ?',
        whereArgs: [matakuliahId, tahunAjaran],
      );
    } catch (e) {
      print('Error getting all nilai komponen: $e');
      rethrow;
    }
  }

  /// Get component scores for a specific mahasiswa across all courses
  Future<List<Map<String, dynamic>>> getNilaiKomponenByMahasiswa({
    required int mahasiswaId,
    required int tahunAjaran,
  }) async {
    final db = await database;
    
    try {
      return await db.query(
        tableNilaiKomponen,
        where: 'mahasiswa_id = ? AND tahun_ajaran = ?',
        whereArgs: [mahasiswaId, tahunAjaran],
      );
    } catch (e) {
      print('Error getting nilai komponen for mahasiswa: $e');
      rethrow;
    }
  }

  /// Get ALL nilai_komponen for a mahasiswa (tanpa filter tahun_ajaran)
  /// Useful untuk mendapatkan semua data MK dari berbagai tahun akademik
  Future<List<Map<String, dynamic>>> getNilaiKomponenByMahasiswaAllYears({
    required int mahasiswaId,
  }) async {
    final db = await database;
    
    try {
      return await db.query(
        tableNilaiKomponen,
        where: 'mahasiswa_id = ?',
        whereArgs: [mahasiswaId],
      );
    } catch (e) {
      print('Error getting nilai komponen for mahasiswa (all years): $e');
      rethrow;
    }
  }

  /// Delete component scores for a student-course combination
  Future<int> deleteNilaiKomponen({
    required int mahasiswaId,
    required int matakuliahId,
    required int tahunAjaran,
  }) async {
    final db = await database;
    
    try {
      return await db.delete(
        tableNilaiKomponen,
        where: 'mahasiswa_id = ? AND matakuliah_id = ? AND tahun_ajaran = ?',
        whereArgs: [mahasiswaId, matakuliahId, tahunAjaran],
      );
    } catch (e) {
      print('Error deleting nilai komponen: $e');
      rethrow;
    }
  }

  // 📊 Bobot Matrix Management Methods

  /// Get bobot matrix for Sub-CPMK calculation from RPS Detail
  /// Returns: Map<subCpmkId, Map<componentIndex, bobot>>
  /// Component order: [0=aktivitas, 1=proyek, 2=kuis, 3=tugas, 4=uts, 5=uas]
  Future<Map<int, List<double>>> getBobotMatrixForMatakuliah({
    required int matakuliahId,
  }) async {
    try {
      // Get matakuliah dari database untuk determine bobot matrix
      // Format: Map<subCpmkId, List<bobot>> 
      // List index: [Aktivitas=0, Proyek=1, Kuis=2, Tugas=3, UTS=4, UAS=5]
      
      final matkulQuery = '''
        SELECT nama FROM $tableMatakuliah WHERE id = ?
      ''';
      final db = await database;
      final matkulResult = await db.rawQuery(matkulQuery, [matakuliahId]);
      
      if (matkulResult.isEmpty) {
        return {};
      }
      
      final matkulNama = (matkulResult.first['nama'] as String?)?.toLowerCase() ?? '';
      
      // Define bobot matrix untuk setiap matakuliah yang sudah dikonfigurasi
      final bobotMatrices = <String, Map<int, List<double>>>{
        // Kalkulus & Vektor - Hardcoded
        'kalkulus': {
          1: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],   // Sub1: Aktivitas, Tugas, UTS
          2: [0.0, 5.0, 5.0, 0.0, 5.0, 0.0],   // Sub2: Proyek, Kuis, UTS
          3: [5.0, 0.0, 0.0, 5.0, 5.0, 0.0],   // Sub3: Aktivitas, Tugas, UTS
          4: [0.0, 0.0, 5.0, 0.0, 0.0, 4.0],   // Sub4: Kuis, UAS
          5: [5.0, 0.0, 0.0, 5.0, 0.0, 4.0],   // Sub5: Aktivitas, Tugas, UAS
          6: [0.0, 5.0, 5.0, 0.0, 0.0, 4.0],   // Sub6: Proyek, Kuis, UAS
          7: [5.0, 0.0, 5.0, 5.0, 0.0, 3.0],   // Sub7: Aktivitas, Kuis, Tugas, UAS
        },
      };
      
      // Priority 1: Try to match hardcoded matakuliah
      for (final pattern in bobotMatrices.keys) {
        if (matkulNama.contains(pattern)) {
          return bobotMatrices[pattern]!;
        }
      }
      
      // Priority 2: Construct dari RPS Details yang user input
      final dynamicMatrix = await _constructBobotMatrixFromRPS(matakuliahId, matkulNama);
      if (dynamicMatrix.isNotEmpty) {
        return dynamicMatrix;
      }
      
      // Priority 3: Fallback ke equal distribution (default)
      return await _getBobotMatrixEqualDistribution(matakuliahId);
    } catch (e) {
      // Error getting bobot matrix - use fallback
      return await _getBobotMatrixEqualDistribution(matakuliahId).catchError((_) => <int, List<double>>{});
    }
  }

  /// 🔧 Construct bobot matrix dari RPS Details yang user input
  /// FIXED: Query rps_detail_sub_cpmk_bobot untuk bobot per Sub-CPMK
  /// Format: Map<subCpmkId, [aktivitas, proyek, kuis, tugas, uts, uas]>
  Future<Map<int, List<double>>> _constructBobotMatrixFromRPS(
    int matakuliahId,
    String matkulNama,
  ) async {
    try {
      final db = await database;
      
      // Get semua RPS Detail untuk mata kuliah ini
      final rpsDetails = await getRPSDetailByMatakuliah(matakuliahId);
      
      if (rpsDetails.isEmpty) {
        return {};
      }
      
      // Map jenis penilaian ke component index
      final componentMap = <String, int>{
        'aktivitas partisipatif': 0,
        'aktivitas': 0,
        'activity': 0,
        'hasil proyek': 1,
        'proyek': 1,
        'project': 1,
        'kuis': 2,
        'quiz': 2,
        'tugas': 3,
        'assignment': 3,
        'uts': 4,
        'ujian tengah semester': 4,
        'mid-term': 4,
        'uas': 5,
        'ujian akhir semester': 5,
        'final': 5,
      };
      
      final componentNames = ['aktivitas', 'proyek', 'kuis', 'tugas', 'uts', 'uas'];
      
      // Collect bobot per Sub-CPMK and component
      // Structure: {subCpmkId: {componentName: totalBobot}}
      final bobotPerComponent = <int, Map<String, double>>{};
      
      // Process each RPS week
      for (final rps in rpsDetails) {
        if (rps.id == null) continue;
        
        // Determine component type dari jenisNilai
        final jenisNilaiLower = (rps.jenisNilai ?? '').toLowerCase().trim();
        int componentIndex = 0;
        
        // Cari component yang match
        bool found = false;
        for (final entry in componentMap.entries) {
          if (jenisNilaiLower.contains(entry.key)) {
            componentIndex = entry.value;
            found = true;
            break;
          }
        }
        
        if (!found) {
          print('⚠️ Komponen "$jenisNilaiLower" tidak dikenal, skip RPS minggu ${rps.mingguKe}');
          continue;
        }
        
        // Query rps_detail_sub_cpmk_bobot untuk bobot per Sub-CPMK di RPS detail ini
        final bobotQuery = '''
          SELECT sub_cpmk_id, bobot FROM $tableRPSDetailSubCPMKBobot
          WHERE rps_detail_id = ?
        ''';
        
        final bobotRows = await db.rawQuery(bobotQuery, [rps.id]);
        
        if (bobotRows.isEmpty) {
          // Fallback: jika tidak ada di rps_detail_sub_cpmk_bobot, gunakan dari subCpmkIds
          if (rps.subCpmkIds != null && rps.subCpmkIds!.isNotEmpty) {
            for (final subCpmkId in rps.subCpmkIds!) {
              bobotPerComponent.putIfAbsent(subCpmkId, () => {});
              final componentName = componentNames[componentIndex];
              bobotPerComponent[subCpmkId]![componentName] = 
                (bobotPerComponent[subCpmkId]![componentName] ?? 0) + (rps.bobot ?? 0);
            }
          }
        } else {
          // ✅ Gunakan bobot dari rps_detail_sub_cpmk_bobot (per Sub-CPMK)
          for (final row in bobotRows) {
            final subCpmkId = row['sub_cpmk_id'] as int;
            final bobot = (row['bobot'] as num).toDouble();
            
            bobotPerComponent.putIfAbsent(subCpmkId, () => {});
            final componentName = componentNames[componentIndex];
            bobotPerComponent[subCpmkId]![componentName] = 
              (bobotPerComponent[subCpmkId]![componentName] ?? 0) + bobot;
          }
        }
      }
      
      if (bobotPerComponent.isEmpty) {
        print('⚠️ Tidak ada bobot dari RPS yang dapat diagregasi');
        return {};
      }
      
      // Convert ke List<double> format
      final result = <int, List<double>>{};
      for (final entry in bobotPerComponent.entries) {
        final subCpmkId = entry.key;
        final componentBobot = entry.value;
        
        // Build list: [aktivitas, proyek, kuis, tugas, uts, uas]
        final bobotList = <double>[];
        for (final compName in componentNames) {
          bobotList.add(componentBobot[compName] ?? 0.0);
        }
        
        final totalBobot = bobotList.fold(0.0, (a, b) => a + b);
        result[subCpmkId] = bobotList;
        print('✅ Sub-CPMK $subCpmkId bobot dari RPS: ${bobotList.map((b) => b.toStringAsFixed(2)).toList()} (total: ${totalBobot.toStringAsFixed(2)})');
      }
      
      return result;
    } catch (e) {
      print('❌ Error constructing bobot dari RPS: $e');
      return {};
    }
  }

  /// 📊 Fallback: Equal distribution bobot untuk semua komponen
  /// Default untuk mata kuliah yang tidak dikonfigurasi
  /// Index: [Aktivitas=0, Proyek=1, Kuis=2, Tugas=3, UTS=4, UAS=5]
  /// Total = 100%, masing-masing = 100/6 ≈ 16.67%
  Future<Map<int, List<double>>> _getBobotMatrixEqualDistribution(
    int matakuliahId,
  ) async {
    try {
      final db = await database;
      
      // Get semua Sub-CPMK untuk mata kuliah ini
      final subCpmkQuery = '''
        SELECT DISTINCT sub_cpmk_id FROM $tableSubCPMKCPMKMapping
        WHERE cpmk_id IN (
          SELECT id FROM $tableCPMK WHERE matakuliah_id = ?
        )
        UNION
        SELECT id FROM $tableSubCPMK WHERE matakuliah_id = ?
      ''';
      
      final result = await db.rawQuery(subCpmkQuery, [matakuliahId, matakuliahId]);
      
      if (result.isEmpty) {
        return {};
      }
      
      // FIXED: Equal distribution 100% untuk 6 komponen
      final equalBobot = [100.0 / 6, 100.0 / 6, 100.0 / 6, 100.0 / 6, 100.0 / 6, 100.0 / 6];
      
      final matrixResult = <int, List<double>>{};
      for (final row in result) {
        final subCpmkId = row['sub_cpmk_id'] as int? ?? row['id'] as int;
        matrixResult[subCpmkId] = List.from(equalBobot);
      }
      
      return matrixResult;
    } catch (e) {
      return {};
    }
  }

  /// Get Sub-CPMK to CPMK bobot mapping
  /// Returns: Map<cpmkId, Map<subCpmkId, bobot>>
  Future<Map<int, Map<int, double>>> getSubCPMKToCPMKBobotMapping({
    required int matakuliahId,
  }) async {
    final db = await database;
    
    try {
      final result = await db.query(
        tableSubCPMKCPMKMapping,
        where: 'cpmk_id IN (SELECT id FROM $tableCPMK WHERE matakuliah_id = ?)',
        whereArgs: [matakuliahId],
      );

      final bobotMapping = <int, Map<int, double>>{};

      for (final row in result) {
        final cpmkId = row['cpmk_id'] as int;
        final subCpmkId = row['sub_cpmk_id'] as int;
        final bobot = (row['bobot'] as num).toDouble();

        if (!bobotMapping.containsKey(cpmkId)) {
          bobotMapping[cpmkId] = {};
        }

        bobotMapping[cpmkId]![subCpmkId] = bobot;
      }

      return bobotMapping;
    } catch (e) {
      print('Error getting Sub-CPMK to CPMK mapping: $e');
      return {};
    }
  }

  /// Insert Sub-CPMK to CPMK bobot mapping
  Future<int> insertSubCPMKToCPMKBobot({
    required int subCpmkId,
    required int cpmkId,
    required double bobot,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    try {
      return await db.insert(
        tableSubCPMKCPMKMapping,
        {
          'sub_cpmk_id': subCpmkId,
          'cpmk_id': cpmkId,
          'bobot': bobot,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting Sub-CPMK to CPMK bobot: $e');
      rethrow;
    }
  }

  /// Batch insert Sub-CPMK to CPMK bobot mappings
  Future<void> insertSubCPMKToCPMKBobotBatch({
    required Map<int, Map<int, double>> bobotMappings,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    try {
      final batch = db.batch();
      
      for (final cpmkEntry in bobotMappings.entries) {
        final cpmkId = cpmkEntry.key;
        final subCpmkBobots = cpmkEntry.value;
        
        for (final subCpmkEntry in subCpmkBobots.entries) {
          final subCpmkId = subCpmkEntry.key;
          final bobot = subCpmkEntry.value;
          
          batch.insert(
            tableSubCPMKCPMKMapping,
            {
              'sub_cpmk_id': subCpmkId,
              'cpmk_id': cpmkId,
              'bobot': bobot,
              'created_at': now,
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      
      await batch.commit();
    } catch (e) {
      print('Error batch inserting Sub-CPMK to CPMK bobot: $e');
      rethrow;
    }
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }

  /// Get CPL ← CPMK mappings from cpl_cpmk table
  /// Returns list of mappings: [{cpl_id, cpmk_id, bobot}, ...]
  /// Returns null if table doesn't exist or is empty (CPL is optional)
  Future<List<Map<String, dynamic>>?> getAllCPLCPMKMappings() async {
    try {
      final db = await database;
      // Try to query cpl_cpmk table (may not exist)
      final result = await db.query('cpl_cpmk');
      return result.isEmpty ? null : result;
    } catch (e) {
      // Table doesn't exist or other error - CPL is optional
      print('ℹ️ CPL←CPMK mappings not available (optional): $e');
      return null;
    }
  }

  /// Get Sub-CPMK component bobot from getBobotMatrixForMatakuliah
  /// This is a wrapper around the existing bobot loading logic
  /// Returns Map<subCpmkId, Map<componentName, bobot>>
  /// Returns null if no data available
  Future<Map<String, Map<String, double>>?> getSubCPMKComponentBobots(int matakuliahId) async {
    try {
      final bobotMatrix = await getBobotMatrixForMatakuliah(
        matakuliahId: matakuliahId,
      );

      if (bobotMatrix.isEmpty) {
        return null;
      }

      // Convert Map<int, List<double>> to Map<String, Map<String, double>>
      const componentNames = ['aktivitas', 'proyek', 'kuis', 'tugas', 'uts', 'uas'];
      final result = <String, Map<String, double>>{};

      for (final entry in bobotMatrix.entries) {
        final subCpmkId = entry.key;
        final bobotList = entry.value;
        final bobotMap = <String, double>{};

        for (int i = 0; i < componentNames.length && i < bobotList.length; i++) {
          bobotMap[componentNames[i]] = bobotList[i];
        }

        result[subCpmkId.toString()] = bobotMap;
      }

      return result.isEmpty ? null : result;
    } catch (e) {
      print('ℹ️ Could not load component bobots for MK $matakuliahId: $e');
      return null;
    }
  }
}
