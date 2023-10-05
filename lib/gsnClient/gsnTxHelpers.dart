import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:flutter_sdk/contracts/tokenFaucet.dart';
import 'package:flutter_sdk/gsnClient/ABI/IForwarder.dart';
import 'package:web3dart/crypto.dart';
import 'package:http/http.dart';
import 'package:flutter_sdk/gsnClient/ABI/IRelayHub.dart';

import 'package:flutter_sdk/gsnClient/utils.dart';

import 'package:web3dart/web3dart.dart';

import '../network_config/network_config.dart';
import 'EIP712/ForwardRequest.dart';
import 'EIP712/RelayData.dart';
import 'EIP712/RelayRequest.dart';
import 'EIP712/typedSigning.dart';

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
    GSNConfig config, Web3Client client) async {
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
  final tx = Transaction.callContract(
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

  if (tx == null) {
    throw 'tx not populated';
  }

  //todo: is the calculation of call data cost(from the rly sdk gsnTxHelper file)
  //similar to the estimate gas here?
  //TODO: remove this to string from next line
  return BigInt.from(calculateCalldataCost(
          uint8ListToHex(tx.data!), config.gtxDataNonZero, config.gtxDataZero))
      .toRadixString(16);
}

Future<String> getSenderNonce(EthereumAddress sender,
    EthereumAddress forwarderAddress, Web3Client client) async {
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
  Wallet account,
  NetworkConfig config,
) async {
  final cloneRequest = {
    "request": ForwardRequest(
      from: relayRequest.request.from,
      to: relayRequest.request.to,
      value: relayRequest.request.value,
      gas: relayRequest.request.gas,
      nonce: relayRequest.request.nonce,
      data: relayRequest.request.data,
      validUntilTime: relayRequest.request.validUntilTime,
    ).toMap(),
    "relayData": RelayData(
      maxFeePerGas: relayRequest.relayData.maxFeePerGas,
      maxPriorityFeePerGas: relayRequest.relayData.maxPriorityFeePerGas,
      transactionCalldataGasUsed:
          relayRequest.relayData.transactionCalldataGasUsed,
      relayWorker: relayRequest.relayData.relayWorker,
      paymaster: relayRequest.relayData.paymaster,
      paymasterData: relayRequest.relayData.paymasterData,
      clientId: relayRequest.relayData.clientId,
      forwarder: relayRequest.relayData.forwarder,
    ).toMap(),
  };
  //     String name, int chainId, EthereumAddress verifier, dynamic relayRequest)
  final signedGsnData = TypedGsnRequestData(
    domainSeparatorName,
    int.parse(chainId),
    relayRequest.relayData.forwarder,
    cloneRequest,
  );

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

// Sign the data using ethsigutil.signTypedData
  final signature = EthSigUtil.signTypedData(
    jsonData: jsonEncode(jsonData),
    privateKey: "0x${bytesToHex(account.privateKey.privateKey)}",
    version: TypedDataVersion.V4,
  );

  String revoered = EthSigUtil.recoverSignature(
    signature: signature,
    message: TypedDataUtil.hashMessage(
      jsonData: jsonEncode(jsonData),
      version: TypedDataVersion.V4,
    ),
  );

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
  Wallet account,
  NetworkConfig config,
  Web3Client client,
) async {
  final faucet = tokenFaucet(
    config,
    EthereumAddress.fromHex(config.contracts.tokenFaucet),
  );

  final tx = Transaction.callContract(
      contract: faucet, function: faucet.function('claim'), parameters: []);
  final gas = await client.estimateGas(
    sender: account.privateKey.address,
    data: tx.data,
    to: faucet.address,
  );

  //TODO:-> following code is inspired from getFeeData method of
  //abstract-provider of ethers js library
  //test if it exactly replicates the functions of getFeeData

  BlockInformation blockInformation = await client.getBlockInformation();
  final BigInt maxPriorityFeePerGas = BigInt.parse("1500000000");
  BigInt? maxFeePerGas;
  if (blockInformation.baseFeePerGas != null) {
    maxFeePerGas = blockInformation.baseFeePerGas!.getInWei * BigInt.from(2) +
        (maxPriorityFeePerGas);
  }

  final gsnTx = GsnTransactionDetails(
    from: account.privateKey.address.toString(),
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
  // Replace this line with the actual method to get the bundleId from the native module
  final bundleId = await getBundleIdFromNativeModule();
//TODO:
  final hexValue = EthereumAddress.fromHex(bundleId).hex;
  return BigInt.parse(hexValue, radix: 16).toString();
}

Future<String> getBundleIdFromNativeModule() {
  // TODO: Replace this with the actual method to get the bundleId from the native module
  // Example: MethodChannel or Platform channel to communicate with native code
  // For demonstration purposes, we'll use a dummy value
  return Future.value('com.savez.app');
}

Future<String> handleGsnResponse(
  Response res,
  Web3Client ethClient,
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
    TransactionReceipt? receipt;
    do {
      receipt = await ethClient.getTransactionReceipt(txHash);
      if (receipt == null) {
        await Future.delayed(const Duration(seconds: 2)); // Wait for 2 seconds
      }
    } while (receipt == null);
    return txHash;
  }
}

Future<BigInt> getSenderContractNonce(Web3Client provider,
    DeployedContract token, EthereumAddress address) async {
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
  if (value is! String) {
    throw ArgumentError.value(value, 'value', 'value must be a string');
  }
  BigInt base = BigInt.from(10).pow(decimals);
  List<String> parts = value.split('.');
  BigInt wholePart = BigInt.parse(parts[0]);
  BigInt fractionalPart = parts.length > 1
      ? BigInt.parse(parts[1].padRight(decimals, '0'))
      : BigInt.zero;

  return wholePart * base + fractionalPart;
}

double formatUnits(BigInt wei, BigInt decimals) {
  const etherUnit = EtherUnit.gwei;
  final balanceFormatted =
      EtherAmount.fromBigInt(etherUnit, wei).getValueInUnit(EtherUnit.gwei);
  return balanceFormatted;
}

class CalldataBytes {
  final int calldataZeroBytes;
  final int calldataNonzeroBytes;

  CalldataBytes(this.calldataZeroBytes, this.calldataNonzeroBytes);
}

String uint8ListToHex(Uint8List list) {
  return '0x${hex.encode(list)}';
}
