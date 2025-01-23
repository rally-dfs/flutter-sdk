import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:rly_network_flutter_sdk/src/gsn/utils.dart';

class Eip712Transaction {
  String to;
  String from;
  BigInt nonce;
  BigInt gas;
  BigInt maxPriorityFeePerGas;
  BigInt maxFeePerGas;
  String data;
  BigInt value;
  BigInt chainId;
  BigInt? gasPerPubdata;
  String? customSignature;
  String? paymaster;
  String? paymasterInput;
  List<String>? factoryDeps;

  Eip712Transaction({
    required this.from,
    required this.to,
    required this.gas,
    this.gasPerPubdata,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    required this.nonce,
    required this.data,
    required this.value,
    required this.chainId,
    this.customSignature,
    this.paymaster,
    this.paymasterInput,
  });

  List<dynamic> toJson() {
    return [
      EthereumAddress.fromHex(from),
      EthereumAddress.fromHex(to),
      gas,
      gasPerPubdata,
      maxFeePerGas,
      maxPriorityFeePerGas,
      (paymaster != null) ? paymaster : null,
      nonce,
      value,
      hexToBytes(data),
      factoryDeps,
      paymasterInput,
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'txType': '113',
      'from': from,
      'to': to,
      'gasLimit': gas.toString(),
      'gasPerPubdataByteLimit': gasPerPubdata.toString(),
      'maxFeePerGas': maxFeePerGas.toString(),
      'maxPriorityFeePerGas': maxPriorityFeePerGas.toString(),
      'paymaster': paymaster ?? '0x',
      'nonce': nonce.toString(),
      'value': value.toString(),
      'data': data,
      'factoryDeps': factoryDeps ?? [],
      'paymasterInput': paymasterInput ?? '0x',
    };
  }

  List<dynamic> toList(customSignature) {
    final list = [
      nonce,
      maxPriorityFeePerGas,
      maxFeePerGas,
      gas,
      EthereumAddress.fromHex(to).addressBytes,
      value,
      hexToUint8List(data),
      chainId,
      hexToUint8List("0x"),
      hexToUint8List("0x"),
      chainId,
      EthereumAddress.fromHex(from).addressBytes,
      gasPerPubdata ?? 0,
      factoryDeps ?? [],
      customSignature,
    ];
    if (paymaster != null && paymasterInput != null) {
      list.add([
        EthereumAddress.fromHex(paymaster!).addressBytes,
        hexToUint8List(paymasterInput!)
      ]);
    } else {
      list.add([]);
    }
    return list;
  }

  static const types = {
    'EIP712Domain': [
      {'name': 'name', 'type': 'string'},
      {'name': 'version', 'type': 'string'},
      {'name': 'chainId', 'type': 'uint256'},
    ],
    'Transaction': [
      {'name': 'txType', 'type': 'uint256'},
      {'name': 'from', 'type': 'uint256'},
      {'name': 'to', 'type': 'uint256'},
      {'name': 'gasLimit', 'type': 'uint256'},
      {'name': 'gasPerPubdataByteLimit', 'type': 'uint256'},
      {'name': 'maxFeePerGas', 'type': 'uint256'},
      {'name': 'maxPriorityFeePerGas', 'type': 'uint256'},
      {'name': 'paymaster', 'type': 'uint256'},
      {'name': 'nonce', 'type': 'uint256'},
      {'name': 'value', 'type': 'uint256'},
      {'name': 'data', 'type': 'bytes'},
      {'name': 'factoryDeps', 'type': 'bytes32[]'},
      {'name': 'paymasterInput', 'type': 'bytes'},
    ],
  };

  static const primaryType = 'Transaction';
}
