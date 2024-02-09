import 'dart:typed_data';

import 'package:eth_sig_util/util/utils.dart';
import 'key_storage_config.dart';

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
    final mnemonic = await _keyManager.generateMnemonic();

    await _saveMnemonic(mnemonic,
        overwrite: overwrite, storageOptions: storageOptions);

    final newWallet = await _makeWalletFromMnemonic(mnemonic);

    _cachedWallet = newWallet;
    return newWallet;
  }

  /// Returns the cloud backup status of the existing wallet.
  /// Returns false if there is currently no wallet. This method should not be used as a check for wallet existence
  /// as it will return false if there is no wallet or if the wallet does exist but is not backed up to cloud.
  ///
  /// If a wallet already exists the reponse will be true or false depending on whether the wallet is backed up to cloud or not.
  /// TRUE response means wallet is backed up to cloud, FALSE means wallet is not backed up to cloud.
  Future<bool> walletBackedUpToCloud() async {
    return await _keyManager.walletBackedUpToCloud();
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

  Future<Wallet> importExistingWallet(String existinMnemonic,
      {bool overwrite = false, KeyStorageConfig? storageOptions}) async {
    await _saveMnemonic(existinMnemonic,
        overwrite: overwrite, storageOptions: storageOptions);

    final wallet = await _makeWalletFromMnemonic(existinMnemonic);

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

  Future<void> _saveMnemonic(String mnemonic,
      {required bool overwrite, KeyStorageConfig? storageOptions}) async {
    final existingWallet = await getWallet();
    if (existingWallet != null && !overwrite) {
      throw 'Wallet already exists. Use overwrite flag to overwrite';
    }

    final storageConfig = storageOptions ??
        KeyStorageConfig(rejectOnCloudSaveFailure: true, saveToCloud: true);

    await _keyManager.saveMnemonic(mnemonic, storageOptions: storageConfig);
    return;
  }

  Future<Wallet> _makeWalletFromMnemonic(String mnemonic) async {
    Uint8List privateKey =
        await _keyManager.getPrivateKeyFromMnemonic(mnemonic);
    String hexCode = "0x${bytesToHex(privateKey)}";
    return Wallet.fromHex(hexCode);
  }
}