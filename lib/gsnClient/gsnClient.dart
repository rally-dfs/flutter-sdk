import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_sdk/gsnClient/EIP712/ForwardRequest.dart';
import 'package:flutter_sdk/gsnClient/EIP712/RelayData.dart';
import 'package:flutter_sdk/gsnClient/utils.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter_sdk/gsnClient/gsnTxHelpers.dart';

import '../network_config/network_config.dart';
import 'EIP712/RelayRequest.dart';

Future<Map<String, dynamic>> updateConfig(
  NetworkConfig config,
  GsnTransactionDetails transaction,
) async {
  final response = await http.get(Uri.parse('${config.gsn.relayUrl}/getaddr'),
      headers: authHeader(config));
  final serverConfigUpdate = GsnServerConfigPayload.fromJson(response.body);

  config.gsn.relayWorkerAddress = serverConfigUpdate.relayWorkerAddress;
  setGasFeesForTransaction(transaction, serverConfigUpdate);

  return {'config': config, 'transaction': transaction};
}

Future<RelayRequest> buildRelayRequest(
  GsnTransactionDetails transaction,
  NetworkConfig config,
  Wallet account,
  Web3Client web3Provider,
) async {
  transaction.gas = estimateGasWithoutCallData(
    transaction,
    config.gsn.gtxDataNonZero,
    config.gsn.gtxDataZero,
  );

  final secondsNow = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final validUntilTime =
      (secondsNow + config.gsn.requestValidSeconds).toString();

  final senderNonce = await getSenderNonce(
    account.privateKey.address,
    EthereumAddress.fromHex(config.gsn.forwarderAddress),
    web3Provider,
  );
  ForwardRequest forwardRequest = ForwardRequest(
    from: transaction.from,
    to: transaction.to,
    value: transaction.value ?? '0',
    gas: int.parse(transaction.gas!.substring(2), radix: 16).toString(),
    nonce: senderNonce,
    data: transaction.data,
    validUntilTime: validUntilTime,
  );
  RelayData relayData = RelayData(
      maxFeePerGas: transaction.maxFeePerGas,
      maxPriorityFeePerGas: transaction.maxPriorityFeePerGas,
      transactionCalldataGasUsed: '',
      relayWorker: config.gsn.relayWorkerAddress,
      paymaster: config.gsn.paymasterAddress,
      paymasterData: (transaction.paymasterData != null)
          ? transaction.paymasterData.toString()
          : '0x',
      clientId: '1',
      forwarder: config.gsn.forwarderAddress);

  RelayRequest relayRequest =
      RelayRequest(request: forwardRequest, relayData: relayData);

  final transactionCalldataGasUsed = await estimateCalldataCostForRequest(
      relayRequest, config.gsn, web3Provider);

  relayRequest.relayData.transactionCalldataGasUsed =
      int.parse(transactionCalldataGasUsed, radix: 16).toString();

  return relayRequest;
}

Future<Map<String, dynamic>> buildRelayHttpRequest(
  RelayRequest relayRequest,
  NetworkConfig config,
  Wallet account,
  Web3Client web3Provider,
) async {
  final signature = await signRequest(relayRequest,
      config.gsn.domainSeparatorName, config.gsn.chainId, account, config);
  const approvalData = '0x';

  final relayWorkerAddress =
      EthereumAddress.fromHex(relayRequest.relayData.relayWorker);
  final relayLastKnownNonce =
      await web3Provider.getTransactionCount(relayWorkerAddress);
  final relayMaxNonce = relayLastKnownNonce + config.gsn.maxRelayNonceGap;

  final metadata = {
    'maxAcceptanceBudget': config.gsn.maxAcceptanceBudget,
    'relayHubAddress': config.gsn.relayHubAddress,
    'signature': signature,
    'approvalData': approvalData,
    'relayMaxNonce': relayMaxNonce,
    'relayLastKnownNonce': relayLastKnownNonce,
    'domainSeparatorName': config.gsn.domainSeparatorName,
    'relayRequestId': '',
  };
  final httpRequest = {
    'relayRequest': relayRequest.toMap(),
    'metadata': metadata,
  };

  return httpRequest;
}

