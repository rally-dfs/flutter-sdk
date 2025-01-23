import 'package:eth_sig_util/model/typed_data.dart';

class ZKSyncChain {
  // The RPC URL of the node you are accessing for the given ZKSync chain.
  final String rpcUrl;

  /// ZKSync bakes 712 support in at the protocol level.
  /// Therefore, these values should be defined at the chain level.
  /// This ensures that the necessary parameters are correctly set
  /// and managed within the blockchain network, providing a seamless
  /// and efficient integration of the 712 standard.
  final EIP712Domain eip712domain;

  ZKSyncChain({required this.rpcUrl, required this.eip712domain});
}
