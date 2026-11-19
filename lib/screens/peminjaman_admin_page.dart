import 'package:flutter/material.dart';

import '../services/labchain_service.dart';

class PeminjamanAdminPage extends StatefulWidget {
  final LabChainService blockchain;

  const PeminjamanAdminPage({
    super.key,
    required this.blockchain,
  });

  @override
  State<PeminjamanAdminPage> createState() =>
      _PeminjamanAdminPageState();
}

class _PeminjamanAdminPageState
    extends State<PeminjamanAdminPage> {
  List<Map<String, dynamic>> daftarPeminjaman = [];

  bool loading = false;
  int? transaksiBerjalan;

  @override
  void initState() {
    super.initState();
    muatPeminjaman();
  }

  // Memuat seluruh data peminjaman dari blockchain.
  Future<void> muatPeminjaman() async {
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
        'Gagal memuat peminjaman: $e',
      );
    }
  }

  // Mengubah status angka menjadi tulisan.
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

  // Mengubah timestamp blockchain menjadi tanggal.
  String formatWaktu(dynamic timestamp) {
    final nilai = timestamp as int;

    if (nilai == 0) {
      return '-';
    }

    final tanggal = DateTime.fromMillisecondsSinceEpoch(
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

  // Konfirmasi persetujuan atau penolakan.
  Future<void> konfirmasiTindakan({
    required int id,
    required bool setujui,
  }) async {
    final tindakan =
        setujui ? 'menyetujui' : 'menolak';

    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            setujui
                ? 'Setujui Peminjaman?'
                : 'Tolak Peminjaman?',
          ),
          content: Text(
            'Apakah kamu yakin ingin $tindakan '
            'pengajuan peminjaman #$id?',
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
                backgroundColor:
                    setujui ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                setujui ? 'Setujui' : 'Tolak',
              ),
            ),
          ],
        );
      },
    );

    if (hasil == true) {
      await prosesTindakan(
        id: id,
        setujui: setujui,
      );
    }
  }

  // Mengirim transaksi ke smart contract.
  Future<void> prosesTindakan({
    required int id,
    required bool setujui,
  }) async {
    if (transaksiBerjalan != null) return;

    setState(() {
      transaksiBerjalan = id;
    });

    try {
      String hasil;

      if (setujui) {
        hasil = await widget.blockchain
            .setujuiPeminjaman(id);
      } else {
        hasil = await widget.blockchain
            .tolakPeminjaman(id);
      }

      if (!mounted) return;

      tampilkanPesan(
        'Transaksi berhasil dikirim. Hash: $hasil',
      );

      await Future.delayed(
        const Duration(seconds: 5),
      );

      if (!mounted) return;

      await muatPeminjaman();
    } catch (e) {
      if (!mounted) return;

      tampilkanPesan(
        'Transaksi gagal: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          transaksiBerjalan = null;
        });
      }
    }
  }

  // Kartu setiap pengajuan peminjaman.
  Widget kartuPeminjaman(
    Map<String, dynamic> data,
  ) {
    final id = data['id'] as int;
    final status = data['status'] as int;
    final menunggu = status == 0;
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
                  Icons.assignment,
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
                      fontSize: 11,
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

            _barisInformasi(
              Icons.inventory_2,
              'Jumlah dipinjam',
              '${data['jumlah']} unit',
            ),

            const SizedBox(height: 9),

            _barisInformasi(
              Icons.account_balance_wallet,
              'Wallet peminjam',
              data['peminjam'].toString(),
            ),

            const SizedBox(height: 9),

            _barisInformasi(
              Icons.access_time,
              'Waktu pengajuan',
              formatWaktu(data['waktuPengajuan']),
            ),

            if (menunggu) ...[
              const SizedBox(height: 18),

              if (sedangDiproses)
                const LinearProgressIndicator(),

              if (!sedangDiproses)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          konfirmasiTindakan(
                            id: id,
                            setujui: false,
                          );
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          konfirmasiTindakan(
                            id: id,
                            setujui: true,
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Setujui'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _barisInformasi(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Persetujuan Peminjaman',
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
                          Icons.assignment_outlined,
                          size: 65,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Center(
                          child: Text(
                            'Belum ada pengajuan peminjaman.',
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Total Pengajuan: '
                          '${daftarPeminjaman.length}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        ...daftarPeminjaman.map(
                          kartuPeminjaman,
                        ),
                      ],
                    ),
            ),
    );
  }
}
