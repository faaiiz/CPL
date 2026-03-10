# Bug Analysis Report: Measurement/Assessment Learning Outcomes Feature

## Summary
Found **17 critical/high-severity bugs** across three screens involving dropdown state management, null pointer exceptions, race conditions, and calculation logic errors.

---

## File 1: assessment_outcomes_screen.dart

### 🔴 BUG #1: Missing Null Safety in _selectedAngkatan Initialization
**Location:** Lines 27-28, 99-103  
**Severity:** HIGH  
**Issue:** `_selectedAngkatan` is initialized as `null`, and while `_loadData()` attempts to set it asynchronously, the dropdown on line 581-598 uses `value: _selectedAngkatan` directly. If the UI is rendered before data loads, the dropdown could show null value.

```dart
// Line 27 - initialized as null
int? _selectedAngkatan;

// Line 99-103 - set asynchronously
if (angkatanList.isNotEmpty) {
  _selectedAngkatan = angkatanList.first;  // This happens in setState after async
  _filterMahasiswaByAngkatan(angkatanList.first);
}
```

**Fix:** Ensure initial value is set before rendering, or use a guard:
```dart
if (_angkatanList.isEmpty) {
  return const SizedBox(child: Text('No data'));
}
DropdownButtonFormField<int>(
  value: _selectedAngkatan ?? _angkatanList.first,  // Provide default
  items: ...
)
```

---

### 🔴 BUG #2: Race Condition in Async loadData() with Missing Mounted Check
**Location:** Lines 43-105  
**Severity:** HIGH  
**Issue:** `_loadData()` is called without `await` in `initState()`, and setState is called inside the async function without checking if the widget is mounted. This can cause crashes if the screen is disposed before async completes.

```dart
@override
void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
  _loadData();  // Not awaited, starts async operation
}

// Inside _loadData() - line 97
setState(() {
  // Could crash if widget is disposed here
  _allMahasiswa = mahasiswaList;
  // ...
});
```

**Fix:** Add mounted check before setState:
```dart
if (mounted) {
  setState(() { ... });
}
```

---

### 🔴 BUG #3: Incorrect Score Averaging Logic
**Location:** Lines 237-243, 291-297  
**Severity:** HIGH  
**Issue:** The averaging calculation is fundamentally broken. When aggregating multiple values, the code does:
```dart
if (!cpmkScores.containsKey(cpmkId)) {
  cpmkScores[cpmkId] = nilaiCpmk;
} else {
  cpmkScores[cpmkId] = (cpmkScores[cpmkId]! + nilaiCpmk) / 2;  // ❌ WRONG
}
```

This produces incorrect averages. For example: with values [70, 80, 90]:
- First: sets to 70
- Second: (70 + 80) / 2 = 75
- Third: (75 + 90) / 2 = 82.5 ❌ (should be 80)

**Fix:** Use a counter or accumulation approach:
```dart
if (!cpmkValues.containsKey(cpmkId)) {
  cpmkValues[cpmkId] = {'sum': nilaiCpmk, 'count': 1};
} else {
  cpmkValues[cpmkId]['sum'] += nilaiCpmk;
  cpmkValues[cpmkId]['count']++;
}

// After loop:
final averages = cpmkValues.map((id, data) => 
  MapEntry(id, data['sum'] / data['count'])
);
```

---

### 🔴 BUG #4: Null Pointer Exception with Unvalidated mahasiswa.id
**Location:** Lines 163-166  
**Severity:** CRITICAL  
**Issue:** The code doesn't null-check `mahasiswa.id` before using it in database queries.

```dart
void _selectMahasiswa(Mahasiswa mahasiswa) {
  setState(() => _selectedMahasiswa = mahasiswa);
  _showLoadingDialog();
  _loadMahasiswaScores(mahasiswa);
}

void _loadMahasiswaScores(Mahasiswa mahasiswa) async {
  // Line 172 - direct unwrap without validation
  final nilaiList = await _dbHelper.getNilaiByMahasiswa(mahasiswa.id!);
  // If mahasiswa.id is null, this crashes
}
```

