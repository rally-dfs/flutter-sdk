import 'dart:typed_data';

import 'package:eth_sig_util/util/utils.dart';

import 'package:web3dart/web3dart.dart';

import 'key_manager.dart';

class AccountsUtil {
  static EthPrivateKey? _cachedWallet;
  final KeyManager _keyManager;

  AccountsUtil(this._keyManager);

  static final AccountsUtil _instance = AccountsUtil(KeyManagerImpl());

  factory AccountsUtil.getInstance() {
    return _instance;
  }

  Future<String> createAccount({bool overwrite = false}) async {
    final existingWallet = await getWallet();
    if (existingWallet != null && !overwrite) {
      throw 'Account already exists';
    }

    final mnemonic = await _keyManager.generateMnemonic();
    _keyManager.saveMnemonic(mnemonic!);
    final newWallet = await _makeWalletFromMnemonic(mnemonic);

    _cachedWallet = newWallet;
    return newWallet.address.hex;
  }

  Future<EthPrivateKey?> getWallet() async {
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

  Future<String?> getAccountAddress() async {
    final wallet = await getWallet();
    if (wallet == null) {
      return null;
    }
    return wallet.address.hex;
  }

  Future<void> permanentlyDeleteAccount() async {
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

  Future<String> signMessage(String message) async {
    final wallet = await getWallet();

    if (wallet == null) {
      throw 'No account';
    }
    throw UnimplementedError();
    // return wallet.signMessage(message);
  }

  Future<String> signTransaction() async {
    final wallet = await getWallet();
    if (wallet == null) {
      throw 'No account';
    }
    throw UnimplementedError();
    // return wallet.signTransaction(tx);
  }

  Future<String> signHash(String hash) async {
    final wallet = await getWallet();
    if (wallet == null) {
      throw 'No account';
    }
    throw UnimplementedError();

    // final signingKey = utils.SigningKey(wallet.privateKey);
    //
    // return utils.joinSignature(signingKey.signDigest(hash));
  }

  Future<EthPrivateKey> _makeWalletFromMnemonic(String mnemonic) async {
    Uint8List privateKey =
        await _keyManager.makePrivateKeyFromMnemonic(mnemonic);
    String hexCode = "0x${bytesToHex(privateKey)}";
    return EthPrivateKey.fromHex(hexCode);
  }
}
