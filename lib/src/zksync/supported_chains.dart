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

///  Example usage with paymaster: 
/// ```dart
///   final transaction = ZKSyncEip712Transaction(
///   from: wallet.address.hex,,     
///   to: '0x111C3E89Ce80e62EE88318C2804920D4c96f92bb',
///   nonce: BigInt.from(0),
///   maxPriorityFeePerGas: BigInt.from(6522020168),
///   maxFeePerGas: BigInt.from(6522020168),
///   gas: BigInt.from(750000),
///   value: BigInt.from(0),
///   data: '0x0000001',
///   chainId: BigInt.from(37111),
///   gasPerPubdata: BigInt.from(50000),
///   paymasterInput: '0x0yourpaymasterinput',
///   paymaster: '0x115B6D4aED14AD0F900a20819ABDAf915111bf50',
///    );

///

/// final lensTestNet = ZKSyncLensNetworkSepolia();

/// await lensTestNet.sendTransaction(transaction, wallet);



class ZKSyncLensNetworkSepolia extends ZKSyncChain {
  ZKSyncLensNetworkSepolia()
      : super(
          rpcUrl: 'https://rpc.testnet.lens.dev',
          eip712domain: EIP712Domain(
            name: 'zkSync',
            version: '2',
            chainId: 37111,
            salt: '',
            verifyingContract: '',
          ),
        );
}
