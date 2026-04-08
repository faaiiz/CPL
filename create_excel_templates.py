#!/usr/bin/env python3
"""
Script untuk membuat file template Excel untuk import data
"""

import xlsxwriter

def create_mahasiswa_template():
    """Membuat template Excel untuk Mahasiswa"""
    workbook = xlsxwriter.Workbook('templates_import/mahasiswa_template.xlsx')
    worksheet = workbook.add_worksheet('Mahasiswa')
    
    # Define formats
    header_format = workbook.add_format({
        'bold': True,
        'font_color': 'white',
        'bg_color': '#366092',
        'align': 'center',
        'valign': 'vcenter',
        'border': 1
    })
    
    data_format = workbook.add_format({
        'border': 1,
        'align': 'left',
        'valign': 'vcenter'
    })
    
    # Add headers
    headers = ["NIM", "Nama", "Tahun Masuk", "Status"]
    for col_num, header in enumerate(headers):
        worksheet.write(0, col_num, header, header_format)
    
    # Add sample data
    sample_data = [
        ["22001", "Budi Santoso", 2022, "aktif"],
        ["22002", "Siti Nurhaliza", 2022, "aktif"],
        ["22003", "Ahmad Wijaya", 2023, "aktif"],
        ["22004", "Dewi Lestari", 2023, "aktif"],
        ["22005", "Rendi Gunawan", 2023, "aktif"],
    ]
    
    for row_num, row_data in enumerate(sample_data, 1):
        for col_num, value in enumerate(row_data):
            worksheet.write(row_num, col_num, value, data_format)
    
    # Set column widths
    worksheet.set_column(0, 0, 15)  # NIM
    worksheet.set_column(1, 1, 25)  # Nama
    worksheet.set_column(2, 2, 15)  # Tahun Masuk
    worksheet.set_column(3, 3, 15)  # Status
    
    workbook.close()
    print("✓ Created mahasiswa_template.xlsx")


def create_matakuliah_template():
    """Membuat template Excel untuk Matakuliah"""
    workbook = xlsxwriter.Workbook('templates_import/matakuliah_template.xlsx')
    worksheet = workbook.add_worksheet('Matakuliah')
    
    # Define formats
    header_format = workbook.add_format({
        'bold': True,
        'font_color': 'white',
        'bg_color': '#366092',
        'align': 'center',
        'valign': 'vcenter',
        'border': 1
    })
    
    data_format = workbook.add_format({
        'border': 1,
        'align': 'left',
        'valign': 'vcenter'
    })
    
    # Add headers
    headers = ["Kode", "Nama", "Semester", "Jenis", "SKS"]
    for col_num, header in enumerate(headers):
        worksheet.write(0, col_num, header, header_format)
    
    # Add sample data
    sample_data = [
        ["MAT101", "Matematika Dasar", "1", "wajib", 3],
        ["FIS101", "Fisika Dasar", "1", "wajib", 3],
        ["KIM101", "Kimia Dasar", "1", "wajib", 2],
        ["ENG101", "Bahasa Inggris", "1", "wajib", 2],
        ["PEM101", "Pemrograman Dasar", "1", "wajib", 3],
        ["ALG101", "Algoritma", "2", "wajib", 3],
        ["BDD101", "Basis Data", "2", "wajib", 3],
    ]
    
    for row_num, row_data in enumerate(sample_data, 1):
        for col_num, value in enumerate(row_data):
            worksheet.write(row_num, col_num, value, data_format)
    
    # Set column widths
    worksheet.set_column(0, 0, 12)  # Kode
    worksheet.set_column(1, 1, 30)  # Nama
    worksheet.set_column(2, 2, 12)  # Semester
    worksheet.set_column(3, 3, 15)  # Jenis
    worksheet.set_column(4, 4, 8)   # SKS
    
    workbook.close()
    print("✓ Created matakuliah_template.xlsx")


