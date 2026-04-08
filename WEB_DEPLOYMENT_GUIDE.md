# 🌐 Panduan Deployment Flutter Web ke Firebase Hosting

## Prerequisites

Pastikan sudah install:

- ✅ Flutter SDK (3.9+)
- ✅ Node.js (v16+)
- ✅ Firebase CLI
- ✅ Git (optional)

---

## 1️⃣ Setup Firebase Hosting

### A. Login ke Firebase CLI

```bash
firebase login
```

Browser akan terbuka, login dengan Google account.

### B. Initialize Firebase Project

```bash
cd e:\1. S2 Fisika\5. Tesis\Flutter\chili_app\CPL\cpl

firebase init hosting
```

**Jawab pertanyaan:**

```
? Which Firebase project do you want to associate with this directory?
→ Pilih project CPL Anda (e.g., cpl-online-12345)

? What do you want to use as your public directory?
→ build/web

? Configure as a single-page app (rewrite all urls to /index.html)?
→ y (yes)

? Set up automatic deploys with GitHub?
→ n (no, bisa setup nanti)
```

**Output:**
```
✔ Firebase initialization complete!
```

---

## 2️⃣ Prepare Flutter Web Build

### A. Clean & Get Dependencies

```bash
flutter clean
flutter pub get
```

### B. Build Web Release

```bash
flutter build web --release
```

**Expected output:**
```
✓ Build web complete (5.2MB).
```

Cek structure:
```
build/
└── web/
    ├── index.html
    ├── main.dart.js
    ├── assets/
    └── ... dll
```

---

## 3️⃣ Configure Firebase for Web

### A. Update `firebase.json`

```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      },
      {
        "source": "/index.html",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=0"
          }
        ]
      }
    ]
  }
}
```

### B. Test Locally

```bash
firebase emulators:start
```

Atau:

```bash
firebase serve
```

Buka: http://localhost:5000

---

## 4️⃣ Deploy ke Firebase Hosting

### A. Deploy

```bash
firebase deploy --only hosting
```

### B. Monitor Deployment

```
  i  deploying hosting
  i  starting release process...

  ✔  Deploy complete!

Project Console: https://console.firebase.google.com/project/your-project-id/overview
Hosting URL: https://your-project-id.web.app
```

### C. Akses Live App

Buka: `https://your-project-id.web.app`

---

## 🔄 Update & Redeploy

Untuk update app setelah development:

```bash
# 1. Code changes...
# 2. Rebuild
flutter build web --release

# 3. Deploy
firebase deploy --only hosting
```

**That's it!** Changes go live within seconds.

---

## 🔐 Security & Performance

### A. HTTPS (Automatic)

Firebase Hosting secara otomatis provide HTTPS → ✅

### B. CDN & Caching

Firebase Hosting punya built-in CDN:
- JavaScript (.js) files: cache 1 tahun
- index.html: no cache (always fresh)

### C. Security Headers

Update `firebase.json`:

```json
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "X-Frame-Options",
            "value": "SAMEORIGIN"
          },
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          },
          {
            "key": "X-XSS-Protection",
            "value": "1; mode=block"
          },
          {
            "key": "Referrer-Policy",
            "value": "strict-origin-when-cross-origin"
          }
        ]
      }
    ]
  }
}
```

Redeploy:
```bash
firebase deploy --only hosting
```

---

## 📊 Monitor & Analytics

### A. Check Hosting Usage

Firebase Console → Hosting → Usage

### B. Check App Performance

Firebase Console → Performance Monitoring

### C. View Logs

```bash
firebase functions:log
```

---

## 🆘 Common Issues & Fixes

### Issue 1: "404 Not Found" after deployment

**Cause:** SPA routing not configured

**Fix:** Pastikan `firebase.json` punya `rewrites`:

