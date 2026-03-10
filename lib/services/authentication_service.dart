import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import 'database_helper.dart';

class AuthenticationService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Hash password menggunakan SHA-256
  String _hashPassword(String password) {
    return sha256.convert(password.codeUnits).toString();
  }

  // Login user
  Future<User?> login(String username, String password) async {
    try {
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
        // TODO: Replace with logging framework
      return null;
    }
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
        // TODO: Replace with logging framework
      return false;
    }
  }

  // Validasi password strength
  bool isPasswordStrong(String password) {
    if (password.length < 6) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false; // At least one uppercase
    if (!password.contains(RegExp(r'[0-9]'))) return false; // At least one number
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
    final user = await _dbHelper.getUserByUsername(username);
    return user != null;
  }

  // Initialize admin user
  Future<void> initializeAdminUser() async {
    try {
      final existingAdmin = await _dbHelper.getUserByUsername('admin');
      if (existingAdmin == null) {
        await registerUser(
          username: 'admin',
          password: 'Admin123',
          role: 'admin',
          nama: 'Administrator',
        );
      }
    } catch (e) {
        // TODO: Replace with logging framework
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
        // TODO: Replace with logging framework
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
        // TODO: Replace with logging framework
      return false;
    }
  }
}
