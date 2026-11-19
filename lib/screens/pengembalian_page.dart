import 'package:flutter/material.dart';

import '../services/labchain_service.dart';

class PengembalianPage extends StatefulWidget {
  final LabChainService blockchain;

  const PengembalianPage({
    super.key,
    required this.blockchain,
  });

  @override
  State<PengembalianPage> createState() =>
      _PengembalianPageState();
}

class _PengembalianPageState extends State<PengembalianPage> {
  List<Map<String, dynamic>> daftarPeminjaman = [];

  bool loading = false;
  int? transaksiBerjalan;

  @override
  void initState() {
    super.initState();
    muatPeminjaman();
  }

  // Memuat peminjaman milik wallet yang sedang terhubung.
  Future<void> muatPeminjaman() async {
    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      final alamatWallet =
          widget.blockchain.walletConnection.address;

      if (alamatWallet == null) {
        throw Exception('Wallet belum terhubung.');
      }

      final jumlah =
          await widget.blockchain.jumlahPeminjaman();

      final List<Map<String, dynamic>> data = [];

      for (int i = 0; i < jumlah; i++) {
        final peminjaman =
            await widget.blockchain.ambilPeminjaman(i);

        final peminjam =
            peminjaman['peminjam'].toString();

        // Hanya menampilkan peminjaman milik wallet ini.
        if (peminjam.toLowerCase() !=
            alamatWallet.toLowerCase()) {
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
        daftarPeminjaman = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      tampilkanPesan(
        'Gagal memuat data peminjaman: $e',
      );
    }
  }

  // Nama status peminjaman.
  String namaStatus(int status) {
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
        return Colors.green;
      case 2:
        return Colors.red;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Format waktu blockchain.
  String formatWaktu(dynamic timestamp) {
    final nilai = timestamp as int;

    if (nilai == 0) {
      return '-';
    }

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

  // Notifikasi.
  void tampilkanPesan(String pesan) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
      ),
    );
  }

  // Dialog konfirmasi pengembalian.
  Future<void> konfirmasiPengembalian(int id) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Ajukan Pengembalian?',
          ),
          content: Text(
            'Apakah kamu yakin ingin mengajukan '
            'pengembalian untuk peminjaman #$id?',
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
              child: const Text('Ya, Ajukan'),
            ),
          ],
        );
      },
    );

    if (hasil == true) {
      await prosesPengembalian(id);
    }
  }

  // Mengirim transaksi ke smart contract.
  Future<void> prosesPengembalian(int id) async {
    if (transaksiBerjalan != null) return;

    setState(() {
      transaksiBerjalan = id;
    });

    try {
      final hasil = await widget.blockchain
          .ajukanPengembalian(id);

      if (!mounted) return;

      tampilkanPesan(
        'Transaksi pengembalian berhasil dikirim. '
        'Hash: $hasil',
      );

      await Future.delayed(
        const Duration(seconds: 5),
      );

      if (!mounted) return;

      await muatPeminjaman();
    } catch (e) {
      if (!mounted) return;

      tampilkanPesan(
        'Gagal mengajukan pengembalian: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          transaksiBerjalan = null;
        });
      }
    }
  }

  // Informasi setiap peminjaman.
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
          width: 115,
          child: Text(
            judul,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            nilai,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Kartu peminjaman.
  Widget kartuPeminjaman(
    Map<String, dynamic> data,
  ) {
    final id = data['id'] as int;
    final status = data['status'] as int;

    final bisaDikembalikan = status == 1;
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
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Peminjaman #$id',
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
                    color: warnaStatus(status)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    namaStatus(status),
                    style: TextStyle(
                      color: warnaStatus(status),
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
              'Jumlah dipinjam',
              '${data['jumlah']} unit',
            ),

            const SizedBox(height: 9),

            barisInformasi(
              Icons.access_time,
              'Waktu pengajuan',
              formatWaktu(data['waktuPengajuan']),
            ),

            if (status == 3) ...[
              const SizedBox(height: 15),
              const Text(
                'Pengembalian sudah diajukan. '
                'Silakan menunggu konfirmasi admin.',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                ),
              ),
            ],

            if (status == 4) ...[
              const SizedBox(height: 15),
              const Text(
                'Alat sudah dikembalikan dan dikonfirmasi admin.',
                style: TextStyle(
                  color: Colors.teal,
                  fontSize: 12,
                ),
              ),
            ],

            if (bisaDikembalikan) ...[
              const SizedBox(height: 18),

              if (sedangDiproses)
                const LinearProgressIndicator(),

              if (!sedangDiproses)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      konfirmasiPengembalian(id);
                    },
                    icon: const Icon(
                      Icons.assignment_return,
                    ),
                    label: const Text(
                      'Ajukan Pengembalian',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengembalian Alat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: loading ? null : muatPeminjaman,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: loading && daftarPeminjaman.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: muatPeminjaman,
              child: daftarPeminjaman.isEmpty
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
                            'Belum ada riwayat peminjaman.',
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Riwayat Peminjaman Saya',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Lihat status dan ajukan pengembalian alat.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 18),

                        ...daftarPeminjaman.map(
                          kartuPeminjaman,
                        ),
                      ],
                    ),
            ),
    );
  }
}
