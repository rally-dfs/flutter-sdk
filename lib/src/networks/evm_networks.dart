import 'package:eth_sig_util/model/typed_data.dart';
import 'package:rly_network_flutter_sdk/src/gsn/gsn_tx_helpers.dart';
import 'package:rly_network_flutter_sdk/src/network.dart';
import 'package:rly_network_flutter_sdk/src/token_helpers.dart';
import 'package:web3dart/web3dart.dart' as web3;

import '../gsn/utils.dart';
import '../gsn/meta_tx_method.dart';
import '../network_config/network_config.dart';
import '../wallet_manager.dart';
import '../contracts/erc20.dart';
import '../errors.dart';
import '../gsn/EIP712/meta_transactions.dart';
import '../gsn/EIP712/permit_transaction.dart';
import '../gsn/gsn_client.dart';

class NetworkImpl extends Network {
  NetworkImpl(NetworkConfig network) : super(network);

  @override
  Future<String> claimRly() async {
    final account = await WalletManager.getInstance().getWallet();

    if (account == null) {
      throw "account does not exist";
    }

    final existingBalance = await getExactBalance();
    // final existingBalance = 0;

    if (existingBalance > BigInt.zero) {
      throw priorDustingError;
    }

    final ethers = getEthClient(config.gsn.rpcUrl);

    final claimTx = await getClaimTx(account, config, ethers);

    return relay(claimTx);
  }

  @override
  Future<dynamic> getBalance(
      {PrefixedHexString? tokenAddress, bool humanReadable = false}) async {
    final account = await WalletManager.getInstance().getWallet();
    if (account == null) {
      throw missingWalletError;
    }

    tokenAddress = tokenAddress ?? config.contracts.rlyERC20;

    final provider = getEthClient(config.gsn.rpcUrl);

    final token = erc20(web3.EthereumAddress.fromHex(tokenAddress));

    final balanceOfCall = await provider.call(
        contract: token,
        function: token.function('balanceOf'),
        params: [account.address]);

    final balance = balanceOfCall[0];

    if (!humanReadable) {
      return balance;
    }

    final decimals = await TokenHelpers.getDecimals(tokenAddress, config);
    return balanceToDouble(balance, decimals);
  }

  @override
  Future<double> getDisplayBalance({PrefixedHexString? tokenAddress}) async {
    final balance =
        await getBalance(tokenAddress: tokenAddress, humanReadable: true);
    return balance as double;
  }

  @override
  Future<BigInt> getExactBalance(
      {PrefixedHexString? tokenAddress, bool humanReadable = false}) async {
    final balance =
        await getBalance(tokenAddress: tokenAddress, humanReadable: false);
    return balance as BigInt;
  }

  @override
  Future<String> relay(GsnTransactionDetails tx) async {
    final account = await WalletManager.getInstance().getWallet();

    if (account == null) {
      throw "account does not exist";
    }

    return relayTransaction(account, config, tx);
  }

  @override
  void setApiKey(String apiKey) {
    config.relayerApiKey = apiKey;
  }

  @override
  Future<String> transfer(
      String destinationAddress, double amount, MetaTxMethod metaTxMethod,
      {PrefixedHexString? tokenAddress, EIP712Domain? eip712DomainData}) async {
    final account = await WalletManager.getInstance().getWallet();

    if (account == null) {
      throw "account does not exist";
    }

    tokenAddress = tokenAddress ?? config.contracts.rlyERC20;

    final sourceBalance = await getDisplayBalance(tokenAddress: tokenAddress);

    final sourceFinalBalance = sourceBalance - amount;

    if (sourceFinalBalance < 0) {
      throw insufficientBalanceError;
    }

    final provider = getEthClient(config.gsn.rpcUrl);

    final token = erc20(web3.EthereumAddress.fromHex(tokenAddress));

    final decimals = await provider.call(
        contract: token, function: token.function('decimals'), params: []);
    BigInt decimalAmount =
        parseUnits(amount.toString(), int.parse(decimals.first.toString()));

    return transferExact(destinationAddress, decimalAmount, metaTxMethod,
        tokenAddress: tokenAddress, eip712DomainData: eip712DomainData);
  }

  @override
  Future<String> transferExact(
      String destinationAddress, BigInt amount, MetaTxMethod metaTxMethod,
      {PrefixedHexString? tokenAddress, EIP712Domain? eip712DomainData}) async {
    final account = await WalletManager.getInstance().getWallet();

    if (account == null) {
      throw "account does not exist";
    }

    tokenAddress = tokenAddress ?? config.contracts.rlyERC20;

    final sourceBalance = await getExactBalance(tokenAddress: tokenAddress);

    final sourceFinalBalance = sourceBalance - amount;

    if (sourceFinalBalance < BigInt.zero) {
      throw insufficientBalanceError;
    }

    final provider = getEthClient(config.gsn.rpcUrl);

    GsnTransactionDetails? transferTx;

    if (metaTxMethod == MetaTxMethod.Permit) {
      transferTx = await getPermitTx(
        account,
        web3.EthereumAddress.fromHex(destinationAddress),
        amount,
        config,
        tokenAddress,
        provider,
        eip712Salt: eip712DomainData?.salt,
        eip712Version: eip712DomainData?.version,
      );
    } else {
      transferTx = await getExecuteMetatransactionTx(
        account,
        destinationAddress,
        amount,
        config,
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
    web3.Web3Client client = getEthClient(config.gsn.rpcUrl);
    final account = await WalletManager.getInstance().getWallet();

    if (account == null) {
      throw missingWalletError;
    }

    final result = await client.sendTransaction(
        account,
        web3.Transaction(
          to: web3.EthereumAddress.fromHex(destinationAddress),
          gasPrice: web3.EtherAmount.fromInt(web3.EtherUnit.wei, 1000000),
          value:
              web3.EtherAmount.fromBigInt(web3.EtherUnit.gwei, BigInt.from(3)),
        ),
        chainId: 80001);
    return result;
  }
}
