import 'dart:convert';
import 'dart:typed_data';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:rly_network_flutter_sdk/contracts/erc20.dart';
import 'package:rly_network_flutter_sdk/gsnClient/gsnTxHelpers.dart';
import 'package:rly_network_flutter_sdk/gsnClient/utils.dart';
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';

import '../../network_config/network_config.dart'; // For the hex string conversion

class MetaTransaction {
  String? name;
  String? version;
  String? salt;
  String? verifyingContract;
  int nonce;
  String from;
  Uint8List functionSignature;

  MetaTransaction({
    this.name,
    this.version,
    this.salt,
    this.verifyingContract,
    required this.nonce,
    required this.from,
    required this.functionSignature,
  });
}

Map<String, dynamic> getTypedMetatransaction(MetaTransaction metaTransaction) {
  final types = {
    'EIP712Domain': [
      {'name': 'name', 'type': 'string'},
      {'name': 'version', 'type': 'string'},
      {'name': 'verifyingContract', 'type': 'address'},
      {'name': 'salt', 'type': 'bytes32'},
    ],
    'MetaTransaction': [
      {'name': 'nonce', 'type': 'uint256'},
      {'name': 'from', 'type': 'address'},
      {'name': 'functionSignature', 'type': 'bytes'},
    ],
  };
  const primaryType = "MetaTransaction";
  final domainSeparator = {
    'name': metaTransaction.name,
    'version': metaTransaction.version,
    'verifyingContract': metaTransaction.verifyingContract,
    'salt': metaTransaction.salt,
  };
  // final domainSeparator = {
  //   'name': 'Rally Polygon',
  //   'version': '3',
  //   'verifyingContract': '0x1C7312Cb60b40cF586e796FEdD60Cf243286c9E9',
  //   'salt': '0x0000000000000000000000000000000000000000000000000000000000013881'
  // };
  final messageData = {
    'nonce': metaTransaction.nonce,
    'from': metaTransaction.from,
    'functionSignature': '0x${bytesToHex(metaTransaction.functionSignature)}',
  };

  // final messageData = {
  //   'nonce': 1,
  //   'from': '0x9E6d844c0257E3356065cD6a3F90eE4d966F1551',
  //   'functionSignature':
  //       '0xa9059cbb0000000000000000000000005205bcc1852c4b626099aa7a2aff36ac3e9de83b0000000000000000000000000000000000000000000000000de0b6b3a7640000',
  // };

  return {
    'types': types,
    'primaryType': primaryType,
    'domain': domainSeparator,
    'message': messageData,
  };
}

Future<Map<String, dynamic>> getMetatransactionEIP712Signature(
  EthPrivateKey account,
  String contractName,
  String contractAddress,
  Uint8List functionSignature,
  NetworkConfig config,
  int nonce,
) async {
  // name and chainId to be used in EIP712
  final chainId = int.parse(config.gsn.chainId);
  String saltHexString = chainId.toRadixString(16);
  String paddedSaltHexString = '0x${saltHexString.padLeft(64, '0')}';
  // typed data for signing
  final eip712Data = getTypedMetatransaction(
    MetaTransaction(
      name: contractName,
      version: '1',
      salt: paddedSaltHexString,
      // Padding the chainId with zeroes to make it 32 bytes
      verifyingContract: contractAddress,
      nonce: nonce,
      from: account.address.hex,
      functionSignature: functionSignature,
    ),
  );
  // signature for metatransaction
  final String signature = EthSigUtil.signTypedData(
    jsonData: jsonEncode(eip712Data),
    version: TypedDataVersion.V4,
    privateKey: "0x${bytesToHex(account.privateKey)}",
    // privateKey:
    //     "0xb0239b0afcbb5d7c36dfed696b621fc428c2ad3094c28e4a4a68a1d983cc679d",
  );

  final cleanedSignature =
      signature.startsWith('0x') ? signature.substring(2) : signature;
  // get r,s,v from signature
  final signatureBytes = hexToBytes(cleanedSignature);

  Map<String, dynamic> rsv = {
    'r': signatureBytes.sublist(0, 32),
    's': signatureBytes.sublist(32, 64),
    'v': signatureBytes[64],
  };

  return rsv;
}

String hexZeroPad(int number, int length) {
  final hexString = hex.encode(Uint8List.fromList([number]));
  final paddedHexString = hexString.padLeft(length * 2, '0');
  return '0x$paddedHexString';
}

Future<GsnTransactionDetails> getExecuteMetatransactionTx(
  EthPrivateKey account,
  String destinationAddress,
  double amount,
  NetworkConfig config,
  String contractAddress,
  Web3Client provider,
) async {
  //TODO: Once things are stable, think about refactoring
  // to avoid code duplication

  final token = erc20(EthereumAddress.fromHex(contractAddress));

  final nameCallResult = await provider
      .call(contract: token, function: token.function('name'), params: []);
  final name = nameCallResult.first;

  final nonce = await getSenderContractNonce(provider, token, account.address);
  final decimals = await provider
      .call(contract: token, function: token.function('decimals'), params: []);

  BigInt decimalAmount =
      parseUnits(amount.toString(), int.parse(decimals.first.toString()));

  // get function signature
  final transferFunc = token.function('transfer');
  final data = transferFunc
      .encodeCall([EthereumAddress.fromHex(destinationAddress), decimalAmount]);

  final signatureData = await getMetatransactionEIP712Signature(
    account,
    name,
    contractAddress,
    data,
    config,
    nonce.toInt(),
  );

  final r = signatureData['r'];
  final s = signatureData['s'];
  final v = signatureData['v'];

  final tx = Transaction.callContract(
    contract: token,
    function: token.function('executeMetaTransaction'),
    parameters: [
      account.address,
      data,
      r,
      s,
      //TODO: is this correct?
      BigInt.from(v),
    ],
  );

  // Estimate the gas required for the transaction
  final gas = await provider.estimateGas(
    sender: account.address,
    data: tx.data,
    to: token.address,
  );

  final info = await provider.getBlockInformation();

  final BigInt maxPriorityFeePerGas = BigInt.parse("1500000000");
  final maxFeePerGas =
      info.baseFeePerGas!.getInWei * BigInt.from(2) + (maxPriorityFeePerGas);
  if (tx == null) {
    throw 'tx not populated';
  }

  final gsnTx = GsnTransactionDetails(
    from: account.address.hex,
    data: "0x${bytesToHex(tx.data!)}",
    value: "0",
    to: tx.to!.hex,
    //TODO: Remove hardcoding
    gas: "0x${gas.toRadixString(16)}",
    maxFeePerGas: maxFeePerGas.toString(),
    maxPriorityFeePerGas: maxPriorityFeePerGas.toString(),
  );
  return gsnTx;
}
