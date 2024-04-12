The Rally Mobile SDK is a key component of the Rally Protocol that allows developers to retake control of the user experience by eliminating the reliance for end-users to complete complex blockchain operations through third party apps. By utilizing the SDK, developers gain access to the necessary tools that enable them to create familiar and native mobile UX while leveraging the benefits of blockchain technology.

# Example Usage

### accounts (EOAs)

```dart
import 'package:rly_network_flutter_sdk/rly_network_flutter_sdk.dart';


//create an account
// By default this will configure the keys for secure cloud syncing
final account = await WalletManager.getInstance().createWallet();

//Want to configure whether keys are synced to the cloud, you can pass in storage options
final account = await WalletManager.getInstance().createWallet(
    storageOptions: KeyStorageConfig(saveToCloud: false, rejectOnCloudSaveFailure: false)
);

// get address of current EOA wallet
final address = await WalletManager.getInstance().getPublicAddress();

// Delete EOA wallet. Be careful calling this, it can not be undone.
await WalletManager.getInstance().permanentlyDeleteWallet();

```

## transactions

```dart
import 'package:rly_network_flutter_sdk/rly_network_flutter_sdk.dart';

//get polygon testnet (amoy) config for rally protocol sdk

final amoy = rlyAmoyNetwork;

// add your API Key

amoy.setApiKey(env.API_KEY);

// this is simple method for claiming 10 test ERC20 tokens for testing

await amoy.claimRly();

// get balance of any ERC20 token

await amoy.getBalance(tokenAddress);

// transfer any ERC20 token, to transfer gaslessly token contract must support permit() or executeMetaTransaction() (most ERC20s on polygon support this)

await amoy.transfer(transferAddress, double.parse(1), MetaTxMethod.ExecuteMetaTransaction, {tokenAddress});



// relay arbitrary tx through our gasless relayer. see complete example at https://github.com/rally-dfs/flutter-example-app/tree/main/app/lib/services/nft.dart

...

final gsnTx = GsnTransactionDetails(
    from: accountAddress,
    data: tx.data,
    value: "0",
    to: contractAddress,
    gas: gas.toString(),
    maxFeePerGas: maxFeePerGas.toString(),
    maxPriorityFeePerGas: maxPriorityFeePerGas.toString(),
    );

await amoy.relay(gsnTx)


```

# Documentation

For comprehensive documentation, see [docs.rallyprotocol.com](https://docs.rallyprotocol.com)

# Supported Blockchains

The Rally Mobile SDK currently supports Polygon. More blockchains coming soon.
