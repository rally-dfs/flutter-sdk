# RallyMobile SDK
RallyMobile SDK, a key component of RallyProtocol, enables developers to equip users with embedded wallets in their mobile apps—no signups, third-party logins, or popups required. Embedded wallets are created instantly, encrypted by the device’s secure enclave, and are permissionless and free.

Most importantly, RallyMobile eliminates intermediaries, allowing developers to retain full ownership of user and wallet data.

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

# RallyTransact

RallyTransact enables gasless transactions for on-chain operations, allowing users to perform one-tap token transfers, NFT claims, and even smart contract deployments from within mobile apps, all without gas fees.

Get your API key here: https://app.rallyprotocol.com/

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

# RallyProtocol

RallyProtocol is an all-in-one web3 mobile toolkit that enables developers to create frictionless, end-to-end onchain experiences for native mobile apps. Whether you’re building an iOS or Android mobile app, our mission is to empower developers to craft user-friendly mobile UX with fewer taps and zero web3 touchpoints.
