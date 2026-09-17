# SI-PKL Mobile

Flutter client untuk aplikasi SI-PKL.

## Menjalankan

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Untuk Android Emulator, jalankan `flutter run`. Backend Laravel harus aktif pada port 8000 agar login dan data industri dapat dimuat.

## Konfigurasi API

URL API berada di `lib/config/api_config.dart`:

- Web/Android Emulator: `http://127.0.0.1:8000/api`

## Akun Demo

| Peran | NIS/Username | Password |
| :--- | :--- | :--- |
| **Admin** | `ADMIN001` | `password` |
| **Siswa** | `2413025058` | `password` |

## Peta

Aplikasi memakai `flutter_map` dengan OpenStreetMap. Tidak diperlukan Google Maps API key. Atribusi OpenStreetMap ditampilkan pada layar peta.

Dokumentasi utama project ada di [README repository](../README.md).
