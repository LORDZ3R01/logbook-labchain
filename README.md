# LabChain

### Logbook Peminjaman dan Pengembalian Alat Laboratorium Berbasis Blockchain Ethereum Sepolia

\<p align="center">
&#x20; \<strong>LabChain\</strong> merupakan aplikasi pencatatan peminjaman dan pengembalian alat laboratorium berbasis teknologi blockchain menggunakan Flutter, Dart, dan Solidity.
\</p>

---

## 1. Deskripsi Proyek

LabChain adalah aplikasi yang dirancang untuk membantu proses pengelolaan peminjaman dan pengembalian alat laboratorium secara digital.

Aplikasi ini memanfaatkan teknologi **Blockchain Ethereum Sepolia** dan **Smart Contract** untuk mencatat aktivitas peminjaman, persetujuan, penolakan, pengajuan pengembalian, serta konfirmasi pengembalian alat.

Dengan memanfaatkan blockchain, transaksi yang telah dikonfirmasi dapat diverifikasi melalui Blockchain Explorer sehingga proses pencatatan menjadi lebih transparan dan dapat ditelusuri.

## 2. Tujuan Proyek

Tujuan pengembangan aplikasi LabChain adalah:

- Mendigitalisasi proses peminjaman dan pengembalian alat laboratorium.
- Mempermudah pengelolaan data inventaris alat laboratorium.
- Menerapkan teknologi blockchain dalam sistem pencatatan transaksi.
- Memanfaatkan Smart Contract untuk mengelola alur peminjaman dan pengembalian.
- Menyediakan riwayat transaksi yang dapat diverifikasi melalui Blockchain Explorer.

## 3. Fitur Aplikasi

### Pengelolaan Alat

- Menambahkan data alat laboratorium.
- Mengubah informasi alat.
- Mengatur jumlah stok alat.
- Mengaktifkan dan menonaktifkan alat.

### Pengelolaan Peminjaman

- Mengajukan peminjaman alat.
- Melihat status pengajuan peminjaman.
- Menyetujui permintaan peminjaman oleh admin.
- Menolak permintaan peminjaman oleh admin.

### Pengelolaan Pengembalian

- Mengajukan pengembalian alat.
- Mengonfirmasi pengembalian oleh admin.
- Memperbarui jumlah stok setelah pengembalian dikonfirmasi.

### Riwayat Blockchain

- Menampilkan riwayat aktivitas transaksi.
- Membaca event dari Smart Contract.
- Menyimpan cache riwayat dan blok terakhir yang telah dipindai.
- Menampilkan informasi transaksi yang dapat diperiksa melalui Blockchain Explorer.

## 4. Teknologi yang Digunakan

| Teknologi      | Keterangan / Versi |
| -------------- | ------------------ |
| Flutter        | 3.47.0             |
| Dart SDK       | >= 3.13.0 < 4.0.0  |
| Java JDK       | 17                 |
| Gradle         | 9.3.1              |
| Solidity       | ^0.8.20            |
| Ethereum       | Sepolia Testnet    |
| Chain ID       | 11155111           |
| Smart Contract | LabChain           |

## 5. Dependensi Flutter

Daftar berikut merupakan dependensi utama yang digunakan berdasarkan versi aktual pada `pubspec.lock`.

| No. | Package            | Versi  |
| --: | ------------------ | ------ |
|   1 | cupertino_icons    | 1.0.9  |
|   2 | web3dart           | 3.0.3  |
|   3 | http               | 1.6.0  |
|   4 | wallet             | 0.0.18 |
|   5 | reown_appkit       | 1.9.0  |
|   6 | web                | 1.1.2  |
|   7 | shared_preferences | 2.5.6  |
|   8 | url_launcher       | 6.3.3  |
|   9 | flutter_lints      | 6.0.0  |

Dependensi tambahan dikelola secara otomatis oleh sistem package manager Flutter dan Dart.

## 6. Persyaratan Sistem

Sebelum menjalankan aplikasi, pastikan perangkat pengembangan memiliki:

- Flutter SDK versi 3.47.0 atau kompatibel.
- Dart SDK sesuai persyaratan proyek.
- Java JDK 17.
- Android Studio atau Visual Studio Code.
- Android Emulator atau perangkat Android.
- Koneksi internet.

## 7. Cara Instalasi dan Menjalankan Aplikasi

### A. Clone Repository

Unduh kode sumber proyek dari GitHub menggunakan perintah:

```bash
git clone https://github.com/LORDZ3R01/logbook-labchain.git
```

### B. Masuk ke Direktori Proyek

```bash
cd logbook-labchain
```

### C. Instal Dependensi

Jalankan perintah berikut untuk mengunduh seluruh dependensi:

```bash
flutter pub get
```

### D. Periksa Konfigurasi Flutter

```bash
flutter doctor
```

Pastikan tidak terdapat masalah konfigurasi yang menghalangi proses build aplikasi.

### E. Periksa Perangkat

Hubungkan perangkat Android atau jalankan emulator, kemudian gunakan:

```bash
flutter devices
```

### F. Jalankan Aplikasi

```bash
flutter run
```

Aplikasi akan dikompilasi dan dijalankan pada perangkat yang dipilih.

