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
      logoBytes = (await rootBundle.load('assets/logocpl.png')).buffer.asUint8List();
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
            [isEnglish ? 'Course:' : 'Mata Kuliah:', matakuliah.namaEng ?? matakuliah.nama],
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
                ? 'Student Assessment Results - ${matakuliah.namaEng ?? matakuliah.nama}'
                : 'Hasil Penilaian Mahasiswa - ${matakuliah.namaEng ?? matakuliah.nama}',
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
      logoBytes = (await rootBundle.load('assets/logocpl.png')).buffer.asUint8List();
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
      logoBytes = (await rootBundle.load('assets/logocpl.png')).buffer.asUint8List();
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

  /// Helper: Build angkatan CPMK table with individual CPMK columns (DEPRECATED - not used)
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

  /// Helper: Build angkatan CPL table with individual CPL columns (DEPRECATED - not used)
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

  /// Helper: Build angkatan detail table (DEPRECATED - not used)
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

  /// Helper: Build spider/radar chart for average values (DEPRECATED - not used)
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

  /// Helper: Build comprehensive radar chart visualization (DEPRECATED - not used)
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

  /// Generate Courses CPL Correlation Table PDF
  /// This creates a table showing correlation between courses (matakuliah) and CPL (PLO)
  static Future<File> generateCoursesCPLCorrelationTable({
    required List<Matakuliah> matakuliahList,
    required List<CPLMaster> cplList,
    required Map<int, List<CPMK>> matakuliahCPMKMap, // Map of matakuliah.id -> List<CPMK>
    required Map<int, List<int>> cpmkCPLMapping, // Map of cpmk.id -> List<cpl.id>
    Map<int, List<String>>? rpsRCPLMappings, // Map of matakuliah.id -> List<cpl_code> from RPS
    bool includeSemester = false,
    String language = 'id',
  }) async {
    final pdf = pw.Document();

    // Load logo from assets (if exists)
    Uint8List? logoBytes;
    try {
      logoBytes = (await rootBundle.load('assets/logocpl.png')).buffer.asUint8List();
    } catch (e) {
      // Logo not found, continue without it
    }

    final isEnglish = language == 'en';

    // PAGE 1: COVER PAGE
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
            isEnglish
                ? 'COURSE - PROGRAM LEARNING OUTCOMES CORRELATION'
                : 'KORELASI MATA KULIAH DENGAN CAPAIAN PEMBELAJARAN LULUSAN',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),

          pw.Text(
            isEnglish
                ? 'Course Learning Outcomes (CLO) and Program Learning Outcomes (PLO)'
                : 'Capaian Pembelajaran Mata Kuliah (CPMK) dan Capaian Pembelajaran Lulusan (CPL)',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),

          pw.SizedBox(height: 40),

          _buildInfoSection([
            [isEnglish ? 'Total Courses:' : 'Total Mata Kuliah:', '${matakuliahList.length}'],
            [isEnglish ? 'Total PLO:' : 'Total CPL:', '${cplList.length}'],
            [isEnglish ? 'Report Date:' : 'Tanggal Laporan:', DateFormat('dd MMMM yyyy', isEnglish ? 'en_US' : 'id_ID').format(DateTime.now())],
          ]),

          pw.SizedBox(height: 40),

          pw.Text(
            isEnglish ? 'Description:' : 'Keterangan:',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            includeSemester
                ? (isEnglish
                    ? 'This report shows how each Program Learning Outcome (PLO) is mapped to courses by semester.'
                    : 'Laporan ini menunjukkan bagaimana setiap Capaian Pembelajaran Lulusan (CPL) dipetakan ke mata kuliah per semester.')
                : (isEnglish
                    ? 'This report shows which Program Learning Outcomes (PLO) are achieved through each course. A checkmark (✓) indicates that the course contributes to achieving that PLO.'
                    : 'Laporan ini menunjukkan Capaian Pembelajaran Lulusan (CPL) mana saja yang tercapai melalui setiap mata kuliah. Tanda centang (✓) menunjukkan bahwa mata kuliah tersebut berkontribusi terhadap pencapaian CPL tersebut.'),
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.justify,
          ),
        ],
      ),
    );

    // PAGE 2: CORRELATION TABLE
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Text(
            includeSemester
                ? (isEnglish
                    ? 'Course - PLO Mapping by Semester'
                    : 'Pemetaan CPL ke Mata Kuliah per Semester')
                : (isEnglish
                    ? 'Course - PLO Correlation Matrix'
                    : 'Matriks Korelasi Mata Kuliah - CPL'),
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 15),

          if (includeSemester)
            _buildPLOCourseSemesterMappingTable(
              matakuliahList,
              cplList,
              matakuliahCPMKMap,
              cpmkCPLMapping,
              rpsRCPLMappings: rpsRCPLMappings,
              language: language,
            )
          else
            _buildCoursesCPLCorrelationTable(
              matakuliahList,
              cplList,
              matakuliahCPMKMap,
              cpmkCPLMapping,
              rpsRCPLMappings: rpsRCPLMappings,
              includeSemester: includeSemester,
              language: language,
            ),

          pw.SizedBox(height: 20),

          _buildFooter(language: language),
        ],
      ),
    );

    // Save PDF
    final downloadsDir = await _getDownloadsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filename = isEnglish
        ? 'Course_PLO_Correlation${includeSemester ? '_With_Semester' : ''}_$timestamp.pdf'
        : 'Korelasi_MK_CPL${includeSemester ? '_Dengan_Semester' : ''}_$timestamp.pdf';
    final file = File('${downloadsDir.path}/$filename');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Build courses CPL correlation table
  static pw.Widget _buildCoursesCPLCorrelationTable(
    List<Matakuliah> matakuliahList,
    List<CPLMaster> cplList,
    Map<int, List<CPMK>> matakuliahCPMKMap,
    Map<int, List<int>> cpmkCPLMapping, {
    Map<int, List<String>>? rpsRCPLMappings, // Map of matakuliah.id -> List<cpl_code> from RPS
    bool includeSemester = false,
    String language = 'id',
  }) {
    final isEnglish = language == 'en';

    // Sort matakuliah by kode
    final sortedMatakuliah = matakuliahList.toList()
      ..sort((a, b) => a.kode.compareTo(b.kode));

    // Sort CPL by nomor
    final sortedCPL = cplList.toList()
      ..sort((a, b) {
        final aNum = int.tryParse(a.nomor) ?? 0;
        final bNum = int.tryParse(b.nomor) ?? 0;
        return aNum.compareTo(bNum);
      });

    // Build headers
    final headers = <String>[
      isEnglish ? 'Code' : 'Kode',
      isEnglish ? 'Course Name' : 'Nama Mata Kuliah',
    ];
    if (includeSemester) {
      headers.add(isEnglish ? 'Semester' : 'Semester');
    }

    final cplPrefix = isEnglish ? 'PLO' : 'CPL';
    headers.addAll(sortedCPL.map((cpl) => '$cplPrefix${cpl.nomor}'));

    // Build rows
    final List<List<pw.Widget>> rows = [];

    for (final mk in sortedMatakuliah) {
      if (mk.id == null) continue;

      final row = <pw.Widget>[
        pw.Text(
          mk.kode,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          isEnglish ? (mk.namaEng ?? mk.nama) : mk.nama,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ];
      if (includeSemester) {
        row.add(
          pw.Text(
            mk.semester,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        );
      }

      // Get CPMK for this matakuliah
      final cpmkList = matakuliahCPMKMap[mk.id] ?? [];
      
      // Get RPS CPL mappings for this matakuliah (if available)
      final rpsCplMappings = rpsRCPLMappings?[mk.id] ?? [];
      
      // For each CPL, check if any CPMK of this matakuliah is mapped to it
      // OR if it's mapped in RPS
      for (final cpl in sortedCPL) {
        if (cpl.id == null) {
          row.add(pw.Text(''));
          continue;
        }

        // Check if any CPMK of this matakuliah maps to this CPL
        bool hasMappingToCPL = false;

        // First check CPMK-CPL mapping
        for (final cpmk in cpmkList) {
          if (cpmk.id != null && cpmkCPLMapping.containsKey(cpmk.id)) {
            final mappedCPLIds = cpmkCPLMapping[cpmk.id] ?? [];
            if (mappedCPLIds.contains(cpl.id)) {
              hasMappingToCPL = true;
              break;
            }
          }
        }
        
        // Then check RPS CPL mapping
        if (!hasMappingToCPL && rpsCplMappings.isNotEmpty) {
          // Check if this CPL is in RPS mappings (CPL code like "CPL.1", "CPL.2", etc)
          hasMappingToCPL = rpsCplMappings.contains(cpl.nomor) ||
                           rpsCplMappings.contains('CPL.${cpl.nomor}') ||
                           (cpl.id != null && rpsCplMappings.contains(cpl.id.toString()));
        }

        row.add(
          pw.Text(
            hasMappingToCPL ? 'V' : '',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: hasMappingToCPL ? PdfColors.green : PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
          ),
        );
      }

      rows.add(row);
    }

    // Calculate column widths
    final codeWidth = pw.FixedColumnWidth(60);
    final nameWidth = pw.FixedColumnWidth(140);
    final cplWidth = pw.FixedColumnWidth(35);

    final columnWidths = <int, pw.FixedColumnWidth>{
      0: codeWidth,
      1: nameWidth,
    };
    if (includeSemester) {
      columnWidths[2] = pw.FixedColumnWidth(60);
    }

    for (int i = includeSemester ? 3 : 2; i < headers.length; i++) {
      columnWidths[i] = cplWidth;
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
                    fontSize: 9,
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
                    style: const pw.TextStyle(fontSize: 9),
                    child: cell,
                  ),
                );
              }).toList(),
            );
          }),
        ],
    );
  }

  static pw.Widget _buildPLOCourseSemesterMappingTable(
    List<Matakuliah> matakuliahList,
    List<CPLMaster> cplList,
    Map<int, List<CPMK>> matakuliahCPMKMap,
    Map<int, List<int>> cpmkCPLMapping, {
    Map<int, List<String>>? rpsRCPLMappings,
    String language = 'id',
  }) {
    final isEnglish = language == 'en';
    final sortedMatakuliah = matakuliahList.where((mk) => mk.id != null).toList()
      ..sort((a, b) => a.kode.compareTo(b.kode));

    final allSemesters = sortedMatakuliah.map((mk) => mk.semester).toSet().toList();
    allSemesters.sort((a, b) {
      final aNum = int.tryParse(a) ?? double.tryParse(a)?.toInt();
      final bNum = int.tryParse(b) ?? double.tryParse(b)?.toInt();
      if (aNum != null && bNum != null) return aNum.compareTo(bNum);
      return a.compareTo(b);
    });

    final fixedSemesterKeys = List.generate(8, (index) => '${index + 1}');
    final fixedSemesterHeaders = List.generate(8, (index) => 'Semester ${index + 1}');

    final cplById = {for (final cpl in cplList.where((cpl) => cpl.id != null)) cpl.id!: cpl};

    final Map<int, Map<String, List<Matakuliah>>> coursesByCplAndSemester = {};

    for (final mk in sortedMatakuliah) {
      final cplIds = <int>{};

      final cpmkList = matakuliahCPMKMap[mk.id] ?? [];
      for (final cpmk in cpmkList) {
        final mapped = cpmkCPLMapping[cpmk.id] ?? [];
        cplIds.addAll(mapped);
      }

      final rpsMappings = rpsRCPLMappings?[mk.id] ?? [];
      for (final raw in rpsMappings) {
        final normalized = raw.trim();
        if (normalized.isEmpty) continue;
        final numberMatch = RegExp(r'^(?:CPL\.)?(\d+)$').firstMatch(normalized);
        if (numberMatch != null) {
          final nomor = numberMatch.group(1);
          if (nomor != null) {
            final matchedCpl = cplList.firstWhere(
              (cpl) => cpl.nomor == nomor,
              orElse: () => CPLMaster(
                id: null,
                kodeCPL: 'CPL.$nomor',
                deskripsi: '',
                nomor: nomor,
                createdAt: DateTime.now(),
              ),
            );
            if (matchedCpl.id != null) {
              cplIds.add(matchedCpl.id!);
            }
          }
        }
      }

      for (final cplId in cplIds) {
        final semesterMap = coursesByCplAndSemester.putIfAbsent(cplId, () => {});
        final list = semesterMap.putIfAbsent(mk.semester, () => []);
        list.add(mk);
      }
    }

    final headers = <String>[
      isEnglish ? 'PLO Code' : 'Kode CPL',
      isEnglish ? 'PLO Description' : 'Deskripsi CPL',
      ...fixedSemesterHeaders,
    ];

    final rows = <List<pw.Widget>>[];
    for (final cpl in cplList.where((cpl) => cpl.id != null)) {
      final mapping = coursesByCplAndSemester[cpl.id!] ?? {};
      final row = <pw.Widget>[
        pw.Text(isEnglish ? 'PLO.${cpl.nomor}' : 'CPL.${cpl.nomor}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.center),
        pw.Text(cpl.deskripsi,
            style: const pw.TextStyle(fontSize: 9)),
      ];

      for (final semester in fixedSemesterKeys) {
        final courses = mapping[semester] ?? mapping['Semester $semester'] ?? [];
        if (courses.isEmpty) {
          row.add(pw.Text(''));
          continue;
        }

        row.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: courses.map((mk) {
              return pw.Text(
                '${mk.kode} - ${isEnglish ? (mk.namaEng ?? mk.nama) : mk.nama}',
                style: const pw.TextStyle(fontSize: 8),
              );
            }).toList(),
          ),
        );
      }

      rows.add(row);
    }

    final columnWidths = <int, pw.FixedColumnWidth>{
      0: pw.FixedColumnWidth(60),
      1: pw.FixedColumnWidth(180),
    };
    for (int i = 2; i < headers.length; i++) {
      columnWidths[i] = pw.FixedColumnWidth(80);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey300),
          children: headers.map((h) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                h,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),
        ...rows.map((row) {
          return pw.TableRow(
            children: row.map((cell) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.DefaultTextStyle(
                  style: const pw.TextStyle(fontSize: 8),
                  child: cell,
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  /// Generate Per Angkatan All Matakuliah Report PDF
  static Future<File> generatePerAngkatanAllMatakuliahReport({
    required int angkatan,
    required Map<int, Map<String, dynamic>> mkResultsMap,
    required List<CPLMaster> cplList,
    String language = 'id',
  }) async {
    final pdf = pw.Document();

    // Load logo from assets (if exists)
    Uint8List? logoBytes;
    try {
      logoBytes = (await rootBundle.load('assets/logocpl.png')).buffer.asUint8List();
    } catch (e) {
      // Logo not found, continue without it
    }

    final isEnglish = language == 'en';
    final pageFormat = PdfPageFormat.a4;
    const marginSize = 20.0;

    // Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(marginSize),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoBytes != null) ...[
                  pw.Image(pw.MemoryImage(logoBytes), height: 80),
                  pw.SizedBox(height: 20),
                ],
                pw.Text(
                  isEnglish ? 'CLO & CPL Report' : 'Laporan CPL & CPMK',
                  style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  isEnglish ? 'Academic Year Cohort: $angkatan' : 'Tahun Angkatan: $angkatan',
                  style: pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  isEnglish
                      ? 'All Courses / Semua Mata Kuliah'
                      : 'Semua Mata Kuliah',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  DateFormat('dd MMMM yyyy', isEnglish ? 'en' : 'id').format(DateTime.now()),
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );

    // SUMMARY PAGE - Ringkasan semua Mata Kuliah dengan Nilai CPL
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          pw.Text(
            isEnglish
                ? 'Summary: Course Learning Outcomes (CLO) by Course - Cohort $angkatan'
                : 'Ringkasan: Nilai CPMK per Mata Kuliah - Angkatan $angkatan',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 15),

          if (mkResultsMap.isNotEmpty)
            pw.TableHelper.fromTextArray(
              context: context,
              data: _buildMatakuliahCplTable(mkResultsMap, language: language),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              cellStyle: const pw.TextStyle(fontSize: 8),
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
                  ? 'No course data available for this cohort.'
                  : 'Tidak ada data mata kuliah untuk angkatan ini.',
              style: const pw.TextStyle(fontSize: 11),
            ),

          pw.SizedBox(height: 20),
          _buildFooter(language: language),
        ],
      ),
    );

    // Content Pages - One per Matakuliah
    for (final entry in mkResultsMap.entries) {
      final mkData = entry.value;
      
      final matakuliah = mkData['matakuliah'] as Matakuliah;
      final mahasiswaList = (mkData['mahasiswaList'] as List?)?.cast<Mahasiswa>() ?? [];
      final calculationResults = (mkData['calculationResults'] as Map<int, OBECalculationResult>?) ?? {};

      if (mahasiswaList.isEmpty || calculationResults.isEmpty) {
        continue; // Skip if no data
      }

      // Build table data
      final tableData = <List<String>>[];
      tableData.add([
        isEnglish ? 'No' : 'No',
        isEnglish ? 'Student ID' : 'NIM',
        isEnglish ? 'Name' : 'Nama',
        isEnglish ? 'Avg CLO' : 'Rata-Rata CPMK',
        isEnglish ? 'Avg PLO' : 'Rata-Rata CPL',
      ]);

      int rowNo = 1;
      for (final mahasiswa in mahasiswaList) {
        if (mahasiswa.id == null || !calculationResults.containsKey(mahasiswa.id)) {
          continue;
        }

        final result = calculationResults[mahasiswa.id!]!;
        
        // Calculate averages
        final avgCpmk = result.cpmkValues.isNotEmpty
            ? (result.cpmkValues.values.reduce((a, b) => a + b) / result.cpmkValues.length)
            : 0.0;
        
        final avgCpl = result.cplValues.isNotEmpty
            ? (result.cplValues.values.reduce((a, b) => a + b) / result.cplValues.length)
            : 0.0;

        tableData.add([
          '$rowNo',
          mahasiswa.nim,
          mahasiswa.nama,
          avgCpmk.toStringAsFixed(2),
          avgCpl.toStringAsFixed(2),
        ]);

        rowNo++;
      }

      // Add page for this matakuliah
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: const pw.EdgeInsets.all(marginSize),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${matakuliah.kode} - ${matakuliah.namaEng ?? matakuliah.nama}',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  isEnglish
                      ? 'Academic Year Cohort: $angkatan'
                      : 'Tahun Angkatan: $angkatan',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 16),
                
                // Table
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
                  cellAlignment: pw.Alignment.center,
                  headerAlignment: pw.Alignment.center,
                  cellPadding: const pw.EdgeInsets.all(6),
                  headerDecoration: pw.BoxDecoration(
                    color: PdfColors.blueGrey700,
                  ),
                  headerHeight: 25,
                  headerStyle: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  data: tableData,
                ),

                pw.Spacer(),
                _buildFooter(language: language),
              ],
            );
          },
        ),
      );
    }

    final outputDir = await _getDownloadsDirectory();
    final fileName = 'Laporan_Angkatan_${angkatan}_AllMK_${DateTime.now().toString().split(' ')[0]}.pdf';
    final outputFile = File('${outputDir.path}\\$fileName');

    await outputFile.writeAsBytes(await pdf.save());

    return outputFile;
  }

  /// Helper: Build per Matakuliah CPL table (Mata Kuliah dengan Nilai CPL rata-rata)
  static List<List<String>> _buildMatakuliahCplTable(
    Map<int, Map<String, dynamic>> mkResultsMap, {
    String language = 'id',
  }) {
    final isEnglish = language == 'en';
    final ploPrefixLabel = isEnglish ? 'PLO' : 'Nilai CPL';
    
    // Build header
    final rows = <List<String>>[
      [
        isEnglish ? 'Course Code' : 'Kode Mata Kuliah',
        isEnglish ? 'Course Name' : 'Nama Mata Kuliah',
        '$ploPrefixLabel.1',
        '$ploPrefixLabel.2',
        '$ploPrefixLabel.3',
        '$ploPrefixLabel.4',
        '$ploPrefixLabel.5',
        '$ploPrefixLabel.6',
        '$ploPrefixLabel.7',
      ],
    ];

    if (mkResultsMap.isEmpty) {
      return rows;
    }

    // Sort mata kuliah by kode
    final sortedEntries = mkResultsMap.entries.toList()
      ..sort((a, b) {
        final mkA = a.value['matakuliah'] as Matakuliah?;
        final mkB = b.value['matakuliah'] as Matakuliah?;
        return (mkA?.kode ?? '').compareTo(mkB?.kode ?? '');
      });

    for (final entry in sortedEntries) {
      final mkData = entry.value;
      final matakuliah = mkData['matakuliah'] as Matakuliah?;
      final calculationResults = (mkData['calculationResults'] as Map<int, OBECalculationResult>?) ?? {};

      if (matakuliah == null || calculationResults.isEmpty) {
        continue;
      }

      // Collect CPL values for each CPL code (1-7)
      final cplSums = <int, double>{};
      final cplCounts = <int, int>{};

      for (final result in calculationResults.values) {
        final cplValues = result.cplValues;
        for (int cplCode = 1; cplCode <= 7; cplCode++) {
          final value = cplValues[cplCode.toString()];
          if (value != null) {
            cplSums[cplCode] = (cplSums[cplCode] ?? 0.0) + value;
            cplCounts[cplCode] = (cplCounts[cplCode] ?? 0) + 1;
          }
        }
      }

      // Build row with average CPL values
      final rowData = [
        matakuliah.kode,
        matakuliah.namaEng ?? matakuliah.nama,
      ];

      // Add average CPL values for codes 1 to 7
      for (int cplCode = 1; cplCode <= 7; cplCode++) {
        if (cplCounts.containsKey(cplCode) && cplCounts[cplCode]! > 0) {
          final average = cplSums[cplCode]! / cplCounts[cplCode]!;
          rowData.add(average.toStringAsFixed(2));
        } else {
          rowData.add('-');
        }
      }

      rows.add(rowData);
    }

    return rows;
  }

  /// Helper: Build footer
  static pw.Widget _buildFooter({String language = 'id'}) {
    final isEnglish = language == 'en';
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
      ),
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isEnglish ? 'Generated by CPL System' : 'Dibuat oleh Sistem CPL',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
          ),
          pw.Text(
            DateFormat('HH:mm:ss').format(DateTime.now()),
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }
}
