# AI_DECLARATION.md — Deklarasi Transparansi Penggunaan AI
**Project:** SI-PKL (Sistem Informasi Pencari Lokasi PKL)  
**Mata Kuliah:** Mobile Programming — UTS  
**Mahasiswa:** [Nama Lengkap] — [NIM]  
**Tanggal:** [Tanggal Submit, misal: 2026-10-20]

---

## 1. Daftar Alat AI yang Digunakan

| Alat | Versi/Platform | Periode Penggunaan | Peran Utama |
|------|----------------|-------------------|-------------|
| GitHub Copilot | VS Code Extension | Pertemuan 1–8 | Autocomplete inline, boilerplate widget, test skeleton |
| Claude (Anthropic) | claude.ai / Claude Code | Pertemuan 4–8 | Code review, debug error kompleks, arsitektur, refactor |
| ChatGPT (OpenAI) | chat.openai.com | Pertemuan 1–3 | Brainstorm fitur, penjelasan konsep Flutter/Dart, regex |

---

## 2. Pembagian Peran: AI vs Manual

| Modul / Fitur | Dibantu AI | Ditulis Manual | Catatan |
|--------------|:------------:|:---------------:|---------|
| `ApiService` (service layer) | ✅ | ✅ | AI: boilerplate `_request()`, `_decode()`; Manual: token flow, error handling, query param design |
| `Industri` model + `resolveLogoUrl()` | ⚠️ | ✅ | AI: regex `replaceFirst`; Manual: field design, computed `terpakai`, URL resolution logic |
| `PetaIndustriScreen` | ✅ | ✅ | AI: FlutterMap setup, MarkerLayer mapping; Manual: Stack overlay, pin alignment, filter, popup |
| `IndustryDetailScreen` | ⚠️ | ✅ | AI: layout boilerplate; Manual: validasi kuota, dialog konfirmasi, navigasi, URL navigasi |
| Sistem Animasi (`animasi.dart`) | ⚠️ | ✅ | AI: TweenAnimationBuilder syntax; Manual: Motion tokens, stagger logic, TombolMuat |
| Design System (`app_theme.dart`) | ❌ | ✅ | Sepenuhnya manual: ColorScheme, status colors, spacing scale |
| Admin CRUD Screens | ✅ | ✅ | AI: form boilerplate; Manual: validasi, image picker, map coordinate picker |
| Backend Laravel (migration, seeder, controller) | ⚠️ | ✅ | AI: boilerplate CRUD; Manual: schema design, relasi, seeder data nyata Lampung, Policy |

**Legenda:** ✅ = signifikan, ⚠️ = parsial/boilerplate, ❌ = tidak

---

## 3. Studi Kasus Prompting (Minimal 2 Contoh)

### Studi Kasus 1: Bug `resolveLogoUrl` — Trailing Slash & CORS

**Prompt ke AI:**
> *"Logo tidak tampil di Flutter Web. Backend kirim `/logo/file.png`. Base URL `http://127.0.0.1:8000/api`. Buat method di model Industri resolve jadi URL penuh. Perhatikan CORS."*

**Hasil Awal AI (Bermasalah):**
```dart
static String? resolveLogoUrl(String? logoUrl) {
  if (logoUrl == null) return null;
  return 'http://127.0.0.1:8000$logoUrl'; // Hardcoded! ❌
}
```

**Masalah Terdeteksi Manual:**
1. Hardcoded base URL — gagal di device fisik/emulator (butuh `10.0.2.2` atau IP LAN)
2. Trailing slash — `baseUrl` sudah `/api`, jadi jadi `.../api/logo/...` (404)
3. CORS — file statis di `/logo` butuh header `Access-Control-Allow-Origin` di Laravel

**Perbaikan Manual (Commit `8321a15`, `abcab16`, `47dbbb5`):**
```dart
// mobile/lib/models/industri.dart
static String? resolveLogoUrl(String? logoUrl) {
  if (logoUrl == null || logoUrl.isEmpty) return null;
  if (logoUrl.startsWith('http')) return logoUrl;
  final path = logoUrl.startsWith('/') ? logoUrl : '/$logoUrl';
  final siteBase = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api$'), '');
  return '$siteBase$path';
}
```
```php
// backend/routes/web.php
Route::get('/logo/{file}', [LogoController::class, 'show'])
    ->where('file', '.*');

// backend/app/Http/Controllers/LogoController.php
public function show(string $file)
{
    $path = storage_path('app/public/logo/' . $file);
    if (!File::exists($path)) abort(404);
    return response()->file($path)
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET');
}
```

**Commit Terkait:** `8321a15`, `abcab16`, `47dbbb5`

---

### Studi Kasus 2: Layout Error `Expanded` di dalam `ItemMasuk`

