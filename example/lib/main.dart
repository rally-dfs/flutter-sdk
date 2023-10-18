import 'package:flutter/material.dart';
import 'package:rly_network_flutter_sdk/key_storage_config.dart';
import 'package:rly_network_flutter_sdk/wallet.dart';
import 'package:rly_network_flutter_sdk/wallet_manager.dart';

import 'account_overview_screen.dart';
import 'generate_account_screen.dart';
import 'loading_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  AppState createState() => AppState();
}

class AppState extends State<App> {
  bool _accountLoaded = false;
  Wallet? _rlyAccount;

  @override
  void initState() {
    super.initState();
    _readAccount();
  }

  Future<void> _readAccount() async {
    final account = await WalletManager.getInstance().getWallet();
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
    final rlyAct = await WalletManager.getInstance().createWallet(
        storageOptions: KeyStorageConfig(
            rejectOnCloudSaveFailure: false, saveToCloud: false));
    setState(() {
      _rlyAccount = rlyAct;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_accountLoaded) {
      return const LoadingScreen();
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
