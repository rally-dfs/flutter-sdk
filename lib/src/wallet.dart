import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';
import 'dart:convert';

class Wallet extends EthPrivateKey {
  Wallet.fromHex(String hex) : super.fromHex(hex);

  String signTypedData(Map<String, dynamic> eip712Data,
      [TypedDataVersion typedDataVersion = TypedDataVersion.V4]) {
    final String signature = EthSigUtil.signTypedData(
      jsonData: jsonEncode(eip712Data),
      version: typedDataVersion,
      //privateKey: '0x${hex.encode(privateKey)}',
      privateKey: '0x77dbfe6e76b421ad09f06f2bcaeed0deef2c0819c97021770a8e93149e2133e8'
    );
    return signature;
  }
}
