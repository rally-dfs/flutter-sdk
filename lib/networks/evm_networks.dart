import 'package:rly_network_flutter_sdk/gsnClient/gsnTxHelpers.dart';
import 'package:rly_network_flutter_sdk/gsnClient/utils.dart';
import 'package:rly_network_flutter_sdk/network.dart';
import 'package:web3dart/web3dart.dart';

import '../account.dart';
import '../contracts/erc20.dart';
import '../error.dart';
import '../gsnClient/EIP712/MetaTransactions.dart';
import '../gsnClient/EIP712/PermitTransaction.dart';
import '../gsnClient/gsnClient.dart';
import '../network_config/network_config.dart';

class NetworkImpl extends Network {
  NetworkConfig network;

  NetworkImpl(this.network);

  @override
  Future<String> claimRly() async {
    final account = await AccountsUtil.getInstance().getWallet();

    if (account == null) {
      throw "account does not exist";
    }

    final existingBalance = await getBalance();
    // final existingBalance = 0;

    if (existingBalance > 0) {
      throw priorDustingError;
    }

    final ethers = getEthClient(network.gsn.rpcUrl);

    final claimTx = await getClaimTx(account, network, ethers);

    return relay(claimTx);
  }

  @override
  Future<double> getBalance(
      {PrefixedHexString? tokenAddress, bool humanReadable = false}) async {
    final account = await AccountsUtil.getInstance().getWallet();
    if (account == null) {
      throw MISSING_WALLET_ERROR;
    }

    tokenAddress = tokenAddress ?? network.contracts.rlyERC20;

    final provider = getEthClient(network.gsn.rpcUrl);

    final token = erc20(EthereumAddress.fromHex(tokenAddress));

    final balanceOfCall = await provider.call(
        contract: token,
        function: token.function('balanceOf'),
        params: [account.address]);

    final balance = balanceOfCall[0];

    final decimals = await _decimalsForToken(token);
    return balanceToDouble(balance, decimals);
  }

  @override
  Future<String> relay(GsnTransactionDetails tx) async {
    final account = await AccountsUtil.getInstance().getWallet();

    if (account == null) {
      throw "account does not exist";
    }

    return relayTransaction(account, network, tx);
  }

  @override
  void setApiKey(String apiKey) {
    network.relayerApiKey = apiKey;
  }

  @override
  Future<String> transfer(
      String destinationAddress, double amount, MetaTxMethod metaTxMethod,
      {PrefixedHexString? tokenAddress}) async {
    final account = await AccountsUtil.getInstance().getWallet();

    if (account == null) {
      throw "account does not exist";
    }

    tokenAddress = tokenAddress ?? network.contracts.rlyERC20;

    final sourceBalance = await getBalance(tokenAddress: tokenAddress);

    final sourceFinalBalance = sourceBalance - amount;

    if (sourceFinalBalance < 0) {
      throw insufficientBalanceError;
    }

    final provider = getEthClient(network.gsn.rpcUrl);

    GsnTransactionDetails? transferTx;

    if (metaTxMethod == MetaTxMethod.Permit) {
      transferTx = await getPermitTx(
        account,
        EthereumAddress.fromHex(destinationAddress),
        amount,
        network,
        tokenAddress,
        provider,
      );
    } else {
      transferTx = await getExecuteMetatransactionTx(
        account,
        destinationAddress,
        amount,
        network,
        tokenAddress,
        provider,
      );
    }

    return relay(transferTx);
  }

  @override
  Future<String> registerAccount() async {
    return claimRly();
  }

  @override
  Future<String> simpleTransfer(String destinationAddress, double amount,
      {String? tokenAddress, MetaTxMethod? metaTxMethod}) async {
    Web3Client client = getEthClient(network.gsn.rpcUrl);
    final account = await AccountsUtil.getInstance().getWallet();

    if (account == null) {
      throw MISSING_WALLET_ERROR;
    }

    final result = await client.sendTransaction(
        account,
        Transaction(
          to: EthereumAddress.fromHex(destinationAddress),
          gasPrice: EtherAmount.fromInt(EtherUnit.wei, 1000000),
          value: EtherAmount.fromBigInt(EtherUnit.gwei, BigInt.from(3)),
        ),
        chainId: 80001);
    return result;
  }

  Future<BigInt> _decimalsForToken(DeployedContract token) async {
    final provider = getEthClient(network.gsn.rpcUrl);

    final funCall = await provider.call(
        contract: token, function: token.function("decimals"), params: []);
    final decimals = funCall[0] as BigInt;

    return decimals;
  }
}
