import 'dart:typed_data';

import 'package:eth_sig_util/util/utils.dart';
import 'package:rly_network_flutter_sdk/key_storage_config.dart';

import 'key_manager.dart';

import 'wallet.dart';

class WalletManager {
  static Wallet? _cachedWallet;
  final KeyManager _keyManager;

  WalletManager(this._keyManager);

  static final WalletManager _instance = WalletManager(KeyManager());

  factory WalletManager.getInstance() {
    return _instance;
  }

  Future<Wallet> createWallet(
      {bool overwrite = false, KeyStorageConfig? storageOptions}) async {
    final existingWallet = await getWallet();
    if (existingWallet != null && !overwrite) {
      throw 'Account already exists';
    }

    final storageConfig = storageOptions ??
        KeyStorageConfig(rejectOnCloudSaveFailure: true, saveToCloud: true);

    final mnemonic = await _keyManager.generateMnemonic();
    await _keyManager.saveMnemonic(mnemonic, storageOptions: storageConfig);
    final newWallet = await _makeWalletFromMnemonic(mnemonic);

    _cachedWallet = newWallet;
    return newWallet;
  }

  Future<Wallet?> getWallet() async {
    if (_cachedWallet != null) {
      return _cachedWallet!;
    }

    String? mnemonic = await _keyManager.getMnemonic();

    if (mnemonic == null) {
      return null;
    }

    final wallet = await _makeWalletFromMnemonic(mnemonic);

    _cachedWallet = wallet;
    return wallet;
  }

  Future<String?> getPublicAddress() async {
    final wallet = await getWallet();
    if (wallet == null) {
      return null;
    }
    return wallet.address.hex;
  }

  Future<void> permanentlyDeleteWallet() async {
    await _keyManager.deleteMnemonic();
    _cachedWallet = null;
  }

  Future<String?> getAccountPhrase() async {
    try {
      return await _keyManager.getMnemonic();
    } catch (error) {
      return null;
    }
  }

  Future<Wallet> _makeWalletFromMnemonic(String mnemonic) async {
    Uint8List privateKey =
        await _keyManager.getPrivateKeyFromMnemonic(mnemonic);
    String hexCode = "0x${bytesToHex(privateKey)}";
    return Wallet.fromHex(hexCode);
  }
}