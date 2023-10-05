import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:eth_sig_util/util/utils.dart';

import 'package:web3dart/web3dart.dart';

import 'keyManager.dart';

class AccountsUtil {
  static Wallet? _cachedWallet;
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
    final pkey = await _keyManager.makePrivateKeyFromMnemonic(mnemonic);
    final newWallet = _makeWalletFromPrivateKey(pkey);

    _cachedWallet = newWallet;
    return newWallet.privateKey.address.hex;
  }

  Future<Wallet?> getWallet() async {
    if (_cachedWallet != null) {
      return _cachedWallet!;
    }

    String? mnemonic = await _keyManager.getMnemonic();

    if (mnemonic == null) {
      return null;
    }

    final privateKey = await _keyManager.makePrivateKeyFromMnemonic(mnemonic);
    final wallet = _makeWalletFromPrivateKey(privateKey);

    _cachedWallet = wallet;
    return wallet;
  }

  Future<String?> getAccountAddress() async {
    final wallet = await getWallet();
    if(wallet == null) {
      return null;
    }
    return wallet.privateKey.address.hex;
  }

  void permanentlyDeleteAccount() {
    _keyManager.deleteMnemonic();
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

  EthPrivateKey getCredentials(Uint8List uint8list) {
    String hexCode = "0x${bytesToHex(uint8list)}";
    return EthPrivateKey.fromHex(hexCode);
  }

  Wallet _makeWalletFromPrivateKey(Uint8List uint8list) {
    EthPrivateKey credentials = getCredentials(uint8list);

    //TODO: What is this password?
    final Wallet newWallet =
        Wallet.createNew(credentials, 'password', Random.secure());

    return newWallet;
  }

  Future<String?> getPrivateKeyHex() async {
    final wallet = await getWallet();

    if(wallet == null) {
      return null;
    }

    return hex.encode(wallet.privateKey.privateKey);
  }
}
