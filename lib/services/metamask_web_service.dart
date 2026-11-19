
import 'dart:convert';
import 'dart:js_interop';

@JS()
external JSPromise<JSString> chainTodoConnect();

@JS()
external JSPromise<JSString> chainTodoSendTransaction(
  JSString contractAddress,
  JSString transactionData,
);

class MetaMaskWebService {
  Future<Map<String, String>> connect() async {
    try {
      final result = await chainTodoConnect().toDart;

      final data =
          jsonDecode(result.toDart) as Map<String, dynamic>;

      final address = data['address'] as String;
      final chainId = data['chainId'] as String;

      if (chainId.toLowerCase() != '0xaa36a7') {
        throw Exception('Wallet belum menggunakan Sepolia');
      }

      return {
        'address': address,
        'chainId': chainId,
      };
    } catch (e) {
      throw Exception('Gagal menghubungkan MetaMask: $e');
    }
  }

  Future<String> sendTransaction({
    required String contractAddress,
    required String transactionData,
  }) async {
    try {
      final result = await chainTodoSendTransaction(
        contractAddress.toJS,
        transactionData.toJS,
      ).toDart;

      return result.toDart;
    } catch (e) {
      throw Exception('Gagal mengirim transaksi MetaMask: $e');
    }
  }
}
