import 'package:flutter_sdk/gsnClient/gsnTxHelpers.dart';
import 'package:flutter_sdk/gsnClient/utils.dart';
import 'package:flutter_sdk/network.dart';
import 'package:flutter_sdk/utils/constants.dart';
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
      throw missingWalletError;
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
  Future<double> getBalance({PrefixedHexString? tokenAddress}) async {
    final account = await AccountsUtil.getInstance().getWallet();
    //if token address use it otherwise default to RLY
    tokenAddress = tokenAddress ?? network.contracts.rlyERC20;
    if (account == null) {
      throw missingWalletError;
    }

    final provider = getEthClient(network.gsn.rpcUrl);
    //TODO: we have to use this provider to make this erc20 contract
    // final token = erc20(provider,tokenAddress);
    final token = erc20(tokenAddress);
    final funCall = await provider.call(
        contract: token, function: token.function("decimals"), params: []);
    final decimals = funCall[0];

    final balanceOfCall = await provider.call(
        contract: token,
        function: token.function('balanceOf'),
        params: [account.address]);
    final balance = balanceOfCall[0];
    return formatUnits(balance, decimals);
  }

  @override
  Future<String> relay(GsnTransactionDetails tx) async {
    final account = await AccountsUtil.getInstance().getWallet();

    if (account == null) {
      throw missingWalletError;
    }

    return relayTransaction(account, network, tx);
  }

  @override
  void setApiKey(String apiKey) {
    network.relayerApiKey = apiKey;
  }

  double formatUnits(BigInt wei, BigInt decimals) {
    final etherUnit = EtherUnit.gwei;
    final balanceFormatted =
        EtherAmount.fromBigInt(etherUnit, wei).getValueInUnit(EtherUnit.gwei);
    return balanceFormatted;
  }

  @override
  Future<String> transfer(String destinationAddress, double amount,
      {PrefixedHexString? tokenAddress, MetaTxMethod? metaTxMethod}) async {
    final account = await AccountsUtil.getInstance().getWallet();

    tokenAddress = tokenAddress ?? network.contracts.rlyERC20;

    if (account == null) {
      throw missingWalletError;
    }

    final sourceBalance = await getBalance(tokenAddress: tokenAddress);

    final sourceFinalBalance = sourceBalance - amount;

    if (sourceFinalBalance < 0) {
      throw insufficientBalanceError;
    }

    final provider = getEthClient(network.gsn.rpcUrl);

    GsnTransactionDetails? transferTx;
    // metaTxMethod = MetaTxMethod.ExecuteMetaTransaction;
    if (metaTxMethod != null &&
        (metaTxMethod == MetaTxMethod.Permit ||
            metaTxMethod == MetaTxMethod.ExecuteMetaTransaction)) {
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
        printLog("From address = ${account.address.hex}");
        transferTx = await getExecuteMetatransactionTx(
          account,
          destinationAddress,
          amount,
          network,
          tokenAddress,
          provider,
        );
      }
    } else {
      final executeMetaTransactionSupported = await hasExecuteMetaTransaction(
          account, destinationAddress, amount, network, tokenAddress, provider);

      final permitSupported = await hasPermit(
        account,
        amount,
        network,
        tokenAddress,
        provider,
      );

      if (executeMetaTransactionSupported) {
        transferTx = await getExecuteMetatransactionTx(
          account,
          destinationAddress,
          amount,
          network,
          tokenAddress,
          provider,
        );
      } else if (permitSupported) {
        transferTx = await getPermitTx(
          account,
          EthereumAddress.fromHex(destinationAddress),
          amount,
          network,
          tokenAddress,
          provider,
        );
      } else {
        throw transferMethodNotSupportedError;
      }
    }
    return relay(transferTx!);
  }

  // This method is deprecated. Update to 'c laimRly' instead.
// Will be removed in future library versions.
  Future<String> registerAccount() async {
    print("This method is deprecated. Update to 'claimRly' instead.");
    return claimRly();
  }

  @override
  Future<String> simpleTransfer(String destinationAddress, double amount,
      {String? tokenAddress, MetaTxMethod? metaTxMethod}) async {
    Web3Client client = getEthClient(network.gsn.rpcUrl);
    final account = await AccountsUtil.getInstance().getWallet();

    if(account == null) {
      throw missingWalletError;
    }

    final result = await client.sendTransaction(
        account,
        Transaction(
          to: EthereumAddress.fromHex(
              '0x39cc7b9f44cf39f3fd53a91db57670096c4c3e4f'),
          gasPrice: EtherAmount.fromInt(EtherUnit.wei, 1000000),
          value: EtherAmount.fromBigInt(EtherUnit.gwei, BigInt.from(3)),
        ),
        chainId: 80001);
    return result;
  }
}