**Fix:** Add null check:
```dart
if (mahasiswa.id == null) {
  _showErrorDialog('Mahasiswa ID tidak valid');
  return;
}
final nilaiList = await _dbHelper.getNilaiByMahasiswa(mahasiswa.id!);
```

---

### 🔴 BUG #5: Loading Dialog Not Closed on Error
**Location:** Lines 327-336  
**Severity:** MEDIUM  
**Issue:** If an exception occurs in `_loadMahasiswaScores()`, the loading dialog might not be closed properly:

```dart
try {
  // ... operations
  if (mounted) {
    Navigator.of(context).pop();  // Only closed on success
  }
} catch (e) {
  print('❌ Error loading scores for mahasiswa: $e');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(...);
    Navigator.of(context).pop();  // Closed here
  }
}
```

The structure works, but there's no guarantee the dialog exists before trying to pop. If showLoadingDialog fails to display, pop() will fail.

**Fix:** Check if Navigator stack is valid or use a guard:
```dart
try {
  // ...
} catch (e) {
  if (mounted && Navigator.canPop(context)) {
    Navigator.pop(context);
  }
}
```

---

### 🔴 BUG #6: Missing Null Safety in CPMK/CPL ID Access
**Location:** Lines 226-230, 284-288  
**Severity:** MEDIUM  
**Issue:** Code assumes CPMK and CPL objects have non-null IDs:

```dart
for (final cpmk in _cpmkList) {
  if (cpmk.id != null) {  // Good check here
    final score = _cpmkScores[cpmk.id] ?? 0.0;
    chartData[cpmk.kodeCPMK] = score.clamp(0, 100);
  }
}
```

However, in other places (lines 237, 254):
```dart
// Line 237 - direct access without null check
cpmkScores[cpmkId] = nilaiCpmk;

// Line 254 - assumes cpmk.id is not null
final cpmk = _cpmkList.firstWhere(
  (c) => c.id == cpmkId,
  orElse: () => CPMK(..., id: cpmkId, ...),  // Creates CPMK with same ID
);
```

---

### 🔴 BUG #7: Empty Text String in Section Header
**Location:** Lines 548-552, 708-712  
**Severity:** LOW  
**Issue:** Empty strings used for section headers:

```dart
Padding(
  padding: const EdgeInsets.all(AppSpacing.md),
  child: Text(
    '',  // Empty string - why is this here?
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    ),
  ),
),
```

This suggests incomplete code. Should either have a label or be removed.

---

### 🔴 BUG #8: Duplicate ID Tracking Logic Issue
**Location:** Lines 349-362  
**Severity:** MEDIUM  
**Issue:** The duplicate tracking in `_buildStyledDataTable()` has logic issues:

```dart
final Set<String> shownIds = {};

for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
  final row = rows[rowIndex];
  final idValue = row[3];  // ID column index
  
  final isIdDuplicate = shownIds.contains(idValue);
  
  if (!isIdDuplicate) {
    shownIds.add(idValue);  // Add AFTER checking
  }
}
```

The logic is:
1. Check if ID already shown (false for first occurrence)
2. Add to set if NOT already shown
3. Use `isIdDuplicate` to decide rendering

This means the **first occurrence is NOT marked as duplicate** (correct), but the tracking happens after the check. The logic works but is confusing.

**Issue:** If the same ID appears, subsequent rows show blank values. But if CPMK/CPL data legitimately maps to multiple mata kuliah, this will incorrectly blank them:

```dart
// Example: CPMK#1 has values in both MK-A and MK-B
// First row (MK-A): isIdDuplicate=false, shows value ✓
// Second row (MK-B): isIdDuplicate=true, blanks value ✗
```

---

### 🔴 BUG #9: Type Casting Without Validation
**Location:** Lines 1029-1047  
**Severity:** MEDIUM  
**Issue:** Unsafe type casting in `_buildCPMKDetailTable()`:

