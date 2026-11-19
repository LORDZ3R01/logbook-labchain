
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/labchain_service.dart';

class RiwayatPage extends StatefulWidget {
  final LabChainService blockchain;

  const RiwayatPage({
    super.key,
    required this.blockchain,
  });

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  bool loading = true;
  String? error;

  final TextEditingController pencarianController =
      TextEditingController();

  List<Map<String, dynamic>> daftarRiwayat = [];

  List<Map<String, dynamic>> daftarTransaksiBlockchain = [];

  int filterStatus = -1;

  @override
  void initState() {
    super.initState();
    muatRiwayat();
  }

  @override
  void dispose() {
    pencarianController.dispose();
    super.dispose();
  }

  // ==========================================
  // MEMUAT DATA RIWAYAT DAN EVENT BLOCKCHAIN
  // ==========================================

  Future<void> muatRiwayat() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Membaca jumlah peminjaman dari smart contract.
      final jumlah =
          await widget.blockchain.jumlahPeminjaman();

      final List<Map<String, dynamic>> data = [];

      // Membaca seluruh data peminjaman.
      for (int i = 0; i < jumlah; i++) {
        final peminjaman =
            await widget.blockchain.ambilPeminjaman(i);

        final alatId = peminjaman['alatId'] as int;

        final alat =
            await widget.blockchain.ambilAlat(alatId);

        data.add({
          'id': i,
          'namaAlat': alat['nama'],
          'jumlah': peminjaman['jumlah'],
          'peminjam': peminjaman['peminjam'],
          'waktuPengajuan':
              peminjaman['waktuPengajuan'],
          'waktuPersetujuan':
              peminjaman['waktuPersetujuan'],
          'waktuPengajuanKembali':
              peminjaman['waktuPengajuanKembali'],
          'waktuPengembalian':
              peminjaman['waktuPengembalian'],
          'status': peminjaman['status'],
        });
      }

      // Membaca Transaction Hash, Wallet Pelaku,
      // dan Block Number langsung dari event blockchain.
      final transaksiBlockchain =
          await widget.blockchain
              .ambilRiwayatTransaksiBlockchain();

      if (!mounted) return;

      setState(() {
        daftarRiwayat = data.reversed.toList();

        daftarTransaksiBlockchain =
            transaksiBlockchain;

        loading = false;
      });

