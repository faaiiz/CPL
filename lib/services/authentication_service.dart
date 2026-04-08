import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import 'database_helper.dart';

class AuthenticationService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Test/Development credentials untuk WEB
  static const Map<String, Map<String, String>> _devCredentials = {
    'admin': {'password': 'Admin123', 'role': 'admin', 'nama': 'Administrator'},
    'dosen': {'password': 'Dosen123', 'role': 'dosen', 'nama': 'Dosen Test'},
    'mhs': {'password': 'Student123', 'role': 'mahasiswa', 'nama': 'Mahasiswa Test', 'nim': '12345'},
  };

  // Hash password menggunakan SHA-256
  String _hashPassword(String password) {
    return sha256.convert(password.codeUnits).toString();
  }

  // Login user
  Future<User?> login(String username, String password) async {
    try {
      // For WEB: Use development credentials (no SQLite available)
      if (kIsWeb) {
        return _webLogin(username, password);
      }

      // For DESKTOP: Use SQLite database
      final user = await _dbHelper.getUserByUsername(username);
      
      if (user == null) {
        return null; // User tidak ditemukan
      }

      if (!user.isActive) {
        return null; // User tidak aktif
      }

      // Verifikasi password
      final hashedPassword = _hashPassword(password);
      if (user.password != hashedPassword) {
        return null; // Password salah
      }

      return user;
    } catch (e) {
      print('❌ Login error: $e');
      return null;
    }
  }

  /// Web login menggunakan dev credentials
  User? _webLogin(String username, String password) {
    print('🌐 WEB Login attempt: $username');
    
    if (!_devCredentials.containsKey(username)) {
      print('❌ User not found: $username');
      return null;
    }

    final devUser = _devCredentials[username]!;
    if (devUser['password'] != password) {
      print('❌ Password incorrect for: $username');
      return null;
    }

    print('✓ WEB Login success: $username');
    return User(
      id: username.hashCode,
      username: username,
      password: _hashPassword(password),
      role: devUser['role']!,
      nama: devUser['nama']!,
      nim: devUser['nim'],
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  // Register user baru (hanya untuk admin)
  Future<bool> registerUser({
    required String username,
    required String password,
    required String role,
    required String nama,
    String? nim,
  }) async {
    try {
      // Check apakah username sudah ada
      final existingUser = await _dbHelper.getUserByUsername(username);
      if (existingUser != null) {
        return false; // Username sudah terdaftar
      }

      final hashedPassword = _hashPassword(password);
      final newUser = User(
        username: username,
        password: hashedPassword,
        role: role,
        nama: nama,
        nim: nim,
        createdAt: DateTime.now(),
      );

      await _dbHelper.insertUser(newUser);
      return true;
    } catch (e) {
        // TODO: Replace with logging framework
      return false;
    }
  }

  // Update password
  Future<bool> updatePassword(int userId, String oldPassword, String newPassword) async {
    try {
      // Skip for web
      if (kIsWeb) {
        return false;
      }
      
      // Get user by id
      final users = await _dbHelper.getAllUsers();
      final user = users.firstWhere((u) => u.id == userId);

      // Verifikasi old password
      final hashedOldPassword = _hashPassword(oldPassword);
      if (user.password != hashedOldPassword) {
        return false; // Old password salah
      }

      final hashedNewPassword = _hashPassword(newPassword);
      final updatedUser = user.copyWith(
        password: hashedNewPassword,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateUser(updatedUser);
      return true;
    } catch (e) {
      print('❌ Update password error: $e');
      return false;
    }
  }

  // Initialize admin user
  Future<void> initializeAdminUser() async {
    if (kIsWeb) {
      print('✓ WEB platform - Using dev credentials');
      return;
    }
    
    try {
      final existingAdmin = await _dbHelper.getUserByUsername('admin');
      if (existingAdmin == null) {
        print('📝 Creating default admin user...');
        await registerUser(
          username: 'admin',
          password: 'Admin123',
          role: 'admin',
          nama: 'Administrator',
        );
        print('✓ Admin user created');
      }
    } catch (e) {
      print('⚠️  Error initializing admin: $e');
    }
  }

  // Deactivate user
  Future<bool> deactivateUser(int userId) async {
    try {
      final users = await _dbHelper.getAllUsers();
      final user = users.firstWhere((u) => u.id == userId);
      final deactivatedUser = user.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      await _dbHelper.updateUser(deactivatedUser);
      return true;
    } catch (e) {
      print('❌ Deactivate user error: $e');
      return false;
    }
  }

  // Activate user
  Future<bool> activateUser(int userId) async {
    try {
      final users = await _dbHelper.getAllUsers();
      final user = users.firstWhere((u) => u.id == userId);
      final activatedUser = user.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );
      await _dbHelper.updateUser(activatedUser);
      return true;
    } catch (e) {
      print('❌ Activate user error: $e');
      return false;
    }
  }

  // Validasi password strength
  bool isPasswordStrong(String password) {
    if (password.length < 6) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  // Get user by id
  Future<User?> getUserById(int id) async {
    try {
      final users = await _dbHelper.getAllUsers();
      return users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  // Check if username exists
  Future<bool> isUsernameExists(String username) async {
    if (kIsWeb) {
      return _devCredentials.containsKey(username);
    }
    
    final user = await _dbHelper.getUserByUsername(username);
    return user != null;
  }
}
