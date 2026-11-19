import 'package:flutter/material.dart';

import '../services/labchain_service.dart';

class PeminjamanPage extends StatefulWidget {
  final LabChainService blockchain;

  const PeminjamanPage({
    super.key,
    required this.blockchain,
  });

  @override
  State<PeminjamanPage> createState() => _PeminjamanPageState();
}

class _PeminjamanPageState extends State<PeminjamanPage> {
  List<Map<String, dynamic>> daftarAlat = [];

  bool loading = true;
  bool mengirim = false;
  String? error;

  @override
  void initState() {
    super.initState();
    muatDaftarAlat();
  }

  Future<void> muatDaftarAlat() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await widget.blockchain.init();

      final jumlah = await widget.blockchain.jumlahAlat();
      final hasil = <Map<String, dynamic>>[];

      for (int i = 0; i < jumlah; i++) {
        final alat = await widget.blockchain.ambilAlat(i);

        hasil.add({
          'id': i,
          ...alat,
        });
      }

      if (!mounted) return;

      setState(() {
        daftarAlat = hasil;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> ajukanPeminjaman(
    Map<String, dynamic> alat,
  ) async {
    final stokTersedia =
        (alat['totalStok'] as int) -
        (alat['sedangDipinjam'] as int);

    if (stokTersedia <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok alat sedang tidak tersedia.'),
        ),
      );
      return;
    }

    final jumlahPinjam = await showDialog<int>(
      context: context,
      builder: (context) {
        return _JumlahPeminjamanDialog(
          namaAlat: alat['nama'] as String,
          stokTersedia: stokTersedia,
        );
      },
    );

    if (jumlahPinjam == null || !mounted) return;

    setState(() {
      mengirim = true;
    });

    try {
      final txHash =
          await widget.blockchain.ajukanPeminjaman(
        alat['id'] as int,
        jumlahPinjam,
      );

      if (!mounted) return;

      setState(() {
        mengirim = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengajuan berhasil dikirim: $txHash',
          ),
          duration: const Duration(seconds: 8),
        ),
      );

      await Future.delayed(const Duration(seconds: 5));

      if (mounted) {
        await muatDaftarAlat();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        mengirim = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengajukan peminjaman: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Widget kartuAlat(Map<String, dynamic> alat) {
    final totalStok = alat['totalStok'] as int;
    final sedangDipinjam = alat['sedangDipinjam'] as int;
    final aktif = alat['aktif'] as bool;

    final tersedia = totalStok - sedangDipinjam;
    final bisaDipinjam = aktif && tersedia > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(
                    Icons.devices,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        alat['nama'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aktif ? 'Alat aktif' : 'Alat tidak aktif',
                        style: TextStyle(
                          color: aktif
                              ? Colors.green
                              : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total stok'),
                Text('$totalStok'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sedang dipinjam'),
                Text('$sedangDipinjam'),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Stok tersedia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$tersedia',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: mengirim || !bisaDipinjam
                    ? null
                    : () => ajukanPeminjaman(alat),
                icon: const Icon(Icons.assignment_outlined),
                label: Text(
                  bisaDipinjam
                      ? 'Ajukan Peminjaman'
                      : 'Tidak Tersedia',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peminjaman Alat'),
        actions: [
          IconButton(
            onPressed: loading || mengirim
                ? null
                : muatDaftarAlat,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: mengirim
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengirim pengajuan ke blockchain...'),
                  SizedBox(height: 8),
                  Text('Silakan konfirmasi di MetaMask.'),
                ],
              ),
            )
          : loading
              ? const Center(
                  child: CircularProgressIndicator(),
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
                            Text('Gagal memuat alat: $error'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: muatDaftarAlat,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : daftarAlat.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada alat laboratorium.',
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: muatDaftarAlat,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: daftarAlat.length,
                            itemBuilder: (context, index) {
                              return kartuAlat(
                                daftarAlat[index],
                              );
                            },
                          ),
                        ),
    );
  }
}

class _JumlahPeminjamanDialog extends StatefulWidget {
  final String namaAlat;
  final int stokTersedia;

  const _JumlahPeminjamanDialog({
    required this.namaAlat,
    required this.stokTersedia,
  });

  @override
  State<_JumlahPeminjamanDialog> createState() =>
      _JumlahPeminjamanDialogState();
}

class _JumlahPeminjamanDialogState
    extends State<_JumlahPeminjamanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController(text: '1');

  @override
  void dispose() {
    _jumlahController.dispose();
    super.dispose();
  }

  void konfirmasi() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      int.parse(_jumlahController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajukan Peminjaman'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama alat: ${widget.namaAlat}'),
            const SizedBox(height: 8),
            Text('Stok tersedia: ${widget.stokTersedia}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah yang dipinjam',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              validator: (value) {
                final jumlah = int.tryParse(value ?? '');

                if (jumlah == null || jumlah <= 0) {
                  return 'Masukkan jumlah yang valid';
                }

                if (jumlah > widget.stokTersedia) {
                  return 'Melebihi stok yang tersedia';
                }

                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: konfirmasi,
          child: const Text('Ajukan'),
        ),
      ],
    );
  }
}
