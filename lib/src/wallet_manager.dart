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

  /// Creates a new wallet and saves it to the device based on the storage options provided.
  /// If a wallet already exists, it will throw an error unless the overwrite flag is set to true.
  /// If the overwrite flag is set to true, the existing wallet will be overwritten with the new wallet.
  /// KeyStorageConfig is used to specify the storage options for the wallet.
  /// If no storage options are provided, the default options of attmpting to save to cloud and rejecting on cloud save failure will be used.
  /// The rejectOnCloudSaveFailure flag is used to specify whether to reject the wallet creation if the cloud save fails.
  /// when set to true, the promise will reject if the cloud save fails. When set to false, the promise will resolve even if the cloud save fails and the wallet will be stored only on device.
  /// The saveToCloud flag is used to specify whether to save the wallet to cloud or not. When set to true, the wallet will be saved to cloud. When set to false, the wallet will be saved only on device.
  /// After the wallet is created, you can check the cloud backup status of the wallet using the walletBackedUpToCloud method.
  Future<Wallet> createWallet(
      {bool overwrite = false, KeyStorageConfig? storageOptions}) async {
    final mnemonic = await _keyManager.generateMnemonic();

    await _saveMnemonic(mnemonic,
        overwrite: overwrite, storageOptions: storageOptions);

    final newWallet = await _makeWalletFromMnemonic(mnemonic);

    _cachedWallet = newWallet;
    return newWallet;
  }

  /// DEPRECATED: Use walletEligibleForCloudSync instead.
  /// The naming of this method was confusing and has been deprecated in favor of walletEligibleForCloudSync.
  /// Name implied a level of control over device syncing that is not possible given the operating system constraints. See walletEligibleForCloudSync for more details.
  Future<bool> walletBackedUpToCloud() async {
    // ignore: avoid_print
    print(
        "walletBackedUpToCloud is deprecated. Use walletCanSyncToOSCloud instead.");
    return walletEligibleForCloudSync();
  }

  /// Returns whether the current wallet is stored in a way that is eligible for OS provided cloud backup and cross device sync.
  /// This is not a guarantee that the wallet is backed up to cloud,
  /// as user & app level settings determine whether secure keys are backed up to device cloud.
  /// On iOS this is a check whether the wallet will sync if user enables iCloud -> Keychain sync.
  /// On Android this is a check whether the wallet is in google play keystore and will sync if user enables google backup.
  /// TRUE response indicates that the wallet will be backed up to OS cloud if user enables the OS provided cloud backup / cross device sync.
  ///
  /// This method should not be used as a check for wallet existence
  /// as it will return false if there is no wallet or if the wallet does exist but is not backed up to cloud.
  ///
  Future<bool> walletEligibleForCloudSync() async {
    return await _keyManager.walletBackedUpToCloud();
  }

  /// Updates the storage settings for an existing wallet.
  /// Accepts a KeyStorageConfig object to specify the storage options for the wallet, same as when creating the wallet
  ///
  /// Throws an error if no wallet is found.
  /// Will reject the promise if the cloud save fails and rejectOnCloudSaveFailure is set to true.
  /// If rejectOnCloudSaveFailure is set to false, cloud save failure will fallback to on device only storage without rejecting the promise.
  ///
  /// Please note that when moving from KeyStorageConfig.saveToCloud = false to true, the wallet will be moved to device cloud
  /// which will replace a non cloud on device wallet your user might have on a different device. You should ensure you properly
  /// communicate to end users that moving to cloud storage will could cause issues if they currently have different wallets on different devices
  ///
  /// If moving from cloud to device only storage, the wallet will be removed from cloud storage and only stored on device. This will remove the wallet from any other devices.
  Future<void> updateWalletStorage(KeyStorageConfig storageOptions) async {
    final mnemonic = await _keyManager.getMnemonic();
    if (mnemonic == null) {
      throw 'Unable to update storage settings, no wallet found';
    }

    await _keyManager.saveMnemonic(mnemonic, storageOptions: storageOptions);

    if (storageOptions.saveToCloud == false) {
      await _keyManager.deleteCloudMnemonic();
    }
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
