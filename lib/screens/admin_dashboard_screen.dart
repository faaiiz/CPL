import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/matakuliah_model.dart';
import '../models/rps_detail_model.dart';
import '../models/cpmk_model.dart';
import '../models/cpl_master_model.dart';
import '../models/sub_cpmk_model.dart';
import '../services/database_helper.dart';
import '../services/rps_pdf_generator.dart';
import '../services/obe_calculation_helper.dart';
import './cpmk_master_screen.dart';
import './excel_import_screen.dart';
import './nilai_batch_import_screen.dart';
import './cpl_cpmk_export_screen.dart';

enum AdminMenuType {
  home,
  mahasiswa,
  matakuliah,
  hitungCPL,
  export,
  import,
  batchNilaiImport,
  inputRPS,
  kelolaAdditional,
  assessmentOutcomes,
}

class AdminDashboardScreen extends StatefulWidget {
  final User user;

  const AdminDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _dbHelper = DatabaseHelper();
  int _totalMahasiswa = 0;
  int _totalMatakuliah = 0;
  AdminMenuType _selectedMenu = AdminMenuType.home;
  
  // 🎯 Cache untuk performa
  DateTime? _lastStatisticsRefresh;
  static const _refreshInterval = Duration(minutes: 5);
  
  // 🎯 GlobalKeys untuk embedded content widgets - untuk refresh data setelah import
  final _mahasiswaContentKey = GlobalKey<_EmbeddedMahasiswaContentState>();
  final _matakuliahContentKey = GlobalKey<_EmbeddedMatakuliahContentState>();

