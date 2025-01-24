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
      privateKey: '0x${hex.encode(privateKey)}',
    );
    return signature;
  }
}
