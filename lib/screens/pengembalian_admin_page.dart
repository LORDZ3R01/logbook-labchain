import 'package:flutter/material.dart';

import '../services/labchain_service.dart';

class PengembalianAdminPage extends StatefulWidget {
  final LabChainService blockchain;

  const PengembalianAdminPage({
    super.key,
    required this.blockchain,
  });

  @override
  State<PengembalianAdminPage> createState() =>
      _PengembalianAdminPageState();
}

class _PengembalianAdminPageState
    extends State<PengembalianAdminPage> {
  List<Map<String, dynamic>> daftarPengembalian = [];

  bool loading = false;
  int? transaksiBerjalan;

  @override
  void initState() {
    super.initState();
    muatPengembalian();
  }

  // Memuat semua pengajuan pengembalian.
  Future<void> muatPengembalian() async {
    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      final jumlah =
          await widget.blockchain.jumlahPeminjaman();

      final List<Map<String, dynamic>> data = [];

      for (int i = 0; i < jumlah; i++) {
        final peminjaman =
            await widget.blockchain.ambilPeminjaman(i);

        // Status 3 = Menunggu Pengembalian.
        if (peminjaman['status'] != 3) {
          continue;
        }

        final alatId = peminjaman['alatId'] as int;

        final alat =
            await widget.blockchain.ambilAlat(alatId);

        data.add({
          ...peminjaman,
          'id': i,
          'namaAlat': alat['nama'],
        });
      }

      if (!mounted) return;

      setState(() {
        daftarPengembalian = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      tampilkanPesan(
        'Gagal memuat pengembalian: $e',
      );
    }
  }

  // Format waktu blockchain.
  String formatWaktu(dynamic timestamp) {
    final nilai = timestamp as int;

    if (nilai == 0) return '-';

    final tanggal =
        DateTime.fromMillisecondsSinceEpoch(
      nilai * 1000,
    ).toLocal();

    String duaDigit(int angka) =>
        angka.toString().padLeft(2, '0');

    return '${duaDigit(tanggal.day)}/'
        '${duaDigit(tanggal.month)}/'
        '${tanggal.year} '
        '${duaDigit(tanggal.hour)}:'
        '${duaDigit(tanggal.minute)}';
  }

  // Menampilkan notifikasi.
  void tampilkanPesan(String pesan) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
      ),
    );
  }

  // Dialog konfirmasi.
  Future<void> konfirmasiTindakan(int id) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Konfirmasi Pengembalian?',
          ),
          content: Text(
            'Pastikan alat pada peminjaman #$id '
            'sudah diterima dan diperiksa.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Konfirmasi'),
            ),
          ],
        );
      },
    );

    if (hasil == true) {
      await prosesKonfirmasi(id);
    }
  }

  // Mengirim transaksi konfirmasi ke blockchain.
  Future<void> prosesKonfirmasi(int id) async {
    if (transaksiBerjalan != null) return;

    setState(() {
      transaksiBerjalan = id;
    });

    try {
      final hasil = await widget.blockchain
          .konfirmasiPengembalian(id);

      if (!mounted) return;

      tampilkanPesan(
        'Transaksi berhasil dikirim. Hash: $hasil',
      );

      await Future.delayed(
        const Duration(seconds: 5),
      );

      if (!mounted) return;

      await muatPengembalian();
    } catch (e) {
      if (!mounted) return;

      tampilkanPesan(
        'Gagal mengonfirmasi pengembalian: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          transaksiBerjalan = null;
        });
      }
    }
  }

  // Baris informasi.
  Widget barisInformasi(
    IconData ikon,
    String judul,
    String nilai,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          ikon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 125,
          child: Text(
            judul,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            nilai,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Kartu pengajuan pengembalian.
  Widget kartuPengembalian(
    Map<String, dynamic> data,
  ) {
    final id = data['id'] as int;
    final sedangDiproses = transaksiBerjalan == id;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_return,
                  color: Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pengembalian #$id',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Menunggu Konfirmasi',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 25),

            Text(
              data['namaAlat'].toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            barisInformasi(
              Icons.inventory_2,
              'Jumlah alat',
              '${data['jumlah']} unit',
            ),

            const SizedBox(height: 9),

            barisInformasi(
              Icons.account_balance_wallet,
              'Wallet mahasiswa',
              data['peminjam'].toString(),
            ),

            const SizedBox(height: 9),

            barisInformasi(
              Icons.access_time,
              'Waktu pengajuan',
              formatWaktu(
                data['waktuPengajuanKembali'],
              ),
            ),

            const SizedBox(height: 18),

            if (sedangDiproses)
              const LinearProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    konfirmasiTindakan(id);
                  },
                  icon: const Icon(
                    Icons.check_circle,
                  ),
                  label: const Text(
                    'Konfirmasi Pengembalian',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Tampilan halaman.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Pengembalian',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : muatPengembalian,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: loading && daftarPengembalian.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: muatPengembalian,
              child: daftarPengembalian.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 130),
                        Icon(
                          Icons.assignment_return_outlined,
                          size: 65,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Center(
                          child: Text(
                            'Belum ada pengajuan pengembalian.',
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Total Pengajuan: '
                          '${daftarPengembalian.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...daftarPengembalian.map(
                          kartuPengembalian,
                        ),
                      ],
                    ),
            ),
    );
  }
}
