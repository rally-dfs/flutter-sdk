import 'package:flutter/services.dart';

import './key_storage_config.dart';

class KeyManager {
  final methodChannel = const MethodChannel('rly_network_flutter_sdk');

  Future<void> deleteMnemonic() async {
    await methodChannel.invokeMethod<bool>("deleteMnemonic");
  }

  /// Removes the mnemonic from the cloud storage. This is a destructive operation.
  ///
  /// This is necessary for the case where dev wants to move user storage from cloud to local only.
  Future<void> deleteCloudMnemonic() async {
    final bool? status =
        await methodChannel.invokeMethod<bool>("deleteCloudMnemonic");

    if (status == null || status == false) {
      throw Exception(
          "Unable to delete mnemonic from cloud storage, something went wrong at native code layer");
    }
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

  Future<bool> walletBackedUpToCloud() async {
    bool? backedUpToCloud =
        await methodChannel.invokeMethod<bool>("mnemonicBackedUpToCloud");
    if (backedUpToCloud == null) {
      throw Exception(
          "Unable to get wallet backup status, something went wrong at native code layer");
    }
    return backedUpToCloud;
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

  Future<void> refreshEndToEndEncryptionAvailability() async {
    await methodChannel.invokeMethod("refreshEndToEndEncryptionAvailability");
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