def create_nilai_template():
    """Membuat template Excel untuk Nilai"""
    workbook = xlsxwriter.Workbook('templates_import/nilai_template.xlsx')
    worksheet = workbook.add_worksheet('Nilai')
    instructions_sheet = workbook.add_worksheet('Instruksi')
    
    # Define formats
    header_format = workbook.add_format({
        'bold': True,
        'font_color': 'white',
        'bg_color': '#366092',
        'align': 'center',
        'valign': 'vcenter',
        'border': 1
    })
    
    data_format = workbook.add_format({
        'border': 1,
        'align': 'left',
        'valign': 'vcenter'
    })
    
    # Add headers
    headers = ["NIM", "Nama Mahasiswa", "Kode Matakuliah", "Nama Matakuliah", "Grade", "Nilai Numerik", "Tahun Ajaran"]
    for col_num, header in enumerate(headers):
        worksheet.write(0, col_num, header, header_format)
    
    # Add sample data
    sample_data = [
        ["22001", "Ahmad Rizki", "MAT101", "Matematika Dasar", "A", 4.0, "2024/2025"],
        ["22002", "Budi Santoso", "MAT101", "Matematika Dasar", "B", 3.0, "2024/2025"],
        ["22003", "Citra Dewi", "FIS101", "Fisika Dasar", "A", 4.0, "2024/2025"],
        ["22004", "Dedi Gunawan", "FIS101", "Fisika Dasar", "C", 2.0, "2024/2025"],
        ["22005", "Eka Putri", "KIM101", "Kimia Dasar", "B", 3.0, "2024/2025"],
        ["22001", "Ahmad Rizki", "PEM101", "Pemrograman Dasar", "A", 4.0, "2024/2025"],
        ["22002", "Budi Santoso", "ALG101", "Algoritma", "B", 3.0, "2024/2025"],
    ]
    
    for row_num, row_data in enumerate(sample_data, 1):
        for col_num, value in enumerate(row_data):
            worksheet.write(row_num, col_num, value, data_format)
    
    # Set column widths
    worksheet.set_column(0, 0, 12)  # NIM
    worksheet.set_column(1, 1, 20)  # Nama Mahasiswa
    worksheet.set_column(2, 2, 15)  # Kode Matakuliah
    worksheet.set_column(3, 3, 25)  # Nama Matakuliah
    worksheet.set_column(4, 4, 10)  # Grade
    worksheet.set_column(5, 5, 15)  # Nilai Numerik
    worksheet.set_column(6, 6, 15)  # Tahun Ajaran
    
    # Add instructions
    title_format = workbook.add_format({
        'bold': True,
        'font_size': 14
    })
    
    text_format = workbook.add_format({
        'text_wrap': True,
        'valign': 'top'
    })
    
    instructions_sheet.write('A1', "Panduan Import Nilai", title_format)
    
    instructions = [
        "",
        "Kolom yang diperlukan:",
        "1. NIM - Nomor Induk Mahasiswa (harus terdaftar di sistem)",
        "2. Nama Mahasiswa - Nama lengkap mahasiswa",
        "3. Kode Matakuliah - Kode matakuliah (harus terdaftar di sistem)",
        "4. Nama Matakuliah - Nama lengkap matakuliah",
        "5. Grade - Grade huruf (A, B, C, D, E)",
        "6. Nilai Numerik - Nilai angka (4.0 untuk A, 3.0 untuk B, 2.0 untuk C, 1.0 untuk D, 0.0 untuk E)",
        "7. Tahun Ajaran - Tahun ajaran (format: 2024/2025)",
        "",
        "Catatan:",
        "- Jangan ubah nama header kolom",
        "- NIM dan Kode Matakuliah harus sudah terdaftar di sistem",
        "- Grade hanya boleh: A, B, C, D, E",
        "- Nilai Numerik harus sesuai dengan Grade yang diberikan",
        "  * A = 4.0, B = 3.0, C = 2.0, D = 1.0, E = 0.0",
        "- Tahun Ajaran format: tahun/tahunberikutnya (contoh: 2024/2025)",
        "- Baris data bisa ditambah sesuai kebutuhan",
        "- Mahasiswa bisa memiliki beberapa nilai untuk matakuliah berbeda",
    ]
    
    for idx, instruction in enumerate(instructions, 1):
        instructions_sheet.write(idx, 0, instruction, text_format)
    
    instructions_sheet.set_column(0, 0, 100)
    
    workbook.close()
    print("✓ Created nilai_template.xlsx")


