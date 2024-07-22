import './network_config.dart';

final NetworkConfig baseSepoliaNetworkConfig = NetworkConfig(
  contracts: Contracts(
    rlyERC20: '0x16723e9bb894EfC09449994eC5bCF5b41EE0D9b2',
    tokenFaucet: '0xCeCFB48a9e7C0765Ed1319ee1Bc0F719a30641Ce',
  ),
  gsn: GSNConfig(
    paymasterAddress: '0x0e20E8A953a1e7D5FD4B24F12aC021b6345F364F',
    forwarderAddress: '0xabf9Fa3b2b2d9bDd77f4271A0d5A309AA465BCBa',
    relayHubAddress: '0xb570b57b821670707fF4E38Ea53fcb67192278F8',
    relayWorkerAddress: '0xbf385a38b766ea8f71f85a39837078c2c533fc5a',
    relayUrl: 'https://api.rallyprotocol.com',
    rpcUrl:
        'https://base-sepolia.g.alchemy.com/v2/oOsX9gjRzWeq5WQrlM3zvWAXZ9nIT2Cr',
    chainId: '84532',
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
