class MetaMaskWebService {
  Future<Map<String, String>> connect() async {
    throw UnsupportedError(
      'MetaMask Web hanya tersedia di browser.',
    );
  }

  Future<String> sendTransaction({
    required String contractAddress,
    required String transactionData,
  }) async {
    throw UnsupportedError(
      'Transaksi MetaMask hanya tersedia di browser.',
    );
  }
}