**Prompt ke AI:**
> *"Buat widget `ItemMasuk` untuk animasi staggered entrance (slide up + fade) dengan index-based delay. Dipakai di ListView/Column."*

**Hasil Awal AI (Bermasalah):**
```dart
class ItemMasuk extends StatelessWidget {
  final int index;
  final Widget child;
  const ItemMasuk({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0), // ❌ direction terbalik
      duration: Duration(milliseconds: 300 + index * 80),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
```

**Masalah Terdeteksi Manual (saat pakai di `IndustryDetailScreen`):**
- Wrap `Expanded` di **dalam** `ItemMasuk` → **ParentDataWidget error** (`Expanded` butuh parent `Row`/`Column` langsung, tapi parent jadi `TweenAnimationBuilder`)
- Animation direction terbalik (mulai 1.0 → 0.0 = fade OUT, bukan IN)

**Perbaikan Manual (Commit `9a1e40f`):**
```dart
// mobile/lib/widgets/animasi.dart — ItemMasuk diperbaiki
class ItemMasuk extends StatelessWidget {
  final int index;
  final Widget child;
  const ItemMasuk({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0), // ✅ benar: 0→1 (fade IN)
      duration: Duration(milliseconds: 200 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)), // ✅ slide up dari bawah
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// Penggunaan yang BENAR di IndustryDetailScreen:
Row(
  children: [
    Expanded(child: ItemMasuk(index: 3, child: _KuotaCard(...))), // ✅ Expanded DI LUAR
    // SALAH: ItemMasuk(child: Expanded(...)) ❌
  ],
)
```

**Commit Terkait:** `9a1e40f`

---

## 4. Kesalahan & Keterbatasan AI Umum yang Ditemui

| Pola Kesalahan | Contoh di Project | Deteksi & Solusi |
|----------------|-------------------|------------------|
| Hardcoded config | Base URL, color hex, API endpoint | Pakai constant/config class (`ApiConfig`, `AppTheme`) |
| ParentDataWidget error | `Expanded`/`Flexible` di wrapper animasi | Test di device — error merah di console |
| Null safety misses | `json['field'] as String` tanpa `?` | `flutter analyze`; tambah `?? ''` atau null check |
| Platform-specific ignore | `flutter_map` web vs mobile, `url_launcher` mode | Baca docs resmi; test di Chrome & Android keduanya |
| Over-engineering | Saran BLoC/Cubit untuk state sederhana | Pilih `setState` + `FutureBuilder` untuk prototype |
| Outdated API | `withOpacity` (deprecated) → `withValues(alpha:)` | `flutter analyze` warning; migrasi manual |

---

## 5. Rencana Pengembangan Menuju UAS

| Prioritas | Fitur Target | Deskripsi Teknis |
|-----------|--------------|------------------|
| **Tinggi** | **Offline-First + Local Database** | `sqflite`/`drift` cache industri & pengajuan; sync saat online; `Connectivity` listener |
| **Tinggi** | **Push Notification (FCM)** | Firebase Cloud Messaging → notif status pengajuan (diterima/ditolak) |
| **Sedang** | **Lokasi Real-time Siswa** | `geolocator` + `permission_handler` → "Industri terdekat dari saya" (radius km) |
| **Sedang** | **Chat/Message Center** | WebSocket (Pusher/Ably) atau polling API → komunikasi siswa-admin-industri |
| **Rendah** | **Export PDF Laporan PKL** | `pdf` package + `printing` → generate surat pengajuan/laporan akhir |
| **Rendah** | **Dark Mode Support** | `ThemeMode.system` + `AppTheme.dark` (foundation sudah ada di `app_theme.dart`) |

**Perubahan Arsitektur UAS:**
- **State Management**: Migrasi ke **Riverpod** / **Bloc** untuk skala lebih besar
- **Dependency Injection**: `get_it` / `flutter_riverpod` provider untuk `ApiService`
- **Testing**: Unit test service (mock `http.Client`), widget test critical flows
- **CI/CD**: GitHub Actions → `flutter analyze`, `flutter test`, build APK/AAB

---

## 6. Pernyataan Integritas

> **Saya menyatakan bahwa:**
> 1. Seluruh logika bisnis, arsitektur, dan keputusan desain dalam project ini adalah hasil pemikiran saya sendiri.
> 2. AI digunakan sebagai **asisten produktivitas (copilot)** — bukan pengganti pemahaman.
> 3. Saya mampu menjelaskan setiap baris kode kritis yang ditunjukkan dalam video presentasi.
> 4. Semua kesalahan yang dihasilkan AI telah saya deteksi, memahami akar masalahnya, dan memperbaiki secara manual.
> 5. Riwayat commit Git mencerminkan proses pengerjaan bertahap selama 8 pertemuan, bukan unggahan massal.

**Tanda Tangan Digital:** Desta Arya Putra 
**Tanggal:** 20 Oktober 2026
