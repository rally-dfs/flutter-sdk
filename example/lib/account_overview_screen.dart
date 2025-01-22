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

  void testZkSyncTx() async {
    setState(() {
      loading = true;
    });

    final wallet = await WalletManager.getInstance().getWallet();

    if (wallet == null) {
      throw 'Something went wrong, no wallet when there should be one';
    }

    final transaction = Eip712Transaction(
      from: '0xf760bdd822fccf93c44be68d94c45133002b3037',
      to: '0x111C3E89Ce80e62EE88318C2804920D4c96f92bb',
      nonce: BigInt.from(7),
      maxPriorityFeePerGas:BigInt.from(2),
      maxFeePerGas: BigInt.from(250000000000000),
      gas: BigInt.from(158774),
      value: BigInt.from(1000000000000000000),
      data: '0xa4136862000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000017900000000000000000000000000000000000000000000000000000000000000',
      chainId: BigInt.from(37111),
      gasPerPubdata: BigInt.from(50000),
      paymaster: '0x4B5DF730c2e6b28E17013A1485E5d9BC41Efe021',
      paymasterInput: '0x8c5a344500000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000',
    );

    final config = ClientConfig(
      rpcUrl: 'https://rpc.testnet.lens.dev',
      domainSeperator: Eip712DomainSeparator(
        name: 'Lens Network Sepolia Testnet',
        version: '1',
        chainId: BigInt.from(37111),
      ),
    );

    final hash = await sendEip712Transaction(transaction, wallet, config);

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
                            onPressed: testZkSyncTx,
                            child: const Text('Test ZKsync Tx'),
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
