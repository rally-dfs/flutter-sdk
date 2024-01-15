import 'package:eth_sig_util/util/utils.dart';
import 'package:web3dart/credentials.dart';

import '../utils.dart';

class RelayData {
  IntString maxFeePerGas;
  IntString maxPriorityFeePerGas;
  IntString transactionCalldataGasUsed;
  Address relayWorker;
  Address paymaster;
  Address forwarder;
  PrefixedHexString paymasterData;
  IntString clientId;

  RelayData({
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.transactionCalldataGasUsed,
    required this.relayWorker,
    required this.paymaster,
    required this.forwarder,
    required this.paymasterData,
    required this.clientId,
  });

  List<dynamic> toJson() {
    return [
      BigInt.parse(maxFeePerGas),
      BigInt.parse(maxPriorityFeePerGas),
      BigInt.parse(transactionCalldataGasUsed),
      EthereumAddress.fromHex(relayWorker),
      EthereumAddress.fromHex(paymaster),
      EthereumAddress.fromHex(forwarder),
      hexToBytes(paymasterData),
      BigInt.parse(clientId),
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'maxFeePerGas': maxFeePerGas,
      'maxPriorityFeePerGas': maxPriorityFeePerGas,
      'transactionCalldataGasUsed': transactionCalldataGasUsed,
      'relayWorker': relayWorker,
      'paymaster': paymaster,
      'forwarder': forwarder,
      'paymasterData': paymasterData,
      'clientId': clientId,
    };
  }
}
