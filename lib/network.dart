import 'package:rly_network_flutter_sdk/networks/evm_networks.dart';
import 'package:rly_network_flutter_sdk/gsn/utils.dart';

import 'network_config/network_config_mumbai.dart';
import 'network_config/network_config_local.dart';
import 'network_config/network_config_polygon.dart';

abstract class Network {
  Future<dynamic> getBalance(
      {PrefixedHexString? tokenAddress, bool humanReadable = false});
  Future<double> getDisplayBalance({PrefixedHexString? tokenAddress});
  Future<BigInt> getExactBalance({PrefixedHexString? tokenAddress});
  Future<String> transfer(
      String destinationAddress, double amount, MetaTxMethod metaTxMethod,
      {PrefixedHexString? tokenAddress});
  Future<String> transferExact(
      String destinationAddress, BigInt amount, MetaTxMethod metaTxMethod,
      {PrefixedHexString? tokenAddress});
  Future<String> simpleTransfer(String destinationAddress, double amount,
      {PrefixedHexString? tokenAddress, MetaTxMethod? metaTxMethod});
  Future<String> claimRly();
  Future<String> registerAccount();
  Future<String> relay(GsnTransactionDetails tx);
  void setApiKey(String apiKey);
}

final Network rlyMumbaiNetwork = NetworkImpl(mumbaiNetworkConfig);
final Network rlyLocalNetwork = NetworkImpl(localNetworkConfig);
final Network rlyPolygonNetwork = NetworkImpl(polygonNetworkConfig);