```dart
for (var item in _cpmkDetailList) {
  final mkKode = item['mkKode'] as String?;  // Could be any type
  final mkNama = item['mkNama'] as String?;
  final cpmkId = item['cpmkId'] as int;      // ❌ Direct cast without check
  final nilai = item['nilai'] as double?;
  
  // If the map contains wrong types, this crashes
}
```

The code blindly casts without validation.

**Fix:** Add type guards:
```dart
if (item is! Map<String, dynamic>) continue;
final mkKode = item['mkKode'] as String? ?? 'Unknown';
final cpmkId = (item['cpmkId'] as int?);
if (cpmkId == null) continue;
```

---

### 🔴 BUG #10: Missing Error Handling in _loadData() Future.wait
**Location:** Lines 59-91  
**Severity:** MEDIUM  
**Issue:** The Future.wait handles individual exceptions poorly:

```dart
try {
  final results = await Future.wait([...]);
} catch (e) {
  // Error loading initial data - too generic
}

// Inside the batch CPMK loading (lines 77-88):
try {
  final cpmkResults = await Future.wait(cpmkQueries);
} catch (e) {
  // Error loading CPMK per matakuliah - silently caught
}
```

Errors are silently swallowed. Users won't know data failed to load.

**Fix:** Add logging and user notification:
```dart
catch (e) {
  print('Error loading CPMK: $e');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

---

## File 2: cpmk_report_screen.dart

### 🔴 BUG #11: Incorrect CPMK Score Calculation - Ignoring Selected Mahasiswa
**Location:** Lines 80-89  
**Severity:** CRITICAL  
**Issue:** The `_loadCPMKScores()` function calculates scores globally instead of for the selected mahasiswa:

```dart
void _loadCPMKScores() async {
  // ... validation checks (_selectedMahasiswa is checked to not be null)
  
  try {
    final scores = <int, double?>{};
    for (final cpmk in _cpmkList) {
      // ❌ This calculates score for CPMK globally, not for selected mahasiswa!
      final score = await _calculationService.calculateCPMKWithWeightedSKS(cpmk.id!);
      scores[cpmk.id!] = score;
    }
    setState(() {
      _cpmkScores = scores;
      _isLoading = false;
    });
  } catch (e) { ... }
}
```

**The Bug:** `calculateCPMKWithWeightedSKS(cpmk.id!)` is called without passing `_selectedMahasiswa`. This means all students see the same scores regardless of who is selected!

**Expected Behavior:** Each student should see their own CPMK scores.

**Fix:** Pass mahasiswa ID to calculation service:
```dart
for (final cpmk in _cpmkList) {
  final score = await _calculationService.calculateCPMKWithWeightedSKS(
    cpmkId: cpmk.id!,
    mahasiswaId: _selectedMahasiswa!.id!,  // Add this parameter
    matakuliahId: _selectedMatakuliah!.id!,  // Add this parameter
  );
  scores[cpmk.id!] = score;
}
```

---

### 🔴 BUG #12: Race Condition in Angkatan Dropdown
**Location:** Lines 47-62  
**Severity:** MEDIUM  
**Issue:** The angkatan dropdown state can become inconsistent:

```dart
void _onAngkatanChanged(int? angkatan) {
  if (angkatan != null) {
    setState(() => _selectedAngkatan = angkatan);
    _filterMahasiswaByAngkatan(angkatan);  // Async operation
  }
}

void _filterMahasiswaByAngkatan(int angkatan) async {
  final mahasiswaList = await _dbHelper.getAllMahasiswa();  // Network I/O
  final filtered = mahasiswaList.where((mhs) => mhs.tahunMasuk == angkatan).toList();
  setState(() {
    _filteredMahasiswaList = filtered;
    _selectedMahasiswa = null;
  });
}
```

**Race Condition:** If user quickly changes angkatan before filtering completes:
1. User selects 2020 → setState sets _selectedAngkatan=2020, async filter starts
2. User selects 2021 before 2020 finishes → setState sets _selectedAngkatan=2021, new async starts
3. 2020 filter completes → setState overwrites _filteredMahasiswaList with wrong year
4. 2021 filter completes → setState overwrites with correct year

Users see flickering or wrong data temporarily.

**Fix:** Cancel previous request or use request ID:
```dart
String? _currentAngkatanRequest;

