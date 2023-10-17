import 'package:flutter/material.dart';
import 'package:rly_network_flutter_sdk/wallet_manager.dart';
import 'package:rly_network_flutter_sdk/gsn/utils.dart';
import 'package:rly_network_flutter_sdk/network.dart';
import 'package:url_launcher/url_launcher.dart';

final rlyNetwork = rlyMumbaiNetwork;

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
  String transferBalance = '1';
  String transferAddress = '0x5205BcC1852c4b626099aa7A2AFf36Ac3e9dE83b';
  String? mnemonic;

  void fetchBalance() async {
    setState(() {
      loading = true;
    });

    double bal = await rlyNetwork.getBalance();
    setState(() {
      balance = bal;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchBalance();
    // RlyNetwork.setApiKey(
    //     "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOjEzNX0.wqnX-E-KRvzqLgIBAw6RV-BT1puWuZgVdAsqxoU1nL2z8hxTkT4OlH7G6Okv9l3qRMLxMbkORg14XTko-gJW1A");
    rlyNetwork.setApiKey(
        "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOjkzfQ.PgErzRN88Sz07OKp9aj0cUxCap_chaqTsDzgkaIc7NMC_WSPeL4HUlmSb_spHe5N_Gk7EYsF-1QFXg-rIp7ETA");
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

    await rlyNetwork.transfer(transferAddress, double.parse(transferBalance),
        MetaTxMethod.ExecuteMetaTransaction);

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
    await WalletManager.getInstance().permanentlyDeleteAccount();
    widget.onAccountDeleted();
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
                          const Text('Your Current Balance Is'),
                          Text(balance?.toString() ?? 'Loading...'),
                          const SizedBox(height: 12),
                          FullWidthButton(
                            onPressed: () async {
                              await launchUrl(Uri.parse(
                                  'https://mumbai.polygonscan.com/address/${widget.walletAddress}'));
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
