import 'package:web3dart/web3dart.dart';
import 'dart:convert';

import 'erc20Data.dart';

DeployedContract erc20(EthereumAddress contractAddress) {
  final abi = getErc20DataJson()['abi'];
  return DeployedContract(
    ContractAbi.fromJson(jsonEncode(abi), 'ERC20'),
    contractAddress,
  );
}
