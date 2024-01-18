import 'dart:async';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter/services.dart';
import 'package:rly_network_flutter_sdk/src/contracts/tokenFaucet.dart';
import 'package:rly_network_flutter_sdk/src/gsn/ABI/IForwarder.dart';
import 'package:web3dart/crypto.dart';
import 'package:http/http.dart';
import 'package:rly_network_flutter_sdk/src/gsn/ABI/IRelayHub.dart';

import 'package:rly_network_flutter_sdk/src/gsn/utils.dart';

import 'package:web3dart/web3dart.dart' as web3;

import '../network_config/network_config.dart';
import '../wallet.dart';
import 'EIP712/forward_request.dart';
import 'EIP712/relay_data.dart';
import 'EIP712/relay_request.dart';

CalldataBytes calculateCalldataBytesZeroNonzero(PrefixedHexString calldata) {
  final calldataBuf =
      Uint8List.fromList(calldata.replaceAll('0x', '').codeUnits);

  int calldataZeroBytes = 0;
  int calldataNonzeroBytes = 0;

  calldataBuf.forEach((ch) {
    calldataZeroBytes += ch == 0 ? 1 : 0;
    calldataNonzeroBytes += ch != 0 ? 1 : 0;
  });

  return CalldataBytes(calldataZeroBytes, calldataNonzeroBytes);
}

int calculateCalldataCost(
  String msgData,
  int gtxDataNonZero,
  int gtxDataZero,
) {
  var calldataBytesZeroNonzero = calculateCalldataBytesZeroNonzero(msgData);
  return (calldataBytesZeroNonzero.calldataZeroBytes * gtxDataZero +
      calldataBytesZeroNonzero.calldataNonzeroBytes * gtxDataNonZero);
}

String estimateGasWithoutCallData(
  GsnTransactionDetails transaction,
  int gtxDataNonZero,
  int gtxDataZero,
) {
  final originalGas = transaction.gas;
  final callDataCost = calculateCalldataCost(
    transaction.data,
    gtxDataNonZero,
    gtxDataZero,
  );
  final adjustedGas = BigInt.parse(originalGas!.substring(2), radix: 16) -
      BigInt.from(callDataCost);

  return '0x${adjustedGas.toRadixString(16)}';
}

Future<String> estimateCalldataCostForRequest(RelayRequest relayRequestOriginal,
    GSNConfig config, web3.Web3Client client) async {
  // Protecting the original object from temporary modifications done here
  var relayRequest = RelayRequest(
    request: ForwardRequest(
      from: relayRequestOriginal.request.from,
      to: relayRequestOriginal.request.to,
      value: relayRequestOriginal.request.value,
      gas: relayRequestOriginal.request.gas,
      nonce: relayRequestOriginal.request.nonce,
      data: relayRequestOriginal.request.data,
      validUntilTime: relayRequestOriginal.request.validUntilTime,
    ),
    relayData: RelayData(
      maxFeePerGas: relayRequestOriginal.relayData.maxFeePerGas,
      maxPriorityFeePerGas: relayRequestOriginal.relayData.maxPriorityFeePerGas,
      transactionCalldataGasUsed: '0xffffffffff',
      relayWorker: relayRequestOriginal.relayData.relayWorker,
      paymaster: relayRequestOriginal.relayData.paymaster,
      paymasterData:
          '0x${List.filled(config.maxPaymasterDataLength, 'ff').join()}',
      clientId: relayRequestOriginal.relayData.clientId,
      forwarder: relayRequestOriginal.relayData.forwarder,
    ),
  );

  const maxAcceptanceBudget = "0xffffffffff";
  // final maxAcceptanceBudget = BigInt.from(12345);
  final signature = '0x${List.filled(65, 'ff').join()}';
  final approvalData =
      '0x${List.filled(config.maxApprovalDataLength, 'ff').join()}';

  final relayHub = relayHubContract(config.relayHubAddress);
  // Estimate the gas cost for the relayCall function call

  var relayRequestJson = relayRequest.toJson();

  final function = relayHub.function('relayCall');

  // Transaction.callContract(contract: contract, function: function, parameters: parameters)
  final tx = web3.Transaction.callContract(
      contract: relayHub,
      function: function,
      parameters: [
        config.domainSeparatorName,
        BigInt.parse(maxAcceptanceBudget.substring(2), radix: 16),
        relayRequestJson,
        hexToBytes(signature),
        hexToBytes(approvalData)
      ]);
  // final tx = await client.call(contract: relayHub, function: function,
  //     params: [
  //       config.domainSeparatorName,
  //       BigInt.parse(maxAcceptanceBudget.substring(2), radix: 16),
  //       relayRequestJson,
  //       hexToBytes(signature),
  //       hexToBytes(approvalData)
  //     ]);

  //todo: is the calculation of call data cost(from the rly sdk gsnTxHelper file)
  //similar to the estimate gas here?
  return BigInt.from(calculateCalldataCost(
          uint8ListToHex(tx.data!), config.gtxDataNonZero, config.gtxDataZero))
      .toRadixString(16);
}

