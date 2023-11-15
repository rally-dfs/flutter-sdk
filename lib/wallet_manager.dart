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

  /*
    * Creates a new wallet and saves it to the device.
    * If a wallet already exists, it will throw an error unless overwrite is set to true.
    *
    * overwrite: If true, will overwrite the existing wallet. Use with caution as old mnemonic will be lost.
    * identifier: The identifier for the underlying mnemonic. You should provide a value here is you intend to use multiple unique mnemonics.
    * It is the responsibility of the developer to ensure that the identifier is unique, and that the same identifier is used to retrieve the wallet in getWallet
    * index: The slot offset / index of the keypair derived from the underlying mnemonic. This is intended for advanced users who wish to use multiple keypairs derived from the same mnemonic.
    * It is the responsibility of the developer to keep track of human friendly names for each index.
    * storageOptions: Options for storing the mnemonic. See KeyStorageConfig for more details.
    *
    * Returns the newly created wallet.
    */
  Future<Wallet> createWallet(
      {bool overwrite = false,
      String identifier = "default",
      int index = 0,
      KeyStorageConfig? storageOptions}) async {
    final existingWallet = await getWallet();
    if (existingWallet != null && !overwrite) {
      throw 'Account already exists';
    }

    final storageConfig = storageOptions ??
        KeyStorageConfig(rejectOnCloudSaveFailure: true, saveToCloud: true);

    final mnemonic = await _keyManager.generateMnemonic();
    await _keyManager.saveMnemonic(mnemonic, storageOptions: storageConfig);
    final newWallet = await _makeWalletFromMnemonic(mnemonic, index: index);

    _cachedWallet = newWallet;
    return newWallet;
  }

  /*
    * Retrieves the wallet from the device.
    *
    * identifier: The identifier for the underlying mnemonic. You should provide a value here is you called createWallet with multiple unique identifiers.
    * index: The slot offset / index of the keypair derived from the underlying mnemonic. This is intended for advanced users who wish to use multiple keypairs derived from the same mnemonic.
    * value provided here should match the value provided to createWallet.
    *
    * Returns the wallet.
    */
  Future<Wallet?> getWallet(
      {String identifier = "default", int index = 0}) async {
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

  Future<String?> getAccountPhrase({String identifier = "default"}) async {
    try {
      return await _keyManager.getMnemonic();
    } catch (error) {
      return null;
    }
  }

  Future<Wallet> _makeWalletFromMnemonic(String mnemonic,
      {int index = 0}) async {
    Uint8List privateKey =
        await _keyManager.getPrivateKeyFromMnemonic(mnemonic);
    String hexCode = "0x${bytesToHex(privateKey)}";
    return Wallet.fromHex(hexCode);
  }
}
