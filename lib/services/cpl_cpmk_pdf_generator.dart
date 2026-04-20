import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/matakuliah_model.dart';
import '../models/mahasiswa_model.dart';
import '../models/cpmk_model.dart';
import '../models/cpl_master_model.dart';
import '../services/obe_calculation_helper.dart';

// For opening files
import 'package:url_launcher/url_launcher.dart';

class CPLCPMKPDFGenerator {
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

  /// Generate CPL & CPMK Report PDF
  static Future<File> generateCPLCPMKReport({
    required Matakuliah matakuliah,
    required List<Mahasiswa> mahasiswaList,
    required List<CPMK> cpmkList,
    required List<CPLMaster> cplList,
    required Map<int, OBECalculationResult> calculationResults,
    required String tahunAjaran,
    String language = 'id',
  }) async {
    final pdf = pw.Document();

    // Load logo from assets (if exists)
    Uint8List? logoBytes;
    try {
      logoBytes = (await rootBundle.load('assets/logo.png')).buffer.asUint8List();
    } catch (e) {
      // Logo not found, continue without it
    }

    // PAGE 1: COVER PAGE
    final isEnglish = language == 'en';
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Logo
          if (logoBytes != null)
            pw.SizedBox(
              height: 80,
              child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
            )
          else
            pw.SizedBox(height: 40),

          pw.SizedBox(height: 20),

          // Title
          pw.Text(
            isEnglish ? 'GRADE REPORT' : 'LAPORAN NILAI',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),

          pw.Text(
            isEnglish
                ? 'Program Learning Outcomes (PLO) and Course Learning Outcomes (CLO)'
                : 'Capaian Pembelajaran Lulusan (CPL) dan Capaian Pembelajaran Mata Kuliah (CPMK)',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),

          pw.SizedBox(height: 40),

          // Course info
          _buildInfoSection([
            [isEnglish ? 'Course:' : 'Mata Kuliah:', matakuliah.nama],
            [isEnglish ? 'Course Code:' : 'Kode Mata Kuliah:', matakuliah.kode],
            [isEnglish ? 'Credits:' : 'SKS:', '${matakuliah.sks}'],
            [isEnglish ? 'Semester:' : 'Semester:', '${matakuliah.semester}'],
            [isEnglish ? 'Academic Year:' : 'Tahun Ajaran:', tahunAjaran],
            [isEnglish ? 'Total Students:' : 'Jumlah Mahasiswa:', '${mahasiswaList.length}'],
          ]),

          pw.SizedBox(height: 40),

          // Report info
          pw.Text(
            isEnglish
                ? 'This report displays Program Learning Outcomes (PLO) and Course Learning Outcomes (CLO) for the course above.'
                : 'Laporan ini menampilkan nilai CPL dan CPMK untuk mata kuliah di atas.',
            style: const pw.TextStyle(fontSize: 11),
            textAlign: pw.TextAlign.justify,
          ),

        ],
      ),
    );

    // PAGE 2+: STUDENT GRADES TABLE WITH CPL AND CPMK
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          // Header
          pw.Text(
            isEnglish
                ? 'Student Assessment Results - ${matakuliah.nama}'
                : 'Hasil Penilaian Mahasiswa - ${matakuliah.nama}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          // Build table
          _buildStudentGradesTable(mahasiswaList, cpmkList, cplList, calculationResults, language: language),

          pw.SizedBox(height: 20),

          _buildFooter(language: language),
        ],
      ),
    );

    // PAGE 3: SUMMARY STATISTICS
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Text(
            isEnglish ? 'SUMMARY STATISTICS' : 'RINGKASAN STATISTIK',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 20),

          _buildStatisticsSection(mahasiswaList, cpmkList, cplList, calculationResults, language: language),

          pw.SizedBox(height: 30),

          _buildFooter(language: language),
        ],
      ),
    );

    // Save PDF
    final downloadsDir = await _getDownloadsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = 'Laporan_CPL_CPMK_${matakuliah.kode}_$timestamp.pdf';
    final file = File('${downloadsDir.path}/$filename');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Build info section with key-value pairs
  static pw.Widget _buildInfoSection(List<List<String>> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items.map((item) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 150,
                  child: pw.Text(
                    item[0],
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(item[1]),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Build student grades table
  static pw.Widget _buildStudentGradesTable(
    List<Mahasiswa> mahasiswaList,
    List<CPMK> cpmkList,
    List<CPLMaster> cplList,
    Map<int, OBECalculationResult> calculationResults, {
    String language = 'id',
  }) {
    final isEnglish = language == 'en';
    // Extract unique CPMK and CPL IDs from results
    final cpmkIds = <String>{};
    final cplIds = <String>{};

    for (final result in calculationResults.values) {
      cpmkIds.addAll(result.cpmkValues.keys);
      cplIds.addAll(result.cplValues.keys);
    }

    // If no IDs found, create dummy ones from model list
    if (cpmkIds.isEmpty && cpmkList.isNotEmpty) {
      for (final cpmk in cpmkList) {
        if (cpmk.id != null) {
          cpmkIds.add(cpmk.id.toString());
        }
      }
    }

    if (cplIds.isEmpty && cplList.isNotEmpty) {
      for (final cpl in cplList) {
        if (cpl.id != null) {
          cplIds.add(cpl.id.toString());
        }
      }
    }

    // Sort IDs
    final sortedCpmkIds = cpmkIds.toList()..sort((a, b) => a.compareTo(b));
    final sortedCplIds = cplIds.toList()..sort((a, b) => a.compareTo(b));

    // Build table headers
    final headers = <String>[
      'No',
      isEnglish ? 'Student ID' : 'NIM',
      isEnglish ? 'Name' : 'Nama Mahasiswa',
    ];
    final cpmkPrefix = isEnglish ? 'CLO' : 'CPMK';
    final cplPrefix = isEnglish ? 'PLO' : 'CPL';
    headers.addAll(sortedCpmkIds.map((id) => '$cpmkPrefix.$id'));
    headers.addAll(sortedCplIds.map((id) => '$cplPrefix.$id'));

    // If still no headers, at least show NIM and Nama
    if (headers.length == 3) {
      headers.add(isEnglish ? 'Notes' : 'Keterangan');
    }

    // Build table rows
    final List<List<pw.Widget>> rows = [];
    int no = 1;

    for (final mahasiswa in mahasiswaList) {
      if (mahasiswa.id == null) continue;

      final result = calculationResults[mahasiswa.id];

      final row = <pw.Widget>[
        pw.Text(no.toString(), textAlign: pw.TextAlign.center),
        pw.Text(mahasiswa.nim, textAlign: pw.TextAlign.center),
        pw.Text(mahasiswa.nama),
      ];

      // Add CPMK values
      for (final cpmkId in sortedCpmkIds) {
        final value = result?.cpmkValues[cpmkId];
        row.add(
          pw.Text(
            value != null ? value.toStringAsFixed(2) : '-',
            textAlign: pw.TextAlign.center,
          ),
        );
      }

      // Add CPL values
      for (final cplId in sortedCplIds) {
        final value = result?.cplValues[cplId];
        row.add(
          pw.Text(
            value != null ? value.toStringAsFixed(2) : '-',
            textAlign: pw.TextAlign.center,
          ),
        );
      }

      // If no CPMK/CPL columns, add remark
      if (sortedCpmkIds.isEmpty && sortedCplIds.isEmpty) {
        row.add(
          pw.Text(
            result != null
                ? (isEnglish ? 'Data available' : 'Data tersedia')
                : (isEnglish ? 'Not calculated' : 'Belum dihitung'),
            textAlign: pw.TextAlign.center,
          ),
        );
      }

      rows.add(row);
      no++;
    }

    // Calculate column widths
    final columnCount = headers.length;
    final columnWidths = <int, pw.FixedColumnWidth>{
      0: const pw.FixedColumnWidth(25),
      1: const pw.FixedColumnWidth(70),
      2: const pw.FixedColumnWidth(120),
    };
    for (int i = 3; i < columnCount; i++) {
      columnWidths[i] = const pw.FixedColumnWidth(50);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: columnWidths,
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: headers.map((h) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                h,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  font: pw.Font.times(),
                ),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),
        // Data rows
        ...rows.map((row) {
          return pw.TableRow(
            children: row.map((cell) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.DefaultTextStyle(
                  style: pw.TextStyle(
                    fontSize: 12,
                    font: pw.Font.times(),
                  ),
                  child: cell,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  /// Build statistics section
  static pw.Widget _buildStatisticsSection(
    List<Mahasiswa> mahasiswaList,
    List<CPMK> cpmkList,
    List<CPLMaster> cplList,
    Map<int, OBECalculationResult> calculationResults, {
    String language = 'id',
  }) {
    final isEnglish = language == 'en';
    
    if (calculationResults.isEmpty) {
      return pw.Text(isEnglish ? 'No data to display' : 'Tidak ada data untuk ditampilkan');
    }

    // Calculate statistics
    double totalCPMK = 0;
    double totalCPL = 0;
    int count = 0;
    double minCPMK = double.infinity;
    double maxCPMK = 0;
    double minCPL = double.infinity;
    double maxCPL = 0;

    for (final result in calculationResults.values) {
      final avgCpmk = result.averageCPMK;
      final avgCpl = result.averageCPL;

      count++;
      totalCPMK += avgCpmk;
      totalCPL += avgCpl;

      if (avgCpmk > 0) {
        minCPMK = avgCpmk < minCPMK ? avgCpmk : minCPMK;
        maxCPMK = avgCpmk > maxCPMK ? avgCpmk : maxCPMK;
      }

      if (avgCpl > 0) {
        minCPL = avgCpl < minCPL ? avgCpl : minCPL;
        maxCPL = avgCpl > maxCPL ? avgCpl : maxCPL;
      }
    }

    final avgCpmk = count > 0 ? totalCPMK / count : 0.0;
    final avgCpl = count > 0 ? totalCPL / count : 0.0;
    final minCpmkVal = minCPMK == double.infinity ? 0.0 : minCPMK;
    final minCplVal = minCPL == double.infinity ? 0.0 : minCPL;
    final maxCpmkVal = minCPMK == double.infinity ? 0.0 : maxCPMK;
    final maxCplVal = minCPL == double.infinity ? 0.0 : maxCPL;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          isEnglish
              ? 'Course Learning Outcomes (CLO) Scores'
              : 'Nilai Capaian Pembelajaran Mata Kuliah (CPMK)',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 10),
        _buildStatItem(
          isEnglish ? 'Average CLO' : 'Rata-rata CPMK',
          avgCpmk,
        ),
        _buildStatItem(
          isEnglish ? 'Highest Score' : 'Nilai Tertinggi',
          maxCpmkVal,
        ),
        _buildStatItem(
          isEnglish ? 'Lowest Score' : 'Nilai Terendah',
          minCpmkVal,
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          isEnglish
              ? 'Program Learning Outcomes (PLO) Scores'
              : 'Nilai Capaian Pembelajaran Lulusan (CPL)',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 10),
        _buildStatItem(
          isEnglish ? 'Average PLO' : 'Rata-rata CPL',
          avgCpl,
        ),
        _buildStatItem(
          isEnglish ? 'Highest Score' : 'Nilai Tertinggi',
          maxCplVal,
        ),
        _buildStatItem(
          isEnglish ? 'Lowest Score' : 'Nilai Terendah',
          minCplVal,
        ),
      ],
    );
  }

  static pw.Widget _buildStatItem(String label, double? value, [double? maxValue]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(label),
          ),
          pw.Text(
            value != null ? value.toStringAsFixed(2) : '-',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (maxValue != null) ...[
            pw.SizedBox(width: 30),
            pw.Text(' s/d  '),
            pw.Text(
              maxValue.toStringAsFixed(2),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildFooter({String language = 'id'}) {
    final isEnglish = language == 'en';
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 10),
        pw.Text(
          isEnglish
              ? 'This document was generated by the CPL Information System'
              : 'Dokumen ini dihasilkan oleh Sistem Informasi CPL',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Generate Per Mahasiswa Report (student's CPMK/CPL per course with averages)
  static Future<File> generatePerMahasiswaReport({
    required Mahasiswa mahasiswa,
    required Map<int, Map<String, dynamic>> mkScoresMap,
    required List<CPLMaster> cplList,
    String language = 'id',
  }) async {
    final pdf = pw.Document();

    // Load logo from assets
    Uint8List? logoBytes;
    try {
      logoBytes = (await rootBundle.load('assets/logo.png')).buffer.asUint8List();
    } catch (e) {
      // Logo not found, continue without it
    }

    // COVER PAGE
    final isEnglish = language == 'en';
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          if (logoBytes != null)
            pw.SizedBox(
              height: 80,
              child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
            )
          else
            pw.SizedBox(height: 40),

          pw.SizedBox(height: 20),

          pw.Text(
            isEnglish ? 'INDIVIDUAL STUDENT REPORT' : 'LAPORAN INDIVIDUAL MAHASISWA',
            style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),

          pw.Text(
            isEnglish
                ? 'Program Learning Outcomes (PLO) and Course Learning Outcomes (CLO)'
                : 'Capaian Pembelajaran Lulusan (CPL) dan Capaian Pembelajaran Mata Kuliah (CPMK)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),

          pw.SizedBox(height: 40),

          _buildInfoSection([
            [isEnglish ? 'Student ID:' : 'NIM:', mahasiswa.nim],
            [isEnglish ? 'Name:' : 'Nama:', mahasiswa.nama],
            [isEnglish ? 'Status:' : 'Status:', mahasiswa.status],
            [isEnglish ? 'Year Entered:' : 'Tahun Masuk:', '${mahasiswa.tahunMasuk}'],
          ]),

          pw.SizedBox(height: 40),

          pw.Text(
            isEnglish ? 'Notes:' : 'Catatan:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            isEnglish
                ? 'This report displays Course Learning Outcomes (CLO) / Program Learning Outcomes (PLO) per course taken and overall average scores.'
                : 'Laporan ini menampilkan nilai CPMK/CPL per mata kuliah yang telah ditempuh dan rata-rata nilai keseluruhan.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    // DATA PAGE
    if (mkScoresMap.isNotEmpty) {
      // Calculate overall averages
      final Map<String, List<double>> cpmkAggregates = {};
      final Map<String, List<double>> cplAggregates = {};

      for (final mkScores in mkScoresMap.values) {
        final cpmk = mkScores['cpmk'] as Map<String, double>? ?? {};
        final cpl = mkScores['cpl'] as Map<String, double>? ?? {};

        for (final entry in cpmk.entries) {
          cpmkAggregates.putIfAbsent(entry.key, () => []).add(entry.value);
        }
        for (final entry in cpl.entries) {
          cplAggregates.putIfAbsent(entry.key, () => []).add(entry.value);
        }
      }

      final cpmkAverages = cpmkAggregates.map((k, v) =>
          MapEntry(k, v.reduce((a, b) => a + b) / v.length));
      final cplAverages = cplAggregates.map((k, v) =>
          MapEntry(k, v.reduce((a, b) => a + b) / v.length));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(30),
          build: (context) => [
            pw.Text(
              isEnglish ? 'Scores Per Course' : 'Nilai Per Mata Kuliah',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 15),

            pw.TableHelper.fromTextArray(
              context: context,
              data: _buildMahasiswaDetailTable(mkScoresMap, language: language),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7),
              rowDecoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Text(
              isEnglish ? 'Course Learning Outcomes (CLO)' : 'Nilai CPMK',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              context: context,
              data: _buildAverageTable('CPMK', cpmkAverages, language: language),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7),
              rowDecoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Text(
              isEnglish ? 'Program Learning Outcomes (PLO)' : 'Nilai CPL',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              context: context,
              data: _buildAverageTable('CPL', cplAverages, language: language),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7),
              rowDecoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),

            pw.SizedBox(height: 20),
            _buildFooter(language: language),
          ],
        ),
      );
    }

    final outputDir = await _getDownloadsDirectory();
    final fileName = 'Laporan_${mahasiswa.nim}_${DateTime.now().toString().split(' ')[0]}.pdf';
    final outputFile = File('${outputDir.path}\\$fileName');

    await pdf.save();
    await outputFile.writeAsBytes(await pdf.save());

    return outputFile;
  }

  /// Generate Per Angkatan Report (all students in cohort with averages)
  static Future<File> generatePerAngkatanReport({
    required int angkatan,
    required Map<int, Map<String, dynamic>> studentScoresMap,
    required List<CPLMaster> cplList,
    String language = 'id',
  }) async {
    final pdf = pw.Document();

    // Load logo from assets
    Uint8List? logoBytes;
    try {
      logoBytes = (await rootBundle.load('assets/logo.png')).buffer.asUint8List();
    } catch (e) {
      // Logo not found
    }

    // COVER PAGE
    final isEnglish = language == 'en';
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          if (logoBytes != null)
            pw.SizedBox(
              height: 80,
              child: pw.Image(pw.MemoryImage(logoBytes), fit: pw.BoxFit.contain),
            )
          else
            pw.SizedBox(height: 40),

          pw.SizedBox(height: 20),

          pw.Text(
            isEnglish ? ' ' : ' ',
            style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),

          pw.Text(
            isEnglish ? 'Program Learning Outcomes (PLO)' : 'Capaian Pembelajaran Lulusan (CPL)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),

          pw.SizedBox(height: 40),

          _buildInfoSection([
            [isEnglish ? 'Year Cohort:' : 'Tahun Angkatan:', '$angkatan'],
            [isEnglish ? 'Total Students:' : 'Jumlah Mahasiswa:', '${studentScoresMap.length}'],
            [isEnglish ? 'Report Date:' : 'Tanggal Laporan:', DateFormat('dd MMMM yyyy', isEnglish ? 'en_US' : 'id_ID').format(DateTime.now())],
          ]),

          pw.SizedBox(height: 40),

          pw.Text(
            isEnglish ? 'Notes:' : 'Catatan:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            isEnglish
                ? 'This report displays average Program Learning Outcomes (PLO) and Course Learning Outcomes (CLO) for all students in one cohort.'
                : 'Laporan ini menampilkan rata-rata nilai CPMK/CPL semua mahasiswa dalam satu angkatan.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    // DATA PAGE - Tabel CPL saja (Landscape)
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          pw.Text(
              isEnglish
                  ? 'Program Learning Outcomes (PLO) Assessment Results - Cohort $angkatan'
                  : 'Nilai Capaian Pembelajaran Lulusan (CPL) - Angkatan $angkatan',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 15),

          if (studentScoresMap.isNotEmpty)
            pw.TableHelper.fromTextArray(
              context: context,
              data: _buildAngkatanCplOnlyTable(studentScoresMap, language: language),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 7),
              rowDecoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
              ),
              headerDecoration: pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            )
          else
            pw.Text(
              isEnglish
                  ? 'No student data available for this cohort.'
                  : 'Tidak ada data mahasiswa untuk angkatan ini.',
              style: const pw.TextStyle(fontSize: 11),
            ),

          pw.SizedBox(height: 20),
          _buildFooter(language: language),
        ],
      ),
    );

    final outputDir = await _getDownloadsDirectory();
    final fileName = 'Laporan_Angkatan_${angkatan}_${DateTime.now().toString().split(' ')[0]}.pdf';
    final outputFile = File('${outputDir.path}\\$fileName');

    await outputFile.writeAsBytes(await pdf.save());

    return outputFile;
  }

  /// Helper: Build mahasiswa detail table
  static List<List<String>> _buildMahasiswaDetailTable(
    Map<int, Map<String, dynamic>> mkScoresMap, {
    String language = 'id',
  }) {
    final isEnglish = language == 'en';
    final rows = <List<String>>[
      [
        isEnglish ? 'No' : 'No',
        isEnglish ? 'Course' : 'Mata Kuliah',
        isEnglish ? 'CLO Code' : 'Kode CPMK',
        isEnglish ? 'CLO Score' : 'Nilai CPMK',
        isEnglish ? 'PLO Code' : 'Kode CPL',
        isEnglish ? 'PLO Score' : 'Nilai CPL',
      ],
    ];

    int no = 1;
    for (final entry in mkScoresMap.entries) {
      final mkData = entry.value;
      final mk = mkData['matakuliah'] as Matakuliah? ?? Matakuliah(
        kode: 'UNK',
        nama: 'Unknown',
        semester: '0',
        jenis: 'wajib',
        sks: 0,
        createdAt: DateTime.now(),
      );
      final cpmkMap = mkData['cpmk'] as Map<String, double>? ?? {};
      final cplMap = mkData['cpl'] as Map<String, double>? ?? {};

      // Build code lists
      final cpmkCodes = cpmkMap.keys.toList()..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
      final cplCodes = cplMap.keys.toList()..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

      final cpmkPrefix = isEnglish ? 'CLO' : 'CPMK';
      final cplPrefix = isEnglish ? 'PLO' : 'CPL';
      final cpmkCodeStr = cpmkCodes.isNotEmpty ? cpmkCodes.map((c) => '$cpmkPrefix.$c').join(', ') : '-';
      final cplCodeStr = cplCodes.isNotEmpty ? cplCodes.map((c) => '$cplPrefix.$c').join(', ') : '-';

      final avgCpmk = cpmkMap.isNotEmpty
          ? (cpmkMap.values.reduce((a, b) => a + b) / cpmkMap.length).toStringAsFixed(2)
          : '-';
      final avgCpl = cplMap.isNotEmpty
          ? (cplMap.values.reduce((a, b) => a + b) / cplMap.length).toStringAsFixed(2)
          : '-';

      rows.add([
        '$no',
        '${mk.kode} - ${mk.nama}',
        cpmkCodeStr,
        avgCpmk,
        cplCodeStr,
        avgCpl,
      ]);

      no++;
    }

    return rows;
  }

  /// Helper: Build average table
  static List<List<String>> _buildAverageTable(
    String type,
    Map<String, double> averages, {
    String language = 'id',
  }) {
    final isEnglish = language == 'en';
    final typeLabel = isEnglish
        ? (type == 'CPMK'
            ? 'CLO Code'
            : 'PLO Code')
        : 'Kode $type';
    final scoreLabel = isEnglish ? 'Average Score' : 'Nilai Rata-Rata';
    
    final rows = <List<String>>[
      [typeLabel, scoreLabel],
    ];

    if (averages.isEmpty) {
      final noDataMsg = isEnglish ? 'No data' : 'Tidak ada data';
      return [[typeLabel, scoreLabel], [noDataMsg, '']];
    }

    // Sort entries by ID (numerically)
    final sortedEntries = averages.entries.toList()
      ..sort((a, b) {
        final aNum = int.tryParse(a.key) ?? 0;
        final bNum = int.tryParse(b.key) ?? 0;
        return aNum.compareTo(bNum);
      });

    for (final entry in sortedEntries) {
      final prefix = isEnglish ? (type == 'CPMK' ? 'CLO' : 'PLO') : type;
      rows.add([
        '$prefix.${entry.key}',
        entry.value.toStringAsFixed(2),
      ]);
    }

    return rows;
  }

  /// Helper: Build angkatan CPMK table with individual CPMK columns
  static List<List<String>> _buildAngkatanCpmkTable(
    Map<int, Map<String, dynamic>> studentScoresMap, {
    String language = 'id',
  }) {
    final isEnglish = language == 'en';
    if (studentScoresMap.isEmpty) {
      return [[
        'No',
        isEnglish ? 'Student ID' : 'NIM',
        isEnglish ? 'Name' : 'Nama',
        isEnglish ? 'Notes' : 'Keterangan',
      ]];
    }

    // Get all unique CPMK IDs and sort them
    final allCpmkIds = <String>{};
    for (final studentData in studentScoresMap.values) {
      final cpmkMap = studentData['cpmk'] as Map<String, double>? ?? {};
      allCpmkIds.addAll(cpmkMap.keys);
    }
    final sortedCpmkIds = allCpmkIds.toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

    // Build header
    final cloPrefix = isEnglish ? 'CLO' : 'CPMK';
    final headers = [
      'No',
      isEnglish ? 'Student ID' : 'NIM',
      isEnglish ? 'Name' : 'Nama',
    ];
    headers.addAll(sortedCpmkIds.map((id) => '$cloPrefix.$id'));
    final rows = <List<String>>[headers];

    // Sort students by NIM
    final sortedEntries = studentScoresMap.entries.toList()
      ..sort((a, b) {
        final mahasiswaA = a.value['mahasiswa'] as Mahasiswa?;
        final mahasiswaB = b.value['mahasiswa'] as Mahasiswa?;
        return (mahasiswaA?.nim ?? '').compareTo(mahasiswaB?.nim ?? '');
      });

    int no = 1;
    for (final entry in sortedEntries) {
      final studentData = entry.value;
      final mahasiswa = studentData['mahasiswa'] as Mahasiswa? ?? Mahasiswa(
        nim: 'N/A',
        nama: 'Unknown',
        tahunMasuk: 2024,
        createdAt: DateTime.now(),
      );
      final cpmkMap = studentData['cpmk'] as Map<String, double>? ?? {};

      final rowData = ['$no', mahasiswa.nim, mahasiswa.nama];
      for (final cpmkId in sortedCpmkIds) {
        final value = cpmkMap[cpmkId];
        rowData.add(value != null ? value.toStringAsFixed(2) : '-');
      }

      rows.add(rowData);
      no++;
    }

    return rows;
  }

  /// Helper: Build angkatan CPL table with individual CPL columns
  static List<List<String>> _buildAngkatanCplTable(
    Map<int, Map<String, dynamic>> studentScoresMap, {
    String language = 'id',
  }) {
    final isEnglish = language == 'en';
    if (studentScoresMap.isEmpty) {
      return [[
        'No',
        isEnglish ? 'Student ID' : 'NIM',
        isEnglish ? 'Name' : 'Nama',
        isEnglish ? 'Notes' : 'Keterangan',
      ]];
    }

    // Get all unique CPL IDs and sort them
    final allCplIds = <String>{};
    for (final studentData in studentScoresMap.values) {
      final cplMap = studentData['cpl'] as Map<String, double>? ?? {};
      allCplIds.addAll(cplMap.keys);
    }
    final sortedCplIds = allCplIds.toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

    // Build header
    final ploPrefix = isEnglish ? 'PLO' : 'CPL';
    final headers = [
      'No',
      isEnglish ? 'Student ID' : 'NIM',
      isEnglish ? 'Name' : 'Nama',
    ];
    headers.addAll(sortedCplIds.map((id) => '$ploPrefix.$id'));
    final rows = <List<String>>[headers];

    // Sort students by NIM
    final sortedEntries = studentScoresMap.entries.toList()
      ..sort((a, b) {
        final mahasiswaA = a.value['mahasiswa'] as Mahasiswa?;
        final mahasiswaB = b.value['mahasiswa'] as Mahasiswa?;
        return (mahasiswaA?.nim ?? '').compareTo(mahasiswaB?.nim ?? '');
      });

    int no = 1;
    for (final entry in sortedEntries) {
      final studentData = entry.value;
      final mahasiswa = studentData['mahasiswa'] as Mahasiswa? ?? Mahasiswa(
        nim: 'N/A',
        nama: 'Unknown',
        tahunMasuk: 2024,
        createdAt: DateTime.now(),
      );
      final cplMap = studentData['cpl'] as Map<String, double>? ?? {};

      final rowData = ['$no', mahasiswa.nim, mahasiswa.nama];
      for (final cplId in sortedCplIds) {
        final value = cplMap[cplId];
        rowData.add(value != null ? value.toStringAsFixed(2) : '-');
      }

      rows.add(rowData);
      no++;
    }

    return rows;
  }

  /// Helper: Build angkatan detail table
  static List<List<String>> _buildAngkatanDetailTable(
    Map<int, Map<String, dynamic>> studentScoresMap, {
    String language = 'id',
  }) {
    final isEnglish = language == 'en';
    final rows = <List<String>>[
      [
        'No',
        isEnglish ? 'Student ID' : 'NIM',
        isEnglish ? 'Name' : 'Nama',
        isEnglish ? 'Average CLO' : 'Rata-Rata CPMK',
        isEnglish ? 'Average PLO' : 'Rata-Rata CPL',
      ],
    ];

    if (studentScoresMap.isEmpty) {
      return rows;
    }

    // Sort by NIM
    final sortedEntries = studentScoresMap.entries.toList()
      ..sort((a, b) {
        final mahasiswaA = a.value['mahasiswa'] as Mahasiswa?;
        final mahasiswaB = b.value['mahasiswa'] as Mahasiswa?;
        return (mahasiswaA?.nim ?? '').compareTo(mahasiswaB?.nim ?? '');
      });

    int no = 1;
    for (final entry in sortedEntries) {
      final studentData = entry.value;
      final mahasiswa = studentData['mahasiswa'] as Mahasiswa? ?? Mahasiswa(
        nim: 'N/A',
        nama: 'Unknown',
        tahunMasuk: 2024,
        createdAt: DateTime.now(),
      );
      final cpmkMap = studentData['cpmk'] as Map<String, double>? ?? {};
      final cplMap = studentData['cpl'] as Map<String, double>? ?? {};

      final avgCpmk = cpmkMap.isNotEmpty
          ? (cpmkMap.values.reduce((a, b) => a + b) / cpmkMap.length).toStringAsFixed(2)
          : '-';
      final avgCpl = cplMap.isNotEmpty
          ? (cplMap.values.reduce((a, b) => a + b) / cplMap.length).toStringAsFixed(2)
          : '-';

      rows.add([
        '$no',
        mahasiswa.nim,
        mahasiswa.nama,
        avgCpmk,
        avgCpl,
      ]);

      no++;
    }

    return rows;
  }

  /// Helper: Build angkatan CPL only table
  static List<List<String>> _buildAngkatanCplOnlyTable(
    Map<int, Map<String, dynamic>> studentScoresMap, {
    String language = 'id',
  }) {
    final isEnglish = language == 'en';
    // Build header: No, NIM, Nama, Nilai CPL.1, Nilai CPL.2, ... Nilai CPL.7
    final ploPrefixLabel = isEnglish ? 'PLO' : 'Nilai CPL';
    final rows = <List<String>>[
      [
        'No',
        isEnglish ? 'Student ID' : 'NIM',
        isEnglish ? 'Name' : 'Nama',
        '$ploPrefixLabel.1',
        '$ploPrefixLabel.2',
        '$ploPrefixLabel.3',
        '$ploPrefixLabel.4',
        '$ploPrefixLabel.5',
        '$ploPrefixLabel.6',
        '$ploPrefixLabel.7',
      ],
    ];

    if (studentScoresMap.isEmpty) {
      return rows;
    }

    // Sort by NIM
    final sortedEntries = studentScoresMap.entries.toList()
      ..sort((a, b) {
        final mahasiswaA = a.value['mahasiswa'] as Mahasiswa?;
        final mahasiswaB = b.value['mahasiswa'] as Mahasiswa?;
        return (mahasiswaA?.nim ?? '').compareTo(mahasiswaB?.nim ?? '');
      });

    int no = 1;
    for (final entry in sortedEntries) {
      final studentData = entry.value;
      final mahasiswa = studentData['mahasiswa'] as Mahasiswa? ?? Mahasiswa(
        nim: 'N/A',
        nama: 'Unknown',
        tahunMasuk: 2024,
        createdAt: DateTime.now(),
      );
      final cplMap = studentData['cpl'] as Map<String, double>? ?? {};

      // Build row with individual CPL values for codes 1-7
      final rowData = [
        '$no',
        mahasiswa.nim,
        mahasiswa.nama,
      ];

      // Add CPL values for codes 1 to 7
      for (int cplCode = 1; cplCode <= 7; cplCode++) {
        final cplValue = cplMap[cplCode.toString()];
        if (cplValue != null) {
          rowData.add(cplValue.toStringAsFixed(2));
        } else {
          rowData.add('-');
        }
      }

      rows.add(rowData);
      no++;
    }

    return rows;
  }

  /// Helper: Build spider/radar chart for average values
  static pw.Widget _buildSpiderChart(Map<String, double> cpmkAverages, Map<String, double> cplAverages) {
    // Combine and sort all IDs
    final allIds = <String>{};
    allIds.addAll(cpmkAverages.keys);
    allIds.addAll(cplAverages.keys);
    
    if (allIds.isEmpty) {
      return pw.Text('Tidak ada data untuk chart');
    }

    final sortedIds = allIds.toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

    // Create description with values
    final chartDescription = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 12,
              height: 12,
              decoration: pw.BoxDecoration(
                color: PdfColors.blue,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text('CPMK', style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            pw.Container(
              width: 12,
              height: 12,
              decoration: pw.BoxDecoration(
                color: PdfColors.red,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text('CPL', style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ],
    );

    // Create value table for reference
    final valueRows = <List<String>>[
      ['ID', 'CPMK', 'CPL'],
    ];
    
    for (final id in sortedIds) {
      final cpmkVal = cpmkAverages[id]?.toStringAsFixed(1) ?? '-';
      final cplVal = cplAverages[id]?.toStringAsFixed(1) ?? '-';
      valueRows.add([id, cpmkVal, cplVal]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 120,
              child: chartDescription,
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.TableHelper.fromTextArray(
                context: null,
                data: valueRows,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                cellStyle: const pw.TextStyle(fontSize: 7),
                rowDecoration: pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Helper: Build comprehensive radar chart visualization
  static pw.Widget _buildRadarChartVisualization(Map<String, double> cpmkAverages, Map<String, double> cplAverages) {
    final allIds = <String>{};
    allIds.addAll(cpmkAverages.keys);
    allIds.addAll(cplAverages.keys);
    
    if (allIds.isEmpty) {
      return pw.Text('Tidak ada data untuk visualisasi');
    }

    final sortedIds = allIds.toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));

    // Build legend
    final legend = pw.Row(
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 15,
              height: 15,
              decoration: pw.BoxDecoration(
                color: PdfColors.blue,
                border: pw.Border.all(color: PdfColors.blue),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text('Nilai CPMK', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(width: 40),
        pw.Row(
          children: [
            pw.Container(
              width: 15,
              height: 15,
              decoration: pw.BoxDecoration(
                color: PdfColors.red,
                border: pw.Border.all(color: PdfColors.red),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text('Nilai CPL', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    );

    // Build data grid visualization
    final gridRows = <pw.Widget>[];
    
    for (final id in sortedIds) {
      final cpmkVal = cpmkAverages[id] ?? 0.0;
      final cplVal = cplAverages[id] ?? 0.0;
      
      // Create bar representation
      final cpmkWidth = (cpmkVal / 100) * 200; // Normalize to %
      final cplWidth = (cplVal / 100) * 200;
      
      gridRows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(
                width: 50,
                child: pw.Text('CPMK.$id', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Container(
                width: cpmkWidth.toDouble(),
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  border: pw.Border.all(color: PdfColors.blue, width: 0.5),
                ),
                child: pw.Center(
                  child: pw.Text(
                    cpmkVal.toStringAsFixed(1),
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.SizedBox(width: 30),
              pw.SizedBox(
                width: 50,
                child: pw.Text('CPL.$id', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Container(
                width: cplWidth.toDouble(),
                height: 20,
                decoration: pw.BoxDecoration(
                  color: PdfColors.red,
                  border: pw.Border.all(color: PdfColors.red, width: 0.5),
                ),
                child: pw.Center(
                  child: pw.Text(
                    cplVal.toStringAsFixed(1),
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        legend,
        pw.SizedBox(height: 20),
        pw.Column(children: gridRows),
      ],
    );
  }

  /// Open PDF file
  static Future<void> openPDF(File pdfFile) async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await launchUrl(Uri.file(pdfFile.path));
      } else {
        await launchUrl(Uri.file(pdfFile.path));
      }
    } catch (e) {
      throw Exception('Tidak dapat membuka file PDF: $e');
    }
  }
}