### G. Build APK Release

Untuk menghasilkan file APK yang dapat dipasang pada perangkat Android:

```bash
flutter build apk --release
```

Hasil build dapat ditemukan pada direktori:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 8. Informasi Blockchain

LabChain menggunakan jaringan Ethereum Sepolia sebagai lingkungan pengujian Smart Contract.

| Keterangan                  | Informasi                                    |
| --------------------------- | -------------------------------------------- |
| Blockchain Network          | Ethereum Sepolia                             |
| Network Type                | Testnet                                      |
| Chain ID                    | 11155111                                     |
| Contract Name               | LabChain                                     |
| Solidity Version Constraint | ^0.8.20                                      |
| Deployment Block            | 12153331                                     |
| Contract Address            | `0x336561E901540E084c028010F1007B176c3a112f` |

### Smart Contract Address

```text
0x336561E901540E084c028010F1007B176c3a112f
```

### Blockchain Explorer

Smart Contract dan transaksi dapat diperiksa melalui tautan berikut:

- **Etherscan Sepolia:**
  [https://sepolia.etherscan.io/address/0x336561E901540E084c028010F1007B176c3a112f](https://sepolia.etherscan.io/address/0x336561E901540E084c028010F1007B176c3a112f)

- **Blockscout Sepolia:**
  [https://eth-sepolia.blockscout.com/address/0x336561E901540E084c028010F1007B176c3a112f](https://eth-sepolia.blockscout.com/address/0x336561E901540E084c028010F1007B176c3a112f)

- **Smart Contract Logs:**
  [https://eth-sepolia.blockscout.com/address/0x336561E901540E084c028010F1007B176c3a112f?tab=logs](https://eth-sepolia.blockscout.com/address/0x336561E901540E084c028010F1007B176c3a112f?tab=logs)

## 9. Smart Contract

Smart Contract LabChain dikembangkan menggunakan bahasa pemrograman Solidity dengan standar compiler `^0.8.20`.

Smart Contract memiliki beberapa fungsi utama:

| Fungsi                     | Keterangan                       |
| -------------------------- | -------------------------------- |
| `tambahAlat()`             | Menambahkan alat laboratorium    |
| `ubahAlat()`               | Mengubah informasi alat          |
| `jumlahAlat()`             | Mengambil jumlah data alat       |
| `ambilAlat()`              | Mengambil informasi alat         |
| `ajukanPeminjaman()`       | Mengajukan peminjaman alat       |
| `setujuiPeminjaman()`      | Menyetujui peminjaman            |
| `tolakPeminjaman()`        | Menolak peminjaman               |
| `ajukanPengembalian()`     | Mengajukan pengembalian alat     |
| `konfirmasiPengembalian()` | Mengonfirmasi pengembalian       |
| `jumlahPeminjaman()`       | Mengambil jumlah data peminjaman |
| `ambilPeminjaman()`        | Mengambil informasi peminjaman   |

### Event Blockchain

Smart Contract menghasilkan event berikut untuk mencatat perubahan aktivitas:

- `AlatDitambahkan`
- `PeminjamanDiajukan`
- `PeminjamanDisetujui`
- `PeminjamanDitolak`
- `PengembalianDiajukan`
- `PengembalianDikonfirmasi`

## 10. Struktur File Penting

Berikut beberapa file penting dalam proyek:

```text
logbook-labchain/
│
├── android/
│
├── assets/
│   └── abi/
│       ├── ChainTodo.json
│       └── LabChain.json
│
├── lib/
│   ├── config/
│   ├── services/
│   ├── screens/
│   └── main.dart
│
├── contracts/
│   └── LabChain.sol
│
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
├── README.md
└── .gitignore
```

*Catatan: Struktur direktori di atas merupakan gambaran umum. Sesuaikan dengan struktur folder aktual pada repository.*

## 11. Jaringan dan Biaya Transaksi

Aplikasi menggunakan Ethereum Sepolia Testnet untuk menjalankan transaksi Smart Contract.

Beberapa hal yang perlu diperhatikan:

- Pastikan konfigurasi RPC mengarah ke Ethereum Sepolia.
- Gunakan dompet yang mendukung jaringan Sepolia.
- Transaksi yang mengubah data Smart Contract membutuhkan Sepolia ETH untuk membayar biaya gas.
- Sepolia merupakan jaringan pengujian, bukan jaringan Ethereum Mainnet.

## 12. Keamanan

- Jangan mengunggah private key atau seed phrase ke repository publik.
- Jangan menyimpan API key rahasia secara langsung di kode sumber yang dipublikasikan.
- Gunakan konfigurasi RPC yang sesuai.
- Pastikan hanya alamat admin yang berwenang menjalankan fungsi khusus admin pada Smart Contract.

## 13. Repository GitHub

Kode sumber aplikasi LabChain tersedia pada repository berikut:

**GitHub Repository:**

[https://github.com/LORDZ3R01/logbook-labchain](https://github.com/LORDZ3R01/logbook-labchain)

---

\<p align="center">   \<strong>LabChain\</strong>\<br>   Blockchain-Based Laboratory Equipment Loan and Return Logbook\<br>   \<em>Ethereum Sepolia • Flutter • Solidity\</em> \</p>
