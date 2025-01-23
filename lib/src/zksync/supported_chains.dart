import 'package:eth_sig_util/model/typed_data.dart';
import 'package:rly_network_flutter_sdk/src/zksync/zk_sync_chain.dart';

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
