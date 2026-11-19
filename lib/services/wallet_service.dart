
import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:wallet/wallet.dart' as wallet;

import '../config/wallet_config.dart';

void cekVersiAppKit() {
  debugPrint('Reown AppKit 1.9.0 siap');
}

class WalletService {
  ReownAppKitModal? _appKitModal;

  bool get isConnected => _appKitModal?.isConnected ?? false;

  String? get walletAddress {
    if (!isConnected) return null;

    try {
      return _appKitModal!.session!.getAddress('eip155');
    } catch (_) {
      return null;
    }
  }

  Future<void> init(BuildContext context) async {
    if (WalletConfig.projectId.isEmpty) {
      throw Exception('Project ID belum diatur');
    }

    _appKitModal = ReownAppKitModal(
      context: context,
      projectId: WalletConfig.projectId,
      metadata: const PairingMetadata(
        name: 'LabChain',
        description:
            'Aplikasi Logbook Peminjaman dan Pengembalian Alat Laboratorium IoT Berbasis Blockchain',
        url: 'https://github.com',
        icons: ['https://reown.com/logo.png'],
        redirect: Redirect(
          native: 'chaintodo://',
          universal: 'https://github.com',
        ),
      ),
    );

    await _appKitModal!.init();
  }

  Future<void> connect() async {
    if (_appKitModal == null) {
      throw Exception('AppKit belum diinisialisasi');
    }

    await _appKitModal!.openModalView();
  }

  Future<void> disconnect() async {
    if (isConnected) {
      await _appKitModal!.disconnect();
    }
  }

  Future<dynamic> kirimTransaksi({
    required DeployedContract contract,
    required String functionName,
    required List<dynamic> parameters,
  }) async {
    if (_appKitModal == null || !isConnected) {
      throw Exception('Wallet belum terhubung');
    }

    final session = _appKitModal!.session;
    final address = walletAddress;

    if (session == null || address == null) {
      throw Exception('Informasi wallet tidak ditemukan');
    }

    final selectedChain = _appKitModal!.selectedChain?.chainId;

    if (selectedChain != WalletConfig.chainId) {
      throw Exception('Silakan pilih jaringan Sepolia');
    }

    final result = await _appKitModal!.requestWriteContract(
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
    debugPrint('Hasil transaksi Reown: $result');
    debugPrint('Tipe hasil: ${result.runtimeType}');
    debugPrint('======================================');

    return result;
  }
}
