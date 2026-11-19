import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart' as wallet;

import '../config/blockchain_config.dart';
import 'wallet_connection_service.dart';
import 'transaction_history_service.dart';

class LabChainService {
  late Web3Client _client;
  late DeployedContract _contract;

  final WalletConnectionService walletConnection;
  final TransactionHistoryService _history = TransactionHistoryService();

  bool _initialized = false;
  bool _sedangMemindai = false;

  static const String _keyBlokTerakhir =
      'labchain_last_scanned_block';
  static const String _keyRiwayatBlockchain =
      'labchain_blockchain_history';

  LabChainService(this.walletConnection);

  // ==========================================
  // INISIALISASI BLOCKCHAIN
  // ==========================================

  Future<void> init() async {
    if (_initialized) return;

    try {
      _client = Web3Client(
        BlockchainConfig.rpcUrl,
        http.Client(),
      );

      final abi = await rootBundle.loadString(
        'assets/abi/LabChain.json',
      );

      final contractAbi = ContractAbi.fromJson(
        abi,
        BlockchainConfig.labChainName,
      );

      _contract = DeployedContract(
        contractAbi,
        wallet.EthereumAddress.fromHex(
          BlockchainConfig.labChainAddress,
        ),
      );

      final networkId = await _client.getNetworkId();

      if (networkId != BlockchainConfig.chainId) {
        throw Exception('Jaringan bukan Sepolia!');
      }

      final code = await _client.getCode(_contract.address);

      if (code.isEmpty) {
        throw Exception(
          'Smart contract LabChain tidak ditemukan!',
        );
      }

      _initialized = true;

      debugPrint('======================================');
      debugPrint('LABCHAIN BLOCKCHAIN TERHUBUNG');
      debugPrint('Contract: ${BlockchainConfig.labChainAddress}');
      debugPrint('Network: Ethereum Sepolia');
      debugPrint(
        'Deployment Block: '
        '${BlockchainConfig.labChainDeploymentBlock}',
      );
      debugPrint('======================================');
    } catch (e) {
      throw Exception('Gagal menginisialisasi LabChain: $e');
    }
  }

  // ==========================================
  // HELPER RETRY UNTUK RPC
  // ==========================================

  Future<T> _denganRetryRpc<T>(
    Future<T> Function() aksi, {
    required String namaOperasi,
    int maksimalPercobaan = 5,
  }) async {
    for (int percobaan = 0;
        percobaan < maksimalPercobaan;
        percobaan++) {
      try {
        final hasil = await aksi();
        return hasil;
      } catch (e) {
        final pesan = e.toString().toLowerCase();
        final terkenaRateLimit =
            pesan.contains('429') ||
            pesan.contains('compute units per second') ||
            pesan.contains('throughput');

        if (!terkenaRateLimit ||
            percobaan == maksimalPercobaan - 1) {
          rethrow;
        }

        final detikTunggu = 1 << percobaan;
        debugPrint(
          'RPC rate limit pada $namaOperasi. '
          'Percobaan ${percobaan + 1}/$maksimalPercobaan, '
          'menunggu $detikTunggu detik. Error: $e',
        );
        await Future.delayed(Duration(seconds: detikTunggu));
      }
    }

    throw Exception('RPC $namaOperasi gagal setelah retry.');
  }

  // ==========================================
  // PENYIMPANAN RIWAYAT BLOCKCHAIN LOKAL
  // ==========================================