void _filterMahasiswaByAngkatan(int angkatan) async {
  final requestId = DateTime.now().toString();
  _currentAngkatanRequest = requestId;
  
  final mahasiswaList = await _dbHelper.getAllMahasiswa();
  if (_currentAngkatanRequest != requestId) return;  // Discard old request
  
  final filtered = mahasiswaList.where((mhs) => mhs.tahunMasuk == angkatan).toList();
  setState(() {
    _filteredMahasiswaList = filtered;
    _selectedMahasiswa = null;
  });
}
```

---

### 🔴 BUG #13: Using `async void` Anti-Pattern
**Location:** Line 55  
**Severity:** MEDIUM  
**Issue:** `_filterMahasiswaByAngkatan` is declared as `async void`:

```dart
void _filterMahasiswaByAngkatan(int angkatan) async {
  // Error handling is impossible here for the caller
}
```

This is a Dart anti-pattern. If an unhandled exception occurs, it won't propagate properly. The function should be `Future<void>` or have try-catch inside.

**Fix:**
```dart
Future<void> _filterMahasiswaByAngkatan(int angkatan) async {
  try {
    // ...
  } catch (e) {
    print('Error filtering mahasiswa: $e');
  }
}
```

---

### 🔴 BUG #14: FutureBuilder with Null Handling Issue
**Location:** Lines 108-130  
**Severity:** MEDIUM  
**Issue:** FutureBuilder doesn't explicitly handle the `connectionState.waiting` state properly:

```dart
FutureBuilder<List<Matakuliah>>(
  future: _matakuliahList,  // _matakuliahList is a late Future
  builder: (context, snapshot) {
    final matakuliahList = snapshot.data ?? [];  // Returns empty list if loading
    return Container(
      child: DropdownButton<Matakuliah>(
        items: matakuliahList.map((matakuliah) {
          return DropdownMenuItem(...);
        }).toList(),
        // ...
      ),
    );
  },
)
```

If `_matakuliahList` future is still loading, `snapshot.data` is null, and the dropdown shows empty. User sees no indication of loading.

**Also:** The `_matakuliahList` is reassigned in `_loadData()` (line 33):
```dart
setState(() {
  _matakuliahList = _dbHelper.getAllMatakuliah();  // Reassigns the future
});
```

If the future completes and user navigates away and back, reassigning the late var could cause issues.

**Fix:** Check snapshot.connectionState:
```dart
builder: (context, snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting) {
    return const CircularProgressIndicator();
  }
  if (snapshot.hasError) {
    return Text('Error: ${snapshot.error}');
  }
  final matakuliahList = snapshot.data ?? [];
  // ...
}
```

---

## File 3: cpl_report_screen.dart

### 🔴 BUG #15: CRITICAL - CPL Calculation Ignores Selected Mahasiswa
**Location:** Lines 73-89  
**Severity:** CRITICAL  
**Issue:** Same critical bug as BUG #11, but for CPL:

```dart
void _loadCPLScores() async {
  if (_selectedMahasiswa == null) {
    return;  // Check passes, _selectedMahasiswa is not null
  }

  setState(() => _isLoading = true);

  try {
    final cplList = await _dbHelper.getAllCPLMaster();
    final scores = <int, double?>{};

    for (final cpl in cplList) {
      // ❌ Calculates globally, ignoring _selectedMahasiswa!
      final score = await _calculationService.calculateCPLWithSKSWeighting(cpl.id!);
      scores[cpl.id!] = score;
    }

    setState(() {
      _cplScores = scores;
      _isLoading = false;
    });
  } catch (e) { ... }
}
```

**The Bug:** Each student sees the same CPL scores because the calculation doesn't consider the student ID.

**Fix:**
```dart
for (final cpl in cplList) {
  final score = await _calculationService.calculateCPLWithSKSWeighting(
    cplId: cpl.id!,
    mahasiswaId: _selectedMahasiswa!.id!,  // Add this
  );
  scores[cpl.id!] = score;
}
```

---

### 🔴 BUG #16: Race Condition in Angkatan Dropdown (Same as BUG #12)
**Location:** Lines 47-62  
**Severity:** MEDIUM  
**Issue:** Identical race condition in angkatan filtering. See BUG #12.

---

### 🔴 BUG #17: Missing Mounted Check in Error Handling
**Location:** Lines 83-95  
**Severity:** MEDIUM  
**Issue:** Error handling in `_loadCPLScores()` has a mounted check, but state clearing in `_onMahasiswaChanged()` doesn't:

```dart
void _onMahasiswaChanged(Mahasiswa? mahasiswa) {
  setState(() {
    _selectedMahasiswa = mahasiswa;
    _cplScores = {};  // State cleared immediately
  });
  _loadCPLScores();  // Async operation starts
}
```

If the widget is disposed during async operation, setState in _loadCPLScores() will fail even with the mounted check because `_onMahasiswaChanged` already called setState.

**Also:** Lines 150-169, FutureBuilder is used with _cplList:
```dart
FutureBuilder<List<CPLMaster>>(
  future: _cplList,  // This future is from initState and never changes
  builder: (context, snapshot) {
    final cplList = snapshot.data ?? [];
    if (cplList.isEmpty) {
      return EmptyStateWidget(...);
    }
    
    return ListView.builder(
      itemCount: cplList.length,
      itemBuilder: (context, index) {
        final cpl = cplList[index];
        final score = _cplScores[cpl.id!];  // ❌ Potential mismatch
        // ...
      },
    );
  },
)
```

**Potential Bug:** If `_cplList` future completes and returns CPL data, but `_cplScores` hasn't been calculated yet for the selected student, the scores will be null/empty initially. The FutureBuilder won't rebuild when _cplScores is updated because the future hasn't changed.

**Fix:** Use a different state management approach or add explicit listener:
```dart
if (_isLoading) {
  return const LoadingWidget();
}
FutureBuilder<List<CPLMaster>>(
  future: _cplList,
  builder: (context, snapshot) {
    final cplList = snapshot.data ?? [];
    if (cplList.isEmpty) return EmptyStateWidget(...);
    
    return ListView.builder(
      itemCount: cplList.length,
      itemBuilder: (context, index) {
        final cpl = cplList[index];
        final score = _cplScores[cpl.id] ?? 'Loading...';  // Better handling
        // ...
      },
    );
  },
)
```

---

## Summary of Bugs by Severity

| Severity | Count | Bug IDs |
|----------|-------|---------|
| CRITICAL | 2 | #11, #15 |
| HIGH | 4 | #1, #2, #3, #4 |
| MEDIUM | 11 | #5, #6, #7, #8, #9, #10, #12, #13, #14, #16, #17 |

### Most Critical Issues to Fix First:
1. **BUG #11, #15** - CPMK/CPL scores calculated globally instead of per-student (all students see same scores)
2. **BUG #3** - Incorrect averaging algorithm produces wrong scores
3. **BUG #4** - Null pointer crash with mahasiswa.id
4. **BUG #2** - Race conditions with async data loading
5. **BUG #1** - Dropdown state initialization issues

---

## Testing Recommendations

1. **Test with multiple students** - Verify each student sees their own scores, not generic scores
2. **Test rapid dropdown changes** - Verify no race conditions in angkatan/matakuliah filtering
3. **Test screen disposal** - Navigate away during data loading, verify no crashes
4. **Test with empty data** - No CPMK/CPL data for selected student
5. **Test with multiple nilai per CPMK** - Verify averaging is correct
6. **Test type mismatches** - Pass wrong data types to maps, verify no crashes
