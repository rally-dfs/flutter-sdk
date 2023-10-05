import 'package:flutter/material.dart';

import 'AccountOverviewScreen.dart';
import 'GenerateAccountScreen.dart';
import 'LoadingScreen.dart';
import 'package:rly_network_flutter_sdk/account.dart';

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool _accountLoaded = false;
  String? _rlyAccount;

  @override
  void initState() {
    super.initState();
    _readAccount();
  }

  Future<void> _readAccount() async {
    final account = await AccountsUtil.getInstance().getAccountAddress();
    print('user account: $account');

    setState(() {
      _accountLoaded = true;
      if (account != null) {
        _rlyAccount = account;
      }
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

    return AccountOverviewScreen(rlyAccount: _rlyAccount!);
  }
}

void main() {
  runApp(MaterialApp(
    home: App(),
  ));
}
