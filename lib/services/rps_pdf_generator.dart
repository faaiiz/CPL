import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/matakuliah_model.dart';
import '../models/rps_detail_model.dart';
import '../models/cpmk_model.dart';
import '../models/cpl_master_model.dart';
import '../models/sub_cpmk_model.dart';

// For opening files
import 'package:url_launcher/url_launcher.dart';

class RPSPDFGenerator {
  // Helper method to get Downloads directory
  static Future<Directory> _getDownloadsDirectory() async {
    final downloadsDir = Directory(
      Platform.isWindows
          ? '${Platform.environment['USERPROFILE']}\\Downloads'
          : Platform.isMacOS
              ? '${Platform.environment['HOME']}/Downloads'
              : '${Platform.environment['HOME']}/Downloads',
    );

    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }

    return downloadsDir;
  }

  // Load logo image from assets
  static Future<pw.Image?> _loadLogoImage() async {
    try {
      // Try to load from asset bundle (for Android/iOS)
      try {
        final imageData = await rootBundle.load('assets/undip.jpg');
        return pw.Image(pw.MemoryImage(imageData.buffer.asUint8List()));
      } catch (e) {
        print('Asset bundle load failed, trying file system...');
      }

      // Fallback for desktop: Try to load from project assets directory
      final assetFile = File('assets/undip.jpg');
      if (assetFile.existsSync()) {
        final bytes = await assetFile.readAsBytes();
        return pw.Image(pw.MemoryImage(bytes));
      }

      // Try alternative path
      final altAssetFile = File('${Directory.current.path}/assets/undip.jpg');
      if (altAssetFile.existsSync()) {
        final bytes = await altAssetFile.readAsBytes();
        return pw.Image(pw.MemoryImage(bytes));
      }

      print('⚠ Logo file not found at: assets/undip.jpg');
      return null;
    } catch (e) {
      print('❌ Error loading logo: $e');
      return null;
    }
  }

  static Future<File> generateSingleRPSPDF(
    Matakuliah matakuliah,
    List<RPSDetail> rpsDetails,
    List<CPMK> cpmks,
    List<CPLMaster> cpls,
    List<SubCPMK> subCpmks,
    Map<int, Map<int, double>>? rpsDetailSubCpmkBobots,
  ) async {
    final pdf = pw.Document();

    // Group RPS details by minggu
    final rpsGrouped = <int, RPSDetail>{};
    for (final rps in rpsDetails) {
      rpsGrouped[rps.mingguKe] = rps;
    }

    // Load logo image
    final logoImage = await _loadLogoImage();

    // Page 1: Header, Course Info, and Learning Objectives
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Logo and institutional text aligned at top
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Logo
              if (logoImage != null)
                pw.Container(
                  width: 75,
                  height: 75,
                  child: logoImage,
                ),
              if (logoImage != null) pw.SizedBox(width: 20),
              // Institutional text
              pw.Expanded(
                child: pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Rencana Pembelajaran Semester',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Program Studi Sarjana Fisika',
                        style: const pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Fakultas Sains dan Matematika',
                        style: const pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Universitas Diponegoro',
                        style: const pw.TextStyle(fontSize: 11),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          _buildCourseInfo(matakuliah),
          pw.SizedBox(height: 20),
          _buildLearningObjectives(cpmks, cpls, subCpmks),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    // Page 2: RPS Table
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text(
            'Rincian Pembelajaran Semesteran per Minggu',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildRPSTable(rpsGrouped, subCpmks),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    // Page 3: Assessment Summary Table
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildAssessmentSummaryTable(rpsDetails, cpmks, cpls, subCpmks, rpsDetailSubCpmkBobots ?? {}),
          pw.SizedBox(height: 20),
          _buildFooter(),
        ],
      ),
    );

    // Save PDF to Downloads folder with descriptive filename
    final downloadsDir = await _getDownloadsDirectory();
    // Remove special characters from mata kuliah name for filename safety
    final safeName = matakuliah.nama.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final filename = 'RPS_${matakuliah.kode}_$safeName.pdf';
    final file = File('${downloadsDir.path}${Platform.isWindows ? '\\' : '/'}$filename');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static Future<File> generateAllRPSPDF(
    List<Matakuliah> matakuliahList,
    Map<String, List<RPSDetail>> rpsDataMap,
    Map<String, List<SubCPMK>> subCpmkDataMap,
    Map<String, List<CPMK>> cpmkDataMap,
    Map<String, List<CPLMaster>> cplDataMap,
    Map<String, Map<int, Map<int, double>>> rpsDetailSubCpmkBobotMap,
  ) async {
    final pdf = pw.Document();

    // Load logo image
    final logoImage = await _loadLogoImage();

    // Page 1: Cover with logo
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 140,
                  height: 140,
                  child: logoImage,
                ),
              if (logoImage != null) pw.SizedBox(height: 30),
              pw.Text(
                'Rencana Pembelajaran Semester',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Program Studi Sarjana Fisika',
                style: const pw.TextStyle(fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Fakultas Sains dan Matematika',
                style: const pw.TextStyle(fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'Universitas Diponegoro',
                style: const pw.TextStyle(fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 40),
              pw.Text(
                'KURIKULUM MERDEKA BELAJAR 2020',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
            ],
          ),
        ),
      ),
    );

    // For each matakuliah, create 3 pages (info + rps table + assessment summary)
    for (final mk in matakuliahList) {
      final rpsDetails = rpsDataMap[mk.kode] ?? [];
      final subCpmks = subCpmkDataMap[mk.kode] ?? [];
      final cpmks = cpmkDataMap[mk.kode] ?? [];
      final cpls = cplDataMap[mk.kode] ?? [];
      final rpsDetailSubCpmkBobots = rpsDetailSubCpmkBobotMap[mk.kode] ?? {};
      
      final rpsGrouped = <int, RPSDetail>{};
      for (final rps in rpsDetails) {
        rpsGrouped[rps.mingguKe] = rps;
      }

      // Page: Mata Kuliah Info
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            _buildHeader(mk),
            pw.SizedBox(height: 15),
            _buildCourseInfo(mk),
            pw.SizedBox(height: 20),
            _buildLearningObjectives(cpmks, cpls, subCpmks),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ],
        ),
      );

      // Page: RPS Table
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            pw.Text(
              'Rincian Pembelajaran Semester',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildRPSTableSimple(rpsDetails, subCpmks),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ],
        ),
      );

      // Page: Assessment Summary
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            _buildAssessmentSummaryTable(rpsDetails, cpmks, cpls, subCpmks, rpsDetailSubCpmkBobots),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ],
        ),
      );
    }

    // Save PDF to Downloads folder
    final downloadsDir = await _getDownloadsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'RPS_SEMUA_MATAKULIAH_$timestamp.pdf';
    final file = File('${downloadsDir.path}${Platform.isWindows ? '\\' : '/'}$filename');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildHeader(Matakuliah matakuliah) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RENCANA PEMBELAJARAN SEMESTER (RPS)',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          '${matakuliah.kode} - ${matakuliah.nama}',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCourseInfo(Matakuliah matakuliah) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Kode: ${matakuliah.kode}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Nama: ${matakuliah.nama}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SKS: ${matakuliah.sks}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Semester: ${matakuliah.semester}',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLearningObjectives(
    List<CPMK> cpmks,
    List<CPLMaster> cpls,
    List<SubCPMK> subCpmks,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Capaian Pembelajaran Lulusan (CPL)',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        if (cpls.isEmpty)
          pw.Text(
            'Belum ada CPL',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          )
        else
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: cpls
                .map(
                  (cpl) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(
                      '${cpl.kodeCPL}: ${cpl.deskripsi}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                )
                .toList(),
          ),
        pw.SizedBox(height: 15),
        pw.Text(
          'Capaian Pembelajaran (CPMK)',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        if (cpmks.isEmpty)
          pw.Text(
            'Belum ada CPMK',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          )
        else
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: cpmks
                .map(
                  (cpmk) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(
                      '${cpmk.kodeCPMK}: ${cpmk.deskripsi}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                )
                .toList(),
          ),
        pw.SizedBox(height: 15),
        pw.Text(
          'Sub CPMK',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        if (subCpmks.isEmpty)
          pw.Text(
            'Belum ada Sub CPMK',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          )
        else
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: subCpmks
                .map(
                  (subCpmk) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Text(
                      '${subCpmk.kodeSubCPMK}: ${subCpmk.deskripsi}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  static pw.Widget _buildRPSTable(Map<int, RPSDetail> rpsGrouped, List<SubCPMK> subCpmks) {
    // Create map of SubCPMK ID to kode for quick lookup
    final subCpmkMap = {for (var s in subCpmks) s.id: s.kodeSubCPMK};
    
    final List<pw.TableRow> rows = [
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey800,
          border: pw.TableBorder(
            top: pw.BorderSide(width: 2),
            bottom: pw.BorderSide(width: 2),
          ),
        ),
        children: [
          _buildTableHeaderCell('Mg', flex: 1),
          _buildTableHeaderCell('Topik Pembelajaran', flex: 3),
          _buildTableHeaderCell('Metode', flex: 2),
          _buildTableHeaderCell('Penilaian', flex: 2),
          _buildTableHeaderCell('Sub CPMK', flex: 2),
          _buildTableHeaderCell('Bobot', flex: 1),
        ],
      ),
    ];

    for (int i = 1; i <= 16; i++) {
      final rps = rpsGrouped[i];
      // Get Sub CPMK kodes for this RPS detail
      final subCpmkKodes = rps?.subCpmkIds?.map((id) => subCpmkMap[id] ?? '-').join(', ') ?? '-';
      
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            border: pw.TableBorder(
              bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey400),
            ),
            color: i.isEven ? PdfColors.grey100 : PdfColors.white,
          ),
          children: [
            _buildTableDataCell('$i', flex: 1, align: pw.TextAlign.center),
            _buildTableDataCell(rps?.topik ?? '-', flex: 3),
            _buildTableDataCell(rps?.metodeAjar ?? '-', flex: 2, align: pw.TextAlign.center),
            _buildTableDataCell(rps?.jenisNilai ?? '-', flex: 2, align: pw.TextAlign.center),
            _buildTableDataCell(subCpmkKodes, flex: 2, align: pw.TextAlign.center),
            _buildTableDataCell(rps?.bobot != null ? '${rps!.bobot}%' : '-', flex: 1, align: pw.TextAlign.center),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(width: 1, color: PdfColors.grey600),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2),
        5: pw.FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  static pw.Widget _buildRPSTableSimple(List<RPSDetail> rpsDetails, List<SubCPMK> subCpmks) {
    // Create map of SubCPMK ID to kode for quick lookup
    final subCpmkMap = {for (var s in subCpmks) s.id: s.kodeSubCPMK};
    
    final rpsGrouped = <int, RPSDetail>{};
    for (final rps in rpsDetails) {
      rpsGrouped[rps.mingguKe] = rps;
    }

    final List<pw.TableRow> rows = [
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey800,
          border: pw.TableBorder(
            top: pw.BorderSide(width: 2),
            bottom: pw.BorderSide(width: 2),
          ),
        ),
        children: [
          _buildTableHeaderCell('Mg', flex: 1),
          _buildTableHeaderCell('Topik Pembelajaran', flex: 3),
          _buildTableHeaderCell('Metode', flex: 2),
          _buildTableHeaderCell('Penilaian', flex: 2),
          _buildTableHeaderCell('Sub CPMK', flex: 2),
          _buildTableHeaderCell('Bobot', flex: 1),
        ],
      ),
    ];

    for (int i = 1; i <= 16; i++) {
      final rps = rpsGrouped[i];
      // Get Sub CPMK kodes for this RPS detail
      final subCpmkKodes = rps?.subCpmkIds?.map((id) => subCpmkMap[id] ?? '-').join(', ') ?? '-';
      
      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            border: pw.TableBorder(
              bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey400),
            ),
            color: i.isEven ? PdfColors.grey100 : PdfColors.white,
          ),
          children: [
            _buildTableDataCell('$i', flex: 1, align: pw.TextAlign.center),
            _buildTableDataCell(rps?.topik ?? '-', flex: 3),
            _buildTableDataCell(rps?.metodeAjar ?? '-', flex: 2, align: pw.TextAlign.center),
            _buildTableDataCell(rps?.jenisNilai ?? '-', flex: 2, align: pw.TextAlign.center),
            _buildTableDataCell(subCpmkKodes, flex: 2, align: pw.TextAlign.center),
            _buildTableDataCell(rps?.bobot != null ? '${rps!.bobot}%' : '-', flex: 1, align: pw.TextAlign.center),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(width: 1, color: PdfColors.grey600),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2),
        5: pw.FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, {int flex = 1}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        maxLines: 2,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildTableDataCell(
    String text, {
    int flex = 1,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: pw.Text(
        text,
        maxLines: 3,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildAssessmentSummaryTable(
    List<RPSDetail> rpsDetails,
    List<CPMK> cpmks,
    List<CPLMaster> cpls,
    List<SubCPMK> subCpmks,
    Map<int, Map<int, double>> rpsDetailSubCpmkBobots,
  ) {
    // If no RPS details, return empty widget
    if (rpsDetails.isEmpty) {
      return pw.SizedBox.shrink();
    }

    // Create a map for quick lookup of SubCPMK names
    final subCpmkMap = {for (var s in subCpmks) s.id: s.kodeSubCPMK};

    // Build data structure: Map of subCpmkId -> assessment data
    final assessmentData = <int, Map<String, double>>{};

    // Collect all unique assessment types (excluding UTS/UAS)
    final assessmentTypes = <String>{};

    // Build assessment data per SubCPMK (including UTS/UAS)
    for (final rps in rpsDetails) {
      // Collect assessment types (excluding UTS/UAS)
      if (rps.jenisNilai != null &&
          rps.jenisNilai!.isNotEmpty &&
          rps.jenisNilai != 'UTS' &&
          rps.jenisNilai != 'UAS') {
        assessmentTypes.add(rps.jenisNilai!);
      }

      // Initialize assessmentData for SubCPMKs
      if (rps.subCpmkIds != null && rps.subCpmkIds!.isNotEmpty) {
        for (final subCpmkId in rps.subCpmkIds!) {
          if (!assessmentData.containsKey(subCpmkId)) {
            assessmentData[subCpmkId] = {};
            // Initialize all assessment types with 0
            for (final type in assessmentTypes) {
              assessmentData[subCpmkId]![type] = 0;
            }
            // Initialize UTS and UAS with 0
            assessmentData[subCpmkId]!['UTS'] = 0;
            assessmentData[subCpmkId]!['UAS'] = 0;
          }
        }
      }
    }

    final sortedAssessmentTypes = assessmentTypes.toList()..sort();

    // Second pass: fill in the bobot values for each assessment type and SubCPMK
    for (final rps in rpsDetails) {
      if (rps.subCpmkIds == null || rps.subCpmkIds!.isEmpty || rps.bobot == null) {
        continue;
      }

      for (final subCpmkId in rps.subCpmkIds!) {
        if (rps.jenisNilai == 'UTS' || rps.jenisNilai == 'UAS') {
          // Untuk UTS/UAS, ambil bobot individual dari SubCPMK jika tersedia
          double bobotValue = 0;
          if (rps.id != null && rpsDetailSubCpmkBobots.containsKey(rps.id!)) {
            // Gunakan bobot per SubCPMK yang disimpan di tabel rps_detail_sub_cpmk_bobot
            bobotValue = rpsDetailSubCpmkBobots[rps.id!]![subCpmkId] ?? 0;
          } else {
            // Fallback: jika tidak ada di bobot table, gunakan total dibagi jumlah SubCPMK
            bobotValue = rps.subCpmkIds!.length == 1 ? rps.bobot! : (rps.bobot! / rps.subCpmkIds!.length);
          }
          
          if (rps.jenisNilai == 'UTS') {
            assessmentData[subCpmkId]!['UTS'] = bobotValue;
          } else if (rps.jenisNilai == 'UAS') {
            assessmentData[subCpmkId]!['UAS'] = bobotValue;
          }
        } else if (rps.jenisNilai != null &&
            rps.jenisNilai!.isNotEmpty &&
            rps.jenisNilai != 'UTS' &&
            rps.jenisNilai != 'UAS') {
          assessmentData[subCpmkId]![rps.jenisNilai!] =
              (assessmentData[subCpmkId]![rps.jenisNilai!] ?? 0) + rps.bobot!;
        }
      }
    }

    // Build table rows
    final List<pw.TableRow> rows = [];

    // Header row
    final headerCells = ['Sub CPMK'];
    headerCells.addAll(sortedAssessmentTypes);
    headerCells.addAll(['UTS', 'UAS', 'Total']);

    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey800,
          border: pw.TableBorder(
            top: pw.BorderSide(width: 2),
            bottom: pw.BorderSide(width: 2),
          ),
        ),
        children: headerCells
            .map((cell) => _buildTableHeaderCell(cell))
            .toList(),
      ),
    );

    // Data rows - sort by SubCPMK ID for consistent ordering
    final sortedSubCpmkIds = assessmentData.keys.toList()..sort();

    int rowIndex = 0;
    for (final subCpmkId in sortedSubCpmkIds) {
      final assessments = assessmentData[subCpmkId]!;
      final subCpmkCode = subCpmkMap[subCpmkId] ?? '-';

      double total = 0;
      final cells = [subCpmkCode];

      // Add assessment type values
      for (final type in sortedAssessmentTypes) {
        final value = assessments[type] ?? 0;
        total += value;
        cells.add(value > 0 ? value.toStringAsFixed(1) : '-');
      }

      // Add UTS and UAS
      final utsValue = assessments['UTS'] ?? 0;
      final uasValue = assessments['UAS'] ?? 0;
      total += utsValue + uasValue;
      
      cells.add(utsValue > 0 ? utsValue.toStringAsFixed(1) : '-');
      cells.add(uasValue > 0 ? uasValue.toStringAsFixed(1) : '-');
      cells.add(total > 0 ? total.toStringAsFixed(1) : '-');

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            border: pw.TableBorder(
              bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey400),
            ),
            color: rowIndex.isEven ? PdfColors.grey50 : PdfColors.white,
          ),
          children: cells.map((cell) => _buildTableDataCell(cell, align: pw.TextAlign.center)).toList(),
        ),
      );
      rowIndex++;
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Ringkasan Penilaian Sub CPMK',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(width: 1, color: PdfColors.grey600),
          children: rows,
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'Dokumen ini dibuat otomatis oleh sistem',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
        ),
        
      ],
    );
  }

  static Future<void> openPDF(File file) async {
    try {
      // For Windows/Desktop: Open PDF from Downloads folder
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        print('📄 Opening PDF: ${file.path}');
        print('📄 File exists: ${file.existsSync()}');
        print('📄 File size: ${file.lengthSync()} bytes');
        
        // Open file with default PDF reader
        await launchUrl(Uri.file(file.path));
        print('✓ PDF opened successfully');
      } else {
        // For mobile: Use Printing share dialog
        await Printing.sharePdf(
          bytes: await file.readAsBytes(),
          filename: file.path.split('/').last,
        );
      }
    } catch (e) {
      print('❌ Error opening PDF: $e');
      rethrow;
    }
  }
}
