import 'package:eth_sig_util/model/typed_data.dart';
import 'package:rly_network_flutter_sdk/src/zksync/zk_sync_chain.dart';

/// Lens Protocol Network Sepolia Testnet
/// Example usage:
/// ```dart
/// final transaction = ZKSyncEip712Transaction(
///   from: wallet.address.hex,
///   to: '0x111C3E89Ce80e62EE88318C2804920D4c96f92bb',
///   nonce: BigInt.from(0),
///   maxPriorityFeePerGas: BigInt.from(2),
///   maxFeePerGas: BigInt.from(250000000000000),
///   gas: BigInt.from(158774),
///   value: BigInt.from(0),
///   data: '0x',
///   chainId: BigInt.from(37111),
///   gasPerPubdata: BigInt.from(50000),
/// );

/// final lensTestNet = ZKSyncLensNetworkSepolia();

/// await lensTestNet.sendTransaction(transaction, wallet);
/// ```
///
class ZKSyncLensNetworkSepolia extends ZKSyncChain {
  ZKSyncLensNetworkSepolia()
      : super(
          rpcUrl: 'https://lens.zksync.io/api/v0.1',
          eip712domain: EIP712Domain(
            name: 'Lens Network Sepolia Testnet',
            version: '1',
            chainId: 37111,
            salt: '',
            verifyingContract: '',
          ),
        );
}
