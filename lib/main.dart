
import 'package:flutter/material.dart';

import 'services/labchain_service.dart';
import 'services/wallet_connection_service.dart';

import 'screens/daftar_alat_page.dart';
import 'screens/peminjaman_page.dart';
import 'screens/peminjaman_admin_page.dart';
import 'screens/pengembalian_page.dart';
import 'screens/pengembalian_admin_page.dart';
import 'screens/riwayat_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LabChainApp());
}

class LabChainApp extends StatelessWidget {
  const LabChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LabChain',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
      home: const LabChainTestPage(),
    );
  }
}

class LabChainTestPage extends StatefulWidget {
  const LabChainTestPage({super.key});

  @override
  State<LabChainTestPage> createState() =>
      _LabChainTestPageState();
}

class _LabChainTestPageState
    extends State<LabChainTestPage> {
  late WalletConnectionService wallet;
  late LabChainService blockchain;

  bool walletReady = false;
  bool walletLoading = false;
  bool loading = false;

  int jumlahAlat = 0;
  int jumlahPeminjaman = 0;

  List<Map<String, dynamic>> daftarAlat = [];
  List<Map<String, dynamic>> daftarPeminjaman = [];

  String status = 'Menginisialisasi aplikasi...';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initWallet();
    });
  }

  // ==========================================
  // INISIALISASI WALLET
  // ==========================================

  Future<void> initWallet() async {
    try {
      wallet = WalletConnectionService();
      blockchain = LabChainService(wallet);

      await wallet.init(context);

      if (!mounted) return;

      setState(() {
        walletReady = true;
        status = 'Silakan hubungkan MetaMask.';
      });

      await muatData();
    } catch (e, stackTrace) {
      debugPrint('[DASHBOARD] ERROR INIT WALLET: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        status = 'Gagal menginisialisasi aplikasi: $e';
      });
    }
  }

  // ==========================================
  // MENGHUBUNGKAN WALLET
  // ==========================================

  Future<void> hubungkanWallet() async {
    if (!walletReady || walletLoading) return;

    setState(() {
      walletLoading = true;
      status = 'Menghubungkan MetaMask...';
    });

    try {
      await wallet.connect();

      if (!mounted) return;

      setState(() {
        walletLoading = false;
        status = 'Wallet berhasil dihubungkan.';
      });

      await muatData();
    } catch (e, stackTrace) {
      debugPrint('[DASHBOARD] ERROR CONNECT WALLET: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        walletLoading = false;
        status = 'Gagal menghubungkan wallet: $e';
      });
    }
  }

  // ==========================================
  // MEMUTUSKAN WALLET
  // ==========================================

  Future<void> putuskanWallet() async {
    if (walletLoading) return;

    setState(() {
      walletLoading = true;
    });

    try {
      await wallet.disconnect();

      if (!mounted) return;

      setState(() {
        walletLoading = false;
        status = 'Wallet berhasil diputuskan.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        walletLoading = false;
        status = 'Gagal memutuskan wallet: $e';
      });
    }
  }

  // ==========================================
  // MEMUAT DATA BLOCKCHAIN
  // ==========================================

  Future<void> muatData() async {
    if (!walletReady || loading) return;

    setState(() {
      loading = true;
      status = 'Memuat data blockchain...';
    });

    try {
      await blockchain.init();

      // Mengambil jumlah data
      final totalAlat = await blockchain.jumlahAlat();

      final totalPeminjaman =
          await blockchain.jumlahPeminjaman();

      debugPrint('======================================');
      debugPrint('[DASHBOARD] MEMUAT DETAIL DATA');
      debugPrint('[DASHBOARD] Total alat: $totalAlat');
      debugPrint(
        '[DASHBOARD] Total peminjaman: $totalPeminjaman',
      );

      // --------------------------------------
      // MENGAMBIL DETAIL ALAT
      // --------------------------------------

      final List<Map<String, dynamic>> dataAlat = [];

      for (int i = 0; i < totalAlat; i++) {
        try {
          final detail = await blockchain.ambilAlat(i);

          dataAlat.add({
            'id': i,
            ...detail,
          });

          debugPrint(
            '[DASHBOARD] Alat ID $i berhasil dimuat: $detail',
          );
        } catch (e) {
          debugPrint(
            '[DASHBOARD] Gagal memuat alat ID $i: $e',
          );
        }
      }

      // --------------------------------------
      // MENGAMBIL DETAIL PEMINJAMAN
      // --------------------------------------

      final List<Map<String, dynamic>> dataPeminjaman = [];

      for (int i = 0; i < totalPeminjaman; i++) {
        try {
          final detail =
              await blockchain.ambilPeminjaman(i);

          dataPeminjaman.add({
            'id': i,
            ...detail,
          });

          debugPrint(
            '[DASHBOARD] Peminjaman ID $i berhasil dimuat: $detail',
          );
        } catch (e) {
          debugPrint(
            '[DASHBOARD] Gagal memuat peminjaman ID $i: $e',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        jumlahAlat = totalAlat;
        jumlahPeminjaman = totalPeminjaman;

        daftarAlat = dataAlat;
        daftarPeminjaman = dataPeminjaman;

        loading = false;
        status = 'Berhasil memuat data LabChain Sepolia.';
      });

      debugPrint('======================================');
      debugPrint('[DASHBOARD] PEMUATAN SELESAI');
      debugPrint(
        '[DASHBOARD] Alat berhasil dimuat: ${dataAlat.length}',
      );
      debugPrint(
        '[DASHBOARD] Peminjaman berhasil dimuat: ${dataPeminjaman.length}',
      );
      debugPrint('======================================');
    } catch (e, stackTrace) {
      debugPrint('[DASHBOARD] ERROR MEMUAT DATA: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        loading = false;
        status = 'Gagal memuat data blockchain: $e';
      });
    }
  }

  // ==========================================
  // NAVIGASI DAFTAR ALAT
  // ==========================================

  void bukaDaftarAlat() {
    if (!wallet.isConnected) {
      tampilkanPesan(
        'Hubungkan MetaMask terlebih dahulu.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DaftarAlatPage(
          blockchain: blockchain,
          isAdmin: true,
        ),
      ),
    );
  }

  // ==========================================
  // NAVIGASI PEMINJAMAN
  // ==========================================

  Future<void> bukaPeminjaman() async {
    if (!wallet.isConnected) {
      tampilkanPesan(
        'Hubungkan MetaMask terlebih dahulu.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PeminjamanPage(
          blockchain: blockchain,
        ),
      ),
    );

    if (mounted) {
      await muatData();
    }
  }

  // ==========================================
  // NAVIGASI PERSETUJUAN ADMIN
  // ==========================================

  Future<void> bukaPersetujuanAdmin() async {
    if (!wallet.isConnected) {
      tampilkanPesan(
        'Hubungkan MetaMask terlebih dahulu.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PeminjamanAdminPage(
          blockchain: blockchain,
        ),
      ),
    );

    if (mounted) {
      await muatData();
    }
  }

  // ==========================================
  // NAVIGASI PENGEMBALIAN
  // ==========================================

  Future<void> bukaPengembalian() async {
    if (!wallet.isConnected) {
      tampilkanPesan(
        'Hubungkan MetaMask terlebih dahulu.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PengembalianPage(
          blockchain: blockchain,
        ),
      ),
    );

    if (mounted) {
      await muatData();
    }
  }

  // ==========================================
  // NAVIGASI KONFIRMASI PENGEMBALIAN
  // ==========================================

  Future<void> bukaKonfirmasiPengembalian() async {
    if (!wallet.isConnected) {
      tampilkanPesan(
        'Hubungkan MetaMask terlebih dahulu.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PengembalianAdminPage(
          blockchain: blockchain,
        ),
      ),
    );

    if (mounted) {
      await muatData();
    }
  }

  // ==========================================
  // NAVIGASI RIWAYAT TRANSAKSI
  // ==========================================

  Future<void> bukaRiwayat() async {
    if (!wallet.isConnected) {
      tampilkanPesan(
        'Hubungkan MetaMask terlebih dahulu.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiwayatPage(
          blockchain: blockchain,
        ),
      ),
    );

    if (mounted) {
      await muatData();
    }
  }

  // ==========================================
  // MENAMPILKAN PESAN
  // ==========================================

  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
      ),
    );
  }

  // ==========================================
  // KARTU STATISTIK
  // ==========================================

  Widget kartuData({
    required String judul,
    required int jumlah,
    required IconData ikon,
    required Color warna,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                ikon,
                size: 35,
                color: warna,
              ),
              const SizedBox(height: 12),
              Text(
                '$jumlah',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                judul,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MENU DASHBOARD
  // ==========================================

  Widget menuDashboard({
    required String judul,
    required String deskripsi,
    required IconData ikon,
    required Color warna,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor:
              warna.withValues(alpha: 0.12),
          child: Icon(
            ikon,
            color: warna,
            size: 27,
          ),
        ),
        title: Text(
          judul,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(deskripsi),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 17,
        ),
        onTap: onTap,
      ),
    );
  }

  // ==========================================
  // KARTU DETAIL ALAT
  // ==========================================

  Widget kartuAlat(Map<String, dynamic> alat) {
    final bool aktif = alat['aktif'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: const Icon(
            Icons.devices,
            color: Colors.green,
          ),
        ),
        title: Text(
          alat['nama'].toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'ID Alat: ${alat['id']}\n'
          'Total stok: ${alat['totalStok']}\n'
          'Sedang dipinjam: ${alat['sedangDipinjam']}',
        ),
        isThreeLine: true,
        trailing: Icon(
          aktif ? Icons.check_circle : Icons.cancel,
          color: aktif ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  // ==========================================
  // KARTU DETAIL PEMINJAMAN
  // ==========================================

  Widget kartuPeminjaman(
    Map<String, dynamic> data,
  ) {
    final int statusPeminjaman =
        data['status'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(
            Icons.assignment,
            color: Colors.blue,
          ),
        ),
        title: Text(
          'Peminjaman #${data['id']}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'ID Alat: ${data['alatId']}\n'
          'Jumlah: ${data['jumlah']}\n'
          'Peminjam: ${data['peminjam']}\n'
          'Status: $statusPeminjaman',
        ),
        isThreeLine: true,
      ),
    );
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  @override
  void dispose() {
    if (walletReady) {
      blockchain.dispose();
    }

    super.dispose();
  }

  // ==========================================
  // TAMPILAN UTAMA
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final connected =
        walletReady && wallet.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LabChain',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loading || !walletReady
                ? null
                : muatData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang data',
          ),
        ],
      ),

      body: !walletReady
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      status,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )

          : RefreshIndicator(
              onRefresh: muatData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ==================================
                  // HEADER DASHBOARD
                  // ==================================

                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Logbook Peminjaman Alat Laboratorium Berbasis Blockchain',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================
                  // WALLET CONNECTION
                  // ==================================

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: Colors.green,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Wallet Connection',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          Row(
                            children: [
                              Icon(
                                connected
                                    ? Icons.check_circle
                                    : Icons.warning,
                                color: connected
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  connected
                                      ? 'Wallet Terhubung'
                                      : 'Wallet Belum Terhubung',
                                ),
                              ),
                            ],
                          ),

                          if (connected &&
                              wallet.address != null) ...[
                            const SizedBox(height: 10),
                            SelectableText(
                              wallet.address!,
                              style: const TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          ],

                          const SizedBox(height: 15),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: walletLoading
                                  ? null
                                  : connected
                                      ? putuskanWallet
                                      : hubungkanWallet,
                              icon: walletLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      connected
                                          ? Icons.link_off
                                          : Icons.link,
                                    ),
                              label: Text(
                                walletLoading
                                    ? 'Memproses...'
                                    : connected
                                        ? 'Putuskan Wallet'
                                        : 'Hubungkan MetaMask',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================
                  // DATA BLOCKCHAIN
                  // ==================================

                  const Text(
                    'Data Blockchain',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      kartuData(
                        judul: 'Jumlah Alat',
                        jumlah: jumlahAlat,
                        ikon: Icons.devices,
                        warna: Colors.green,
                      ),
                      kartuData(
                        judul: 'Jumlah Peminjaman',
                        jumlah: jumlahPeminjaman,
                        ikon: Icons.assignment,
                        warna: Colors.blue,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ==================================
                  // DAFTAR ALAT
                  // ==================================

                  const Text(
                    'Daftar Alat Laboratorium',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (loading && daftarAlat.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (daftarAlat.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Belum ada data alat.',
                        ),
                      ),
                    )
                  else
                    ...daftarAlat.map(kartuAlat),

                  const SizedBox(height: 20),

                  // ==================================
                  // DATA PEMINJAMAN
                  // ==================================

                  const Text(
                    'Data Peminjaman',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (loading && daftarPeminjaman.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (daftarPeminjaman.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Belum ada data peminjaman.',
                        ),
                      ),
                    )
                  else
                    ...daftarPeminjaman.map(kartuPeminjaman),

                  const SizedBox(height: 20),

                  // ==================================
                  // MENU UTAMA
                  // ==================================

                  const Text(
                    'Menu Utama',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  menuDashboard(
                    judul: 'Daftar Alat Laboratorium',
                    deskripsi:
                        'Lihat dan kelola data alat laboratorium',
                    ikon: Icons.inventory_2,
                    warna: Colors.green,
                    onTap: bukaDaftarAlat,
                  ),

                  menuDashboard(
                    judul: 'Peminjaman Alat',
                    deskripsi:
                        'Ajukan peminjaman alat laboratorium',
                    ikon: Icons.assignment,
                    warna: Colors.blue,
                    onTap: bukaPeminjaman,
                  ),

                  menuDashboard(
                    judul: 'Persetujuan Peminjaman',
                    deskripsi:
                        'Kelola pengajuan peminjaman mahasiswa',
                    ikon: Icons.fact_check,
                    warna: Colors.orange,
                    onTap: bukaPersetujuanAdmin,
                  ),

                  menuDashboard(
                    judul: 'Pengembalian Alat',
                    deskripsi:
                        'Ajukan pengembalian alat laboratorium',
                    ikon: Icons.assignment_return,
                    warna: Colors.teal,
                    onTap: bukaPengembalian,
                  ),

                  menuDashboard(
                    judul: 'Konfirmasi Pengembalian',
                    deskripsi:
                        'Konfirmasi alat yang dikembalikan mahasiswa',
                    ikon: Icons.fact_check,
                    warna: Colors.orange,
                    onTap: bukaKonfirmasiPengembalian,
                  ),

                  menuDashboard(
                    judul: 'Riwayat Transaksi',
                    deskripsi:
                        'Lihat seluruh riwayat peminjaman dan pengembalian alat',
                    ikon: Icons.history,
                    warna: Colors.purple,
                    onTap: bukaRiwayat,
                  ),

                  const SizedBox(height: 15),

                  // ==================================
                  // STATUS BLOCKCHAIN
                  // ==================================

                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.green,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Status Blockchain',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(status),

                          if (loading) ...[
                            const SizedBox(height: 10),
                            const LinearProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'LabChain • Ethereum Sepolia',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