  @override
  void initState() {
    super.initState();
    // Load statistics hanya saat pertama kali
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      // Parallelize independent queries
      final results = await Future.wait([
        _dbHelper.getAllMahasiswa(),
        _dbHelper.getAllMatakuliah(),
      ]);
      
      final mahasiswa = results[0] as List<dynamic>;
      final matakuliah = results[1] as List<dynamic>;
      
      if (mounted) {
        setState(() {
          _totalMahasiswa = mahasiswa.length;
          _totalMatakuliah = matakuliah.length;
          _lastStatisticsRefresh = DateTime.now();
        });
      }
    } catch (e) {
      // Error loading statistics - continue
    }
  }

  // Wrapper untuk menu selection - batasi refresh frequency
  void _selectMenu(AdminMenuType menu) {
    setState(() => _selectedMenu = menu);
    
    // 🎯 Hanya refresh statistics jika sudah lebih dari 5 menit
    final now = DateTime.now();
    if (_lastStatisticsRefresh == null || 
        now.difference(_lastStatisticsRefresh!).compareTo(_refreshInterval) > 0) {
      _loadStatistics();
    }
  }
  
  // 🎯 Handler untuk import mahasiswa - dengan auto refresh setelah import
  Future<void> _handleMahasiswaImportClick() async {
    final result = await Navigator.pushNamed(context, '/mahasiswa_template_import');
    // Jika import berhasil (return true), refresh data mahasiswa
    if (result == true && mounted) {
      _mahasiswaContentKey.currentState?.refreshData();
      // Juga refresh statistics
      _loadStatistics();
    }
  }
  
  // 🎯 Handler untuk import matakuliah - dengan auto refresh setelah import
  Future<void> _handleMatakuliahImportClick() async {
    final result = await Navigator.pushNamed(context, '/matakuliah_template_import');
    // Jika import berhasil (return true), refresh data matakuliah
    if (result == true && mounted) {
      _matakuliahContentKey.currentState?.refreshData();
      // Juga refresh statistics
      _loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Ketua Prodi'),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 4,
        actions: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: Text(
                'Selamat datang, ${widget.user.nama}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.danger),
                    SizedBox(width: AppSpacing.sm),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar (10%) - Fixed/Static
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  right: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Logo/Header
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                    child: const Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  // Menu Items - Scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildSidebarMenuItem(
                            icon: Icons.home,
                            label: 'Beranda',
                            isSelected: _selectedMenu == AdminMenuType.home,
                            onTap: () => _selectMenu(AdminMenuType.home),
                          ),
                          _buildDivider(),
                          _buildSidebarMenuItem(
                            icon: Icons.person,
                            label: 'Mahasiswa',
                            isSelected: _selectedMenu == AdminMenuType.mahasiswa,
                            onTap: () => _selectMenu(AdminMenuType.mahasiswa),
                          ),
                          _buildSidebarMenuItem(
                            icon: Icons.book,
                            label: 'Matakuliah',
                            isSelected: _selectedMenu == AdminMenuType.matakuliah,
                            onTap: () => _selectMenu(AdminMenuType.matakuliah),
                          ),
                          _buildDivider(),
                          _buildSidebarMenuItem(
                            icon: Icons.settings,
                            label: 'Kelola CPL & CPMK',
                            isSelected: _selectedMenu == AdminMenuType.kelolaAdditional,
                            onTap: () => _selectMenu(AdminMenuType.kelolaAdditional),
                          ),
                          _buildSidebarMenuItem(
                            icon: Icons.description,
                            label: 'Input RPS',
                            isSelected: _selectedMenu == AdminMenuType.inputRPS,
                            onTap: () => _selectMenu(AdminMenuType.inputRPS),
                          ),
                          _buildDivider(),
                          _buildSidebarMenuItem(
                            icon: Icons.calculate,
                            label: 'Hitung CPL dan CPMK',
                            isSelected: _selectedMenu == AdminMenuType.hitungCPL,
                            onTap: () => _selectMenu(AdminMenuType.hitungCPL),
                          ),
                          _buildSidebarMenuItem(
                            icon: Icons.assessment,
                            label: 'Pengukuran CPL dan CPMK',
                            isSelected: _selectedMenu == AdminMenuType.assessmentOutcomes,
                            onTap: () => _selectMenu(AdminMenuType.assessmentOutcomes),
                          ),
                          _buildDivider(),
                          _buildSidebarMenuItem(
                            icon: Icons.file_upload,
                            label: 'Import',
                            isSelected: _selectedMenu == AdminMenuType.import,
                            onTap: () => _selectMenu(AdminMenuType.import),
                          ),
                          _buildSidebarMenuItem(
                            icon: Icons.file_download,
                            label: 'Export',
                            isSelected: _selectedMenu == AdminMenuType.export,
                            onTap: () => _selectMenu(AdminMenuType.export),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right Content Area (90%)
          Expanded(
            child: Container(
              color: Colors.white,
              child: _buildContentArea(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarMenuItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      color: isSelected ? AppColors.secondary.withValues(alpha: 0.1) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.secondary : Colors.grey[600],
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.secondary : Colors.grey[700],
          ),
        ),
        selected: isSelected,
        onTap: onTap,
        hoverColor: AppColors.primary.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey[300],
      height: 1,
      thickness: 1,
    );
  }

  // 🎯 Build content area dengan IndexedStack untuk preserve state
  Widget _buildContentArea() {
    final menuIndex = AdminMenuType.values.indexOf(_selectedMenu);
    
    return IndexedStack(
      index: menuIndex,
      children: [
        // 0: home
        _buildHomeContent(),
        // 1: mahasiswa
        _EmbeddedMahasiswaContent(key: _mahasiswaContentKey, dbHelper: _dbHelper),
        // 2: matakuliah
        _EmbeddedMatakuliahContent(key: _matakuliahContentKey, dbHelper: _dbHelper),
        // 3: hitungCPL
        _EmbeddedHitungCPLContent(context: context),
        // 4: export
        _EmbeddedExportContent(context: context),
        // 5: import
        _EmbeddedImportContent(
          context: context,
          onMahasiswaImport: _handleMahasiswaImportClick,
          onMatakuliahImport: _handleMatakuliahImportClick,
        ),
        // 6: batchNilaiImport
        const NilaiBatchImportScreen(),
        // 7: inputRPS
        _EmbeddedInputRPSContent(context: context),
        // 8: kelolaAdditional
        _buildKelolaAdditionalContent(),
        // 9: assessmentOutcomes
        _EmbeddedAssessmentOutcomesContent(context: context),
      ],
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, Color(0xFF2980B9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sistem Capaian Pembelajaran Lulusan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Kelola data mahasiswa, nilai, dan analisis CPL dengan mudah',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Selamat datang, ${widget.user.nama}!',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Quick Stats
          const Text(
            'Statistik Cepat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Mahasiswa',
                  value: _totalMahasiswa.toString(),
                  color: AppColors.secondary,
                  icon: Icons.person,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildStatCard(
                  title: 'Matakuliah',
                  value: _totalMatakuliah.toString(),
                  color: AppColors.success,
                  icon: Icons.book,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Informasi Sistem',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Pengguna', widget.user.nama),
                  _buildInfoRow('Role', widget.user.role),
                  _buildInfoRow('Status', widget.user.isActive ? 'Aktif' : 'Tidak Aktif'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKelolaAdditionalContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kelola CPL & CPMK',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _buildMenuCard(
                icon: Icons.flag,
                label: 'Kelola CPL',
                color: const Color(0xFF27AE60),
                onTap: () => Navigator.pushNamed(context, '/cpl_master'),
              ),
              _buildMenuCard(
                icon: Icons.assignment_turned_in,
                label: 'Kelola CPMK',
                color: const Color(0xFF229954),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CPMKMasterScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 160,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0.65),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.subtleText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.subtleText,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Embedded Content Widgets
class _EmbeddedMahasiswaContent extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const _EmbeddedMahasiswaContent({super.key, required this.dbHelper});

  @override
  State<_EmbeddedMahasiswaContent> createState() =>
      _EmbeddedMahasiswaContentState();
}

class _EmbeddedMahasiswaContentState extends State<_EmbeddedMahasiswaContent> {
  late Future<List<dynamic>> _mahasiswaList;
  final _filterController = TextEditingController();
  String _sortBy = 'nim'; // nim, nama, tahun
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _mahasiswaList = widget.dbHelper.getAllMahasiswa();
    });
  }
  
  // 🎯 Public method untuk refresh data - dipanggil dari parent setelah import
  void refreshData() {
    _loadData();
  }

  List<dynamic> _filterAndSortData(List<dynamic> data) {
    // Filter
    var filtered = data.where((mhs) {
      final nim = mhs.nim?.toLowerCase() ?? '';
      final nama = mhs.nama?.toLowerCase() ?? '';
      final query = _filterController.text.toLowerCase();
      return nim.contains(query) || nama.contains(query);
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'nim':
          comparison = (a.nim ?? '').compareTo(b.nim ?? '');
          break;
        case 'nama':
          comparison = (a.nama ?? '').compareTo(b.nama ?? '');
          break;
        case 'tahun':
          comparison = (a.tahunMasuk ?? 0).compareTo(b.tahunMasuk ?? 0);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daftar Mahasiswa',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Filter Section
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _filterController,
                  decoration: InputDecoration(
                    hintText: 'Cari NIM atau Nama Mahasiswa...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Sort Controls
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.sort, color: AppColors.primary),
                          items: const [
                            DropdownMenuItem(value: 'nim', child: Text('Urutkan: NIM')),
                            DropdownMenuItem(value: 'nama', child: Text('Urutkan: Nama')),
                            DropdownMenuItem(value: 'tahun', child: Text('Urutkan: Tahun')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value ?? 'nim';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: AppColors.primary,
                        ),
                        tooltip: _sortAscending ? 'Naik (A-Z)' : 'Turun (Z-A)',
                        onPressed: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Data Display
          FutureBuilder<List<dynamic>>(
            future: _mahasiswaList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final data = snapshot.data ?? [];
              final filtered = _filterAndSortData(data);
              if (filtered.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          data.isEmpty ? 'Belum ada data mahasiswa' : 'Hasil pencarian tidak ditemukan',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final mhs = filtered[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: NIM | Tahun Masuk
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NIM',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      mhs.nim ?? '-',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Tahun Masuk',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      mhs.tahunMasuk?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Nama Mahasiswa
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Mahasiswa',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mhs.nama ?? '-',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmbeddedMatakuliahContent extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const _EmbeddedMatakuliahContent({super.key, required this.dbHelper});

  @override
  State<_EmbeddedMatakuliahContent> createState() =>
      _EmbeddedMatakuliahContentState();
}

class _EmbeddedMatakuliahContentState
    extends State<_EmbeddedMatakuliahContent> {
  late Future<List<dynamic>> _matakuliahList;
  final _filterController = TextEditingController();
  String _sortBy = 'kode'; // kode, nama, semester
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _matakuliahList = widget.dbHelper.getAllMatakuliah();
    });
  }
  
  // 🎯 Public method untuk refresh data - dipanggil dari parent setelah import
  void refreshData() {
    _loadData();
  }

  List<dynamic> _filterAndSortData(List<dynamic> data) {
    // Filter
    var filtered = data.where((mk) {
      final kode = mk.kode?.toLowerCase() ?? '';
      final nama = mk.nama?.toLowerCase() ?? '';
      final query = _filterController.text.toLowerCase();
      return kode.contains(query) || nama.contains(query);
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'kode':
          comparison = (a.kode ?? '').compareTo(b.kode ?? '');
          break;
        case 'nama':
          comparison = (a.nama ?? '').compareTo(b.nama ?? '');
          break;
        case 'semester':
          comparison = (a.semester ?? 0).compareTo(b.semester ?? 0);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daftar Matakuliah',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Filter Section
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _filterController,
                  decoration: InputDecoration(
                    hintText: 'Cari Kode atau Nama Matakuliah...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                // Sort Controls
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.sort, color: AppColors.primary),
                          items: const [
                            DropdownMenuItem(value: 'kode', child: Text('Urutkan: Kode')),
                            DropdownMenuItem(value: 'nama', child: Text('Urutkan: Nama')),
                            DropdownMenuItem(value: 'semester', child: Text('Urutkan: Semester')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value ?? 'kode';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: AppColors.primary,
                        ),
                        tooltip: _sortAscending ? 'Naik (A-Z)' : 'Turun (Z-A)',
                        onPressed: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Data Display
          FutureBuilder<List<dynamic>>(
            future: _matakuliahList,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final data = snapshot.data ?? [];
              final filtered = _filterAndSortData(data);
              if (filtered.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_books_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          data.isEmpty ? 'Belum ada data matakuliah' : 'Hasil pencarian tidak ditemukan',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final mk = filtered[index];
                  final isWajib = mk.jenis?.toLowerCase() == 'wajib';
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: Kode | Semester | SKS
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kode',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      mk.kode ?? '-',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Semester',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      mk.semester?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'SKS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      mk.sks?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Nama Matakuliah
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Matakuliah',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mk.nama ?? '-',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Jenis Badge
                          Chip(
                            label: Text(
                              mk.jenis?.toUpperCase() ?? '-',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isWajib ? const Color(0xFF27AE60) : const Color(0xFFE67E22),
                              ),
                            ),
                            backgroundColor: isWajib 
                                ? const Color(0xFF27AE60).withValues(alpha: 0.1)
                                : const Color(0xFFE67E22).withValues(alpha: 0.1),
                            side: BorderSide(
                              color: isWajib ? const Color(0xFF27AE60) : const Color(0xFFE67E22),
                              width: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmbeddedHitungCPLContent extends StatefulWidget {
  final BuildContext context;

  const _EmbeddedHitungCPLContent({required this.context});

  @override
  State<_EmbeddedHitungCPLContent> createState() =>
      _EmbeddedHitungCPLContentState();
}

class _EmbeddedHitungCPLContentState extends State<_EmbeddedHitungCPLContent>
    with TickerProviderStateMixin {
  final _dbHelper = DatabaseHelper();
  final _obeHelper = OBECalculationHelper();

  Future<List<Map<String, dynamic>>>? _matakuliahWithNilaiList;
  
  // 🎯 Track timeout state (used for debugging timeout scenarios)
  // ignore: unused_field
  bool _dataLoadTimeout = false;
  // ignore: unused_field
  bool _noDataDialogShown = false;

  OBECalculationResult? _calculationResult;
  List<OBECalculationResult>? _batchCalculationResults;
  
  // 🎯 Simpan hasil perhitungan per matakuliah: format 'mkId_tahunAjaran' -> List<OBECalculationResult>
  final Map<String, List<OBECalculationResult>> _calculationResultsByMK = {};
  
  // 🎯 Track yang sudah dihitung: format 'mkId_tahunAjaran'
  final Set<String> _calculatedMatakuliahSet = {};
  
  // 🎯 Track matakuliah yang sedang dihitung (prevent race condition)
  final Set<String> _calculatingMatakuliahSet = {};
  
  // 🎯 Track matakuliah yang sedang ditampilkan hasilnya
  String? _currentDisplayedMKKey;
  
  // 🎯 Simpan info matakuliah yang sedang ditampilkan (nama dan tahun ajaran)
  String _currentMatakuliahNama = '';
  int _currentTahunAjaran = 0;
  
  // GlobalKey untuk scroll ke section hasil
  final _resultsKey = GlobalKey();
  
  // 🎯 Lazy loading flag
  bool _dataLoaded = false;
  
  late AnimationController _loadingAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  
  // 🎯 Track dialog state untuk mencegah multiple pop
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeIn),
    );
    
    // 🎯 Lazy load: jangan load data di initState, tunggu pertama kali widget ditampilkan
    // Data akan di-load di build method saat pertama kali diperlukan
  }
  
  @override
  void dispose() {
    _loadingAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🎯 Initialize data hanya saat dibutuhkan (lazy loading)
  void _initializeDataIfNeeded() {
    // 🎯 Selalu reload data untuk menangkap matakuliah baru
    // Clear hasil perhitungan lama agar RPS terbaru tetap ter-reflect
    _batchCalculationResults = null;
    _calculationResult = null;
    
    _loadData();
    if (!_dataLoaded) {
      _dataLoaded = true;
    }
  }

  void _loadData() {
    if (!mounted) return;
    _matakuliahWithNilaiList = _loadMatakuliahWithNilai();
    // Load calculation status from database
    _loadCalculationStatus();
    if (mounted) {
      setState(() {});
    }
  }

  // Load calculation status dari database
  Future<void> _loadCalculationStatus() async {
    try {
      final calculatedSet = await _dbHelper.getCalculatedMatakuliahSet();
      if (mounted) {
        setState(() {
          _calculatedMatakuliahSet.clear();
          _calculatedMatakuliahSet.addAll(calculatedSet);
        });
      }
    } catch (e) {
      // Error loading calculation status - continue
    }
  }

  // Method untuk menampilkan hasil perhitungan yang sudah ada untuk matakuliah spesifik
  void _showSavedResults(int matakuliahId, int tahunAjaran) async {
    final mkKey = '${matakuliahId}_$tahunAjaran}';
    
    // 🎯 Cek apakah hasil sudah ada di cache per matakuliah
    if (_calculationResultsByMK.containsKey(mkKey) && _calculationResultsByMK[mkKey]!.isNotEmpty) {
      // Cari nama matakuliah dari list
      final matakuliahData = await _matakuliahWithNilaiList;
      String mkNama = 'Mata Kuliah';
      if (matakuliahData != null) {
        for (final item in matakuliahData) {
          if (item['matakuliah_id'] == matakuliahId && item['tahun_ajaran'] == tahunAjaran) {
            mkNama = item['matakuliah_nama'] as String;
            break;
          }
        }
      }
      
      // Reset dan play fade animation untuk menampilkan hasil
      if (mounted) {
        _fadeAnimationController.reset();
        setState(() {
          _batchCalculationResults = _calculationResultsByMK[mkKey];
          _currentDisplayedMKKey = mkKey;
          _currentMatakuliahNama = mkNama;
          _currentTahunAjaran = tahunAjaran;
          _calculationResult = null;
        });
        
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          await _fadeAnimationController.forward();
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Menampilkan hasil perhitungan'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Jika belum ada di cache, load dari database dengan recalculate
    // (karena hasil perhitungan perlu dikomputasi dari nilai yang ada)
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📊 Menghitung hasil perhitungan OBE...'),
          duration: Duration(seconds: 2),
        ),
      );

      final results = await _obeHelper.calculateBatchOBEResultsForMatakuliah(
        matakuliahId: matakuliahId,
        tahunAjaran: tahunAjaran,
      );

      if (!mounted) return;
      
      // Cari nama matakuliah dari list
      final matakuliahData = await _matakuliahWithNilaiList;
      String mkNama = 'Mata Kuliah';
      if (matakuliahData != null) {
        for (final item in matakuliahData) {
          if (item['matakuliah_id'] == matakuliahId && item['tahun_ajaran'] == tahunAjaran) {
            mkNama = item['matakuliah_nama'] as String;
            break;
          }
        }
      }

      // Reset dan play animation
      _fadeAnimationController.reset();
      
      setState(() {
        _batchCalculationResults = results;
        _calculationResultsByMK[mkKey] = results; // 🎯 Simpan ke cache per MK
        _currentDisplayedMKKey = mkKey;
        _currentMatakuliahNama = mkNama;
        _currentTahunAjaran = tahunAjaran;
        _calculationResult = null;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        await _fadeAnimationController.forward();
      }

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Tidak ada data perhitungan untuk ditampilkan'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Hasil perhitungan dimuat (${results.length} mahasiswa)'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Load matakuliah yang memiliki data nilai (nilai sudah diupload)
  Future<List<Map<String, dynamic>>> _loadMatakuliahWithNilai() async {
    try {
      // 🎯 Reset flags sebelum loading baru
      _dataLoadTimeout = false;
      _noDataDialogShown = false;
      
      print('🔄 [_loadMatakuliahWithNilai] Starting data load with 20s timeout...');
      
      final result = await _loadMatakuliahWithNilaiInternal()
          .timeout(const Duration(seconds: 20), onTimeout: () {
        print('⏱️ [TIMEOUT] Data loading exceeded 20 seconds - showing no data dialog');
        
        // Timeout terpicu - langsung perbarui state dan tampilkan dialog
        if (mounted) {
          setState(() {
            _dataLoadTimeout = true;
            _noDataDialogShown = true;
            print('🔍 [TIMEOUT] State updated: _dataLoadTimeout=true, _noDataDialogShown=true');
          });
          
          // Tampilkan dialog langsung (bukan via addPostFrameCallback)
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_dialogOpen) {
                print('📢 [TIMEOUT] Showing no data dialog...');
                _showNoNilaiDialog();
              }
            });
          }
        }
        
        print('⏱️ [TIMEOUT] Returning empty list to break loading...');
        return [];
      });
      
      if (result.isNotEmpty) {
        print('✅ [_loadMatakuliahWithNilai] Data loaded successfully: ${result.length} items');
      }
      
      setState(() {
        _dataLoadTimeout = false;
      });
      
      return result;
    } catch (e) {
      print('❌ Error loading matakuliah: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadMatakuliahWithNilaiInternal() async {
    try {
      print('🔍 [_loadMatakuliahWithNilaiInternal] START - querying database...');
      
      final startTime = DateTime.now();
      
      final allNilai = await _dbHelper.getAllNilai();
      print('   ⏱️  getAllNilai took ${DateTime.now().difference(startTime).inMilliseconds}ms: ${allNilai.length} records');
      
      final allMatakuliah = await _dbHelper.getAllMatakuliah();
      print('   ⏱️  getAllMatakuliah took ${DateTime.now().difference(startTime).inMilliseconds}ms: ${allMatakuliah.length} records');
      
      print('🔍 DEBUG: allNilai count = ${allNilai.length}');
      print('🔍 DEBUG: allMatakuliah count = ${allMatakuliah.length}');
      
      // Create map untuk quick lookup
      final mkMap = <int, Matakuliah>{};
      for (final mk in allMatakuliah) {
        if (mk.id != null) {
          mkMap[mk.id!] = mk;
        }
      }
      
      // 🎯 HANYA tampilkan matakuliah yang punya nilai
      final groupedData = <String, Map<String, dynamic>>{};
      for (final nilai in allNilai) {
        final key = '${nilai.matakuliahId}_${nilai.tahunAjaran}';
        
        // Jika belum ada entry untuk kombinasi ini, buat baru
        if (!groupedData.containsKey(key)) {
          final mk = mkMap[nilai.matakuliahId];
          if (mk != null) {
            groupedData[key] = {
              'id': key,
              'matakuliah_id': nilai.matakuliahId,
              'matakuliah_nama': mk.nama,
              'matakuliah_kode': mk.kode,
              'tahun_ajaran': nilai.tahunAjaran,
              'has_nilai': true,
            };
            print('  ✅ Added: ${mk.kode} ${mk.nama} (${nilai.tahunAjaran})');
          }
        }
      }
      
      print('🔍 DEBUG: Total unique mk with nilai = ${groupedData.length}');
      
      // Convert to list dan sort by tahun_ajaran (descending) then nama
      final result = groupedData.values.toList();
      result.sort((a, b) {
        final tahunCompare = (b['tahun_ajaran'] as int).compareTo(a['tahun_ajaran'] as int);
        if (tahunCompare != 0) return tahunCompare;
        return (a['matakuliah_nama'] as String).compareTo(b['matakuliah_nama'] as String);
      });
      
      print('✅ [_loadMatakuliahWithNilaiInternal] COMPLETE in ${DateTime.now().difference(startTime).inSeconds}s: ${result.length} matakuliah');
      for (final item in result) {
        print('  - ${item['matakuliah_kode']} ${item['matakuliah_nama']} (${item['tahun_ajaran']})');
      }
      
      return result;
    } catch (e) {
      print('❌ Error loading matakuliah: $e');
      return [];
    }
  }

  void _showNoNilaiDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        icon: Icon(
          Icons.info_outline,
          size: 64,
          color: Colors.orange[700],
        ),
        title: const Text(
          'Belum Ada Nilai',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tidak ada data nilai dalam sistem.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Langkah selanjutnya:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[900],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '1. Lakukan import nilai terlebih dahulu\n'
                    '2. Gunakan menu "Import → Import Nilai"\n'
                    '3. Pilih file Excel/CSV dengan data nilai\n'
                    '4. Kembali ke halaman ini',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[900],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              print('🔄 [Coba Lagi] User clicked retry - resetting and reloading...');
              // Reset state dan reload data
              setState(() {
                _dataLoadTimeout = false;
                _noDataDialogShown = false;
                _matakuliahWithNilaiList = null;
                print('🔄 [Coba Lagi] Flags reset, calling _loadData()...');
              });
              _loadData();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk menghitung CPL dari tabel
  Future<void> _calculateCPLFromTable(int matakuliahId, int tahunAjaran) async {
    final mkKey = '${matakuliahId}_$tahunAjaran';
    
    // 🎯 PREVENT RACE CONDITION: Check jika sedang dihitung
    if (_calculatingMatakuliahSet.contains(mkKey)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏳ Perhitungan sedang berlangsung untuk matakuliah ini'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    // Mark bahwa matakuliah ini sedang dihitung
    setState(() {
      _calculatingMatakuliahSet.add(mkKey);
    });
    
    _showCalculatingDialog();

    try {
      // Perhitungan batch untuk semua mahasiswa di matakuliah ini
      final results = await _obeHelper.calculateBatchOBEResultsForMatakuliah(
        matakuliahId: matakuliahId,
        tahunAjaran: tahunAjaran,
      );

      if (!mounted) {
        // 🎯 Ensure cleanup jika widget disposed
        _calculatingMatakuliahSet.remove(mkKey);
        return;
      }
      
      // ✅ Tutup dialog dengan safety check
      if (_dialogOpen && mounted) {
        try {
          Navigator.pop(context);
          _dialogOpen = false;
        } catch (e) {
          print('⚠️ Warning: Gagal menutup dialog: $e');
          _dialogOpen = false;
        }
      }
      
      // 🎯 PERMANENT: Simpan hasil perhitungan ke database (bukan hanya flag)
      // Try-catch untuk handle jika table tidak exist (database migration issue)
      try {
        print('💾 Attempting to save ${results.length} calculation results to database...');
        await _dbHelper.saveCPLCalculationResults(results);
        print('✅ Successfully saved calculation results to cpl_hasil_perhitungan');
      } catch (saveError) {
        print('❌ CRITICAL ERROR: Tidak bisa simpan hasil ke database!');
        print('❌ Error detail: $saveError');
        print('❌ Stack trace: ${StackTrace.current}');
        print('⚠️ Hasil perhitungan masih ditampilkan, tapi tidak persisten');
        // Continue - jangan block UI hanya karena save gagal
      }
      
      // 🎯 Save calculation status to database (flag tracking)
      try {
        await _dbHelper.recordCPLCalculation(matakuliahId, tahunAjaran);
      } catch (trackError) {
        print('⚠️ Warning: Tidak bisa update tracking: $trackError');
      }
      
      // Cari nama matakuliah dari list
      final matakuliahData = await _matakuliahWithNilaiList;
      String mkNama = 'Mata Kuliah';
      if (matakuliahData != null) {
        for (final item in matakuliahData) {
          if (item['matakuliah_id'] == matakuliahId && item['tahun_ajaran'] == tahunAjaran) {
            mkNama = item['matakuliah_nama'] as String;
            break;
          }
        }
      }
      
      if (!mounted) {
        _calculatingMatakuliahSet.remove(mkKey);
        return;
      }
      
      // Reset animation ke awal sebelum menampilkan hasil
      _fadeAnimationController.reset();
      
      setState(() {
        _batchCalculationResults = results;
        _calculationResultsByMK[mkKey] = results; // 🎯 Simpan per matakuliah
        _currentDisplayedMKKey = mkKey;
        _currentMatakuliahNama = mkNama;
        _currentTahunAjaran = tahunAjaran;
        _calculationResult = null;
        // 🎯 Track yang sudah dihitung
        _calculatedMatakuliahSet.add(mkKey);
        _calculatingMatakuliahSet.remove(mkKey); // ✅ Clear calculating flag
      });

      // Play fade animation setelah state update
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        await _fadeAnimationController.forward();
      }

      // Scroll ke hasil
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && _resultsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultsKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

      if (results.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada mahasiswa dengan nilai untuk perhitungan'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Perhitungan selesai untuk ${results.length} mahasiswa'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // 🎯 IMPROVE: Better error handling dengan mandatory cleanup
      print('❌ Error dalam _calculateCPLFromTable: $e');
      
      // Pastikan cleanup di semua kondisi
      _calculatingMatakuliahSet.remove(mkKey);
      
      if (!mounted) return;
      
      // Tutup dialog jika ada dengan try-catch
      if (_dialogOpen) {
        try {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          _dialogOpen = false;
        } catch (navError) {
          print('⚠️ Warning: Gagal menutup dialog pada error: $navError');
          _dialogOpen = false;
        }
      }
      
      // Show error snackbar dengan detail yang lebih comprehensive
      if (mounted) {
        String errorMsg = e.toString();
        String actionHint = '';
        
        // Provide helpful error messages berdasarkan error type
        if (errorMsg.contains('no such table') || errorMsg.contains('cpl_hasil_perhitungan')) {
          actionHint = '\n\n💡 Solusi: Restart aplikasi atau reinstall app untuk update database';
        } else if (errorMsg.contains('unique constraint')) {
          actionHint = '\n\n💡 Solusi: Data ini mungkin sudah diperhitungkan';
        } else if (errorMsg.contains('database is locked')) {
          actionHint = '\n\n💡 Solusi: Tunggu sebentar dan coba lagi';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error: $errorMsg$actionHint',
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      // Update state untuk clear calculating flag
      if (mounted) {
        setState(() {
          // _isCalculating cleared in finally block
        });
      }
    } finally {
      // 🎯 GUARANTEE: Clear calculating flag di semua kondisi
      if (mounted) {
        setState(() {
          _calculatingMatakuliahSet.remove(mkKey);
        });
      }
    }
  }

  
  void _showCalculatingDialog() {
    _dialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated spinner
                AnimatedBuilder(
                  animation: _loadingAnimationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _loadingAnimationController.value * 2 * 3.14159,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border(
                            top: BorderSide(
                              color: AppColors.primary,
                              width: 4,
                            ),
                            right: BorderSide(
                              color: AppColors.primary,
                              width: 4,
                            ),
                            bottom: BorderSide(
                              color: Colors.grey[300]!,
                              width: 4,
                            ),
                            left: BorderSide(
                              color: Colors.grey[300]!,
                              width: 4,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Sedang menghitung CPL...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Mohon tunggu sebentar',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Mark dialog as closed when it's dismissed
      _dialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 Lazy load data saat pertama kali widget ditampilkan
    // ⚠️ PENTING: Hanya register callback sekali untuk prevent looping!
    if (!_dataLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _initializeDataIfNeeded();
        }
      });
    }
    
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hitung CPL (Capaian Pembelajaran Lulusan)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // 🎯 Tabel Mata Kuliah dengan Nilai - dengan error handling
          if (_dataLoaded)
            _buildMatakuliahNilaiTable()
          else
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          
          // 🎯 Hasil Perhitungan - dengan padding dan styling yang lebih baik
          if (_calculationResult != null || _batchCalculationResults != null)
            Container(
              key: _resultsKey,
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_calculationResult != null && _calculationResult!.hasData)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildCalculationResults(),
                    )
                  else if (_batchCalculationResults != null && _batchCalculationResults!.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: _buildBatchCalculationResults(),
                    )
                  else if (_calculationResult != null || _batchCalculationResults != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'Tidak ada data untuk ditampilkan',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 🎯 Build button dengan indicator status perhitungan
  Widget _buildCalculateButton(int matakuliahId, int tahunAjaran) {
    final calculationKey = '${matakuliahId}_$tahunAjaran';
    final isCalculatingThisMK = _calculatingMatakuliahSet.contains(calculationKey);
    final isCalculating = isCalculatingThisMK && _batchCalculationResults == null;
    final isCalculated = _calculatedMatakuliahSet.contains(calculationKey);

    // Status 1: Sedang menghitung
    if (isCalculating || isCalculatingThisMK) {
      return Center(
        child: Tooltip(
          message: 'Perhitungan sedang berjalan...',
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.secondary,
              ),
            ),
          ),
        ),
      );
    }

    // Status 2: Sudah dihitung - tampilkan checkmark button dengan Lihat Hasil dan Clear
    if (isCalculated) {
      final mkKey = '${matakuliahId}_$tahunAjaran';
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            // 🎯 Hitung ulang button
            ElevatedButton.icon(
              onPressed: isCalculatingThisMK 
                  ? null 
                  : () => _calculateCPLFromTable(matakuliahId, tahunAjaran),
              icon: const Icon(Icons.check_circle, size: 14),
              label: const Text('Hitung', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            // 🎯 Lihat hasil button
            ElevatedButton.icon(
              onPressed: () => _showSavedResults(matakuliahId, tahunAjaran),
              icon: const Icon(Icons.visibility, size: 14),
              label: const Text('Lihat', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            // 🎯 Tombol clear per-matakuliah
            Tooltip(
              message: 'Hapus hasil perhitungan',
              child: ElevatedButton.icon(
                onPressed: isCalculatingThisMK
                    ? null
                    : () async {
                  // Confirm sebelum hapus
                  final shouldDelete = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Hapus Hasil Perhitungan?'),
                      content: const Text('Hasil perhitungan CPL untuk matakuliah ini akan dihapus dari database. Lanjutkan?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  
                  if (shouldDelete != true) return;
                  
                  try {
                    // 🎯 HAPUS dari database (permanent storage)
                    await _dbHelper.deleteCPLCalculationResults(matakuliahId, tahunAjaran);
                    
                    // 🎯 HAPUS dari cache memory
                    setState(() {
                      _calculationResultsByMK.remove(mkKey);
                      if (_currentDisplayedMKKey == mkKey) {
                        _batchCalculationResults = null;
                        _currentDisplayedMKKey = null;
                        _currentMatakuliahNama = '';
                        _currentTahunAjaran = 0;
                      }
                      _calculatedMatakuliahSet.remove(mkKey);
                      // 🎯 GUARANTEE: Clear calculating flag jika ada
                      _calculatingMatakuliahSet.remove(mkKey);
                    });
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Hasil perhitungan dihapus dari database'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.close, size: 14),
                label: const Text('Hapus', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  backgroundColor: Colors.orange[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Status 3: Belum dihitung - button normal
    return ElevatedButton.icon(
      onPressed: isCalculatingThisMK
          ? null
          : () => _calculateCPLFromTable(matakuliahId, tahunAjaran),
      icon: const Icon(Icons.calculate, size: 16),
      label: const Text('Hitung CPL'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMatakuliahNilaiTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daftar Mata Kuliah dengan Data Nilai',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Row(
              children: [
                // 🔍 Show data count badge
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _matakuliahWithNilaiList ?? Future.value([]),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        '$count matakuliah',
                        style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                      ),
                    );
                  },
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _noDataDialogShown = false;
                      _matakuliahWithNilaiList = _loadMatakuliahWithNilai();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Data Mata Kuliah',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _matakuliahWithNilaiList ?? Future.value([]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red[900]),
                ),
              );
            }

            final data = snapshot.data ?? [];
            
            // 🔍 DEBUG: Block ini untuk membantu debugging
            print('📊 FutureBuilder snapshot received: ${data.length} items');
            for (final item in data) {
              print('   └─ ${item['matakuliah_kode']} ${item['matakuliah_nama']} (${item['tahun_ajaran']})');
            }
            
            if (data.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[900]),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Belum ada data nilai. Silakan import nilai terlebih dahulu melalui menu "Import Nilai".',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // 🔍 DEBUG: Info badge di tabel
            print('✅ Will render ${data.length} rows');

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(AppRadius.md),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            'No',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: Text(
                            'Nama Mata Kuliah',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'Tahun Ajaran',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: Text(
                            'Aksi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  // Data rows - SingleChildScrollView for horizontal scroll if needed
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(
                          data.length,
                          (index) {
                            final item = data[index];
                            final mkId = item['matakuliah_id'] as int;
                            final tahunAjaran = item['tahun_ajaran'] as int;
                            final mkNama = item['matakuliah_nama'] as String;
                            final mkKode = item['matakuliah_kode'] as String;
                            
                            print('🎯 Building row $index: $mkKode - $mkNama ($tahunAjaran)');

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 50,
                                        child: Text('${index + 1}'),
                                      ),
                                      SizedBox(
                                        width: 250,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              mkNama,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              mkKode,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text(tahunAjaran.toString()),
                                      ),
                                      SizedBox(
                                        width: 250,
                                        child: _buildCalculateButton(mkId, tahunAjaran),
                                      ),
                                    ],
                                  ),
                                ),
                                if (index < data.length - 1)
                                  Divider(height: 1),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBatchCalculationResults() {
    final results = _batchCalculationResults!;
    
    // 🎯 Build label dengan nama matakuliah dan tahun ajaran
    String mkLabel = '';
    if (_currentDisplayedMKKey != null) {
      mkLabel = ' - $_currentMatakuliahNama - $_currentTahunAjaran';
    }
    
    // 🎯 Hitung rata-rata keseluruhan
    double avgCPMK = 0;
    double avgCPL = 0;
    int cpmkCount = 0;
    int cplCount = 0;
    
    for (final result in results) {
      for (final value in result.cpmkValues.values) {
        avgCPMK += value;
        cpmkCount++;
      }
      for (final value in result.cplValues.values) {
        avgCPL += value;
        cplCount++;
      }
    }
    
    if (cpmkCount > 0) avgCPMK /= cpmkCount;
    if (cplCount > 0) avgCPL /= cplCount;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hasil Perhitungan$mkLabel',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '${results.length} mahasiswa',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        
        // 🎯 Summary Cards
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27AE60).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.school, color: Color(0xFF27AE60), size: 32),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        avgCPMK.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Rata-rata CPMK',
                        style: TextStyle(fontSize: 12, color: AppColors.subtleText),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8E44AD).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.flag, color: Color(0xFF8E44AD), size: 32),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        avgCPL.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E44AD),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Text(
                        'Rata-rata CPL',
                        style: TextStyle(fontSize: 12, color: AppColors.subtleText),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        
        // 🎯 Tabel CPMK dan CPL Gabungan
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.blue[300]!,
                    ),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.md),
                    topRight: Radius.circular(AppRadius.md),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, color: Colors.blue, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      'Tabel Nilai CPMK & CPL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  minHeight: 200,
                  maxHeight: 800,
                ),
                child: _buildCombinedCPMKCPLTable(results),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🎯 Tabel Gabungan CPMK dan CPL
  Widget _buildCombinedCPMKCPLTable(List<OBECalculationResult> results) {
    return FutureBuilder<List<dynamic>>(
      future: _dbHelper.getAllMahasiswa(),
      builder: (context, mahasiswaSnapshot) {
        if (mahasiswaSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (mahasiswaSnapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Text(
              'Error memuat data mahasiswa: ${mahasiswaSnapshot.error}',
              style: TextStyle(color: Colors.red[900]),
            ),
          );
        }

        final mahasiswaMap = <int, String>{};
        if (mahasiswaSnapshot.hasData) {
          for (final mhs in mahasiswaSnapshot.data ?? []) {
            mahasiswaMap[mhs.id] = '${mhs.nim} - ${mhs.nama}';
          }
        }

        // Extract unique Sub-CPMK, CPMK dan CPL IDs
        final subCpmkIds = <int>{};
        final cpmkIds = <int>{};
        final cplIds = <int>{};
        for (final result in results) {
          subCpmkIds.addAll(result.subCPMKValues.keys);
          cpmkIds.addAll(result.cPMKValues.keys);
          cplIds.addAll(result.cPLValues.keys);
        }
        final sortedSubCpmkIds = subCpmkIds.toList()..sort();
        final sortedCpmkIds = cpmkIds.toList()..sort();
        final sortedCplIds = cplIds.toList()..sort();
        
        // Create mapping dari Sub-CPMK ID ke index (1-based)
        final subCpmkIndexMap = <int, int>{};
        for (int i = 0; i < sortedSubCpmkIds.length; i++) {
          subCpmkIndexMap[sortedSubCpmkIds[i]] = i + 1;
        }

        // Build columns
        final columns = <DataColumn>[
          const DataColumn(
            label: SizedBox(
              width: 30,
              child: Text('No', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            numeric: true,
          ),
          const DataColumn(
            label: SizedBox(
              width: 100,
              child: Text('NIM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const DataColumn(
            label: SizedBox(
              width: 150,
              child: Text('Nama Mahasiswa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ];

        // Add Sub-CPMK columns (using 1-based index)
        for (final subCpmkId in sortedSubCpmkIds) {
          final index = subCpmkIndexMap[subCpmkId] ?? 0;
          columns.add(
            DataColumn(
              label: SizedBox(
                width: 65,
                child: Center(
                  child: Text(
                    'Sub.${index}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF3498DB)),
                  ),
                ),
              ),
            ),
          );
        }

        // Add CPMK columns
        for (final cpmkId in sortedCpmkIds) {
          columns.add(
            DataColumn(
              label: SizedBox(
                width: 75,
                child: Center(
                  child: Text(
                    'CPMK${cpmkId}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF27AE60)),
                  ),
                ),
              ),
            ),
          );
        }

        // Add CPL columns
        for (final cplId in sortedCplIds) {
          columns.add(
            DataColumn(
              label: SizedBox(
                width: 75,
                child: Center(
                  child: Text(
                    'CPL$cplId',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8E44AD)),
                  ),
                ),
              ),
            ),
          );
        }

        // Build rows
        final rows = List.generate(
          results.length,
          (index) {
            final result = results[index];
            final namaMahasiswa = mahasiswaMap[result.mahasiswaId] ?? 'Mahasiswa ${result.mahasiswaId}';
            final parts = namaMahasiswa.split(' - ');
            final nim = parts.isNotEmpty ? parts[0] : '';
            final nama = parts.length > 1 ? parts[1] : namaMahasiswa;

            final cells = <DataCell>[
              DataCell(
                SizedBox(
                  width: 30,
                  child: Text('${index + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 100,
                  child: Text(nim, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 150,
                  child: Text(
                    nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ];

            // Add Sub-CPMK values
            for (final subCpmkId in sortedSubCpmkIds) {
              final value = result.subCPMKValues[subCpmkId];  // ← Use legacy getter subCPMKValues
              cells.add(
                DataCell(
                  SizedBox(
                    width: 65,
                    child: Center(
                      child: Text(
                        value != null ? value.toStringAsFixed(2) : '-',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3498DB),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }

            // Add CPMK values
            for (final cpmkId in sortedCpmkIds) {
              final value = result.cPMKValues[cpmkId];  // ← Use legacy getter cPMKValues
              cells.add(
                DataCell(
                  SizedBox(
                    width: 75,
                    child: Center(
                      child: Text(
                        value != null ? value.toStringAsFixed(2) : '-',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF27AE60),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }

            // Add CPL values
            for (final cplId in sortedCplIds) {
              final value = result.cPLValues[cplId];  // ← Use legacy getter cPLValues
              cells.add(
                DataCell(
                  SizedBox(
                    width: 75,
                    child: Center(
                      child: Text(
                        value != null ? value.toStringAsFixed(2) : '-',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8E44AD),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }

            return DataRow(cells: cells);
          },
        );

        // Check if results is empty
        if (results.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Text(
                'Tidak ada data untuk ditampilkan',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        // Hitung total width yang dibutuhkan
        final totalWidth = (280.0) + // No, NIM, Nama columns
            (sortedSubCpmkIds.length * 80.0) + // Sub-CPMK columns
            (sortedCpmkIds.length * 90.0) + // CPMK columns
            (sortedCplIds.length * 90.0) + // CPL columns
            20; // padding

        // Tabel dengan scroll horizontal dan vertikal
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: DataTable(
                columnSpacing: 10,
                horizontalMargin: 8,
                dataRowHeight: 50,
                headingRowHeight: 56,
                columns: columns,
                rows: rows,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalculationResults() {
    // 🎯 DEBUG: Log data structure untuk memastikan data tersedia
    print('🔍 [_buildCalculationResults] START');
    print('   _calculationResult != null: ${_calculationResult != null}');
    
    if (_calculationResult != null) {
      print('   _calculationResult.hasData: ${_calculationResult!.hasData}');
      print('   subCPMKValues.length: ${_calculationResult!.subCPMKValues.length}');
      print('   cpmkValues.length: ${_calculationResult!.cpmkValues.length}');
      print('   cplValues.length: ${_calculationResult!.cplValues.length}');
      print('   averageSubCPMKNilai: ${_calculationResult!.averageSubCPMKNilai}');
      print('   averageCPMKNilai: ${_calculationResult!.averageCPMKNilai}');
      print('   averageCPLNilai: ${_calculationResult!.averageCPLNilai}');
      
      // Log isi setiap map
      for (final entry in _calculationResult!.subCPMKValues.entries) {
        print('   SubCPMK.${entry.key}: ${entry.value}');
      }
      for (final entry in _calculationResult!.cpmkValues.entries) {
        print('   CPMK.${entry.key}: ${entry.value}');
      }
      for (final entry in _calculationResult!.cplValues.entries) {
        print('   CPL.${entry.key}: ${entry.value}');
      }
    }
    
    // 🎯 Check apakah ada data sama sekali
    final hasSubCPMKData = _calculationResult?.subCPMKValues.isNotEmpty ?? false;
    final hasCPMKData = _calculationResult?.cpmkValues.isNotEmpty ?? false;
    final hasCPLData = _calculationResult?.cplValues.isNotEmpty ?? false;
    final hasAnyData = hasSubCPMKData || hasCPMKData || hasCPLData;
    
    print('   hasSubCPMKData: $hasSubCPMKData');
    print('   hasCPMKData: $hasCPMKData');
    print('   hasCPLData: $hasCPLData');
    print('   hasAnyData: $hasAnyData');
    print('✅ [_buildCalculationResults] END\n');
    
    // 🎯 TIDAK bungkus dengan SingleChildScrollView - parent Column sudah scrollable
    // GUNAKAN Column biasa saja dengan mainAxisSize.min
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          const Text(
            'Hasil Perhitungan OBE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Ringkasan Nilai
          _buildSummaryCard(),
          const SizedBox(height: AppSpacing.lg),
          
          // 🎯 Sub-CPMK Nilai
          if (hasSubCPMKData)
            _buildValueTable(
              title: 'Nilai Sub-CPMK',
              icon: Icons.assessment,
              color: const Color(0xFF3498DB),
              values: _calculationResult!.subCPMKValues,
              labelPrefix: 'Sub-CPMK',
            ),
          if (hasSubCPMKData)
            const SizedBox(height: AppSpacing.lg),
          
          // 🎯 CPMK Nilai
          if (hasCPMKData)
            _buildValueTable(
              title: 'Nilai CPMK',
              icon: Icons.school,
              color: const Color(0xFF27AE60),
              values: _calculationResult!.cPMKValues,
              labelPrefix: 'CPMK',
            ),
          if (hasCPMKData)
            const SizedBox(height: AppSpacing.lg),
          
          // 🎯 CPL Nilai
          if (hasCPLData)
            _buildValueTable(
              title: 'Nilai CPL',
              icon: Icons.flag,
              color: const Color(0xFF8E44AD),
              values: _calculationResult!.cPLValues,
              labelPrefix: 'CPL',
            ),
          
          // 🎯 Fallback jika tidak ada data nilai
          if (!hasAnyData)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.orange[700],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Tidak Ada Data Nilai',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[900],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Data Sub-CPMK, CPMK, dan CPL tidak ditemukan dalam hasil perhitungan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '💡 Pastikan RPS dan nilai sudah diupload dengan benar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.orange[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
  }

  Widget _buildSummaryCard() {
    // 🎯 DEBUG log summary values
    print('📊 [_buildSummaryCard] Summary Values:');
    print('   averageSubCPMKNilai: ${_calculationResult?.averageSubCPMKNilai}');
    print('   averageCPMKNilai: ${_calculationResult?.averageCPMKNilai}');
    print('   averageCPLNilai: ${_calculationResult?.averageCPLNilai}');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎯 Wrap Row dengan LayoutBuilder untuk responsive design tanpa nested scroll
            LayoutBuilder(
              builder: (context, constraints) {
                // Jika space cukup, gunakan Row normal
                // Jika tidak, gunakan Column
                final itemWidth = constraints.maxWidth / 3;
                final needsStack = itemWidth < 100;
                
                if (needsStack) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSummaryItem(
                        label: 'Rata-rata Sub-CPMK',
                        value: _calculationResult?.averageSubCPMKNilai.toStringAsFixed(2) ?? '0.00',
                        color: const Color(0xFF3498DB),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildSummaryItem(
                        label: 'Rata-rata CPMK',
                        value: _calculationResult?.averageCPMKNilai.toStringAsFixed(2) ?? '0.00',
                        color: const Color(0xFF27AE60),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildSummaryItem(
                        label: 'Rata-rata CPL',
                        value: _calculationResult?.averageCPLNilai.toStringAsFixed(2) ?? '0.00',
                        color: const Color(0xFF8E44AD),
                      ),
                    ],
                  );
                } else {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        label: 'Rata-rata Sub-CPMK',
                        value: _calculationResult?.averageSubCPMKNilai.toStringAsFixed(2) ?? '0.00',
                        color: const Color(0xFF3498DB),
                      ),
                      _buildSummaryItem(
                        label: 'Rata-rata CPMK',
                        value: _calculationResult?.averageCPMKNilai.toStringAsFixed(2) ?? '0.00',
                        color: const Color(0xFF27AE60),
                      ),
                      _buildSummaryItem(
                        label: 'Rata-rata CPL',
                        value: _calculationResult?.averageCPLNilai.toStringAsFixed(2) ?? '0.00',
                        color: const Color(0xFF8E44AD),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.subtleText,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildValueTable({
    required String title,
    required IconData icon,
    required Color color,
    required Map<int, double> values,
    String? labelPrefix,
  }) {
    // 🎯 DEBUG log
    print('🎯 [_buildValueTable] $title - Items: ${values.length}');
    
    // 🎯 Pastikan values tidak kosong
    if (values.isEmpty) {
      print('⚠️ [_buildValueTable] $title is empty!');
      return Card(
        elevation: 1,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$title - Tidak ada data',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: color.withValues(alpha: 0.3)),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${values.length} item',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 🎯 Gunakan ListView.separated dengan shrinkWrap untuk bounded constraints
          // JANGAN gunakan SingleChildScrollView nested - itu menyebabkan infinite height
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: values.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Colors.grey[200],
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
            ),
            itemBuilder: (context, index) {
              final entry = values.entries.elementAt(index);
              final id = entry.key;
              final nilai = entry.value;
              final name = labelPrefix != null ? '$labelPrefix.$id' : '$title ID $id';
              
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        nilai.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

}

class _EmbeddedExportContent extends StatelessWidget {
  final BuildContext context;

  const _EmbeddedExportContent({required this.context});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _buildExportCard(
                icon: Icons.description,
                label: 'Export RPS ke PDF',
                subtitle: 'Ekspor data RPS semua mata kuliah',
                color: const Color(0xFF2980B9),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _RPSExportScreen(
                        dbHelper: DatabaseHelper(),
                      ),
                    ),
                  );
                },
              ),
              _buildExportCard(
                icon: Icons.assessment,
                label: 'Export CPL & CPMK',
                subtitle: 'Laporan nilai CPL dan CPMK per mata kuliah',
                color: const Color(0xFF8E44AD),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CPLCPMKExportScreen(
                        dbHelper: DatabaseHelper(),
                      ),
                    ),
                  );
                },
              ),
              _buildExportCard(
                icon: Icons.file_download,
                label: 'Export Data Sistem',
                subtitle: 'Ekspor seluruh data sistem',
                color: const Color(0xFF27AE60),
                onTap: () => Navigator.pushNamed(context, '/export_data'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 180,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0.65),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RPSExportScreen extends StatefulWidget {
  final DatabaseHelper dbHelper;

  const _RPSExportScreen({required this.dbHelper});

  @override
  State<_RPSExportScreen> createState() => _RPSExportScreenState();
}

class _RPSExportScreenState extends State<_RPSExportScreen> {
  late Future<List<Matakuliah>> _matakuliahFuture;

  @override
  void initState() {
    super.initState();
    _matakuliahFuture = widget.dbHelper.getAllMatakuliah();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export RPS ke PDF'),
        backgroundColor: const Color(0xFF2980B9),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: FutureBuilder<List<Matakuliah>>(
          future: _matakuliahFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            final matakuliahList = snapshot.data ?? [];
            if (matakuliahList.isEmpty) {
              return const Center(
                child: Text('Belum ada mata kuliah'),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Mata Kuliah untuk Export RPS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.file_download),
                          label: const Text('Export Semua RPS ke PDF'),
                          onPressed: () async {
                            await _exportAllRPStoPDF();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27AE60),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Atau pilih mata kuliah tertentu:',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.subtleText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView.builder(
                    itemCount: matakuliahList.length,
                    itemBuilder: (context, index) {
                      final mk = matakuliahList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ListTile(
                          leading: Container(
                            width: 75,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2980B9).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Center(
                              child: Text(
                                mk.kode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Color(0xFF2980B9),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          title: Text(mk.nama),
                          subtitle: Text('${mk.sks} SKS • Semester ${mk.semester}'),
                          trailing: ElevatedButton.icon(
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Export'),
                            onPressed: () async {
                              await _exportSingleRPStoPDF(mk);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2980B9),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _exportAllRPStoPDF() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sedang membuat PDF...')),
      );

      final matakuliahList = await widget.dbHelper.getAllMatakuliah();
      
      // Collect all RPS data
      final rpsDataMap = <String, List<RPSDetail>>{};
      final subCpmkDataMap = <String, List<SubCPMK>>{};
      final cpmkDataMap = <String, List<CPMK>>{};
      final cplDataMap = <String, List<CPLMaster>>{};
      final rpsDetailSubCpmkBobotMap = <String, Map<int, Map<int, double>>>{};
      
      for (final mk in matakuliahList) {
        final rpsDetails = await widget.dbHelper.getRPSDetailByMatakuliah(mk.id!);
        rpsDataMap[mk.kode] = rpsDetails;
        
        // Load SubCPMK data for this matakuliah
        final subCpmks = await widget.dbHelper.getSubCPMKByMatakuliah(mk.id!);
        subCpmkDataMap[mk.kode] = subCpmks;
        
        // Load bobot per SubCPMK untuk setiap RPS Detail
        final rpsDetailSubCpmkBobots = <int, Map<int, double>>{};
        for (final rps in rpsDetails) {
          if (rps.id != null) {
            try {
              final bobotList = await widget.dbHelper.getRPSDetailSubCPMKBobot(rps.id!);
              if (bobotList.isNotEmpty) {
                rpsDetailSubCpmkBobots[rps.id!] = {
                  for (var item in bobotList)
                    item['sub_cpmk_id'] as int: (item['bobot'] as num).toDouble()
                };
              }
            } catch (e) {
              // Error loading bobot per SubCPMK untuk RPS Detail
            }
          }
        }
        rpsDetailSubCpmkBobotMap[mk.kode] = rpsDetailSubCpmkBobots;
        
        // Extract unique CPMK IDs from RPS details
        final cpmkIdSet = <int>{};
        for (final rps in rpsDetails) {
          if (rps.cpmkIds != null) {
            cpmkIdSet.addAll(rps.cpmkIds!);
          }
        }
        
        // Get only CPMK that are used in RPS
        List<CPMK> cpmks = [];
        if (cpmkIdSet.isNotEmpty) {
          final allProgramCpmks = await widget.dbHelper.getCPMKByMatakuliah(0);
          cpmks = allProgramCpmks.where((c) => cpmkIdSet.contains(c.id)).toList();
        }
        cpmkDataMap[mk.kode] = cpmks;
        
        // Extract unique CPL IDs from RPS details
        final cplIdSet = <int>{};
        for (final rps in rpsDetails) {
          if (rps.cplIds != null) {
            cplIdSet.addAll(rps.cplIds!);
          }
        }
        
        // Get only CPL that are used in RPS
        List<CPLMaster> cpls = [];
        if (cplIdSet.isNotEmpty) {
          final allCPLs = await widget.dbHelper.getAllCPLMaster();
          cpls = allCPLs.where((c) => cplIdSet.contains(c.id)).toList();
        }
        cplDataMap[mk.kode] = cpls;
      }

      // Create PDF
      final pdfFile = await RPSPDFGenerator.generateAllRPSPDF(
        matakuliahList,
        rpsDataMap,
        subCpmkDataMap,
        cpmkDataMap,
        cplDataMap,
        rpsDetailSubCpmkBobotMap,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF berhasil dibuat'),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () async {
                try {
                  await RPSPDFGenerator.openPDF(pdfFile);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error membuka PDF: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportSingleRPStoPDF(Matakuliah mk) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sedang membuat PDF...')),
      );

      final rpsDetails = await widget.dbHelper.getRPSDetailByMatakuliah(mk.id!);
      
      // Load bobot per SubCPMK untuk setiap RPS Detail
      final rpsDetailSubCpmkBobots = <int, Map<int, double>>{};
      for (final rps in rpsDetails) {
        if (rps.id != null) {
          try {
            final bobotList = await widget.dbHelper.getRPSDetailSubCPMKBobot(rps.id!);
            if (bobotList.isNotEmpty) {
              rpsDetailSubCpmkBobots[rps.id!] = {
                for (var item in bobotList)
                  item['sub_cpmk_id'] as int: (item['bobot'] as num).toDouble()
              };
            }
          } catch (e) {
            // Error loading bobot per SubCPMK untuk RPS Detail
          }
        }
      }
      
      // Extract unique CPMK IDs from RPS details
      final cpmkIdSet = <int>{};
      for (final rps in rpsDetails) {
        if (rps.cpmkIds != null) {
          cpmkIdSet.addAll(rps.cpmkIds!);
        }
      }
      
      // Get only CPMK that are used in RPS
      List<CPMK> cpmks = [];
      if (cpmkIdSet.isNotEmpty) {
        final allProgramCpmks = await widget.dbHelper.getCPMKByMatakuliah(0);
        cpmks = allProgramCpmks.where((c) => cpmkIdSet.contains(c.id)).toList();
      }
      
      // Extract unique CPL IDs from RPS details
      final cplIdSet = <int>{};
      for (final rps in rpsDetails) {
        if (rps.cplIds != null) {
          cplIdSet.addAll(rps.cplIds!);
        }
      }
      
      // Get only CPL that are used in RPS
      List<CPLMaster> cpls = [];
      if (cplIdSet.isNotEmpty) {
        final allCPLs = await widget.dbHelper.getAllCPLMaster();
        cpls = allCPLs.where((c) => cplIdSet.contains(c.id)).toList();
      }
      
      final subCpmks = await widget.dbHelper.getSubCPMKByMatakuliah(mk.id!);
      
      final pdfFile = await RPSPDFGenerator.generateSingleRPSPDF(
        mk,
        rpsDetails,
        cpmks,
        cpls,
        subCpmks,
        rpsDetailSubCpmkBobots,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF berhasil dibuat'),
            action: SnackBarAction(
              label: 'Buka',
              onPressed: () async {
                try {
                  await RPSPDFGenerator.openPDF(pdfFile);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error membuka PDF: $e')),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _EmbeddedImportContent extends StatelessWidget {
  final BuildContext context;
  final VoidCallback onMahasiswaImport;
  final VoidCallback onMatakuliahImport;

  const _EmbeddedImportContent({
    required this.context,
    required this.onMahasiswaImport,
    required this.onMatakuliahImport,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Import Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Import Options Grid
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, size: 40, color: const Color(0xFF8E44AD)),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Import Mahasiswa',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Import data mahasiswa dari file Excel/CSV',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: onMahasiswaImport,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Import'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            backgroundColor: const Color(0xFF8E44AD),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book, size: 40, color: const Color(0xFF16A085)),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Import Matakuliah',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Import data matakuliah dari file Excel/CSV',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: onMatakuliahImport,
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Import'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            backgroundColor: const Color(0xFF16A085),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Import CPL dan CPMK
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag, size: 40, color: const Color(0xFF2980B9)),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Import CPL',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Import Capaian Pembelajaran Lulusan',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExcelImportScreen(
                                initialImportType: 'cpl',
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Import'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            backgroundColor: const Color(0xFF2980B9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard, size: 40, color: const Color(0xFFE74C3C)),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Import CPMK',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Import Capaian Program Keahlian Mata Kuliah',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExcelImportScreen(
                                initialImportType: 'cpmk',
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Import'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            backgroundColor: const Color(0xFFE74C3C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Import Sub CPMK dan Nilai Detail
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.layers, size: 40, color: const Color(0xFF9B59B6)),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Import Sub CPMK',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Import Sub Capaian Pembelajaran per Mata Kuliah',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ExcelImportScreen(
                                initialImportType: 'sub_cpmk',
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Import'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            backgroundColor: const Color(0xFF9B59B6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description, size: 40, color: const Color(0xFF27AE60)),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Import RPS',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Import RPS (Rencana Pembelajaran Semester) dari Excel',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/rps_template_import',
                          ),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Import'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            backgroundColor: const Color(0xFF27AE60),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Import Nilai (Batch)
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assessment, size: 40, color: const Color(0xFFF39C12)),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Import Nilai',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Import nilai mahasiswa dari file Excel/CSV masal',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/nilai_batch_import',
                          ),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Import'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            backgroundColor: const Color(0xFFF39C12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.batch_prediction, size: 40, color: const Color(0xFF8E44AD)),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Import Nilai Batch',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Import nilai mahasiswa dari file Excel/CSV dengan validasi',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/nilai_batch_import',
                          ),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Import'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            backgroundColor: const Color(0xFF8E44AD),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Import Info Card
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[900], size: 24),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tips Import Data',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '• Gunakan template Excel yang telah disediakan\n• Format file: .xlsx, .xls, atau .csv\n• Pastikan data lengkap sebelum import\n• Data akan disimpan di Downloads saat download template',
                          style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmbeddedInputRPSContent extends StatelessWidget {
  final BuildContext context;

  const _EmbeddedInputRPSContent({required this.context});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Input RPS (Rencana Pembelajaran Semester)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description, size: 56, color: AppColors.secondary),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Atur rencana pembelajaran semester untuk setiap minggu',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Kelola topik, metode, bobot, CPMK, dan CPL per minggu',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/rps_input'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Mulai Input RPS'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      backgroundColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmbeddedAssessmentOutcomesContent extends StatelessWidget {
  final BuildContext context;

  const _EmbeddedAssessmentOutcomesContent({required this.context});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengukuran Capaian Pembelajaran Mata Kuliah',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, size: 56, color: const Color(0xFF2C3E50)),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Analisis Capaian Pembelajaran per Angkatan',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Lihat tabel mahasiswa per angkatan dan detail CPMK/CPL mereka',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/assessment_outcomes'),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Buka Pengukuran'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      backgroundColor: const Color(0xFF2C3E50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