Future<String> getSenderNonce(web3.EthereumAddress sender,
    web3.EthereumAddress forwarderAddress, web3.Web3Client client) async {
  final forwarder = iForwarderContract(forwarderAddress);

  final List<dynamic> result = await client.call(
    contract: forwarder,
    function: forwarder.function("getNonce"),
    params: [sender],
  );

  // Extract the nonce value from the result and convert it to a string
  // if you go to getNonce method of IForwarderData.dart
  //there is only one output defined in the getNonce method
  //that's why we can be sure that result[0] will be used here
  final nonce = result.first.toString();
  return nonce;
}

Future<String> signRequest(
  RelayRequest relayRequest,
  String domainSeparatorName,
  String chainId,
  Wallet wallet,
  NetworkConfig config,
) async {
  // Define the domain separator
  final domainSeparator = {
    'name': domainSeparatorName,
    'version': '3',
    'chainId': chainId, // Ethereum Mainnet chain ID
    'verifyingContract': config.gsn.forwarderAddress,
  };

// Define the types and primary type
  final types = {
    'EIP712Domain': [
      {'name': 'name', 'type': 'string'},
      {'name': 'version', 'type': 'string'},
      {'name': 'chainId', 'type': 'uint256'},
      {'name': 'verifyingContract', 'type': 'address'},
    ],
    'RelayRequest': [
      // Define fields for ForwardRequest
      {'name': 'from', 'type': 'address'},
      {'name': 'to', 'type': 'address'},
      {'name': 'value', 'type': 'uint256'},
      {'name': 'gas', 'type': 'uint256'},
      {'name': 'nonce', 'type': 'uint256'},
      {'name': 'data', 'type': 'bytes'},
      {'name': 'validUntilTime', 'type': 'uint256'},
      {"name": "relayData", "type": "RelayData"}
    ],
    'RelayData': [
      // Define fields for RelayData
      {'name': 'maxFeePerGas', 'type': 'uint256'},
      {'name': 'maxPriorityFeePerGas', 'type': 'uint256'},
      {'name': 'transactionCalldataGasUsed', 'type': 'uint256'},
      {'name': 'relayWorker', 'type': 'address'},
      {'name': 'paymaster', 'type': 'address'},
      {'name': 'forwarder', 'type': 'address'},
      {'name': 'paymasterData', 'type': 'bytes'},
      {'name': 'clientId', 'type': 'uint256'},
    ],
  };

  const primaryType = 'RelayRequest';

// Define the message data
  final messageData = {
    ...relayRequest.request.toMap(),
    'relayData': relayRequest.relayData.toMap(),
  };

// Combine domain separator, types, primary type, and message data
  final jsonData = {
    'types': types,
    'primaryType': primaryType,
    'domain': domainSeparator,
    'message': messageData,
  };

// Sign the data
  final signature = wallet.signTypedData(jsonData);

  return signature;
}

String getRelayRequestID(
  Map<String, dynamic> relayRequest,
  String signature,
) {
  final types = ['address', 'uint256', 'bytes'];
  final parameters = [
    relayRequest['request']['from'],
    relayRequest['request']['nonce'],
    signature
  ];

  final hash = keccak256(AbiUtil.rawEncode(types, parameters));
  final rawRelayRequestId = hex.encode(hash).padLeft(64, '0');
  const prefixSize = 8;
  final prefixedRelayRequestId = rawRelayRequestId.replaceFirst(
      RegExp('^.{$prefixSize}'), '0' * prefixSize);
  return '0x$prefixedRelayRequestId';
}

