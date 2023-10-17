import 'dart:convert';
import 'dart:typed_data';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:rly_network_flutter_sdk/contracts/erc20.dart';
import 'package:rly_network_flutter_sdk/gsn/gsn_tx_helpers.dart';
import 'package:rly_network_flutter_sdk/gsn/utils.dart';
import 'package:web3dart/web3dart.dart' as web3;
import 'package:convert/convert.dart';
import '../../wallet.dart';

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

  final messageData = {
    'nonce': metaTransaction.nonce,
    'from': metaTransaction.from,
    'functionSignature': '0x${bytesToHex(metaTransaction.functionSignature)}',
  };

  return {
    'types': types,
    'primaryType': primaryType,
    'domain': domainSeparator,
    'message': messageData,
  };
}

Future<Map<String, dynamic>> getMetatransactionEIP712Signature(
  Wallet wallet,
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
      from: wallet.address.hex,
      functionSignature: functionSignature,
    ),
  );
  // signature for metatransaction
  final String signature = wallet.signTypedData(eip712Data);

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
  Wallet wallet,
  String destinationAddress,
  double amount,
  NetworkConfig config,
  String contractAddress,
  web3.Web3Client provider,
) async {
  final token = erc20(web3.EthereumAddress.fromHex(contractAddress));

  final nameCallResult = await provider
      .call(contract: token, function: token.function('name'), params: []);
  final name = nameCallResult.first;

  final nonce = await getSenderContractNonce(provider, token, wallet.address);
  final decimals = await provider
      .call(contract: token, function: token.function('decimals'), params: []);

  BigInt decimalAmount =
      parseUnits(amount.toString(), int.parse(decimals.first.toString()));

  // get function signature
  final transferFunc = token.function('transfer');
  final data = transferFunc.encodeCall(
      [web3.EthereumAddress.fromHex(destinationAddress), decimalAmount]);

  final signatureData = await getMetatransactionEIP712Signature(
    wallet,
    name,
    contractAddress,
    data,
    config,
    nonce.toInt(),
  );

  final r = signatureData['r'];
  final s = signatureData['s'];
  final v = signatureData['v'];

  final tx = web3.Transaction.callContract(
    contract: token,
    function: token.function('executeMetaTransaction'),
    parameters: [
      wallet.address,
      data,
      r,
      s,
      //TODO: is this correct?
      BigInt.from(v),
    ],
  );

  // Estimate the gas required for the transaction
  final gas = await provider.estimateGas(
    sender: wallet.address,
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
    from: wallet.address.hex,
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
