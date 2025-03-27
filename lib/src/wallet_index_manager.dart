import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'wallet_item.dart'; 

class WalletIndexManager {
  // The key under which the mnemonic index is stored.
  static const String _walletIndexKey = 'WALLET_INDEX'; 
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

   Future<List<WalletItem>> getWalletItems() async {
    final String? jsonString = await _secureStorage.read(key: _walletIndexKey);
    if (jsonString == null) {
      return [];
    }
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((e) => WalletItem.fromJson(e)).toList();
  }

    Future<void> addWalletItem(WalletItem item) async {
    List<WalletItem> items = await getWalletItems();

    if (!items.any((element) => element.label == item.label)) {
      items.add(item);
      await _secureStorage.write(
        key: _walletIndexKey,
        value: json.encode(items.map((e) => e.toJson()).toList()),
      );
    }
  }



}