def create_rps_template():
    """Membuat template Excel untuk RPS (Rencana Pembelajaran Semester)"""
    workbook = xlsxwriter.Workbook('templates_import/rps_template.xlsx')
    worksheet = workbook.add_worksheet('RPS')
    instructions_sheet = workbook.add_worksheet('Instruksi')
    
    # Define formats
    header_format = workbook.add_format({
        'bold': True,
        'font_color': 'white',
        'bg_color': '#1F4E78',
        'align': 'center',
        'valign': 'vcenter',
        'border': 1,
        'text_wrap': True
    })
    
    data_format = workbook.add_format({
        'border': 1,
        'align': 'left',
        'valign': 'top',
        'text_wrap': True
    })
    
    number_format = workbook.add_format({
        'border': 1,
        'align': 'center',
        'valign': 'vcenter'
    })
    
    # Add headers - sesuai urutan yang benar: Minggu ke, Topik Pembelajaran, Metode Ajar, Jenis Penilaian, Bobot, Kode CPL, Kode CPMK, Kode Sub CPMK
    headers = [
        "Minggu Ke",
        "Topik Pembelajaran",
        "Metode Ajar",
        "Jenis Penilaian",
        "Bobot (%)",
        "Kode CPL",
        "Kode CPMK",
        "Kode Sub CPMK"
    ]
    
    for col_num, header in enumerate(headers):
        worksheet.write(0, col_num, header, header_format)
    
    # Add sample data (untuk referensi)
    sample_data = [
        [1, "Kinematika - Pendahuluan", "Small Group Discussion", "Aktivitas Partisipatif", 5, "CPL-1", "CPMK-01", "Sub-CPMK.01"],
        [2, "Kinematika - Gerak Lurus", "Discovery Learning", "Kuis", 5, "CPL-1", "CPMK-01", "Sub-CPMK.01"],
        [3, "Dinamika - Hukum Newton", "Cooperative Learning", "Tugas", 5, "CPL-2", "CPMK-02", "Sub-CPMK.02"],
        [4, "Energi dan Kerja", "Project Based Learning", "Hasil Proyek", 5, "CPL-2", "CPMK-02", "Sub-CPMK.02"],
        [5, "Momentum dan Impuls", "Small Group Discussion", "Aktivitas Partisipatif", 5, "CPL-3", "CPMK-03", "Sub-CPMK.03"],
        [6, "Rotasi Benda Tegar", "Discovery Learning", "Kuis", 5, "CPL-3", "CPMK-03", "Sub-CPMK.03"],
        [7, "Osilasi dan Gelombang", "Cooperative Learning", "Tugas", 5, "CPL-4", "CPMK-04", "Sub-CPMK.04"],
        [8, "Persiapan UTS", "", "", 0, "", "", ""],
        [9, "Termodinamika - Pendahuluan", "Small Group Discussion", "Aktivitas Partisipatif", 5, "CPL-4", "CPMK-05", "Sub-CPMK.05"],
        [10, "Hukum Termodinamika", "Discovery Learning", "Kuis", 5, "CPL-5", "CPMK-05", "Sub-CPMK.05"],
        [11, "Gas Ideal", "Cooperative Learning", "Tugas", 5, "CPL-5", "CPMK-06", "Sub-CPMK.06"],
        [12, "Elektromagnetik Dasar", "Project Based Learning", "Hasil Proyek", 5, "CPL-6", "CPMK-06", "Sub-CPMK.06"],
        [13, "Medan Magnet", "Small Group Discussion", "Aktivitas Partisipatif", 5, "CPL-6", "CPMK-07", "Sub-CPMK.07"],
        [14, "Induksi Elektromagnetik", "Discovery Learning", "Kuis", 5, "CPL-7", "CPMK-07", "Sub-CPMK.07"],
        [15, "Review dan Latihan Soal", "Cooperative Learning", "Tugas", 5, "CPL-7", "CPMK-07", "Sub-CPMK.07"],
        [16, "Ujian Akhir Semester (UAS)", "", "", 0, "", "", ""],
    ]
    
    for row_num, row_data in enumerate(sample_data, 1):
        for col_num, value in enumerate(row_data):
            if col_num == 0 or col_num == 4:  # Minggu Ke dan Bobot
                worksheet.write(row_num, col_num, value, number_format)
            else:
                worksheet.write(row_num, col_num, value, data_format)
    
    # Set column widths
    worksheet.set_column(0, 0, 11)   # Minggu Ke
    worksheet.set_column(1, 1, 30)   # Topik Pembelajaran
    worksheet.set_column(2, 2, 20)   # Metode Ajar
    worksheet.set_column(3, 3, 18)   # Jenis Penilaian
    worksheet.set_column(4, 4, 10)   # Bobot
    worksheet.set_column(5, 5, 12)   # Kode CPL
    worksheet.set_column(6, 6, 12)   # Kode CPMK
    worksheet.set_column(7, 7, 15)   # Kode Sub CPMK
    
    # Add Instruksi sheet
    title_format = workbook.add_format({
        'bold': True,
        'font_size': 14,
        'bg_color': '#1F4E78',
        'font_color': 'white',
        'align': 'left',
        'border': 1
    })
    
    text_format = workbook.add_format({
        'text_wrap': True,
        'valign': 'top'
    })
    
    instructions_sheet.write('A1', "Panduan Import RPS (Rencana Pembelajaran Semester)", title_format)
    
    instructions = [
        "",
        "KOLOM YANG DIPERLUKAN (Urutan dari kiri ke kanan):",
        "1. Minggu Ke - Nomor minggu pembelajaran (1-16)",
        "2. Topik Pembelajaran - Judul/deskripsi topik yang diajarkan",
        "3. Metode Ajar - Pilih dari daftar berikut:",
        "   • Small Group Discussion",
        "   • Discovery Learning",
        "   • Self Direct Learning",
        "   • Cooperative Learning",
        "   • Collaborative Learning",
        "   • Contextual Instruction",
        "   • Project Based Learning",
        "   • Case Based Learning",
        "4. Jenis Penilaian - Pilih dari daftar berikut:",
        "   • Aktivitas Partisipatif",
        "   • Kuis",
        "   • Tugas",
        "   • Hasil Proyek",
        "5. Bobot (%) - Persentase bobot pembelajaran (0-100)",
        "6. Kode CPL - Kode CPL (contoh: CPL-1, CPL-2)",
        "7. Kode CPMK - Kode CPMK (contoh: CPMK-01, CPMK-02)",
        "8. Kode Sub CPMK - Kode Sub CPMK (contoh: Sub-CPMK.01, Sub-CPMK.02)",
        "",
        "CATATAN PENTING:",
        "- JANGAN ubah nama header kolom",
        "- Minggu Ke hanya boleh: 1-16 (minggu 8 = UTS, minggu 16 = UAS)",
        "- Untuk UTS (minggu 8) dan UAS (minggu 16): Metode Ajar, Jenis Penilaian, Bobot, Kode CPL, Kode CPMK, Kode Sub CPMK boleh kosong",
        "- Metode Ajar harus salah satu dari daftar di atas",
        "- Jenis Penilaian harus salah satu dari daftar di atas",
        "- Total bobot per matakuliah harus = 100% untuk minggu pembelajaran (exclude UTS & UAS)",
        "- Kode CPL, CPMK, Sub CPMK harus sudah terdaftar di sistem",
        "- Baris data bisa ditambah sesuai kebutuhan (15-16 minggu pembelajaran)",
        "",
        "CARA PENGGUNAAN:",
        "1. Edit file ini sesuai data RPS Anda",
        "2. Pastikan urutan kolom dan format data BENAR",
        "3. Buka aplikasi CPL > Input RPS > Import RPS Excel",
        "4. Pilih file Excel ini",
        "5. Review data dan klik Simpan",
        "- Minggu Ke hanya boleh: 1-16 (minggu 8 = UTS, minggu 16 = UAS)",
        "- Untuk UTS (minggu 8) dan UAS (minggu 16): Topik, Metode, Jenis Penilaian, Sub CPMK boleh kosong",
        "- Total bobot per matakuliah TIDAK boleh melebihi 100%",
        "- Sub CPMK harus sudah dibuat di menu Input RPS terlebih dahulu",
        "- Baris data bisa ditambah sesuai kebutuhan",
        "- Total bobot harus tepat 100% untuk minggu 1-7, 9-15 (exclude UTS & UAS)",
        "",
        "CARA PENGGUNAAN:",
        "1. Edit file ini sesuai data RPS Anda",
        "2. Pastikan Kode Matakuliah dan Nama Matakuliah BENAR",
        "3. Buka aplikasi CPL > Input RPS > Import RPS Excel",
        "4. Pilih file Excel ini",
        "5. Pilih Matakuliah yang ingin di-import",
        "6. Review data dan klik Simpan",
    ]
    
    for idx, instruction in enumerate(instructions, 1):
        instructions_sheet.write(idx, 0, instruction, text_format)
    
    instructions_sheet.set_column(0, 0, 100)
    
    workbook.close()
    print("✓ Created rps_template.xlsx")


if __name__ == "__main__":
    try:
        create_mahasiswa_template()
        create_matakuliah_template()
        create_nilai_template()
        create_rps_template()
        print("\n✅ Semua template Excel berhasil dibuat!")
        print("   - templates_import/mahasiswa_template.xlsx")
        print("   - templates_import/matakuliah_template.xlsx")
        print("   - templates_import/nilai_template.xlsx")
        print("   - templates_import/rps_template.xlsx")
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
