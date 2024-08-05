import './network_config.dart';

final NetworkConfig baseSepoliaNetworkConfig = NetworkConfig(
  contracts: Contracts(
    rlyERC20: '0x846D8a5fb8a003b431b67115f809a9B9FFFe5012',
    tokenFaucet: '0xFCfC511B8915D3aFD0eadc794A0c4151278fE7D1',
  ),
  gsn: GSNConfig(
    paymasterAddress: '0x9bf59A7924cBa2475A03AD77e92fcf1Eaddb2Cc2',
    forwarderAddress: '0xabf9Fa3b2b2d9bDd77f4271A0d5A309AA465BCBa',
    relayHubAddress: '0xb570b57b821670707fF4E38Ea53fcb67192278F8',
    relayWorkerAddress: '0xdb1d6c7b07c857cc22a4ef10ac7b1dd06dd7501f',
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
