import 'dart:convert';

import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:web3dart/web3dart.dart';
import 'package:rly_network_flutter_sdk/gsnClient/gsnTxHelpers.dart';

import '../../contracts/erc20.dart';
import '../../network_config/network_config.dart';
import '../utils.dart';

class Permit {
  String name;
  String version;
  int chainId;
  String verifyingContract;
  String owner;
  String spender;
  dynamic value;
  dynamic nonce;
  dynamic deadline;
  String salt;

  Permit({
    required this.name,
    required this.version,
    required this.chainId,
    required this.verifyingContract,
    required this.owner,
    required this.spender,
    required this.value,
    required this.nonce,
    required this.deadline,
    required this.salt,
  });
}

Map<String, dynamic> getTypedPermitTransaction(Permit permit) {
  final types = {
    'EIP712Domain': [
      {'name': 'name', 'type': 'string'},
      {'name': 'version', 'type': 'string'},
      {'name': 'chainId', 'type': 'uint256'},
      {'name': 'verifyingContract', 'type': 'address'},
    ],
    'Permit': [
      {'name': 'owner', 'type': 'address'},
      {'name': 'spender', 'type': 'address'},
      {'name': 'value', 'type': 'uint256'},
      {'name': 'nonce', 'type': 'uint256'},
      {'name': 'deadline', 'type': 'uint256'},
    ],
  };

  const primaryType = "Permit";

  final domain = {
    'name': permit.name,
    'version': permit.version,
    'chainId': permit.chainId,
    'verifyingContract': permit.verifyingContract,
  };

  if (permit.salt !=
          '0x0000000000000000000000000000000000000000000000000000000000000000' &&
      permit.salt.isNotEmpty) {
    domain['salt'] = permit.salt;
    types['EIP712Domain']!.add({'name': 'salt', 'type': 'bytes32'});
  }

  final message = {
    'owner': permit.owner,
    'spender': permit.spender,
    'value': permit.value.toInt(),
    'nonce': permit.nonce.toInt(),
    'deadline': permit.deadline.toInt(),
  };

  return {
    'types': types,
    'primaryType': primaryType,
    'domain': domain,
    'message': message,
  };
}

Future<Map<String, dynamic>> getPermitEIP712Signature(
  Wallet account,
  String contractName,
  String contractAddress,
  NetworkConfig config,
  int nonce,
  BigInt amount,
  BigInt deadline,
  String salt,
) async {
  // chainId to be used in EIP712
  final chainId = int.parse(config.gsn.chainId);

  // typed data for signing
  final eip712Data = getTypedPermitTransaction(
    Permit(
      name: contractName,
      version: '1',
      chainId: chainId,
      verifyingContract: contractAddress,
      owner: account.privateKey.address.hex,
      spender: config.gsn.paymasterAddress,
      value: amount,
      nonce: nonce,
      deadline: deadline,
      salt: salt,
    ),
  );

  // signature for metatransaction
  final String signature = EthSigUtil.signTypedData(
    jsonData: jsonEncode(eip712Data),
    version: TypedDataVersion.V4,
    privateKey: "0x${bytesToHex(account.privateKey.privateKey)}",
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

Future<GsnTransactionDetails> getPermitTx(
  Wallet account,
  EthereumAddress destinationAddress,
  double amount,
  NetworkConfig config,
  String contractAddress,
  Web3Client provider,
) async {
  final token = erc20(EthereumAddress.fromHex(contractAddress));
  final noncesCallResult = await provider.call(
      contract: token,
      function: token.function("nonces"),
      params: [EthereumAddress.fromHex(account.privateKey.address.hex)]);

  final nameCall = await provider
      .call(contract: token, function: token.function('name'), params: []);
  final name = nameCall[0];
  final nonce = noncesCallResult[0];
  // final nonce = await provider.getTransactionCount(
  //     EthereumAddress.fromHex(account.privateKey.address.hex));

  final decimals = await provider
      .call(contract: token, function: token.function('decimals'), params: []);

  final deadline = await getPermitDeadline(provider);
  final eip712DomainCallResult = await provider.call(
      contract: token, function: token.function('eip712Domain'), params: []);

  final salt = "0x${bytesToHex(eip712DomainCallResult[5])}";

  BigInt decimalAmount =
      parseUnits(amount.toString(), int.parse(decimals.first.toString()));

  final signature = await getPermitEIP712Signature(
    account,
    name,
    contractAddress,
    config,
    nonce.toInt(),
    decimalAmount,
    deadline,
    salt,
  );

  final r = signature['r'];
  final s = signature['s'];
  final v = signature['v'];

  final fromTx = token.function('transferFrom').encodeCall([
    EthereumAddress.fromHex(account.privateKey.address.hex),
    destinationAddress,
    decimalAmount,
  ]);

  final tx = Transaction.callContract(
    contract: token,
    function: token.function('permit'),
    parameters: [
      EthereumAddress.fromHex(account.privateKey.address.hex),
      EthereumAddress.fromHex(config.gsn.paymasterAddress),
      decimalAmount,
      deadline,
      BigInt.from(v),
      r,
      s,
    ],
  );

  final gas = await provider.estimateGas(
    to: token.address,
    data: tx.data,
    sender: account.privateKey.address,
  );

  final paymasterData =
      '0x${token.address.hex.replaceFirst('0x', '')}${bytesToHex(fromTx)}';
  //following code is inspired from getFeeData method of
  //abstract-provider of ethers js library
  final info = await provider.getBlockInformation();

  final BigInt maxPriorityFeePerGas = BigInt.parse("1500000000");
  final maxFeePerGas =
      info.baseFeePerGas!.getInWei * BigInt.from(2) + (maxPriorityFeePerGas);

  final gsnTx = GsnTransactionDetails(
    from: account.privateKey.address.hex,
    data: "0x${bytesToHex(tx.data!)}",
    value: "0",
    to: tx.to!.hex,
    gas: "0x${gas.toRadixString(16)}",
    maxFeePerGas: maxFeePerGas.toString(),
    maxPriorityFeePerGas: maxPriorityFeePerGas.toString(),
    paymasterData: paymasterData,
  );

  return gsnTx;
}

// get timestamp that will always be included in the next 3 blocks
Future<BigInt> getPermitDeadline(Web3Client provider) async {
  final block = await provider.getBlockInformation();
  return BigInt.from(
      block.timestamp.add(const Duration(seconds: 45)).millisecondsSinceEpoch);
}
