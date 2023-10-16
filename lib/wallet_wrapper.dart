import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';

class WalletWrapper extends EthPrivateKey {
  WalletWrapper.fromHex(String hex) : super.fromHex(hex);

  String signTypedData(String eip712Data, TypedDataVersion typedDataVersion) {
    final String signature = EthSigUtil.signTypedData(
      jsonData: eip712Data,
      version: typedDataVersion,
      privateKey: '0x${hex.encode(privateKey)}',
    );
    return signature;
  }
}