  Future<List<Map<String, dynamic>>> _muatRiwayatTersimpan() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyRiwayatBlockchain);

    if (data == null || data.isEmpty) return [];

    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();
    } catch (e) {
      debugPrint('Gagal membaca cache riwayat: $e');
      return [];
    }
  }

  Future<void> _simpanRiwayatTersimpan(
    List<Map<String, dynamic>> riwayat,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyRiwayatBlockchain,
      jsonEncode(riwayat),
    );
  }

  Future<int> _ambilBlokTerakhir() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyBlokTerakhir) ??
        (BlockchainConfig.labChainDeploymentBlock - 1);
  }

  Future<void> _simpanBlokTerakhir(int blok) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyBlokTerakhir, blok);
  }

  // Menghapus checkpoint hanya jika memang ingin mengulang
  // pemindaian seluruh riwayat dari awal.
  Future<void> resetRiwayatBlockchainLokal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBlokTerakhir);
    await prefs.remove(_keyRiwayatBlockchain);
    debugPrint('Checkpoint dan cache riwayat LabChain dihapus.');
  }

  // ==========================================
  // MENGIRIM TRANSAKSI
  // ==========================================

  Future<String> _transaksi(
    String functionName,
    List<dynamic> parameters, {
    int? peminjamanId,
    String? aktivitas,
  }) async {
    if (!_initialized) await init();

    if (!walletConnection.isConnected) {
      throw Exception('Hubungkan wallet terlebih dahulu');
    }

    final result = await walletConnection.kirimTransaksi(
      contract: _contract,
      functionName: functionName,
      parameters: parameters,
    );

    final transactionHash = result.toString();

    debugPrint('======================================');
    debugPrint('LABCHAIN TRANSACTION');
    debugPrint('Fungsi: $functionName');
    debugPrint('Transaction Hash: $transactionHash');
    debugPrint('======================================');

    final hashValid = RegExp(r'^0x[a-fA-F0-9]{64}$')
        .hasMatch(transactionHash);

    if (hashValid && aktivitas != null) {
      try {
        await _history.simpanTransaksi(
          peminjamanId: peminjamanId,
          aktivitas: aktivitas,
          transactionHash: transactionHash,
          wallet: walletConnection.address ?? '',
        );
        debugPrint('Riwayat transaksi lokal berhasil disimpan.');
      } catch (e) {
        debugPrint('Gagal menyimpan riwayat lokal: $e');
      }
    }

    return transactionHash;
  }

  // ==========================================
  // MEMBACA RIWAYAT TRANSAKSI BLOCKCHAIN
  // ==========================================

  Future<List<Map<String, dynamic>>>
      ambilRiwayatTransaksiBlockchain({
    int ukuranRentangBlok = 10,
  }) async {
    if (!_initialized) await init();

    if (ukuranRentangBlok <= 0 || ukuranRentangBlok > 10) {
      throw Exception(
        'Rentang blok harus antara 1 sampai 10 untuk Alchemy Free.',
      );
    }

    // Jika pemanggilan kedua terjadi ketika scan masih berjalan,
    // tampilkan cache yang tersedia tanpa memulai scan paralel.
    if (_sedangMemindai) {
      debugPrint('Pemindaian riwayat sedang berlangsung.');
      return _muatRiwayatTersimpan();
    }

    _sedangMemindai = true;

    try {
      final int blokTerbaru = await _denganRetryRpc(
        () => _client.getBlockNumber(),
        namaOperasi: 'getBlockNumber',
      );

      final int blokAwal = BlockchainConfig.labChainDeploymentBlock;
      final List<Map<String, dynamic>> hasil =
          await _muatRiwayatTersimpan();

      int blokTerakhir = await _ambilBlokTerakhir();
      if (blokTerakhir < blokAwal - 1) {
        blokTerakhir = blokAwal - 1;
      }

      debugPrint('======================================');
      debugPrint('INCREMENTAL SCANNING LABCHAIN');
      debugPrint('Blok deployment: $blokAwal');
      debugPrint('Blok terakhir tersimpan: $blokTerakhir');
      debugPrint('Blok terbaru: $blokTerbaru');
      debugPrint('Riwayat tersimpan: ${hasil.length}');
      debugPrint('======================================');

      if (blokTerbaru < blokAwal || blokTerakhir >= blokTerbaru) {
        debugPrint('Tidak ada blok baru untuk dipindai.');
        _urutkanRiwayat(hasil);
        return hasil;
      }

      final Map<String, ContractEvent> daftarEvent = {
        'PeminjamanDiajukan': _contract.event('PeminjamanDiajukan'),
        'PeminjamanDisetujui': _contract.event('PeminjamanDisetujui'),
        'PeminjamanDitolak': _contract.event('PeminjamanDitolak'),
        'PengembalianDiajukan': _contract.event('PengembalianDiajukan'),
        'PengembalianDikonfirmasi':
            _contract.event('PengembalianDikonfirmasi'),
      };

      final Map<String, ContractEvent> eventBerdasarkanSignature = {};
      for (final entry in daftarEvent.entries) {
        final signature = bytesToHex(
          entry.value.signature,
          include0x: true,
        ).toLowerCase();
        eventBerdasarkanSignature[signature] = entry.value;
      }

      final Set<String> transaksiSudahAda = hasil.map((item) {
        return '${item['transactionHash']}_${item['logIndex']}';
      }).toSet();

      int dariBlok = blokTerakhir + 1;

      while (dariBlok <= blokTerbaru) {
        final int sampaiBlok = (dariBlok + ukuranRentangBlok - 1)
            .clamp(dariBlok, blokTerbaru)
            .toInt();

        debugPrint('Membaca blok $dariBlok sampai $sampaiBlok');

        // Jika eth_getLogs gagal setelah retry, exception diteruskan.
        // Cursor belum dimajukan sehingga rentang ini akan dicoba lagi
        // ketika fungsi dipanggil berikutnya.
        final logs = await _denganRetryRpc(
          () => _client.getLogs(
            FilterOptions(
              address: _contract.address,
              fromBlock: BlockNum.exact(dariBlok),
              toBlock: BlockNum.exact(sampaiBlok),
            ),
          ),
          namaOperasi: 'eth_getLogs $dariBlok-$sampaiBlok',
        );

        for (final log in logs) {
          if (log.removed == true) continue;

          final topics = log.topics;
          final data = log.data;
          if (topics == null || topics.isEmpty || data == null) continue;

          final signature = topics.first?.toLowerCase();
          if (signature == null) continue;

          final event = eventBerdasarkanSignature[signature];
          if (event == null) continue;

          final transactionHash = log.transactionHash;
          if (transactionHash == null || transactionHash.isEmpty) continue;

          final int logIndex = log.logIndex ?? 0;
          final String uniqueKey = '${transactionHash}_$logIndex';
          if (transaksiSudahAda.contains(uniqueKey)) continue;

          try {
            final decoded = event.decodeResults(topics, data);
            if (decoded.isEmpty) continue;

            final int idPeminjaman =
                (decoded[0] as BigInt).toInt();

            String aktivitas;
            switch (event.name) {
              case 'PeminjamanDiajukan':
                aktivitas = 'Pengajuan Peminjaman';
                break;
              case 'PeminjamanDisetujui':
                aktivitas = 'Persetujuan Peminjaman';
                break;
              case 'PeminjamanDitolak':
                aktivitas = 'Penolakan Peminjaman';
                break;
              case 'PengembalianDiajukan':
                aktivitas = 'Pengajuan Pengembalian';
                break;
              case 'PengembalianDikonfirmasi':
                aktivitas = 'Konfirmasi Pengembalian';
                break;
              default:
                continue;
            }

            // Kegagalan mengambil detail transaksi tidak membuang event.
            // Wallet dikosongkan dan event tetap tersimpan.
            String walletPelaku = '';
            try {
              final transaction = await _denganRetryRpc(
                () => _client.getTransactionByHash(transactionHash),
                namaOperasi: 'getTransactionByHash',
              );
              if (transaction != null) {
                walletPelaku = transaction.from.with0x;
              }
            } catch (e) {
              debugPrint(
                'Wallet transaksi belum berhasil dibaca '
                '($transactionHash): $e',
              );
            }

            hasil.add({
              'peminjamanId': idPeminjaman,
              'aktivitas': aktivitas,
              'eventName': event.name,
              'transactionHash': transactionHash,
              'wallet': walletPelaku,
              'blockNumber': log.blockNum ?? 0,
              'blockHash': log.blockHash ?? '',
              'transactionIndex': log.transactionIndex ?? 0,
              'logIndex': logIndex,
            });

            transaksiSudahAda.add(uniqueKey);
          } catch (e) {
            // Jangan diam-diam melewatkan event yang gagal didekode.
            // Dengan melempar exception, cursor rentang ini tidak maju.
            debugPrint('Gagal decode event ${event.name}: $e');
            rethrow;
          }
        }

        // Simpan hasil dan cursor setelah seluruh log pada rentang ini
        // berhasil diproses. Jika aplikasi berhenti, rentang berikutnya
        // dilanjutkan dari cursor yang tersimpan.
        await _simpanRiwayatTersimpan(hasil);
        await _simpanBlokTerakhir(sampaiBlok);

        debugPrint('Berhasil menyimpan sampai blok $sampaiBlok');
        dariBlok = sampaiBlok + 1;
      }

      _urutkanRiwayat(hasil);
      await _simpanRiwayatTersimpan(hasil);

      debugPrint('======================================');
      debugPrint('INCREMENTAL SCANNING SELESAI');
      debugPrint('Blok terakhir: $blokTerbaru');
      debugPrint('Total transaksi: ${hasil.length}');
      debugPrint('======================================');

      return hasil;
    } finally {
      _sedangMemindai = false;
    }
  }

  void _urutkanRiwayat(List<Map<String, dynamic>> hasil) {
    hasil.sort((a, b) {
      final perbandinganBlok =
          (b['blockNumber'] as int).compareTo(a['blockNumber'] as int);
      if (perbandinganBlok != 0) return perbandinganBlok;

      final perbandinganTransaksi =
          (b['transactionIndex'] as int)
              .compareTo(a['transactionIndex'] as int);
      if (perbandinganTransaksi != 0) return perbandinganTransaksi;

      return (b['logIndex'] as int).compareTo(a['logIndex'] as int);
    });
  }

  // ==========================================
  // MENGELOLA ALAT
  // ==========================================

  Future<String> tambahAlat(String nama, int totalStok) async {
    if (nama.trim().isEmpty || totalStok <= 0) {
      throw Exception('Nama dan stok alat harus valid');
    }
    return _transaksi('tambahAlat', [
      nama.trim(),
      BigInt.from(totalStok),
    ]);
  }

  Future<int> jumlahAlat() async {
    if (!_initialized) await init();
    final result = await _client.call(
      contract: _contract,
      function: _contract.function('jumlahAlat'),
      params: [],
    );
    return (result[0] as BigInt).toInt();
  }

  Future<Map<String, dynamic>> ambilAlat(int id) async {
    if (!_initialized) await init();
    final result = await _client.call(
      contract: _contract,
      function: _contract.function('ambilAlat'),
      params: [BigInt.from(id)],
    );
    return {
      'nama': result[0] as String,
      'totalStok': (result[1] as BigInt).toInt(),
      'sedangDipinjam': (result[2] as BigInt).toInt(),
      'aktif': result[3] as bool,
    };
  }

  Future<String> ubahAlat(
    int id,
    String nama,
    int totalStok,
    bool aktif,
  ) async {
    if (id < 0 || nama.trim().isEmpty || totalStok < 0) {
      throw Exception('Data alat tidak valid');
    }
    return _transaksi('ubahAlat', [
      BigInt.from(id),
      nama.trim(),
      BigInt.from(totalStok),
      aktif,
    ]);
  }

  // ==========================================
  // PEMINJAMAN MAHASISWA
  // ==========================================

  Future<String> ajukanPeminjaman(int alatId, int jumlah) async {
    if (alatId < 0 || jumlah <= 0) {
      throw Exception('Data peminjaman tidak valid');
    }
    final idPeminjaman = await jumlahPeminjaman();
    return _transaksi(
      'ajukanPeminjaman',
      [BigInt.from(alatId), BigInt.from(jumlah)],
      peminjamanId: idPeminjaman,
      aktivitas: 'Pengajuan Peminjaman',
    );
  }

  // ==========================================
  // PERSETUJUAN DAN PENOLAKAN ADMIN
  // ==========================================

  Future<String> setujuiPeminjaman(int id) async {
    if (id < 0) throw Exception('ID peminjaman tidak valid');
    return _transaksi(
      'setujuiPeminjaman',
      [BigInt.from(id)],
      peminjamanId: id,
      aktivitas: 'Persetujuan Peminjaman',
    );
  }

  Future<String> tolakPeminjaman(int id) async {
    if (id < 0) throw Exception('ID peminjaman tidak valid');
    return _transaksi(
      'tolakPeminjaman',
      [BigInt.from(id)],
      peminjamanId: id,
      aktivitas: 'Penolakan Peminjaman',
    );
  }

  // ==========================================
  // PENGEMBALIAN MAHASISWA
  // ==========================================

  Future<String> ajukanPengembalian(int id) async {
    if (id < 0) throw Exception('ID peminjaman tidak valid');
    return _transaksi(
      'ajukanPengembalian',
      [BigInt.from(id)],
      peminjamanId: id,
      aktivitas: 'Pengajuan Pengembalian',
    );
  }

  // ==========================================
  // KONFIRMASI PENGEMBALIAN ADMIN
  // ==========================================

  Future<String> konfirmasiPengembalian(int id) async {
    if (id < 0) throw Exception('ID peminjaman tidak valid');
    return _transaksi(
      'konfirmasiPengembalian',
      [BigInt.from(id)],
      peminjamanId: id,
      aktivitas: 'Konfirmasi Pengembalian',
    );
  }

  // ==========================================
  // MEMBACA DATA PEMINJAMAN
  // ==========================================

  Future<int> jumlahPeminjaman() async {
    if (!_initialized) await init();
    final result = await _client.call(
      contract: _contract,
      function: _contract.function('jumlahPeminjaman'),
      params: [],
    );
    return (result[0] as BigInt).toInt();
  }

  Future<Map<String, dynamic>> ambilPeminjaman(int id) async {
    if (!_initialized) await init();
    final result = await _client.call(
      contract: _contract,
      function: _contract.function('ambilPeminjaman'),
      params: [BigInt.from(id)],
    );
    return {
      'alatId': (result[0] as BigInt).toInt(),
      'jumlah': (result[1] as BigInt).toInt(),
      'peminjam':
          (result[2] as wallet.EthereumAddress).with0x,
      'waktuPengajuan': (result[3] as BigInt).toInt(),
      'waktuPersetujuan': (result[4] as BigInt).toInt(),
      'waktuPengajuanKembali': (result[5] as BigInt).toInt(),
      'waktuPengembalian': (result[6] as BigInt).toInt(),
      'status': (result[7] as BigInt).toInt(),
    };
  }

  // ==========================================
  // MENUTUP KONEKSI
  // ==========================================

  Future<void> dispose() async {
    if (_initialized) {
      await _client.dispose();
      _initialized = false;
    }
  }
}
