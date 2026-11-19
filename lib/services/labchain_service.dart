
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
  final TransactionHistoryService _history =
      TransactionHistoryService();

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

    debugPrint('======================================');
    debugPrint('[LABCHAIN] MEMULAI INISIALISASI');
    debugPrint('======================================');

    try {
      debugPrint('[LABCHAIN] Membuat koneksi RPC');

      _client = Web3Client(
        BlockchainConfig.rpcUrl,
        http.Client(),
      );

      debugPrint('[LABCHAIN] Memuat ABI LabChain');

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

      debugPrint('[LABCHAIN] ABI berhasil dimuat');
      debugPrint(
        '[LABCHAIN] Contract: '
        '${BlockchainConfig.labChainAddress}',
      );

      final networkId = await _denganRetryRpc(
        () => _client.getNetworkId(),
        namaOperasi: 'getNetworkId',
      );

      debugPrint('[LABCHAIN] Network ID: $networkId');

      if (networkId != BlockchainConfig.chainId) {
        throw Exception(
          'Jaringan bukan Sepolia. Network ID: $networkId',
        );
      }

      final code = await _denganRetryRpc(
        () => _client.getCode(_contract.address),
        namaOperasi: 'getCode',
      );

      debugPrint(
        '[LABCHAIN] Contract code length: ${code.length}',
      );

      if (code.isEmpty) {
        throw Exception(
          'Smart contract LabChain tidak ditemukan!',
        );
      }

      final latestBlock = await _denganRetryRpc(
        () => _client.getBlockNumber(),
        namaOperasi: 'getBlockNumber',
      );

      debugPrint('[LABCHAIN] Latest block: $latestBlock');
      debugPrint(
        '[LABCHAIN] Deployment block: '
        '${BlockchainConfig.labChainDeploymentBlock}',
      );

      _initialized = true;

      debugPrint('======================================');
      debugPrint('[LABCHAIN] BLOCKCHAIN TERHUBUNG');
      debugPrint('[LABCHAIN] Ethereum Sepolia');
      debugPrint('[LABCHAIN] Inisialisasi berhasil');
      debugPrint('======================================');
    } catch (e, stackTrace) {
      debugPrint('======================================');
      debugPrint('[LABCHAIN] ERROR INISIALISASI');
      debugPrint('[LABCHAIN] $e');
      debugPrint('$stackTrace');
      debugPrint('======================================');

      throw Exception(
        'Gagal menginisialisasi LabChain: $e',
      );
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
        return await aksi();
      } catch (e) {
        final pesan = e.toString().toLowerCase();

        final terkenaRateLimit =
            pesan.contains('429') ||
            pesan.contains('compute units per second') ||
            pesan.contains('throughput');

        if (!terkenaRateLimit ||
            percobaan == maksimalPercobaan - 1) {
          debugPrint(
            '[LABCHAIN] RPC ERROR $namaOperasi: $e',
          );
          rethrow;
        }

        final detikTunggu = 1 << percobaan;

        debugPrint(
          '[LABCHAIN] RPC rate limit: $namaOperasi. '
          'Percobaan ${percobaan + 1}/$maksimalPercobaan. '
          'Menunggu $detikTunggu detik.',
        );

        await Future.delayed(
          Duration(seconds: detikTunggu),
        );
      }
    }

    throw Exception(
      'RPC $namaOperasi gagal setelah retry.',
    );
  }

  // ==========================================
  // PENYIMPANAN RIWAYAT BLOCKCHAIN LOKAL
  // ==========================================

  Future<List<Map<String, dynamic>>>
      _muatRiwayatTersimpan() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString(
      _keyRiwayatBlockchain,
    );

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(data) as List<dynamic>;

      return decoded.map((item) {
        return Map<String, dynamic>.from(
          item as Map,
        );
      }).toList();
    } catch (e) {
      debugPrint(
        '[LABCHAIN] Gagal membaca cache riwayat: $e',
      );

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

    await prefs.setInt(
      _keyBlokTerakhir,
      blok,
    );
  }

  Future<void> resetRiwayatBlockchainLokal() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyBlokTerakhir);
    await prefs.remove(_keyRiwayatBlockchain);

    debugPrint(
      '[LABCHAIN] Checkpoint dan cache riwayat dihapus.',
    );
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
    if (!_initialized) {
      await init();
    }

    if (!walletConnection.isConnected) {
      throw Exception(
        'Hubungkan wallet terlebih dahulu',
      );
    }

    final result = await walletConnection.kirimTransaksi(
      contract: _contract,
      functionName: functionName,
      parameters: parameters,
    );

    final transactionHash = result.toString();

    debugPrint('======================================');
    debugPrint('[LABCHAIN] TRANSAKSI');
    debugPrint('[LABCHAIN] Fungsi: $functionName');
    debugPrint('[LABCHAIN] Hash: $transactionHash');
    debugPrint('======================================');

    final hashValid = RegExp(
      r'^0x[a-fA-F0-9]{64}$',
    ).hasMatch(transactionHash);

    if (hashValid && aktivitas != null) {
      try {
        await _history.simpanTransaksi(
          peminjamanId: peminjamanId,
          aktivitas: aktivitas,
          transactionHash: transactionHash,
          wallet: walletConnection.address ?? '',
        );

        debugPrint(
          '[LABCHAIN] Riwayat transaksi lokal disimpan.',
        );
      } catch (e) {
        debugPrint(
          '[LABCHAIN] Gagal menyimpan riwayat lokal: $e',
        );
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
    if (!_initialized) {
      await init();
    }

    if (ukuranRentangBlok <= 0 ||
        ukuranRentangBlok > 10) {
      throw Exception(
        'Rentang blok harus antara 1 sampai 10.',
      );
    }

    if (_sedangMemindai) {
      debugPrint(
        '[LABCHAIN] Pemindaian riwayat sedang berlangsung.',
      );

      return _muatRiwayatTersimpan();
    }

    _sedangMemindai = true;

    try {
      final int blokTerbaru = await _denganRetryRpc(
        () => _client.getBlockNumber(),
        namaOperasi: 'getBlockNumber',
      );

      final int blokAwal =
          BlockchainConfig.labChainDeploymentBlock;

      final List<Map<String, dynamic>> hasil =
          await _muatRiwayatTersimpan();

      int blokTerakhir = await _ambilBlokTerakhir();

      if (blokTerakhir < blokAwal - 1) {
        blokTerakhir = blokAwal - 1;
      }

      debugPrint('======================================');
      debugPrint('[LABCHAIN] PEMINDAIAN RIWAYAT');
      debugPrint('[LABCHAIN] Blok deployment: $blokAwal');
      debugPrint('[LABCHAIN] Blok terakhir: $blokTerakhir');
      debugPrint('[LABCHAIN] Blok terbaru: $blokTerbaru');
      debugPrint('[LABCHAIN] Cache: ${hasil.length}');
      debugPrint('======================================');

      if (blokTerbaru < blokAwal ||
          blokTerakhir >= blokTerbaru) {
        debugPrint(
          '[LABCHAIN] Tidak ada blok baru untuk dipindai.',
        );

        _urutkanRiwayat(hasil);
        return hasil;
      }

      final Map<String, ContractEvent> daftarEvent = {
        'PeminjamanDiajukan':
            _contract.event('PeminjamanDiajukan'),
        'PeminjamanDisetujui':
            _contract.event('PeminjamanDisetujui'),
        'PeminjamanDitolak':
            _contract.event('PeminjamanDitolak'),
        'PengembalianDiajukan':
            _contract.event('PengembalianDiajukan'),
        'PengembalianDikonfirmasi':
            _contract.event('PengembalianDikonfirmasi'),
      };

      final Map<String, ContractEvent>
          eventBerdasarkanSignature = {};

      for (final entry in daftarEvent.entries) {
        final signature = bytesToHex(
          entry.value.signature,
          include0x: true,
        ).toLowerCase();

        eventBerdasarkanSignature[signature] =
            entry.value;
      }

      final Set<String> transaksiSudahAda =
          hasil.map((item) {
        return '${item['transactionHash']}_${item['logIndex']}';
      }).toSet();

      int dariBlok = blokTerakhir + 1;

      while (dariBlok <= blokTerbaru) {
        final int sampaiBlok =
            (dariBlok + ukuranRentangBlok - 1)
                .clamp(dariBlok, blokTerbaru)
                .toInt();

        debugPrint(
          '[LABCHAIN] Membaca blok '
          '$dariBlok sampai $sampaiBlok',
        );

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

        debugPrint(
          '[LABCHAIN] Log ditemukan: ${logs.length}',
        );

        for (final log in logs) {
          if (log.removed == true) continue;

          final topics = log.topics;
          final data = log.data;

          if (topics == null ||
              topics.isEmpty ||
              data == null) {
            continue;
          }

          final signature = topics.first?.toLowerCase();

          if (signature == null) continue;

          final event =
              eventBerdasarkanSignature[signature];

          if (event == null) continue;

          final transactionHash = log.transactionHash;

          if (transactionHash == null ||
              transactionHash.isEmpty) {
            continue;
          }

          final int logIndex = log.logIndex ?? 0;

          final String uniqueKey =
              '${transactionHash}_$logIndex';

          if (transaksiSudahAda.contains(uniqueKey)) {
            continue;
          }

          try {
            final decoded = event.decodeResults(
              topics,
              data,
            );

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

            String walletPelaku = '';

            try {
              final transaction = await _denganRetryRpc(
                () => _client.getTransactionByHash(
                  transactionHash,
                ),
                namaOperasi: 'getTransactionByHash',
              );

              if (transaction != null) {
                walletPelaku =
                    transaction.from.with0x;
              }
            } catch (e) {
              debugPrint(
                '[LABCHAIN] Gagal membaca wallet transaksi: $e',
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
              'transactionIndex':
                  log.transactionIndex ?? 0,
              'logIndex': logIndex,
            });

            transaksiSudahAda.add(uniqueKey);

            debugPrint(
              '[LABCHAIN] Event ditemukan: '
              '${event.name}, ID peminjaman: $idPeminjaman',
            );
          } catch (e, stackTrace) {
            debugPrint(
              '[LABCHAIN] Gagal decode event: $e',
            );
            debugPrint('$stackTrace');
            rethrow;
          }
        }

        await _simpanRiwayatTersimpan(hasil);
        await _simpanBlokTerakhir(sampaiBlok);

        debugPrint(
          '[LABCHAIN] Checkpoint tersimpan: $sampaiBlok',
        );

        dariBlok = sampaiBlok + 1;
      }

      _urutkanRiwayat(hasil);

      await _simpanRiwayatTersimpan(hasil);

      debugPrint('======================================');
      debugPrint('[LABCHAIN] PEMINDAIAN SELESAI');
      debugPrint('[LABCHAIN] Total transaksi: ${hasil.length}');
      debugPrint('[LABCHAIN] Blok terbaru: $blokTerbaru');
      debugPrint('======================================');

      return hasil;
    } finally {
      _sedangMemindai = false;
    }
  }

  void _urutkanRiwayat(
    List<Map<String, dynamic>> hasil,
  ) {
    hasil.sort((a, b) {
      final perbandinganBlok =
          (b['blockNumber'] as int)
              .compareTo(a['blockNumber'] as int);

      if (perbandinganBlok != 0) {
        return perbandinganBlok;
      }

      final perbandinganTransaksi =
          (b['transactionIndex'] as int)
              .compareTo(a['transactionIndex'] as int);

      if (perbandinganTransaksi != 0) {
        return perbandinganTransaksi;
      }

      return (b['logIndex'] as int)
          .compareTo(a['logIndex'] as int);
    });
  }

  // ==========================================
  // MENGELOLA ALAT
  // ==========================================

  Future<String> tambahAlat(
    String nama,
    int totalStok,
  ) async {
    if (nama.trim().isEmpty || totalStok <= 0) {
      throw Exception(
        'Nama dan stok alat harus valid',
      );
    }

    return _transaksi(
      'tambahAlat',
      [
        nama.trim(),
        BigInt.from(totalStok),
      ],
    );
  }

  Future<int> jumlahAlat() async {
    if (!_initialized) {
      await init();
    }

    debugPrint('[LABCHAIN] Memanggil jumlahAlat()');

    final result = await _denganRetryRpc(
      () => _client.call(
        contract: _contract,
        function: _contract.function('jumlahAlat'),
        params: [],
      ),
      namaOperasi: 'jumlahAlat',
    );

    final jumlah = (result[0] as BigInt).toInt();

    debugPrint('[LABCHAIN] Jumlah alat: $jumlah');

    return jumlah;
  }

  Future<Map<String, dynamic>> ambilAlat(
    int id,
  ) async {
    if (!_initialized) {
      await init();
    }

    debugPrint('[LABCHAIN] Membaca alat ID: $id');

    try {
      final result = await _denganRetryRpc(
        () => _client.call(
          contract: _contract,
          function: _contract.function('ambilAlat'),
          params: [
            BigInt.from(id),
          ],
        ),
        namaOperasi: 'ambilAlat $id',
      );

      debugPrint(
        '[LABCHAIN] Raw hasil ambilAlat($id): $result',
      );

      final alat = {
        'nama': result[0] as String,
        'totalStok': (result[1] as BigInt).toInt(),
        'sedangDipinjam': (result[2] as BigInt).toInt(),
        'aktif': result[3] as bool,
      };

      debugPrint(
        '[LABCHAIN] Detail alat ID $id: $alat',
      );

      return alat;
    } catch (e, stackTrace) {
      debugPrint(
        '[LABCHAIN] ERROR membaca alat ID $id: $e',
      );
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  Future<String> ubahAlat(
    int id,
    String nama,
    int totalStok,
    bool aktif,
  ) async {
    if (id < 0 ||
        nama.trim().isEmpty ||
        totalStok < 0) {
      throw Exception('Data alat tidak valid');
    }

    return _transaksi(
      'ubahAlat',
      [
        BigInt.from(id),
        nama.trim(),
        BigInt.from(totalStok),
        aktif,
      ],
    );
  }

  // ==========================================
  // PEMINJAMAN MAHASISWA
  // ==========================================

  Future<String> ajukanPeminjaman(
    int alatId,
    int jumlah,
  ) async {
    if (alatId < 0 || jumlah <= 0) {
      throw Exception(
        'Data peminjaman tidak valid',
      );
    }

    final idPeminjaman = await jumlahPeminjaman();

    return _transaksi(
      'ajukanPeminjaman',
      [
        BigInt.from(alatId),
        BigInt.from(jumlah),
      ],
      peminjamanId: idPeminjaman,
      aktivitas: 'Pengajuan Peminjaman',
    );
  }

  // ==========================================
  // PERSETUJUAN DAN PENOLAKAN ADMIN
  // ==========================================

  Future<String> setujuiPeminjaman(int id) async {
    if (id < 0) {
      throw Exception(
        'ID peminjaman tidak valid',
      );
    }

    return _transaksi(
      'setujuiPeminjaman',
      [BigInt.from(id)],
      peminjamanId: id,
      aktivitas: 'Persetujuan Peminjaman',
    );
  }

  Future<String> tolakPeminjaman(int id) async {
    if (id < 0) {
      throw Exception(
        'ID peminjaman tidak valid',
      );
    }

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
    if (id < 0) {
      throw Exception(
        'ID peminjaman tidak valid',
      );
    }

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

  Future<String> konfirmasiPengembalian(
    int id,
  ) async {
    if (id < 0) {
      throw Exception(
        'ID peminjaman tidak valid',
      );
    }

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
    if (!_initialized) {
      await init();
    }

    debugPrint(
      '[LABCHAIN] Memanggil jumlahPeminjaman()',
    );

    final result = await _denganRetryRpc(
      () => _client.call(
        contract: _contract,
        function: _contract.function('jumlahPeminjaman'),
        params: [],
      ),
      namaOperasi: 'jumlahPeminjaman',
    );

    final jumlah = (result[0] as BigInt).toInt();

    debugPrint(
      '[LABCHAIN] Jumlah peminjaman: $jumlah',
    );

    return jumlah;
  }

  Future<Map<String, dynamic>> ambilPeminjaman(
    int id,
  ) async {
    if (!_initialized) {
      await init();
    }

    debugPrint(
      '[LABCHAIN] Membaca peminjaman ID: $id',
    );

    try {
      final result = await _denganRetryRpc(
        () => _client.call(
          contract: _contract,
          function: _contract.function('ambilPeminjaman'),
          params: [
            BigInt.from(id),
          ],
        ),
        namaOperasi: 'ambilPeminjaman $id',
      );

      debugPrint(
        '[LABCHAIN] Raw hasil ambilPeminjaman($id): $result',
      );

      final peminjaman = {
        'alatId': (result[0] as BigInt).toInt(),
        'jumlah': (result[1] as BigInt).toInt(),
        'peminjam':
            (result[2] as wallet.EthereumAddress).with0x,
        'waktuPengajuan': (result[3] as BigInt).toInt(),
        'waktuPersetujuan': (result[4] as BigInt).toInt(),
        'waktuPengajuanKembali':
            (result[5] as BigInt).toInt(),
        'waktuPengembalian':
            (result[6] as BigInt).toInt(),
        'status': (result[7] as BigInt).toInt(),
      };

      debugPrint(
        '[LABCHAIN] Detail peminjaman ID $id: $peminjaman',
      );

      return peminjaman;
    } catch (e, stackTrace) {
      debugPrint(
        '[LABCHAIN] ERROR membaca peminjaman ID $id: $e',
      );
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  // ==========================================
  // MENUTUP KONEKSI
  // ==========================================

  Future<void> dispose() async {
    if (_initialized) {
      await _client.dispose();
      _initialized = false;

      debugPrint(
        '[LABCHAIN] Koneksi blockchain ditutup.',
      );
    }
  }
}
