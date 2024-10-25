import './network_config.dart';

final NetworkConfig baseMainnetNetworkConfig = NetworkConfig(
  contracts: Contracts(
    rlyERC20: '0x000',
    tokenFaucet: '0x000',
  ),
  gsn: GSNConfig(
    paymasterAddress: '0x01B83B33F0DD8be68627a9BE68E9e7E3c209a6b1',
    forwarderAddress: '0x524266345fB331cb624E27D2Cf5B61E769527FCC',
    relayHubAddress: '0x54623092d2dB00D706e0Ad4ADaCc024F9cB9E915',
    relayWorkerAddress: '0x7c5b7cf606ab2b56ead90b583bad47c5fd2c3417',
    relayUrl: 'https://api.rallyprotocol.com',
    rpcUrl:
        'https://base-mainnet.g.alchemy.com/v2/_M_BJfgrIyhpDtfZVjywzWb7AwCr0gG0',
    chainId: '8453',
    maxAcceptanceBudget: '285252',
    domainSeparatorName: 'GSN Relayed Transaction',
    gtxDataNonZero: 16,
    gtxDataZero: 4,
    requestValidSeconds: 172800,
    maxPaymasterDataLength: 300,
    maxApprovalDataLength: 300,
    maxRelayNonceGap: 3,
  ),
);
