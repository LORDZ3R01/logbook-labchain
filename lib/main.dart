
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

  String status = 'Menginisialisasi aplikasi...';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      initWallet();
    });
  }

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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status = 'Gagal menginisialisasi aplikasi: $e';
      });
    }
  }

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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        walletLoading = false;
        status = 'Gagal menghubungkan wallet: $e';
      });
    }
  }

  Future<void> putuskanWallet() async {
    try {
      await wallet.disconnect();

      if (!mounted) return;

      setState(() {
        status = 'Wallet berhasil diputuskan.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status = 'Gagal memutuskan wallet: $e';
      });
    }
  }

  Future<void> muatData() async {
    if (!walletReady || loading) return;

    setState(() {
      loading = true;
    });

    try {
      await blockchain.init();

      final alat = await blockchain.jumlahAlat();
      final peminjaman =
          await blockchain.jumlahPeminjaman();

      if (!mounted) return;

      setState(() {
        jumlahAlat = alat;
        jumlahPeminjaman = peminjaman;
        loading = false;
        status = 'Berhasil terhubung ke LabChain Sepolia.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        status = 'Gagal memuat data blockchain: $e';
      });
    }
  }

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

  // Membuka halaman Riwayat Transaksi
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

  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
      ),
    );
  }

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

  @override
  void dispose() {
    if (walletReady) {
      blockchain.dispose();
    }

    super.dispose();
  }

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
                  Text(status),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: muatData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Logbook Peminjaman Alat Laboratorium IoT',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Wallet Connection
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

                  // Data Blockchain
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

                  // Menu Utama
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

                  // Menu Riwayat Transaksi
                  menuDashboard(
                    judul: 'Riwayat Transaksi',
                    deskripsi:
                        'Lihat seluruh riwayat peminjaman dan pengembalian alat',
                    ikon: Icons.history,
                    warna: Colors.purple,
                    onTap: bukaRiwayat,
                  ),

                  const SizedBox(height: 15),

                  // Status Blockchain
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