import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

enum RlyEnv {
  local,
}

enum MetaTxMethod {
  Permit,
  ExecuteMetaTransaction,
}

class GsnTransactionDetails {
  // users address
  final String from;
  // tx data
  final String data;
  //contract address
  final String to;

  //ether value
  final String? value;
  //optional gas
  String? gas;

  //should be hex
  String maxFeePerGas;
  //should be hex
  String maxPriorityFeePerGas;
  //paymaster contract address
  final String? paymasterData;

  //Value used to identify applications in RelayRequests.
  final String? clientId;

  // Optional parameters for RelayProvider only:
  /**
   * Set to 'false' to create a direct transaction
   */
  final bool? useGSN;

  GsnTransactionDetails({
    required this.from,
    required this.data,
    required this.to,
    this.value,
    this.gas,
    required this.maxFeePerGas,
    required this.maxPriorityFeePerGas,
    this.paymasterData,
    this.clientId,
    this.useGSN,
  });
  @override
  String toString() {
    // TODO: implement toString
    return 'from: $from, data: $data, to: $to, value: $value, gas: $gas, maxFeePerGas: $maxFeePerGas, maxPriorityFeePerGas: $maxPriorityFeePerGas, paymasterData: $paymasterData, clientId: $clientId, useGSN: $useGSN';
  }
}

typedef PrefixedHexString = String;
typedef Address = String;
typedef IntString = String;

Web3Client getEthClient(String apiUrl) {
  var httpClient = Client();
  return Web3Client(apiUrl, httpClient);
}
