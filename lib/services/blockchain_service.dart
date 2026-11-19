
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart' as wallet;

import '../config/blockchain_config.dart';
import 'wallet_connection_service.dart';

class BlockchainService {
  late Web3Client _client;
  late DeployedContract _contract;

  final WalletConnectionService walletConnection;

  bool _initialized = false;

  BlockchainService(this.walletConnection);

  Future<void> init() async {
    if (_initialized) return;

    try {
      _client = Web3Client(
        BlockchainConfig.rpcUrl,
        http.Client(),
      );

      final abi = await rootBundle.loadString(
        'assets/abi/ChainTodo.json',
      );

      final contractAbi = ContractAbi.fromJson(
        abi,
        BlockchainConfig.chainTodoName,
      );

      _contract = DeployedContract(
        contractAbi,
        wallet.EthereumAddress.fromHex(
          BlockchainConfig.chainTodoAddress,
        ),
      );

      final networkId = await _client.getNetworkId();

      if (networkId != BlockchainConfig.chainId) {
        throw Exception('Jaringan bukan Sepolia!');
      }

      final code = await _client.getCode(_contract.address);

      if (code.isEmpty) {
        throw Exception('Smart contract tidak ditemukan!');
      }

      _initialized = true;
    } catch (e) {
      throw Exception(
        'Gagal menginisialisasi blockchain: $e',
      );
    }
  }

  Future<int> jumlahTugas() async {
    if (!_initialized) await init();

    final function = _contract.function('jumlahTugas');

    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [],
    );

    return (result[0] as BigInt).toInt();
  }

  Future<Map<String, dynamic>> ambilTugas(int id) async {
    if (!_initialized) await init();

    final function = _contract.function('ambilTugas');

    final result = await _client.call(
      contract: _contract,
      function: function,
      params: [BigInt.from(id)],
    );

    return {
      'judul': result[0] as String,
      'selesai': result[1] as bool,
      'waktuDibuat': (result[2] as BigInt).toInt(),
      'pembuat':
          (result[3] as wallet.EthereumAddress).with0x,
    };
  }

  Future<String> tambahTugas(String judul) async {
    if (!_initialized) await init();

    if (judul.trim().isEmpty) {
      throw Exception('Judul tugas tidak boleh kosong');
    }

    if (!walletConnection.isConnected) {
      throw Exception('Hubungkan wallet terlebih dahulu');
    }

    final result = await walletConnection.kirimTransaksi(
      contract: _contract,
      functionName: 'tambahTugas',
      parameters: [judul.trim()],
    );

    debugPrint('Hasil transaksi tambah tugas: $result');

    return result.toString();
  }

  Future<String> tandaiSelesai(int id) async {
    if (!_initialized) await init();

    if (id < 0) {
      throw Exception('ID tugas tidak valid');
    }

    if (!walletConnection.isConnected) {
      throw Exception('Hubungkan wallet terlebih dahulu');
    }

    final result = await walletConnection.kirimTransaksi(
      contract: _contract,
      functionName: 'tandaiSelesai',
      parameters: [BigInt.from(id)],
    );

    debugPrint('Hasil transaksi tandai selesai: $result');

    return result.toString();
  }

  Future<void> dispose() async {
    if (_initialized) {
      await _client.dispose();
      _initialized = false;
    }
  }
}
