## 0.0.1

* TODO: Describe initial release.

## 0.1.0

* All wallet management code is now stable and has been used by 3rd party apps.

* We've added new methods to make it easier to understand which format you want to get a token balance in. True BigInt form for use in computation and transfers, or more human readable friendly float form.

## 0.2.0

* We've added a new method `walletBackedUpToCloud` on `WalletManager` to help you determine if a wallet has been backed up to the cloud. This is useful for apps that need to understand the cloud backup status of a wallet outside of the creation process.

### 0.2.1

* Fixed an issue that broke abiilty to claimRly. This was a regression from 0.2.0.

## 0.3.0

* Library has been reorganized to better follow flutter / dart best practices. **This is a breaking change** and you will need to update your imports to reflect the new package structure. All classes are now under the `rly_network_flutter_sdk/rly_network_flutter_sdk.dart` file. See README for an example of updated import.

* As a result of library restructuring, the auto generated API docs are now much easier to navigate and understand


### 0.3.1

* Creation / storage of wallets on Android is now more consistent with the iOS experience. When creating a wallet on Android, storage will automatically fall back to local storage if cloud storage fails, and the `rejectOnCloudSaveFailure` is set to false.

### 0.3.2

* Addressed a bug that caused SDK to hang when trying to interact with wallets on Android following device backup and restore.

## 0.4.0

If you are only using wallet management features, there are no changes in this release

**This release is not backwards compatible with previous versions if you are using any transaction features**

This release migrates away from Mumbai and over to Amoy. This is required as Mumbai is deprecated and will stop working around 4/13.

To migrate you will need to follow the following steps:
1. Update your SDK to 0.4.0
2. Rename references from `rlyMumbaiNetwork` to `rlyAmoyNetwork`
3. Get your new Amoy API key from https://app.rallyprotocol.com
4. Update your config to set the new API key

### 0.4.1

* Fixed a bug that prevented relay token transfers of more than 9.9 value for a token with 18 decimals.
* Fixed a bug that causes simple relay token transfers to work unexpectedly when using custom token addresses.

## 0.5.0

This release addresses an issue where the cloud sync status returned by WalletManager.walletBackedUpToCloud on iOS was returning inaccurate & misleading response.  We are now more correctly setting our iOS keychain storage flags for real cloud sync.

Migrating from device only storage to cloud sync storage comes with some end user risk if users have multiple wallets on different devices. Therefore, there
is no auto migration of data. Instead we have exposed a method through WalletManager that allows developers to update the storage config of an existing wallet.

## 0.5.1

Adds `refreshEndToEndEncryptionAvailability` that refreshes end-to-end encryption availability on Android. This should be used before attempting to save the wallet to cloud on Android.

## 0.6.0

### Enhancements
- **Added support for Base Network** (#61)
  - Added network configuration for Base mainnet and sepolia (testnet).

- **Updated Example Application to Use Sepolia Base Network by Default** (#60)
  - Configured the example app to default to Sepolia Base instead of Amoy.
  - Introduced a new API token and updated network configurations.
  - Corrected transaction type to support RLY permit token variant.

- **Improved Gas Fee Logic and Estimation** (#60, #59)
  - Computed actual `maxPriorityFeePerGas` value, inspired by viem, without relying on dedicated RPC calls.
  - Added a 10% padding to `maxPriorityFeePerGas` for fluctuating gas prices.
  - Refined gas estimation encoding issues.
  - Extracted all gas fee computations into a shared code path to eliminate duplication and simplify debugging.

- **Explicit EIP712 Domain Data Support for Better Token Compatibility** (#58)
  - Enabled explicit passing of EIP712 domain data for improved token compatibility.
  - Optimized by avoiding dynamic salt determination when explicitly provided, improving performance and reducing unnecessary RPC calls.

### Other Improvements
- **Helper Extraction for Token Specific Operations** (#49)
  - Extracted token-specific helper methods (e.g., getting decimals) to simplify usage for third-party developers.
  - Added RLY exec meta token variant addresses to helper classes for easier reference.

## 0.7.0

### Enhancements
- **Add support for EIP712 on ZKSync Chains (#63)**
  - EIP712 is now supported on ZKSync chains, enabling users to sign transactions with our secure Wallet.
  - Submission of signed transctions to ZKSync chains is now possible through the ZKSyncChain class.
  - Added pre-built chain support for Lens Network Testnet