```json
{
  "hosting": {
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

### Issue 2: "Cannot POST /api/..."

**Cause:** Firebase Hosting is static hosting only, no backend.

**Solutions:**
- Use Firebase Cloud Functions (backend)
- Use Firestore (database)
- Use Firebase Authentication (auth)

### Issue 3: Assets (images) not loading

**Cause:** Wrong asset path

**Fix:** Pastikan di `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/
```

Dan di code:
```dart
Image.asset('assets/logo.png')  // ✅ CORRECT
# NOT: Image.asset('/assets/logo.png')  // ❌ WRONG
```

### Issue 4: CORS errors di browser console

**Cause:** Firestore rules too restrictive

**Fix:** Update Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Issue 5: Cannot authenticate (Firebase returns error)

**Cause:** Web app credentials not correct in `firebase_options.dart`

**Fix:** Copy dari Firebase Console → Project Settings:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'AIzaSyD...',  // Exact dari console
  appId: '1:123456789:web:abc123',
  messagingSenderId: '123456789',
  projectId: 'your-project-id',
  authDomain: 'your-project-id.firebaseapp.com',
  databaseURL: 'https://your-project-id.firebaseio.com',
  storageBucket: 'your-project-id.appspot.com',
);
```

---

## 🚀 Advanced: Custom Domain

### A. Setup Custom Domain

Firebase Console → Hosting → Add Custom Domain

### B. Update DNS Records

Follow Firebase instructions untuk update domain DNS.

### C. Verify Domain

DNS verification otomatis setelah 24 jam.

---

## 🔄 CI/CD Integration (GitHub Actions)

Otomatis deploy on push:

**File:** `.github/workflows/deploy.yml`

```yaml
name: Deploy to Firebase

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
      
      - name: Build Web
        run: |
          flutter clean
          flutter pub get
          flutter build web --release
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-project-id
```

Setup GitHub Secrets:
1. Firebase Console → Project Settings → Service Accounts
2. Generate new key → Save as JSON
3. GitHub → Settings → Secrets → Add `FIREBASE_SERVICE_ACCOUNT`

---

## 📈 Scaling & Performance Tips

### 1. Enable Compression

```bash
# Build dengan compression
flutter build web --release --dart-obfuscation
```

### 2. Image Optimization

```dart
Image.asset(
  'assets/logo.png',
  cacheWidth: 300,
  cacheHeight: 300,
)
```

### 3. Lazy Loading Routes

```dart
// Instead of importing all screens at top
import 'screens/login_screen.dart';

// Load dynamically
home: FutureBuilder(
  future: _loadScreen(),
  builder: (ctx, snapshot) => snapshot.data ?? LoadingScreen(),
)
```

### 4. Enable HTTP/2 Push

Firebase Hosting sudah support HTTP/2 otomatis.

---

## 📋 Production Checklist

- [ ] App tested locally (`flutter run -d chrome`)
- [ ] Web build successful (`flutter build web --release`)
- [ ] No console errors
- [ ] Responsive design tested (mobile, tablet, desktop)
- [ ] All images & assets loading
- [ ] Authentication working
- [ ] Database read/write working
- [ ] Security rules published (not test mode!)
- [ ] Firebase credentials correct
- [ ] `firebase.json` configured
- [ ] Deployed to Firebase Hosting
- [ ] Live URL accessible
- [ ] Performance acceptable (<3s load)
- [ ] No 404 errors
- [ ] Mobile-responsive tested

---

## 🎯 Final Summary

**Your app is now live! 🎉**

- 🌐 Access: https://your-project-id.web.app
- 🔄 Update: `flutter build web --release && firebase deploy`
- 📊 Monitor: Firebase Console
- 🔐 Secure: Built-in HTTPS + security headers
- ⚡ Fast: Global CDN

---

## 🔗 Useful Links

- Firebase Console: https://console.firebase.google.com/
- Firebase Docs: https://firebase.flutter.dev/
- Flutter Web: https://flutter.dev/web
- Firebase Hosting: https://firebase.google.com/products/hosting

---

✅ Selesai! Aplikasi CPL sudah online! 🚀
