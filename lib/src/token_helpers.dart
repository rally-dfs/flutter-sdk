import 'package:rly_network_flutter_sdk/src/gsn/utils.dart';
import 'package:web3dart/web3dart.dart' as web3;

import '../contracts.dart';
import 'network_config/network_config.dart';

class TokenHelpers {
  static Future<BigInt> getDecimals(
      PrefixedHexString tokenAddress, NetworkConfig network) async {
    final provider = getEthClient(network.gsn.rpcUrl);

    final token = erc20(web3.EthereumAddress.fromHex(tokenAddress));

    final decimals = await provider.call(
        contract: token, function: token.function('decimals'), params: []);
    return decimals.first as BigInt;
  }
}