Future<GsnTransactionDetails> getClaimTx(
  Wallet wallet,
  NetworkConfig config,
  web3.Web3Client client,
) async {
  final faucet = tokenFaucet(
    config,
    web3.EthereumAddress.fromHex(config.contracts.tokenFaucet),
  );

  final tx = web3.Transaction.callContract(
      contract: faucet, function: faucet.function('claim'), parameters: []);
  final gas = await client.estimateGas(
    sender: wallet.address,
    data: tx.data,
    to: faucet.address,
  );

  //TODO:-> following code is inspired from getFeeData method of
  //abstract-provider of ethers js library
  //test if it exactly replicates the functions of getFeeData

  web3.BlockInformation blockInformation = await client.getBlockInformation();
  final BigInt maxPriorityFeePerGas = BigInt.parse("1500000000");
  BigInt? maxFeePerGas;
  if (blockInformation.baseFeePerGas != null) {
    maxFeePerGas = blockInformation.baseFeePerGas!.getInWei * BigInt.from(2) +
        (maxPriorityFeePerGas);
  }

  final gsnTx = GsnTransactionDetails(
    from: wallet.address.toString(),
    data: uint8ListToHex(tx.data!),
    value: "0",
    to: faucet.address.hex,
    gas: "0x${gas.toRadixString(16)}",
    maxFeePerGas: maxFeePerGas!.toRadixString(16),
    maxPriorityFeePerGas: maxPriorityFeePerGas.toRadixString(16),
  );

  return gsnTx;
}

Future<String> getClientId() async {
  final bundleId = await getBundleIdFromOS();
  final hexValue = web3.EthereumAddress.fromHex(bundleId).hex;
  return BigInt.parse(hexValue, radix: 16).toString();
}

Future<String> getBundleIdFromOS() async {
  const methodChannel = MethodChannel('rly_network_flutter_sdk');
  final osBundleId = await methodChannel.invokeMethod<String>("getBundleId");

  if (osBundleId == null) {
    throw Exception("Unable to get bundle id from OS");
  }
  return osBundleId;
}

Future<String> handleGsnResponse(
  Response res,
  web3.Web3Client ethClient,
) async {
  // printLog("res.body  = ${res.body}");
  Map<String, dynamic> responseMap = jsonDecode(res.body);
  if (responseMap['error'] != null) {
    throw {
      'message': 'RelayError',
      'details': responseMap['error'],
    };
  } else {
    final txHash =
        "0x${bytesToHex(keccak256(hexToBytes(responseMap['signedTx'])))}";
    // Poll for the transaction receipt until it's confirmed
    web3.TransactionReceipt? receipt;
    do {
      receipt = await ethClient.getTransactionReceipt(txHash);
      if (receipt == null) {
        await Future.delayed(const Duration(seconds: 2)); // Wait for 2 seconds
      }
    } while (receipt == null);
    return txHash;
  }
}

Future<BigInt> getSenderContractNonce(web3.Web3Client provider,
    web3.DeployedContract token, web3.EthereumAddress address) async {
  try {
    final fn = token.function('nonces');
    final fnCall =
        await provider.call(contract: token, function: fn, params: [address]);
    return fnCall[0];
  } on Exception {
    final fn = token.function('getNonce');
    final fnCall =
        await provider.call(contract: token, function: fn, params: [address]);
    return fnCall[0];
  }
}

BigInt parseUnits(String value, int decimals) {
  BigInt base = BigInt.from(10).pow(decimals);
  List<String> parts = value.split('.');
  BigInt wholePart = BigInt.parse(parts[0]);
  BigInt fractionalPart = parts.length > 1
      ? BigInt.parse(parts[1].padRight(decimals, '0'))
      : BigInt.zero;

  return wholePart * base + fractionalPart;
}

// Converts the given value to a double using the given number of decimals.
// For example, if the value is 1000 and the decimals is 2, the result will be 10.00
// Beware that this can cause precision loss for large values and should be used for display purposes only.
double balanceToDouble(BigInt value, BigInt decimals) {
  final base = BigInt.from(10).pow(decimals.toInt());

  return value.toDouble() / base.toDouble();
}

class CalldataBytes {
  final int calldataZeroBytes;
  final int calldataNonzeroBytes;

  CalldataBytes(this.calldataZeroBytes, this.calldataNonzeroBytes);
}

String uint8ListToHex(Uint8List list) {
  return '0x${hex.encode(list)}';
}
