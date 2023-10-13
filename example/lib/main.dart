import 'package:flutter/material.dart';
import 'package:web3dart/web3dart.dart';

import 'account_overview_screen.dart';
import 'GenerateAccountScreen.dart';
import 'LoadingScreen.dart';
import 'package:rly_network_flutter_sdk/account.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  bool _accountLoaded = false;
  EthPrivateKey? _rlyAccount;

  @override
  void initState() {
    super.initState();
    _readAccount();
  }

  Future<void> _readAccount() async {
    final account = await AccountsUtil.getInstance().getWallet();
    setState(() {
      _accountLoaded = true;
      if (account != null) {
        _rlyAccount = account;
      }
    });
  }

  void _clearAccount() {
    setState(() {
      _rlyAccount = null;
    });
  }

  Future<void> _createRlyAccount() async {
    AccountsUtil accountsUtil = AccountsUtil.getInstance();
    final rlyAct = await accountsUtil.createAccount();
    setState(() {
      _rlyAccount = rlyAct;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_accountLoaded) {
      return LoadingScreen();
    }

    if (_rlyAccount == null) {
      return GenerateAccountScreen(generateAccount: _createRlyAccount);
    }

    return AccountOverviewScreen(
        walletAddress: _rlyAccount!.address.hex,
        onAccountDeleted: _clearAccount);
  }
}

void main() {
  runApp(const MaterialApp(
    home: App(),
  ));
}
