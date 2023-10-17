import 'dart:convert';

import 'package:rly_network_flutter_sdk/gsn/ABI/IRelayHubData.dart';
import 'package:web3dart/web3dart.dart';

DeployedContract relayHubContract(String contractAddress) {
  return DeployedContract(
    ContractAbi.fromJson(jsonEncode(getIRelayHubData()), 'IRelayHub'),
    EthereumAddress.fromHex(contractAddress),
  );
}
