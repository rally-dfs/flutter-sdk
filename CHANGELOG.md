## 0.0.1

* TODO: Describe initial release.

## 0.1.0

* All wallet management code is now stable and has been used by 3rd party apps.

* We've added new methods to make it easier to understand which format you want to get a token balance in. True BigInt form for use in computation and transfers, or more human readable friendly float form.

## 0.2.0

* We've added a new method `walletBackedUpToCloud` on `WalletManager` to help you determine if a wallet has been backed up to the cloud. This is useful for apps that need to understand the cloud backup status of a wallet outside of the creation process.

### 0.2.1

* Fixed an issue that broke abiilty to claimRly. This was a regression from 0.2.0.