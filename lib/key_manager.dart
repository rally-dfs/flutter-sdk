import 'package:flutter/services.dart';

import 'key_storage_config.dart';

abstract class KeyManager {
  Future<String?> getMnemonic();
  Future<String?> generateMnemonic();
  Future<void> saveMnemonic(String mnemonic, {KeyStorageConfig? options});
  Future<void> deleteMnemonic();
  Future<Uint8List> makePrivateKeyFromMnemonic(String mnemonic);
  Future<Uint8List> getStoredPrivateKey();
}

class KeyManagerImpl extends KeyManager {
  final methodChannel = const MethodChannel('rly_network_flutter_sdk');

  @override
  Future<void> deleteMnemonic() async {
    await methodChannel.invokeMethod<bool>("deleteMnemonic");
  }

  @override
  Future<String?> generateMnemonic() async {
    String? mnemonic =
        await methodChannel.invokeMethod<String>("generateNewMnemonic");
    await saveMnemonic(mnemonic!);
    return mnemonic;
  }

  @override
  Future<String?> getMnemonic() async {
    String? mnemonic = await methodChannel.invokeMethod<String>("getMnemonic");
    return mnemonic;
  }

  @override
  Future<Uint8List> makePrivateKeyFromMnemonic(String mnemonic) async {
    List<Object?>? pvtKey = await methodChannel
        .invokeMethod<List<Object?>>("getPrivateKeyFromMnemonic", {
      'mnemonic': mnemonic,
    });
    Uint8List privateKey = _intListToUint8List(pvtKey!);
    return privateKey;
  }

  @override
  Future<void> saveMnemonic(String mnemonic,
      {KeyStorageConfig? options}) async {
    if (options == null || !options.saveToCloud) {
      await methodChannel.invokeMethod("saveMnemonic", {
        "mnemonic": mnemonic,
        "useBlockStore": true,
        "forceBlockStore": true,
      });
    }
  }

  @override
  Future<Uint8List> getStoredPrivateKey() async {
    String? mnemonic = await getMnemonic();
    return await makePrivateKeyFromMnemonic(mnemonic!);
  }

  Uint8List _intListToUint8List(List<Object?> intList) {
    List<int> ints = [];
    for (Object? obj in intList) {
      ints.add(int.parse(obj.toString()));
    }
    // Return the string of bytes as a hex string.
    Uint8List uInt8List = Uint8List.fromList(ints);
    return uInt8List;
  }
}
