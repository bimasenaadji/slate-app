# 🪨 Slate — Minimalist Daily Task Planner

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter&logoColor=white" alt="Flutter Version" />
  <img src="https://img.shields.io/badge/Dart-3.12+-0175C2?logo=dart&logoColor=white" alt="Dart Version" />
  <img src="https://img.shields.io/badge/State_Management-Riverpod_2.5-4A90E2" alt="State Management" />
  <img src="https://img.shields.io/badge/Database-Hive_NoSQL-FFA000" alt="Database" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License" />
</p>

<p align="center">
  <b>Slate</b> adalah aplikasi pencatat tugas harian (*daily planner*) dengan filosofi <i>"Clean Slate"</i> — dirancang bebas distraksi, berfokus pada hari ini, dengan interaksi berbasis gestur intuitif dan estetika monokrom modern.
</p>

---

## ✨ Fitur Utama (*Key Features*)

- **🌅 Clean Slate Philosophy**: Setiap awal hari baru (tengah malam), catatan hari sebelumnya otomatis diarsipkan/dibersihkan secara lokal, memberi Anda kanvas segar setiap pagi.
- **👆 Gesture-Driven UX (Dual-Direction Action)**:
  - **Tarik ke Bawah (Pull Down dari atas)**: Menyegarkan (*refresh*) & memvalidasi status data harian.
  - **Tarik ke Atas (Pull Up dari bawah)**: Memunculkan indikator animasi berputar dinamis (180°) disertai getaran *haptic feedback* untuk membuka dialog catatan baru.
- **🌫️ Frosted Glass Modal**: Dialog input tugas (*"Catatan baru"*) melayang yang bersih dengan *backdrop blur*, tipografi *Plus Jakarta Sans*, dan aksi instan (*Simpan & Batal*).
- **⚡ Offline-First & Instan**: Menggunakan database lokal NoSQL **Hive** dan **Riverpod State Management** untuk performa tanpa latensi.
- **🎯 Swipe Actions**: Geser kartu ke kanan untuk menyelesaikan tugas (*Complete*), atau geser ke kiri untuk menghapus (*Delete*).

---

## 🏗️ Arsitektur & Struktur Proyek (*Project Structure*)

Proyek ini dibangun menggunakan prinsip **Clean Code & Modular Component Hierarchy**:

```
lib/
├── core/                           # Fondasi Sistem & Konfigurasi
│   ├── constants.dart              # String, konstanta ukuran & padding
│   ├── theme.dart                  # Palet warna monokrom, typography & shapes
│   └── utils/
│       └── date_helper.dart        # Helper format tanggal & sapaan waktu Indonesia
│
├── models/                         # Lapisan Data (Entity Models)
│   └── task_model.dart             # Model data tugas (id, title, isDone, createdAt)
│
├── providers/                      # State Management & Database
│   └── task_provider.dart          # Riverpod StateNotifier + Integrasi Hive NoSQL
│
├── screens/                        # Halaman Aplikasi
│   ├── splash_screen.dart          # Animasi layar pembuka
│   └── home_screen.dart            # Layout orkestrator halaman utama
│
└── widgets/                        # Komponen UI Modular
    ├── home/                       # Komponen Spesifik Home Screen
    │   ├── home_header.dart        # Sapaan waktu, tanggal hari ini, & tombol "+"
    │   ├── progress_chip.dart      # Badge dinamis status progres tugas
    │   └── bottom_pull_indicator.dart # Kapsul animasi gestur tarik ke atas
    ├── task/                       # Komponen Tugas
    │   ├── task_card.dart          # Kartu tugas dengan gesture swipe
    │   └── empty_state.dart        # Tampilan zen saat belum ada tugas
    └── dialogs/                    # Dialog & Modal
        └── add_task_dialog.dart    # Modal dialog frosted glass "Catatan baru"
```

---

## 🚀 Memulai (*Getting Started*)

### Prasyarat
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (versi 3.20.0 atau lebih tinggi)
- Android Studio / VS Code dengan ekstensi Flutter & Dart terpasang
- Perangkat fisik / Emulator Android / Web Browser

### Instalasi & Menjalankan Proyek

```bash
# 1. Clone repositori ini
git clone https://github.com/bimasenaadji/slate-app.git

# 2. Masuk ke direktori proyek
cd slate-app

# 3. Unduh semua dependensi
flutter pub get

# 4. Jalankan aplikasi (pilih target device atau web)
flutter run
```

---

## 🛠️ Tech Stack & Dependencies

| Paket | Fungsi |
| :--- | :--- |
| **[flutter_riverpod](https://pub.dev/packages/flutter_riverpod)** | State Management reaktif & terisolasi |
| **[hive_flutter](https://pub.dev/packages/hive_flutter)** | Penyimpanan database lokal NoSQL cepat & ringan |
| **[google_fonts](https://pub.dev/packages/google_fonts)** | Tipografi elegan *Plus Jakarta Sans* |
| **[flutter_slidable](https://pub.dev/packages/flutter_slidable)** | Gesture swipe-to-action (Complete / Delete) |
| **[intl](https://pub.dev/packages/intl)** | Lokalisasi & format tanggal bahasa Indonesia |

---

## 🌿 Git Branching Strategy

Repositori ini menerapkan alur kerja percabangan terstandar:
- **`main`**: Branch stabil siap rilis (*production-ready*).
- **`feature/*`**: Branch pengembangan fitur spesifik & eksperimen interaksi baru.

---

## 📄 Lisensi (*License*)

Proyek ini didistribusikan di bawah lisensi [MIT License](LICENSE).
