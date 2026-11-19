
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TransactionHistoryService {
  static const String _storageKey = 'labchain_transaction_history';

  Future<List<Map<String, dynamic>>> ambilSemuaTransaksi() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(data) as List;

      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> simpanTransaksi({
    int? peminjamanId,
    required String aktivitas,
    required String transactionHash,
    required String wallet,
  }) async {
    if (transactionHash.isEmpty) {
      throw Exception('Transaction hash tidak boleh kosong');
    }

    final prefs = await SharedPreferences.getInstance();
    final transaksi = await ambilSemuaTransaksi();

    final hashBersih = transactionHash.trim();

    final sudahAda = transaksi.any(
      (item) =>
          item['transactionHash']?.toString().toLowerCase() ==
          hashBersih.toLowerCase(),
    );

    if (sudahAda) return;

    transaksi.add({
      'peminjamanId': peminjamanId,
      'aktivitas': aktivitas,
      'transactionHash': hashBersih,
      'wallet': wallet,
      'waktu': DateTime.now().toIso8601String(),
    });

    await prefs.setString(
      _storageKey,
      jsonEncode(transaksi),
    );
  }

  Future<void> hapusSemuaTransaksi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
