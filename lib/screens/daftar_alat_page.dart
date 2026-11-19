import 'package:flutter/material.dart';

import '../services/labchain_service.dart';

class DaftarAlatPage extends StatefulWidget {
  final LabChainService blockchain;
  final bool isAdmin;

  const DaftarAlatPage({
    super.key,
    required this.blockchain,
    required this.isAdmin,
  });

  @override
  State<DaftarAlatPage> createState() => _DaftarAlatPageState();
}

class _DaftarAlatPageState extends State<DaftarAlatPage> {
  List<Map<String, dynamic>> daftarAlat = [];

  bool loading = true;
  bool menyimpan = false;
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

  Future<void> tambahAlat() async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const _TambahAlatDialog();
      },
    );

    if (data == null || !mounted) return;

    setState(() {
      menyimpan = true;
      error = null;
    });

    try {
      final txHash = await widget.blockchain.tambahAlat(
        data['nama'] as String,
        data['stok'] as int,
      );

      if (!mounted) return;

      setState(() {
        menyimpan = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaksi dikirim: $txHash'),
          duration: const Duration(seconds: 8),
        ),
      );

      // Beri waktu agar transaksi diproses jaringan.
      await Future.delayed(const Duration(seconds: 5));

      if (mounted) {
        await muatDaftarAlat();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        menyimpan = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan alat: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Widget kartuAlat(Map<String, dynamic> alat) {
    final aktif = alat['aktif'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(
            Icons.devices,
            color: Colors.green,
          ),
        ),
        title: Text(
          alat['nama'] as String,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Alat Laboratorium'),
        actions: [
          IconButton(
            onPressed: loading || menyimpan
                ? null
                : muatDaftarAlat,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: menyimpan
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengirim transaksi ke blockchain...'),
                  SizedBox(height: 8),
                  Text('Silakan tunggu.'),
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
                            Text('Gagal memuat data: $error'),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 65,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Belum ada alat laboratorium',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: muatDaftarAlat,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: daftarAlat.length,
                            itemBuilder: (context, index) {
                              return kartuAlat(daftarAlat[index]);
                            },
                          ),
                        ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: loading || menyimpan
                  ? null
                  : tambahAlat,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Alat'),
            )
          : null,
    );
  }
}

// Form dialog tambah alat dipisahkan dari halaman utama.
class _TambahAlatDialog extends StatefulWidget {
  const _TambahAlatDialog();

  @override
  State<_TambahAlatDialog> createState() =>
      _TambahAlatDialogState();
}

class _TambahAlatDialogState extends State<_TambahAlatDialog> {
  final _formKey = GlobalKey<FormState>();

  final _namaController = TextEditingController();
  final _stokController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  void simpanForm() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop({
      'nama': _namaController.text.trim(),
      'stok': int.parse(_stokController.text),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Alat Laboratorium'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Alat',
                hintText: 'Contoh: Sensor DHT11',
                prefixIcon: Icon(Icons.devices),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama alat wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stokController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Stok',
                hintText: 'Contoh: 10',
                prefixIcon: Icon(Icons.inventory),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final stok = int.tryParse(value ?? '');

                if (stok == null || stok <= 0) {
                  return 'Masukkan stok lebih dari 0';
                }

                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: simpanForm,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
