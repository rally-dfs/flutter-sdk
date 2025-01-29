import 'package:flutter/material.dart';
import 'package:rly_network_flutter_sdk/rly_network_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

final rlyNetwork = rlyBaseSepoliaNetwork;

class AccountOverviewScreen extends StatefulWidget {
  final String walletAddress;
  final VoidCallback onAccountDeleted;

  const AccountOverviewScreen(
      {super.key, required this.walletAddress, required this.onAccountDeleted});

  @override
  AccountOverviewScreenState createState() => AccountOverviewScreenState();
}

class AccountOverviewScreenState extends State<AccountOverviewScreen> {
  bool loading = false;
  double? balance;
  bool? backedUpToCloud;
  String transferBalance = '1';
  String transferAddress = '0x5205BcC1852c4b626099aa7A2AFf36Ac3e9dE83b';
  String? mnemonic;

  void getWalletBackupState() async {
    bool backedUp = await WalletManager.getInstance().walletBackedUpToCloud();

    setState(() {
      backedUpToCloud = backedUp;
    });
  }

  void fetchBalance() async {
    setState(() {
      loading = true;
    });

    double bal = await rlyNetwork.getDisplayBalance();
    setState(() {
      balance = bal;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getWalletBackupState();
    fetchBalance();
    rlyNetwork.setApiKey(
        "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOjcyNn0.VPX2UxDyrxQ-4316qI-IsuAfDjCdgAZ094ud6tYTn4KPIPdQkYEld51PGc9DRrvUFRJ7nKnE_y-5QJAhScPqag");
  }

  void claimRlyTokens() async {
    setState(() {
      loading = true;
    });

    await rlyNetwork.claimRly();

    fetchBalance();
  }

  void transferTokens() async {
    setState(() {
      loading = true;
    });

    await rlyNetwork.transfer(
        transferAddress, double.parse(transferBalance), MetaTxMethod.Permit);

    fetchBalance();

    setState(() {
      loading = false;
    });
  }


  void sendZkTx() async {
    setState(() {
      loading = true;
    });

    final wallet = await WalletManager.getInstance().getWallet();

    if (wallet == null) {
      throw 'No Wallet Found';
    }

    final transaction = ZKSyncEip712Transaction(
      from: '0x9916e2438299ffAC7042bEb13Ee1C4671acf22E3',   
      to: '0xfE0E2d77249562A70fc12B12da1f582428FBFf35',
      nonce: BigInt.from(9),
      maxPriorityFeePerGas: BigInt.from(4968169131),
      maxFeePerGas: BigInt.from(4968169131),
      gas: BigInt.from(158774),
      value: BigInt.from(0),
      data: '0x44f765120000000000000000000000008fec8579c658722d47904fe5cc5913e13fb755310000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001',
      chainId: BigInt.from(37111),
      gasPerPubdata: BigInt.from(50000),
      paymasterInput: '0x8c5a3445000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000002c7536e3605d9c16a7a3d7b1898e529396a65c2300000000000000000000000000000000000000000000000000000000679976c10000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000004162c268c3c3ef69bf0aea95178eb1a7ba9626273c631692e77f046267142e90021255e9ecca4038a7b6eaa6e133372986422d9ee2d3163ebdbc80a57dab5e8f741c00000000000000000000000000000000000000000000000000000000000000',
      paymaster: '0x115B6D4aED14AD0F900a20819ABDAf915111bf50'
    );

    final lensTestNet = ZKSyncLensNetworkSepolia();

    final hash = await lensTestNet.sendTransaction(transaction, wallet);

    setState(() {
      loading = false;
    });
  } 

  void simpleTransferTokens() async {
    setState(() {
      loading = true;
    });

    await rlyNetwork.simpleTransfer(
        transferAddress, double.parse(transferBalance));

    fetchBalance();

    setState(() {
      loading = false;
    });
  }

  void deleteAccount() async {
    await WalletManager.getInstance().permanentlyDeleteWallet();
    widget.onAccountDeleted();
  }

  void switchStorageLocation() async {
    if (backedUpToCloud == true) {
      await WalletManager.getInstance().updateWalletStorage(KeyStorageConfig(
          saveToCloud: false, rejectOnCloudSaveFailure: false));
    } else {
      await WalletManager.getInstance().updateWalletStorage(
          KeyStorageConfig(saveToCloud: true, rejectOnCloudSaveFailure: true));
    }
    getWalletBackupState();
  }

  void revealMnemonic() async {
    String? value = await WalletManager.getInstance().getAccountPhrase();
    if (value == null || value.isEmpty) {
      throw 'Something went wrong, no Mnemonic when there should be one';
    }
    showMnemonic(value);
  }

  void showMnemonic(String mnemonic) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Copy The Phrase below to export your wallet'),
                  const SizedBox(height: 12),
                  Text(mnemonic),
                ],
              ),
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                    width: double.infinity,
                    child: Card(
                        child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('Welcome to Rally Protocol',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 12),
                          Text(widget.walletAddress,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              )),
                          const SizedBox(height: 12),
                          Text(
                              'Backed up to cloud: ${backedUpToCloud ?? 'Loading...'}'),
                          const SizedBox(height: 24),
                          const Text('Your Current Balance Is'),
                          Text(balance?.toString() ?? 'Loading...'),
                          const SizedBox(height: 12),
                          FullWidthButton(
                            onPressed: () async {
                              await launchUrl(Uri.parse(
                                  'https://www.oklink.com/amoy/address/${widget.walletAddress}'));
                            },
                            child: const Text('View on Polygon'),
                          ),
                        ],
                      ),
                    ))),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text('Exercise the SDKs features'),
                          const SizedBox(height: 12),
                          if (balance != null && balance! < 1)
                            FullWidthButton(
                              onPressed: claimRlyTokens,
                              child: const Text('Claim ERC20'),
                            ),
                          const SizedBox(height: 12),
                          FullWidthButton(
                            onPressed: simpleTransferTokens,
                            child: const Text('Simple Transfer'),
                          ),
                          FullWidthButton(
                            onPressed: transferTokens,
                            child: const Text('Transfer ERC20'),
                          ),
                          FullWidthButton(
                            onPressed: sendZkTx,
                            child: const Text('Send ZkSync Tx'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Card(
                    child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      const Center(
                        child: Text('Manage Your Wallet'),
                      ),
                      const SizedBox(height: 12),
                      FullWidthButton(
                        onPressed: switchStorageLocation,
                        child: const Text('Swap Storage Location'),
                      ),
                      const SizedBox(height: 12),
                      FullWidthButton(
                        onPressed: revealMnemonic,
                        child: const Text('Export Your Account'),
                      ),
                      const SizedBox(height: 12),
                      FullWidthButton(
                        onPressed: deleteAccount,
                        child: const Text('Delete Your Account'),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                loading ? const CircularProgressIndicator() : const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FullWidthButton extends MaterialButton {
  const FullWidthButton({
    Key? key,
    required VoidCallback onPressed,
    required Widget child,
  }) : super(
          key: key,
          onPressed: onPressed,
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