Future<String> relayTransaction(
  Wallet account,
  NetworkConfig config,
  GsnTransactionDetails transaction,
) async {
  final web3Provider = getEthClient(config.gsn.rpcUrl);
  final updatedConfig = await updateConfig(config, transaction);
  final relayRequest = await buildRelayRequest(
    updatedConfig['transaction'],
    updatedConfig['config'],
    account,
    web3Provider,
  );
  final httpRequest = await buildRelayHttpRequest(
    relayRequest,
    updatedConfig['config'],
    account,
    web3Provider,
  );

  final relayRequestId = getRelayRequestID(
    httpRequest['relayRequest'],
    httpRequest['metadata']['signature'],
  );

  // Update request metadata with relayrequestid
  httpRequest['metadata']['relayRequestId'] = relayRequestId;

  final authHeader = {
    'Content-Type': 'application/json', // Specify the content type as JSON
    'Authorization': 'Bearer ${config.relayerApiKey ?? ''}',
  };

  final res = await http.post(
    Uri.parse('${config.gsn.relayUrl}/relay'),
    headers:
        authHeader, // Assuming authHeader is a map of headers you want to include
    body: json.encode(httpRequest),
  );
  return handleGsnResponse(res, web3Provider);
}

Map<String, String> authHeader(NetworkConfig config) {
  return {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${config.relayerApiKey ?? ''}',
  };
}

void setGasFeesForTransaction(
  GsnTransactionDetails transaction,
  GsnServerConfigPayload serverConfigUpdate,
) {
  final serverSuggestedMinPriorityFeePerGas =
      int.parse(serverConfigUpdate.minMaxPriorityFeePerGas, radix: 10);

  final paddedMaxPriority = (serverSuggestedMinPriorityFeePerGas * 1.4).round();
  transaction.maxPriorityFeePerGas = paddedMaxPriority.toString();

  // Special handling for mumbai because of quirk with gas estimate returned by GSN for mumbai
  if (serverConfigUpdate.chainId == '80001') {
    transaction.maxFeePerGas = paddedMaxPriority.toString();
  } else {
    transaction.maxFeePerGas = serverConfigUpdate.maxMaxFeePerGas;
  }
}

class GsnServerConfigPayload {
  final String relayWorkerAddress;
  final String relayManagerAddress;
  final String relayHubAddress;
  final String ownerAddress;
  final String minMaxPriorityFeePerGas;
  final String maxMaxFeePerGas;
  final String minMaxFeePerGas;
  final String maxAcceptanceBudget;
  final String chainId;
  final String networkId;
  final bool ready;
  final String version;

  GsnServerConfigPayload({
    required this.relayWorkerAddress,
    required this.relayManagerAddress,
    required this.relayHubAddress,
    required this.ownerAddress,
    required this.minMaxPriorityFeePerGas,
    required this.maxMaxFeePerGas,
    required this.minMaxFeePerGas,
    required this.maxAcceptanceBudget,
    required this.chainId,
    required this.networkId,
    required this.ready,
    required this.version,
  });
  // make fromJson method for this class
  factory GsnServerConfigPayload.fromJson(String json) {
    Map<String, dynamic> dataMap = jsonDecode(json);
    return GsnServerConfigPayload(
      relayWorkerAddress: dataMap['relayWorkerAddress'],
      relayManagerAddress: dataMap['relayManagerAddress'],
      relayHubAddress: dataMap['relayHubAddress'],
      ownerAddress: dataMap['ownerAddress'],
      minMaxPriorityFeePerGas: dataMap['minMaxPriorityFeePerGas'],
      maxMaxFeePerGas: dataMap['maxMaxFeePerGas'],
      minMaxFeePerGas: dataMap['minMaxFeePerGas'],
      maxAcceptanceBudget: dataMap['maxAcceptanceBudget'],
      chainId: dataMap['chainId'],
      networkId: dataMap['networkId'],
      ready: dataMap['ready'],
      version: dataMap['version'],
    );
  }
}
