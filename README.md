# SI-PKL

Sistem Informasi Pencari Lokasi Praktik Kerja Lapangan berbasis mobile.

SI-PKL membantu siswa menemukan lokasi PKL di sekitar mereka, melihat informasi mitra, memeriksa kuota, dan mengirim pengajuan PKL. Sekolah dapat memverifikasi pengajuan serta mengelola data mitra, jurusan, dan pengguna.

## Fitur

### Siswa

- Login menggunakan NIS dan password
- Melihat mitra industri pada peta
- Mencari industri berdasarkan nama
- Mencari tempat usaha sekitar berdasarkan data OpenStreetMap
- Melihat detail alamat, jurusan, dan kuota industri
- Mengajukan lokasi PKL
- Melihat status pengajuan: `menunggu`, `disetujui`, atau `ditolak`

### Admin

- Login dengan role admin
- Melihat seluruh pengajuan siswa
- Menyetujui atau menolak pengajuan
- Mengelola data mitra dan kuota melalui API backend

## Arsitektur

```text
Flutter Mobile/Web
	|
	| REST API + Sanctum Token
	v
Laravel Backend
	|
	+-- SQLite/MySQL
	+-- OpenStreetMap/Overpass untuk pencarian tempat sekitar
```

## Struktur Repository

```text
SI-PKL/
├── backend/     # Laravel REST API, autentikasi, database, dan aturan kuota
├── mobile/      # Flutter Android/Web
└── README.md
```

## Persyaratan

- PHP 8.2 atau lebih baru
- Composer
- Flutter SDK
- Dart SDK
- Android SDK atau Chrome
- SQLite untuk pengembangan lokal, atau MySQL untuk deployment

## Menjalankan Backend

Dari root repository:

```powershell
cd backend
Copy-Item .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve --host=127.0.0.1 --port=8000
```

Backend tersedia di `http://127.0.0.1:8000`.

Jika port 8000 sedang digunakan, jalankan backend pada port lain dan sesuaikan URL API Flutter:

```powershell
php artisan serve --host=127.0.0.1 --port=8001
```

Jangan menjalankan `php artisan serve` dari root repository. Perintah tersebut harus dijalankan dari folder `backend`.

## Akun Demo

| Role | NIS | Password |
|---|---|---|
| Siswa | `2413025058` | `password` |
| Admin | `ADMIN001` | `password` |

Ganti password demo sebelum deployment ke server publik.

## Menjalankan Flutter

```powershell
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Untuk Android Emulator:

```powershell
flutter run
```

URL API diatur di [api_config.dart](mobile/lib/config/api_config.dart):

- Chrome: `http://127.0.0.1:8000/api`
- Android Emulator: `http://10.0.2.2:8000/api`
- Perangkat fisik: gunakan IP komputer pada jaringan Wi-Fi yang sama

## Peta dan Data Tempat

Peta menggunakan `flutter_map` dan tile OpenStreetMap, jadi project tidak membutuhkan Google Maps API key.

Data peta terdiri dari dua sumber:

1. **Mitra sekolah** dari database SI-PKL. Data ini dapat memiliki kuota, jurusan yang diterima, dan pengajuan PKL.
2. **Tempat sekitar** dari OpenStreetMap melalui Overpass API. Data ini hanya hasil pencarian lokasi; tempat tersebut belum otomatis menjadi mitra resmi sekolah.

Peta harus tetap menampilkan atribusi `OpenStreetMap contributors`. Layanan Overpass publik dapat mengalami pembatasan atau timeout; aplikasi menampilkan pesan error jika layanan sedang tidak tersedia.

## API Utama

Semua endpoint selain login membutuhkan token Sanctum.

| Method | Endpoint | Keterangan |
|---|---|---|
| `POST` | `/api/login` | Login siswa/admin |
| `POST` | `/api/logout` | Logout pengguna |
| `GET` | `/api/profil` | Profil pengguna aktif |
| `GET` | `/api/industri` | Daftar dan pencarian mitra |
| `GET` | `/api/industri/{id}` | Detail mitra |
| `GET` | `/api/tempat-sekitar` | Pencarian usaha sekitar melalui Overpass |
| `GET` | `/api/pengajuan` | Pengajuan milik siswa |
| `POST` | `/api/pengajuan` | Membuat pengajuan PKL |
| `GET` | `/api/admin/pengajuan` | Daftar pengajuan untuk admin |
| `PATCH` | `/api/admin/pengajuan/{id}/setujui` | Menyetujui pengajuan |
| `PATCH` | `/api/admin/pengajuan/{id}/tolak` | Menolak pengajuan |

Contoh request pencarian tempat sekitar:

```text
GET /api/tempat-sekitar?latitude=-5.3971&longitude=105.2668&cari=percetakan
```

## Database

Tabel utama menggunakan nama berbahasa Indonesia:

- `pengguna`
- `jurusan`
- `industri`
- `industri_jurusan`
- `pengajuan_pkl`

Sisa kuota dihitung dari:

```text
kuota maksimal - (pengajuan menunggu + pengajuan disetujui)
```

Proses pengajuan menggunakan database transaction dan lock untuk menjaga konsistensi kuota.

## Pengujian

Backend:

```powershell
cd backend
php artisan test
```

Flutter:

```powershell
cd mobile
flutter analyze
flutter test
flutter build web
```

## Catatan Keamanan

- Jangan commit file `.env`.
- Jangan menaruh token atau password production di repository.
- Gunakan password berbeda untuk deployment.
- Batasi akses database production.
- Gunakan HTTPS saat backend online.
- OpenStreetMap dan Overpass memiliki kebijakan penggunaan serta batas layanan masing-masing.

## Status Project

Project saat ini berada pada tahap MVP aktif. Fitur autentikasi, industri, peta gratis, pencarian tempat sekitar, pengajuan PKL, dan approval dasar sudah tersedia. Modul admin CRUD lengkap, deployment online, dan penyamaan seluruh halaman dengan wireframe masih menjadi pekerjaan lanjutan.
