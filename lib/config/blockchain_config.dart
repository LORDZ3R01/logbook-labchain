
class BlockchainConfig {
  // ==========================================
  // KONFIGURASI ETHEREUM SEPOLIA
  // ==========================================

  // API Key Alchemy dibaca dari secrets.json
  static const String _alchemyApiKey =
      String.fromEnvironment('ALCHEMY_API_KEY');

  // URL RPC Ethereum Sepolia
  static String get rpcUrl {
    if (_alchemyApiKey.isEmpty) {
      throw StateError(
        'ALCHEMY_API_KEY belum diatur. '
        'Jalankan aplikasi dengan '
        '--dart-define-from-file=secrets.json',
      );
    }

    return 'https://eth-sepolia.g.alchemy.com/v2/$_alchemyApiKey';
  }

  // Chain ID Ethereum Sepolia
  static const int chainId = 11155111;

  // ==========================================
  // KONFIGURASI SMART CONTRACT CHAINTODO
  // ==========================================

  static const String chainTodoAddress =
      '0x3C503088f0A0371f18a08424684742553Ab60b8A';

  static const String chainTodoName = 'ChainTodo';

  // ==========================================
  // KONFIGURASI SMART CONTRACT LABCHAIN
  // ==========================================

  static const String labChainAddress =
      '0x336561E901540E084c028010F1007B176c3a112f';

  static const String labChainName = 'LabChain';

  static const int labChainDeploymentBlock = 12153331;

  // ==========================================
  // KONFIGURASI BLOCK EXPLORER
  // ==========================================

  static const String blockExplorerUrl =
      'https://eth-sepolia.blockscout.com';

  // URL transaksi
  static String transactionUrl(String transactionHash) {
    return '$blockExplorerUrl/tx/$transactionHash';
  }

  // URL smart contract LabChain
  static String get labChainExplorerUrl {
    return '$blockExplorerUrl/address/$labChainAddress';
  }

  // URL riwayat log smart contract
  static String get labChainLogsUrl {
    return '$blockExplorerUrl/address/$labChainAddress?tab=logs';
  }
}
