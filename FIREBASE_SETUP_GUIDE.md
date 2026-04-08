# 🚀 Panduan Setup Firebase untuk CPL Online

## 1️⃣ STEP 1: Setup Firebase Project

### A. Buat Firebase Project Baru

1. Buka https://console.firebase.google.com/
2. Klik **"Buat Proyek Baru"**
3. Nama proyek: `CPL-Online` (atau nama pilihan Anda)
4. **Jangan aktifkan Google Analytics** (untuk kesederhanaan)
5. Klik **"Buat proyek"** dan tunggu selesai

### B. Registrasi Web App

1. Di Firebase Console, klik **"Tambahkan aplikasi"** → pilih **"Web"** (icon `</>`))
2. Nama aplikasi: `CPL-Web-App`
3. Batalkan **"Setup Firebase Hosting"** untuk sekarang
4. Klik **"Daftar aplikasi"**
5. **COPY firebase config** yang muncul:

```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef123456"
};
```

---

## 2️⃣ STEP 2: Update Firebase Credentials di Flutter

### A. Update `lib/firebase_options.dart`

Ganti `YOUR_*` values dengan data dari Firebase Config di atas:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',           // ← dari firebase config
  appId: '1:SENDER_ID:web:APP_ID',  // ← format: 1:messagingSenderId:web:appId
  messagingSenderId: 'SENDER_ID',   // ← dari firebase config
  projectId: 'your-project-id',     // ← dari firebase config
  authDomain: 'your-project.firebaseapp.com',
  databaseURL: 'https://your-project.firebaseio.com',
  storageBucket: 'your-project.appspot.com',
);
```

---

## 3️⃣ STEP 3: Setup Firestore Database

### A. Aktifkan Firestore

1. Di Firebase Console, buka **"Firestore Database"** (di menu kiri)
2. Klik **"Buat Database"**
3. Pilih region: **`asia-southeast2`** (untuk Indonesia/Singapore)
4. Mode keamanan: **"Mulai dalam mode tes"** (untuk development, ganti nanti)
5. Klik **"Buat"**

### B. Setup Security Rules

Setelah Firestore dibuat, buka **"Rules"** dan ganti dengan:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Hanya authenticated users yang bisa akses
    match /{document=**} {
      allow read, write: if request.auth != null;
    }

    // Mahasiswa hanya bisa access data mereka sendiri
    match /mahasiswa/{docId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == docId || isAdmin();
    }

    // Admin bisa akses semua
    match /cpl/{docId} {
      allow read, write: if isAdmin();
    }
    
    match /cpmk/{docId} {
      allow read, write: if isAdmin();
    }

    match /sub_cpmk/{docId} {
      allow read, write: if isAdmin();
    }
  }

  function isAdmin() {
    return request.auth.token.isAdmin == true;
  }
}
```

**Publish rules** dengan klik tombol "Publikasikan"

### C. Setup Collections di Firestore

Buat collections berikut (bisa lewat console):

```
firestore-root/
├── users/
├── mahasiswa/
├── matakuliah/
├── nilai/
├── rps/
├── rps_detail/
├── cpl/
├── cpl_master/
├── cpmk/
├── sub_cpmk/
├── cpmk_cpl_mapping/
├── assessment_type/
└── nilai_komponen/
```

Atau buat otomatis dengan menjalankan script di console:

```javascript
// Firebase Cloud Function (optional, untuk auto-create collections)
exports.initializeDatabase = functions.auth.user().onCreate(async (user) => {
  const db = admin.firestore();
  
  // Create user document
  await db.collection('users').doc(user.uid).set({
    uid: user.uid,
    email: user.email,
    role: 'mahasiswa',
    isActive: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
});
```

---

## 4️⃣ STEP 4: Setup Firebase Authentication

### A. Aktifkan Email/Password Authentication

1. Di Firebase Console, buka **"Authentication"**
2. Buka tab **"Sign-in method"**
3. Klik **"Email/Password"** dan aktifkan
4. Klik **"Simpan"**

### B. (Optional) Setup Custom Claims untuk Admin

Jalankan di Cloud Functions Console:

```javascript
const admin = require('firebase-admin');

admin.auth().setCustomUserClaims(uid, {isAdmin: true})
  .then(() => {
    console.log('Custom claims updated');
  });
```

---

## 5️⃣ STEP 5: Konfigurasi Flutter untuk Web

### A. Enable Web Platform

```bash
flutter config --enable-web
flutter devices  # Should show "Chrome" device
```

