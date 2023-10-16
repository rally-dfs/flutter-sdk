import 'package:flutter/services.dart';

import 'key_storage_config.dart';

class KeyManager {
  final methodChannel = const MethodChannel('rly_network_flutter_sdk');

  Future<void> deleteMnemonic() async {
    await methodChannel.invokeMethod<bool>("deleteMnemonic");
  }

  Future<String> generateMnemonic() async {
    String? mnemonic =
        await methodChannel.invokeMethod<String>("generateNewMnemonic");

    if (mnemonic == null) {
      throw Exception(
          "Unable to generate mnemonic, something went wrong at native code layer");
    }

    return mnemonic;
  }

  Future<String?> getMnemonic() async {
    String? mnemonic = await methodChannel.invokeMethod<String>("getMnemonic");
    return mnemonic;
  }

  Future<Uint8List> getPrivateKeyFromMnemonic(String mnemonic) async {
    List<Object?>? pvtKey = await methodChannel
        .invokeMethod<List<Object?>>("getPrivateKeyFromMnemonic", {
      'mnemonic': mnemonic,
    });
    Uint8List privateKey = _intListToUint8List(pvtKey!);
    return privateKey;
  }

  Future<void> saveMnemonic(String mnemonic,
      {required KeyStorageConfig storageOptions}) async {
    await methodChannel.invokeMethod("saveMnemonic", {
      "mnemonic": mnemonic,
      "saveToCloud": storageOptions.saveToCloud,
      "rejectOnCloudSaveFailure": storageOptions.rejectOnCloudSaveFailure,
    });
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
