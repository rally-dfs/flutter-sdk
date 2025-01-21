
import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/src/utils/rlp.dart' as rlp;
import 'package:convert/convert.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:rly_network_flutter_sdk/src/gsn/utils.dart';



class Eip712DomainSeparator {
  String name;
  String version;
  BigInt chainId;

  Eip712DomainSeparator({
    required this.name,
    required this.version,
    required this.chainId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'version': version,
      'chainId': chainId.toString(),
    };
  }
}

class ClientConfig{
  final String rpcUrl;
  Eip712DomainSeparator domainSeperator;

  ClientConfig({
    required this.rpcUrl,
    required this.domainSeperator,
  });
}

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
      (paymaster != null)? paymaster : null,
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
      'paymaster': paymaster,
      'nonce': nonce.toString(), 
      'value': value.toString(),
      'data': data,
      'factoryDeps': factoryDeps ?? [],
      'paymasterInput': paymasterInput,
    };
  }

}

final types = {
    'EIP712Domain': [
      {'name': 'name', 'type': 'string'},
      {'name': 'version', 'type': 'string'},
      {'name': 'chainId', 'type': 'uint256'},
    ],
    'Transaction': [
        { 'name': 'txType', 'type': 'uint256' },
        { 'name': 'from', 'type': 'uint256' },
        { 'name': 'to', 'type': 'uint256' },
        { 'name': 'gasLimit', 'type': 'uint256' },
        { 'name': 'gasPerPubdataByteLimit', 'type': 'uint256' },
        { 'name': 'maxFeePerGas', 'type': 'uint256' },
        { 'name': 'maxPriorityFeePerGas', 'type': 'uint256' },
        { 'name': 'paymaster', 'type': 'uint256' },
        { 'name': 'nonce', 'type': 'uint256' },
        { 'name': 'value', 'type': 'uint256' },
        { 'name': 'data', 'type': 'bytes' },
        { 'name': 'factoryDeps', 'type': 'bytes32[]' },
        { 'name': 'paymasterInput', 'type': 'bytes' },
      ],
  };

  const primaryType = 'Transaction';

  String concatHex(List<String> values) {
    String concatenatedHex = values.fold('', (acc, x) => acc + x.replaceAll('0x', ''));
    String hexWithPrefix = '0x' + concatenatedHex;
  return hexWithPrefix;
}  

Uint8List hexToUint8List(String hex) {
  // Remove '0x' prefix if present
  if (hex.startsWith('0x')) {
    hex = hex.substring(2);
  }

  // Ensure the hex string has an even length
  if (hex.length % 2 != 0) {
    throw FormatException('Invalid hex string length');
  }

  // Convert hex string to Uint8List
  final bytes = Uint8List(hex.length ~/ 2);
  for (int i = 0; i < hex.length; i += 2) {
    bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
  }

  return bytes;
}

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

  Future<String> sendEip712Transaction(Eip712Transaction transaction, ClientConfig clientConfig) async {  

    final eip712Data = {
      'domain': clientConfig.domainSeperator.toMap(),
      'types': types,
      'primaryType': primaryType,
      'message': transaction.toMap(),
    };


    final String customSignature = signTypedData(eip712Data);

    final List<dynamic> serializedTransaction = [
      "0x${transaction.nonce.toRadixString(16)}",
      "0x${transaction.maxPriorityFeePerGas.toRadixString(16)}",
      "0x${transaction.maxFeePerGas.toRadixString(16)}",
      "0x${transaction.gas.toRadixString(16)}",
      transaction.to,
      "0x${transaction.value.toRadixString(16)}",
      transaction.data,
      "0x${transaction.chainId.toRadixString(16)}",
      "0x",
      "0x",
      "0x${transaction.chainId.toRadixString(16)}",
      transaction.from,
      transaction.gasPerPubdata != null ? "0x${transaction.gasPerPubdata!.toRadixString(16)}" : "0x",
      transaction.factoryDeps ?? [],
      customSignature,
      (transaction.paymaster != null && transaction.paymasterInput != null && transaction.paymasterInput != '0x') ? [transaction.paymaster, transaction.paymasterInput] : [],
    ];
   
    final serializedTransactionList =  hexToUint8List(concatHex(["0x71", bytesToHex(rlp.encode(serializedTransaction))]));

    Web3Client client = getEthClient(clientConfig.rpcUrl);

    final String hash = await client.sendRawTransaction(serializedTransactionList);

    return hash;

  }
}
