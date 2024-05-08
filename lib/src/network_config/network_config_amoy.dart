import './network_config.dart';

final NetworkConfig amoyNetworkConfig = NetworkConfig(
  contracts: Contracts(
    rlyERC20: '0x758641a1b566998CaC5Bc5fC8032F001e1CEBeEf',
    tokenFaucet: '0xAb5C5633a5c483499047e552C96E1760136dc70A',
  ),
  gsn: GSNConfig(
    paymasterAddress: '0xb570b57b821670707fF4E38Ea53fcb67192278F8',
    forwarderAddress: '0x0ae8FC9867CB4a124d7114B8bd15C4c78C4D40E5',
    relayHubAddress: '0xe213A20A9E6CBAfd8456f9669D8a0b9e41Cb2751',
    relayWorkerAddress: '0xb9950b71ec94cbb274aeb1be98e697678077a17f',
    relayUrl: 'https://api.rallyprotocol.com',
    rpcUrl:
        'https://polygon-amoy.g.alchemy.com/v2/oOsX9gjRzWeq5WQrlM3zvWAXZ9nIT2Cr',
    chainId: '80002',
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
