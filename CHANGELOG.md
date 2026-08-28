# 📝 Changelog

Semua perubahan penting pada proyek **Slate** akan didokumentasikan dalam berkas ini. Format mengikuti standar [Keep a Changelog](https://keepachangelog.com/id/1.0.0/).

---

## [1.0.0] - 2026-08-28

### ✨ Added
- **Core Architecture**: Inisialisasi arsitektur Flutter dengan Riverpod 2.5 dan penyimpanan lokal Hive NoSQL.
- **Clean Slate Engine**: Logika background timer pembersihan catatan hari kemarin setiap tengah malam.
- **Frosted Glass Modal**: Dialog modal *"Catatan baru"* dengan efek `BackdropFilter` blur dan kartu melayang presisi.
- **Dual-Direction Gestures**:
  - Tarik ke bawah (*Top pull-down*) murni dialokasikan untuk pembaruan data (*Refresh*).
  - Tarik ke atas (*Bottom pull-up*) memicu kapsul indikator dengan ikon `+` berputar 180° dan *haptic feedback* untuk mencatat.
- **Swipe Actions**: Geser kanan kartu untuk menyelesaikan tugas, geser kiri untuk menghapus.
- **Developer Experience**: Penambahan konfigurasi `.vscode/launch.json` untuk dukungan debug F5 1-klik.

### ♻️ Refactored
- Modularisasi arsitektur widget ke dalam subdirektori terorganisir (`home/`, `task/`, `dialogs/`).
- Penyusutan kompleksitas file `home_screen.dart` menjadi struktur deklaratif yang bersih.
- Pembaruan sintaks warna Flutter modern (`withValues(alpha: ...)`).
