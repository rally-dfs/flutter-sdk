import 'dart:convert';

import 'package:web3dart/web3dart.dart';

import 'IForwarderData.dart';

DeployedContract iForwarderContract(
    EthereumAddress contractAddress) {
  return DeployedContract(
    ContractAbi.fromJson(jsonEncode(getIForwarderABIData()),'IForwarder'), contractAddress,
  );
}
