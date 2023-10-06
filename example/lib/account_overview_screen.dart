import 'package:flutter/material.dart';
import 'package:rly_network_flutter_sdk/account.dart';
import 'package:rly_network_flutter_sdk/gsnClient/utils.dart';
import 'package:rly_network_flutter_sdk/network.dart';
import 'package:url_launcher/url_launcher.dart';

final rlyNetwork = rlyMumbaiNetwork;

class AccountOverviewScreen extends StatefulWidget {
  final String rlyAccount;

  const AccountOverviewScreen({super.key, required this.rlyAccount});

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

    final txHash = await rlyNetwork.transfer(transferAddress,
        double.parse(transferBalance), MetaTxMethod.ExecuteMetaTransaction);

    fetchBalance();

    setState(() {
      transferBalance = '';
      transferAddress = '';
      loading = false;
    });
  }

  void simpleTransferTokens() async {
    setState(() {
      loading = true;
    });

    final txnId = await rlyNetwork.simpleTransfer(
        transferAddress, double.parse(transferBalance));

    fetchBalance();

    setState(() {
      transferBalance = '';
      transferAddress = '';
      loading = false;
    });
  }

  void deleteAccount() async {
    AccountsUtil.getInstance().permanentlyDeleteAccount();
  }

  void revealMnemonic() async {
    String? value = await AccountsUtil.getInstance().getAccountPhrase();
    if (value == null || value.isEmpty) {
      throw 'Something went wrong, no Mnemonic when there should be one';
    }

    setState(() {
      mnemonic = value;
    });
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
                const SizedBox(height: 12),
                Text('Welcome to RLY'),
                const SizedBox(height: 12),
                Text(widget.rlyAccount.isNotEmpty
                    ? widget.rlyAccount
                    : 'No Account Exists'),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text('Your Current Balance Is'),
                        Text(balance?.toString() ?? 'Loading...'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            await launchUrl(Uri.parse(
                                'https://mumbai.polygonscan.com/address/${widget.rlyAccount}'));
                          },
                          child: Text('View on Polygon'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text('What Would You Like to Do?'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: claimRlyTokens,
                          child: Text('Register My Account'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: simpleTransferTokens,
                          child: Text('Simple Transfer'),
                        ),
                        ElevatedButton(
                          onPressed: transferTokens,
                          child: Text('Transfer RLY'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: revealMnemonic,
                          child: Text('Export Your Account'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: deleteAccount,
                          child: Text('Delete Your Account'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text('Copy The Phrase below to export your wallet'),
                        const SizedBox(height: 12),
                        Text(mnemonic ?? ''),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              mnemonic = null;
                            });
                          },
                          child: Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                loading ? CircularProgressIndicator() : SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