### B. Update `pubspec.yaml` (sudah dilakukan)

Pastikan sudah punya:
```yaml
dependencies:
  firebase_core: ^3.8.0
  cloud_firestore: ^5.2.0
  firebase_auth: ^5.3.0
  firebase_storage: ^12.2.0
```

### C. Get Dependencies

```bash
cd e:\1. S2 Fisika\5. Tesis\Flutter\chili_app\CPL\cpl
flutter pub get
```

---

## 6️⃣ STEP 6: Setup Firebase Hosting

### A. Install Firebase CLI

```bash
# Install Node.js terlebih dahulu dari https://nodejs.org

npm install -g firebase-tools
firebase login
```

### B. Initialize Firebase Project

```bash
cd e:\1. S2 Fisika\5. Tesis\Flutter\chili_app\CPL\cpl
firebase init hosting
```

Jawab pertanyaan:
- **Project**: pilih project yang sudah dibuat (`cpl-online`)
- **Public directory**: `build/web`
- **Single page app**: `y` (yes)
- **Overwrite**: `n` (no)
- **Automatic deploys**: `n` (no, untuk sekarang)

---

## 7️⃣ STEP 7: Build & Deploy Web App

### A. Build Flutter Web

```bash
flutter clean
flutter pub get
flutter build web --release
```

**Output** akan ada di: `build/web/`

### B. Deploy ke Firebase Hosting

```bash
firebase deploy --only hosting
```

Tunggu `✔ Deploy complete!` muncul.

### C. Akses Online

URL akan muncul seperti:
```
https://your-project-id.web.app
```

Buka di browser dan test aplikasi!

---

## 8️⃣ STEP 8: Troubleshooting

### Error: "Firebase is not initialized"

**Solusi:**
- Pastikan `firebase_options.dart` punya credentials yang benar
- Restart app: `flutter run -d chrome`

### Error: "Permission denied" di Firestore

**Solusi:**
- Check Firestore security rules
- Pastikan user sudah authenticated
- Di development, coba mode test rules (tidak aman untuk production!)

### Error: "Web app is not registered"

**Solusi:**
- Buka Firebase Console → Project Settings
- Di tab "Apps", pastikan web app terdaftar
- Copy ulang credentials ke `firebase_options.dart`

### Firestore Collection tidak muncul setelah insert

**Solusi:**
- Collections otomatis dibuat ketika ada dokumen pertama
- Pastikan `addMahasiswa()` dll benar-benar dipanggil
- Check di Firebase Console → Firestore → Data

---

## 9️⃣ Tips & Deployment Checklist

### Pre-Production Checklist:

- [ ] Semua environment variables sudah di-set
- [ ] Firestore rules sudah di-publish (bukan mode test!)
- [ ] Firebase Authentication sudah aktif
- [ ] Web app bisa diakses online
- [ ] Semua CRUD operations sudah tested
- [ ] Error handling sudah di-implement
- [ ] Loading indicators sudah ada

### Production Security:

```javascript
// JANGAN PAKAI DI PRODUCTION!
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    allow read, write: if request.auth != null;
  }
}

// PAKAI INI DI PRODUCTION:
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Public read, no write
    match /public/{document=**} {
      allow read: if true;
      allow write: if false;
    }
    
    // Private user data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Admin only
    match /admin/{document=**} {
      allow read, write: if request.auth.token.isAdmin == true;
    }
  }
}
```

---

## 🔟 Untuk Development Selanjutnya

### Session Memory File

Local development commands:
```bash
# Build web
flutter build web --release

# Deploy
firebase deploy --only hosting

# Check logs
firebase apps:list
firebase database:instances:list
```

### Backup Data dari SQLite

Sebelum migration, export data dari SQLite:

```dart
// Di database_helper.dart
Future<Map<String, dynamic>> exportAllData() async {
  final db = await database;
  return {
    'mahasiswa': await db.query('mahasiswa'),
    'matakuliah': await db.query('matakuliah'),
    'nilai': await db.query('nilai'),
    'rps': await db.query('rps'),
    'cpl': await db.query('cpl'),
    'cpmk': await db.query('cpmk'),
  };
}
```

---

## ✅ Selesai!

Aplikasi CPL Anda sekarang bisa diakses online via Firebase! 🎉

Untuk update/deploy berikutnya, tinggal:
1. Edit code
2. `flutter build web --release`
3. `firebase deploy --only hosting`

Setiap deploy akan go live otomatis ke `https://your-project-id.web.app`
