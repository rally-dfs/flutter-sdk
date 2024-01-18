class NetworkConfig {
  final Contracts contracts;
  final GSNConfig gsn;
  String? relayerApiKey;

  NetworkConfig({
    required this.contracts,
    required this.gsn,
    this.relayerApiKey,
  });
  @override
  String toString() {
    return 'NetworkConfig{contracts: ${contracts.toString()}, gsn: ${gsn.toString()}, relayerApiKey: $relayerApiKey}';
  }
}

class Contracts {
  final String tokenFaucet;
  final String rlyERC20;

  Contracts({
    required this.tokenFaucet,
    required this.rlyERC20,
  });
  @override
  String toString() {
    return 'Contracts{tokenFaucet: $tokenFaucet, rlyERC20: $rlyERC20}';
  }
}

class GSNConfig {
  final String paymasterAddress;
  final String forwarderAddress;
  final String relayHubAddress;
  String relayWorkerAddress;
  final String relayUrl;
  final String rpcUrl;
  final String chainId;
  final String maxAcceptanceBudget;
  final String domainSeparatorName;
  final int gtxDataZero;
  final int gtxDataNonZero;
  final int requestValidSeconds;
  final int maxPaymasterDataLength;
  final int maxApprovalDataLength;
  final int maxRelayNonceGap;

  GSNConfig({
    required this.paymasterAddress,
    required this.forwarderAddress,
    required this.relayHubAddress,
    required this.relayWorkerAddress,
    required this.relayUrl,
    required this.rpcUrl,
    required this.chainId,
    required this.maxAcceptanceBudget,
    required this.domainSeparatorName,
    required this.gtxDataZero,
    required this.gtxDataNonZero,
    required this.requestValidSeconds,
    required this.maxPaymasterDataLength,
    required this.maxApprovalDataLength,
    required this.maxRelayNonceGap,
  });
  @override
  String toString() {
    return 'GSNConfig{paymasterAddress: $paymasterAddress, forwarderAddress: $forwarderAddress, relayHubAddress: $relayHubAddress, relayWorkerAddress: $relayWorkerAddress, relayUrl: $relayUrl, rpcUrl: $rpcUrl, chainId: $chainId, maxAcceptanceBudget: $maxAcceptanceBudget, domainSeparatorName: $domainSeparatorName, gtxDataZero: $gtxDataZero, gtxDataNonZero: $gtxDataNonZero, requestValidSeconds: $requestValidSeconds, maxPaymasterDataLength: $maxPaymasterDataLength, maxApprovalDataLength: $maxApprovalDataLength, maxRelayNonceGap: $maxRelayNonceGap}';
  }
}
