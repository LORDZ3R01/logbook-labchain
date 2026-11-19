# LabChain – Logbook Peminjaman dan Pengembalian Alat Laboratorium Berbasis Blockchain

LabChain adalah aplikasi mobile berbasis Flutter yang digunakan untuk mengelola proses peminjaman dan pengembalian alat laboratorium dengan memanfaatkan teknologi blockchain Ethereum Sepolia dan smart contract Solidity.

Aplikasi ini dirancang untuk meningkatkan transparansi, keamanan, dan keterlacakan data transaksi peminjaman serta pengembalian alat laboratorium.

## Fitur Utama

- **Manajemen Alat:** Menampilkan daftar alat laboratorium, stok, dan status ketersediaan.
- **Pengajuan Peminjaman:** Pengguna dapat mengajukan peminjaman alat melalui aplikasi.
- **Persetujuan Peminjaman:** Admin dapat menyetujui atau menolak pengajuan.
- **Pengajuan Pengembalian:** Pengguna dapat mengajukan pengembalian alat.
- **Konfirmasi Pengembalian:** Admin dapat mengonfirmasi pengembalian alat.
- **Integrasi Wallet:** Menghubungkan wallet menggunakan Reown AppKit dan MetaMask.
- **Riwayat Blockchain:** Menampilkan aktivitas berdasarkan event smart contract.
- **Verifikasi Transaksi:** Transaksi dapat diperiksa melalui Blockscout.

## Teknologi yang Digunakan

| Teknologi | Kegunaan |
|---|---|
| Flutter | Pengembangan aplikasi mobile |
| Dart | Bahasa pemrograman aplikasi |
| Solidity | Pembuatan smart contract |
| Ethereum Sepolia | Jaringan blockchain |
| Web3dart | Interaksi dengan Ethereum |
| Reown AppKit | Koneksi wallet |
| MetaMask | Wallet pengguna |
| Alchemy | RPC provider |
| Blockscout | Penjelajah blockchain |

## Arsitektur Sistem

1. Pengguna berinteraksi dengan aplikasi LabChain melalui Flutter.
2. Wallet MetaMask dihubungkan menggunakan Reown AppKit.
3. Aplikasi berkomunikasi dengan Ethereum Sepolia melalui RPC Alchemy.
4. Smart contract Solidity memproses transaksi peminjaman dan pengembalian.
5. Event blockchain digunakan untuk membangun riwayat aktivitas.
6. Transaksi dapat diverifikasi melalui Blockscout.

## Smart Contract

Smart contract LabChain dikembangkan menggunakan Solidity
dan di-deploy pada jaringan Ethereum Sepolia.

- Source Code: `contracts/LabChain.sol`
- Network: Ethereum Sepolia
- Chain ID: 11155111
- Contract Address:
  `0x336561E901540E084c028010F1007B176c3a112f`

- Block Explorer:
  https://eth-sepolia.blockscout.com/address/0x336561E901540E084c028010F1007B176c3a112f

## Persyaratan

Sebelum menjalankan proyek, pastikan sudah tersedia:

- Flutter SDK
- Dart SDK
- Android Studio atau VS Code
- Android SDK
- Wallet MetaMask
- Sepolia ETH untuk biaya transaksi
- API key Alchemy

## Cara Menjalankan Aplikasi

1. Clone repository:

   ```bash
   git clone https://github.com/LORDZ3R01/logbook-labchain.git
   ```

2. Masuk ke direktori proyek:

   ```bash
   cd logbook-labchain
   ```

3. Install dependency:

   ```bash
   flutter pub get
   ```

4. Buat file `secrets.json` di direktori utama proyek:

   ```json
   {
     "ALCHEMY_API_KEY": "MASUKKAN_API_KEY_ALCHEMY"
   }
   ```

5. Jalankan aplikasi:

   ```bash
   flutter run --dart-define-from-file=secrets.json
   ```

**Catatan:** File `secrets.json` tidak disertakan dalam repository. Setiap pengguna harus membuat file tersebut sendiri menggunakan API key miliknya. API key yang dimasukkan melalui `--dart-define` tetap dapat diekstrak dari APK sehingga bukan penyimpanan rahasia yang sepenuhnya aman.

## Struktur Proyek

```text
lib/
├── config/
├── screens/
├── services/
└── main.dart

contracts/
android/
test/
```

Sesuaikan struktur di atas dengan direktori aktual repository.

## Jaringan Blockchain

Proyek ini menggunakan Ethereum Sepolia sebagai jaringan pengujian (*testnet*), bukan Ethereum Mainnet. Gunakan Sepolia ETH untuk melakukan transaksi pengujian.

## Tim Pengembang

Dikembangkan sebagai proyek akademik secara berkelompok.

## Lisensi

Proyek ini dibuat untuk keperluan pendidikan dan pengembangan pembelajaran teknologi blockchain.
