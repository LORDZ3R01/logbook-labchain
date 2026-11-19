
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:reown_appkit/reown_appkit.dart';

import 'metamask_service.dart';
import 'wallet_service.dart';

class WalletConnectionService {
  final WalletService mobileWallet = WalletService();
  final MetaMaskWebService webWallet = MetaMaskWebService();

  String? address;
  bool isConnected = false;

  Future<void> init(BuildContext context) async {
    if (!kIsWeb) {
      await mobileWallet.init(context);
    }
  }

  Future<void> connect() async {
    if (kIsWeb) {
      final result = await webWallet.connect();

      address = result['address'];
      isConnected = address != null;
    } else {
      await mobileWallet.connect();

      address = mobileWallet.walletAddress;
      isConnected = mobileWallet.isConnected;
    }

    if (!isConnected) {
      throw Exception('Gagal menghubungkan wallet');
    }
  }

  Future<void> disconnect() async {
    if (!kIsWeb) {
      await mobileWallet.disconnect();
    }

    address = null;
    isConnected = false;
  }

  Future<dynamic> kirimTransaksi({
    required DeployedContract contract,
    required String functionName,
    required List<dynamic> parameters,
  }) async {
    if (!isConnected || address == null) {
      throw Exception('Wallet belum terhubung');
    }

    if (kIsWeb) {
      // Mengambil fungsi smart contract.
      final function = contract.function(functionName);

      // Mengubah parameter menjadi calldata hexadecimal.
      final encodedData = function.encodeCall(parameters);

      final transactionData = encodedData
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();

      // Mengirim transaksi melalui MetaMask.
      return await webWallet.sendTransaction(
        contractAddress: contract.address.with0x,
        transactionData: '0x$transactionData',
      );
    }

    // Mengirim transaksi melalui Reown AppKit di Android.
    return await mobileWallet.kirimTransaksi(
      contract: contract,
      functionName: functionName,
      parameters: parameters,
    );
  }
}
