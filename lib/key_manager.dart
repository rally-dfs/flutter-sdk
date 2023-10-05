import 'package:flutter/services.dart';

import 'keyStorageConfig.dart';

abstract class KeyManager {
  Future<String?> getMnemonic();
  Future<String?> generateMnemonic();
  void saveMnemonic(String mnemonic, {KeyStorageConfig? options});
  void deleteMnemonic();
  Future<Uint8List> makePrivateKeyFromMnemonic(String mnemonic);
  Future<Uint8List> getStoredPrivateKey();
}

class KeychainAccessibilityConstant {
  final int value;

  const KeychainAccessibilityConstant(this.value);
}

const AFTER_FIRST_UNLOCK = KeychainAccessibilityConstant(0);
const AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY = KeychainAccessibilityConstant(1);
const ALWAYS = KeychainAccessibilityConstant(2);
const WHEN_PASSCODE_SET_THIS_DEVICE_ONLY = KeychainAccessibilityConstant(3);
const ALWAYS_THIS_DEVICE_ONLY = KeychainAccessibilityConstant(4);
const WHEN_UNLOCKED = KeychainAccessibilityConstant(5);
const WHEN_UNLOCKED_THIS_DEVICE_ONLY = KeychainAccessibilityConstant(6);

class KeyManagerImpl extends KeyManager {
  final methodChannel = const MethodChannel('flutter_sdk');

  @override
  void deleteMnemonic() {
    methodChannel.invokeMethod<bool>("deleteMnemonic");
  }

  @override
  Future<String?> generateMnemonic() async {
    String? mnemonic =
        await methodChannel.invokeMethod<String>("generateNewMnemonic");
    saveMnemonic(mnemonic!);
    return mnemonic;
  }

  @override
  Future<String?> getMnemonic() async {
    String? mnemonic = await methodChannel.invokeMethod<String>("getMnemonic");
    return mnemonic;
  }

  @override
  Future<Uint8List> makePrivateKeyFromMnemonic(String mnemonic) async {
    //TODO: ultimately this has to be done from native code
    List<Object?>? pvtKey = await methodChannel
        .invokeMethod<List<Object?>>("getPrivateKeyFromMnemonic", {
      'mnemonic': mnemonic,
    });
    Uint8List privateKey = intListToUint8List(pvtKey!);
    return privateKey;
  }

  Uint8List intListToUint8List(List<Object?> intList) {
    List<int> ints = [];
    for (Object? obj in intList) {
      ints.add(int.parse(obj.toString()));
    }
    // Return the string of bytes as a hex string.
    Uint8List uInt8List = Uint8List.fromList(ints);
    return uInt8List;
  }

  @override
  Future<void> saveMnemonic(String mnemonic,
      {KeyStorageConfig? options}) async {
    if (options == null || !options.saveToCloud) {
      // TODO: don't pass true,true. Give option to users to select
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
}
