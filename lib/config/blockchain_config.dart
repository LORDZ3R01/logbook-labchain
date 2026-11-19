
class BlockchainConfig {
  // ==========================================
  // KONFIGURASI JARINGAN ETHEREUM SEPOLIA
  // ==========================================

  static const String rpcUrl =
    'https://eth-sepolia.g.alchemy.com/v2/REDACTED';

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

  // Blok saat smart contract LabChain pertama kali di-deploy.
  // Digunakan sebagai titik awal pembacaan event blockchain.
  static const int labChainDeploymentBlock = 12153331;

  // ==========================================
  // KONFIGURASI BLOCK EXPLORER
  // ==========================================

  static const String blockExplorerUrl =
      'https://eth-sepolia.blockscout.com';

  // URL transaksi berdasarkan Transaction Hash.
  static String transactionUrl(String transactionHash) {
    return '$blockExplorerUrl/tx/$transactionHash';
  }

  // URL smart contract LabChain.
  static String get labChainExplorerUrl {
    return '$blockExplorerUrl/address/$labChainAddress';
  }
}