      debugPrint('======================================');
      debugPrint('RIWAYAT LABCHAIN BERHASIL DIMUAT');
      debugPrint(
        'Total peminjaman: ${daftarRiwayat.length}',
      );
      debugPrint(
        'Total event blockchain: '
        '${daftarTransaksiBlockchain.length}',
      );
      debugPrint('======================================');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });

      debugPrint(
        'Gagal memuat riwayat LabChain: $e',
      );
    }
  }

  // ==========================================
  // FILTER DAN RINGKASAN
  // ==========================================

  List<Map<String, dynamic>> get riwayatTerfilter {
    final kataKunci =
        pencarianController.text.trim().toLowerCase();

    return daftarRiwayat.where((data) {
      final nama = data['namaAlat']
          .toString()
          .toLowerCase();

      final walletPeminjam = data['peminjam']
          .toString()
          .toLowerCase();

      final id = data['id'].toString();

      // Cari juga Transaction Hash dan Wallet Pelaku.
      final transaksi = transaksiUntukPeminjaman(
        data['id'] as int,
      );

      final cocokTransaksi = transaksi.any((item) {
        final hash = item['transactionHash']
                ?.toString()
                .toLowerCase() ??
            '';

        final wallet = item['wallet']
                ?.toString()
                .toLowerCase() ??
            '';

        return hash.contains(kataKunci) ||
            wallet.contains(kataKunci);
      });

      final cocokPencarian =
          kataKunci.isEmpty ||
          nama.contains(kataKunci) ||
          walletPeminjam.contains(kataKunci) ||
          id.contains(kataKunci) ||
          cocokTransaksi;

      final status = data['status'] as int;

      final cocokStatus =
          filterStatus == -1 ||
          status == filterStatus;

      return cocokPencarian && cocokStatus;
    }).toList();
  }

  int get totalDikembalikan {
    return daftarRiwayat.where(
      (data) => data['status'] == 4,
    ).length;
  }

  int get totalDitolak {
    return daftarRiwayat.where(
      (data) => data['status'] == 2,
    ).length;
  }

  int get totalBerlangsung {
    return daftarRiwayat.where((data) {
      final status = data['status'] as int;

      return status == 0 ||
          status == 1 ||
          status == 3;
    }).length;
  }

  // ==========================================
  // FORMAT TANGGAL
  // ==========================================

  String formatTanggal(dynamic timestamp) {
    final int waktu =
        timestamp is int ? timestamp : 0;

    if (waktu <= 0) {
      return 'Belum tersedia';
    }

    final tanggal = DateTime.fromMillisecondsSinceEpoch(
      waktu * 1000,
    );

    final hari =
        tanggal.day.toString().padLeft(2, '0');

    final bulan =
        tanggal.month.toString().padLeft(2, '0');

    final tahun = tanggal.year;

    final jam =
        tanggal.hour.toString().padLeft(2, '0');

    final menit =
        tanggal.minute.toString().padLeft(2, '0');

    return '$hari/$bulan/$tahun $jam:$menit';
  }

  // ==========================================
  // STATUS PEMINJAMAN
  // ==========================================

  String statusPeminjaman(int status) {
    switch (status) {
      case 0:
        return 'Menunggu Persetujuan';
      case 1:
        return 'Disetujui';
      case 2:
        return 'Ditolak';
      case 3:
        return 'Menunggu Pengembalian';
      case 4:
        return 'Dikembalikan';
      default:
        return 'Status Tidak Diketahui';
    }
  }

  Color warnaStatus(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.red;
      case 3:
        return Colors.deepOrange;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ==========================================
  // TRANSAKSI BLOCKCHAIN
  // ==========================================

  List<Map<String, dynamic>> transaksiUntukPeminjaman(
    int id,
  ) {
    final hasil = daftarTransaksiBlockchain.where(
      (transaksi) {
        final idTransaksi = int.tryParse(
          transaksi['peminjamanId']?.toString() ?? '',
        );

        return idTransaksi == id;
      },
    ).toList();

    // Urutkan berdasarkan block paling lama ke terbaru
    // agar aktivitas tampil sesuai urutan proses.
    hasil.sort((a, b) {
      final blokA =
          (a['blockNumber'] as num?)?.toInt() ?? 0;

      final blokB =
          (b['blockNumber'] as num?)?.toInt() ?? 0;

      if (blokA != blokB) {
        return blokA.compareTo(blokB);
      }

      final logA =
          (a['logIndex'] as num?)?.toInt() ?? 0;

      final logB =
          (b['logIndex'] as num?)?.toInt() ?? 0;

      return logA.compareTo(logB);
    });

    return hasil;
  }

  // ==========================================
  // SALIN TRANSACTION HASH
  // ==========================================

  Future<void> salinHash(String hash) async {
    await Clipboard.setData(
      ClipboardData(text: hash),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Transaction Hash berhasil disalin',
        ),
      ),
    );
  }

  // ==========================================
  // BUKA BLOCKSCOUT
  // ==========================================

  Future<void> bukaBlockscout(String hash) async {
    final valid = RegExp(
      r'^0x[a-fA-F0-9]{64}$',
    ).hasMatch(hash);

    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transaction Hash tidak valid',
          ),
        ),
      );

      return;
    }

    final url = Uri.parse(
      'https://eth-sepolia.blockscout.com/tx/$hash',
    );

    try {
      final berhasil = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!berhasil && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tidak dapat membuka Blockscout',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal membuka Blockscout: $e',
          ),
        ),
      );
    }
  }

  // ==========================================
  // DETAIL TRANSAKSI BLOCKCHAIN
  // ==========================================

  Widget bagianTransaksiBlockchain(int id) {
    final transaksi = transaksiUntukPeminjaman(id);

    return Card(
      elevation: 0,
      color: Colors.blue.withValues(alpha: 0.05),
      child: ExpansionTile(
        leading: const Icon(
          Icons.account_balance,
          color: Colors.blue,
        ),
        title: const Text(
          'Detail Transaksi Blockchain',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${transaksi.length} aktivitas tercatat di blockchain',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          if (transaksi.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Belum ditemukan event blockchain '
                'untuk peminjaman ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            )
          else
            ...transaksi.map((item) {
              final aktivitas =
                  item['aktivitas']?.toString() ??
                      'Aktivitas';

              final hash =
                  item['transactionHash']?.toString() ??
                      '';

              final walletPelaku =
                  item['wallet']?.toString() ?? '';

              final blockNumber =
                  (item['blockNumber'] as num?)?.toInt() ??
                      0;

              final eventName =
                  item['eventName']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Divider(),

                    Text(
                      aktivitas,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 5),

                    if (eventName.isNotEmpty)
                      Text(
                        'Event: $eventName',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),

                    const SizedBox(height: 12),

                    const Text(
                      'Transaction Hash',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 5),

                    SelectableText(
                      hash.isEmpty
                          ? 'Tidak tersedia'
                          : hash,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: hash.isEmpty
                                ? null
                                : () => salinHash(hash),
                            icon: const Icon(
                              Icons.copy,
                              size: 16,
                            ),
                            label: const Text(
                              'Salin Hash',
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: hash.isEmpty
                                ? null
                                : () => bukaBlockscout(hash),
                            icon: const Icon(
                              Icons.open_in_new,
                              size: 16,
                            ),
                            label: const Text(
                              'Blockscout',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Wallet Pelaku',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 5),

                    SelectableText(
                      walletPelaku.isEmpty
                          ? 'Tidak tersedia'
                          : walletPelaku,
                      style: const TextStyle(
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Icon(
                          Icons.view_in_ar,
                          size: 16,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 7),

                        Expanded(
                          child: Text(
                            'Block Number: $blockNumber',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET RINGKASAN
  // ==========================================

  Widget kartuRingkasan({
    required String judul,
    required int jumlah,
    required IconData ikon,
    required Color warna,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 14,
          ),
          child: Column(
            children: [
              Icon(
                ikon,
                color: warna,
                size: 27,
              ),

              const SizedBox(height: 8),

              Text(
                '$jumlah',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: warna,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                judul,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget bagianRingkasan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Transaksi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            kartuRingkasan(
              judul: 'Total',
              jumlah: daftarRiwayat.length,
              ikon: Icons.receipt_long,
              warna: Colors.blue,
            ),

            kartuRingkasan(
              judul: 'Dikembalikan',
              jumlah: totalDikembalikan,
              ikon: Icons.check_circle,
              warna: Colors.green,
            ),

            kartuRingkasan(
              judul: 'Berlangsung',
              jumlah: totalBerlangsung,
              ikon: Icons.pending_actions,
              warna: Colors.orange,
            ),
          ],
        ),

        const SizedBox(height: 5),

        Text(
          'Ditolak: $totalDitolak transaksi',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET WAKTU
  // ==========================================

  Widget informasiWaktu({
    required String judul,
    required dynamic waktu,
    required IconData ikon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            ikon,
            size: 18,
            color: Colors.grey.shade600,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  formatTanggal(waktu),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // KARTU RIWAYAT PEMINJAMAN
  // ==========================================

  Widget kartuRiwayat(
    Map<String, dynamic> data,
  ) {
    final int status = data['status'] as int;
    final Color warna = warnaStatus(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Colors.green.withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.devices,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['namaAlat'].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      Text(
                        'ID Peminjaman #${data['id']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 25),

            Row(
              children: [
                const Icon(
                  Icons.inventory,
                  size: 18,
                  color: Colors.grey,
                ),

                const SizedBox(width: 10),

                const Text('Jumlah dipinjam:'),

                const Spacer(),

                Text(
                  '${data['jumlah']} unit',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Alamat Wallet Peminjam',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 4),

            SelectableText(
              data['peminjam'].toString(),
              style: const TextStyle(
                fontSize: 11,
              ),
            ),

            const Divider(height: 25),

            const Text(
              'Riwayat Aktivitas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 15),

            informasiWaktu(
              judul: 'Pengajuan Peminjaman',
              waktu: data['waktuPengajuan'],
              ikon: Icons.send,
            ),

            informasiWaktu(
              judul: 'Persetujuan Admin',
              waktu: data['waktuPersetujuan'],
              ikon: Icons.verified,
            ),

            informasiWaktu(
              judul: 'Pengajuan Pengembalian',
              waktu: data['waktuPengajuanKembali'],
              ikon: Icons.assignment_return,
            ),

            informasiWaktu(
              judul: 'Konfirmasi Pengembalian',
              waktu: data['waktuPengembalian'],
              ikon: Icons.check_circle,
            ),

            const Divider(height: 20),

            Row(
              children: [
                const Text(
                  'Status:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: warna.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusPeminjaman(status),
                    style: TextStyle(
                      color: warna,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            bagianTransaksiBlockchain(
              data['id'] as int,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // PENCARIAN
  // ==========================================

  Widget bagianPencarian() {
    return TextField(
      controller: pencarianController,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText:
            'Cari nama alat, wallet, hash, atau ID...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon:
            pencarianController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      pencarianController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ==========================================
  // FILTER STATUS
  // ==========================================

  Widget bagianFilter() {
    return DropdownButtonFormField<int>(
      initialValue: filterStatus,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Filter Status Transaksi',
        prefixIcon: const Icon(Icons.filter_list),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: -1,
          child: Text('Semua Status'),
        ),
        DropdownMenuItem(
          value: 0,
          child: Text('Menunggu Persetujuan'),
        ),
        DropdownMenuItem(
          value: 1,
          child: Text('Disetujui'),
        ),
        DropdownMenuItem(
          value: 2,
          child: Text('Ditolak'),
        ),
        DropdownMenuItem(
          value: 3,
          child: Text('Menunggu Pengembalian'),
        ),
        DropdownMenuItem(
          value: 4,
          child: Text('Dikembalikan'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          filterStatus = value;
        });
      },
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final hasil = riwayatTerfilter;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : muatRiwayat,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),

      body: loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text(
                    'Memuat data blockchain...',
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Mohon tunggu, sedang membaca event Sepolia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 45,
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Gagal memuat riwayat transaksi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          error!,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 15),

                        ElevatedButton.icon(
                          onPressed: muatRiwayat,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: muatRiwayat,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      bagianRingkasan(),

                      const SizedBox(height: 22),

                      const Text(
                        'Cari Transaksi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(height: 10),

                      bagianPencarian(),

                      const SizedBox(height: 15),

                      bagianFilter(),

                      const SizedBox(height: 20),

                      Text(
                        'Menampilkan ${hasil.length} '
                        'dari ${daftarRiwayat.length} transaksi',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (hasil.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 55,
                                color: Colors.grey.shade400,
                              ),

                              const SizedBox(height: 12),

                              const Text(
                                'Transaksi Tidak Ditemukan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                'Coba ubah kata kunci '
                                'atau filter status.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...hasil.map(kartuRiwayat),
                    ],
                  ),
                ),
    );
  }
}
