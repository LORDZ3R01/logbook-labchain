
import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:wallet/wallet.dart' as wallet;

import '../config/wallet_config.dart';

class WalletService {
  ReownAppKitModal? _appKitModal;

  bool _isInitialized = false;
  bool _isInitializing = false;

  // Status koneksi wallet
  bool get isConnected => _appKitModal?.isConnected ?? false;

  // Mengambil alamat wallet yang terhubung
  String? get walletAddress {
    if (!isConnected) return null;

    try {
      return _appKitModal!.session!.getAddress('eip155');
    } catch (e) {
      debugPrint(
        '[LABCHAIN] Gagal mengambil alamat wallet: $e',
      );
      return null;
    }
  }

  // Inisialisasi Reown AppKit
  Future<void> init(BuildContext context) async {
    if (_isInitialized) {
      debugPrint(
        '[LABCHAIN] WalletService sudah diinisialisasi',
      );
      return;
    }

    if (_isInitializing) {
      debugPrint(
        '[LABCHAIN] Inisialisasi wallet sedang berlangsung',
      );
      return;
    }

    _isInitializing = true;

    debugPrint(
      '[LABCHAIN] Memulai inisialisasi WalletService',
    );

    try {
      if (WalletConfig.projectId.isEmpty) {
        throw Exception('Project ID belum diatur');
      }

      debugPrint('[LABCHAIN] Project ID tersedia');
      debugPrint('[LABCHAIN] Membuat objek Reown AppKit');

      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: WalletConfig.projectId,
        metadata: const PairingMetadata(
          name: 'LabChain',
          description:
              'Aplikasi Logbook Peminjaman dan Pengembalian Alat Laboratorium Berbasis Blockchain',
          url: 'https://github.com',
          icons: [
            'https://reown.com/logo.png',
          ],
          redirect: Redirect(
            native: 'chaintodo://',
            universal: 'https://github.com',
          ),
        ),
      );

      debugPrint(
        '[LABCHAIN] Objek AppKit berhasil dibuat',
      );

      debugPrint('[LABCHAIN] Memulai AppKit init');

      await _appKitModal!.init();

      _isInitialized = true;

      debugPrint(
        '[LABCHAIN] AppKit berhasil diinisialisasi',
      );

      debugPrint(
        '[LABCHAIN] WalletService siap digunakan',
      );
    } catch (e, stackTrace) {
      _appKitModal = null;
      _isInitialized = false;

      debugPrint(
        '[LABCHAIN] ERROR INISIALISASI WALLET: $e',
      );

      debugPrint(
        '[LABCHAIN] STACK TRACE: $stackTrace',
      );

      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  // Membuka modal koneksi wallet
  Future<void> connect() async {
    debugPrint(
      '[LABCHAIN] Memulai koneksi wallet',
    );

    if (_appKitModal == null || !_isInitialized) {
      throw Exception(
        'AppKit belum diinisialisasi',
      );
    }

    await _appKitModal!.openModalView();

    debugPrint(
      '[LABCHAIN] Modal wallet berhasil dibuka',
    );
  }

  // Memutuskan koneksi wallet
  Future<void> disconnect() async {
    debugPrint(
      '[LABCHAIN] Memutuskan koneksi wallet',
    );

    if (_appKitModal == null || !_isInitialized) {
      return;
    }

    if (isConnected) {
      await _appKitModal!.disconnect();
    }

    debugPrint(
      '[LABCHAIN] Wallet berhasil diputuskan',
    );
  }

  // Normalisasi Chain ID
  bool _isSepoliaNetwork(dynamic chainId) {
    if (chainId == null) {
      return false;
    }

    final normalizedChainId = chainId
        .toString()
        .trim()
        .toLowerCase();

    return normalizedChainId == 'eip155:11155111' ||
        normalizedChainId == '11155111';
  }

  // Mengirim transaksi ke smart contract
  Future<dynamic> kirimTransaksi({
    required DeployedContract contract,
    required String functionName,
    required List<dynamic> parameters,
  }) async {
    debugPrint(
      '[LABCHAIN] Memulai pengiriman transaksi',
    );

    // Memeriksa inisialisasi
    if (_appKitModal == null || !_isInitialized) {
      throw Exception(
        'AppKit belum diinisialisasi',
      );
    }

    // Memeriksa koneksi wallet
    if (!isConnected) {
      throw Exception(
        'Wallet belum terhubung',
      );
    }

    // Mengambil session
    final session = _appKitModal!.session;
    final address = walletAddress;

    if (session == null || address == null) {
      throw Exception(
        'Informasi wallet tidak ditemukan',
      );
    }

    // Memeriksa jaringan
    // Ambil konfigurasi jaringan Sepolia dari Reown AppKit.
final sepoliaNetwork = ReownAppKitModalNetworks.getNetworkInfo(
  'eip155',
  '11155111',
);

if (sepoliaNetwork == null) {
  throw Exception('Konfigurasi jaringan Sepolia tidak ditemukan');
}

// Minta Reown AppKit dan wallet berpindah ke Sepolia.
await _appKitModal!.selectChain(sepoliaNetwork);

// Periksa kembali jaringan setelah proses perpindahan.
final selectedChain = _appKitModal!.selectedChain?.chainId;

debugPrint('[LABCHAIN] Selected Chain setelah switch: $selectedChain');
debugPrint('[LABCHAIN] Expected Chain: ${WalletConfig.chainId}');

if (!_isSepoliaNetwork(selectedChain)) {
  throw Exception(
    'Gagal berpindah ke Ethereum Sepolia. '
    'Jaringan saat ini: $selectedChain',
  );
}

    // Mengirim transaksi
    debugPrint(
      '[LABCHAIN] Mengirim transaksi',
    );

    debugPrint(
      '[LABCHAIN] Fungsi: $functionName',
    );

    debugPrint(
      '[LABCHAIN] Wallet: $address',
    );

    debugPrint(
      '[LABCHAIN] Chain ID: $selectedChain',
    );

    final result =
        await _appKitModal!.requestWriteContract(
      topic: session.topic,
      chainId: WalletConfig.chainId,
      deployedContract: contract,
      functionName: functionName,
      transaction: Transaction(
        from: wallet.EthereumAddress.fromHex(address),
        to: contract.address,
      ),
      parameters: parameters,
    );

    debugPrint('======================================');
    debugPrint('LABCHAIN TRANSACTION');
    debugPrint('Fungsi: $functionName');
    debugPrint('Wallet: $address');
    debugPrint('Chain: $selectedChain');
    debugPrint('Hasil transaksi Reown: $result');
    debugPrint('Tipe hasil: ${result.runtimeType}');
    debugPrint('======================================');

    return result;
  }
}
