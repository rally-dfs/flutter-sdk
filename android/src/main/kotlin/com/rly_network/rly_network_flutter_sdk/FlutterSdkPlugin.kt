package com.rly_network.rly_network_flutter_sdk

import androidx.annotation.NonNull
import com.rlynetworkmobilesdk.EncryptedSharedPreferencesHelper
import com.rlynetworkmobilesdk.MnemonicStorageHelper
import org.kethereum.bip39.generateMnemonic
import org.kethereum.bip39.validate
import org.kethereum.bip39.dirtyPhraseToMnemonicWords
import org.kethereum.bip39.toSeed
import org.kethereum.bip39.wordlists.WORDLIST_ENGLISH
import org.kethereum.bip39.model.MnemonicWords
import org.kethereum.bip32.toKey

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.Locale

/** FlutterSdkPlugin */
const val MNEMONIC_STORAGE_KEY = "BIP39_MNEMONIC"

class FlutterSdkPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var mnemonicHelper: MnemonicStorageHelper

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "rly_network_flutter_sdk")
    channel.setMethodCallHandler(this)
    this.flutterPluginBinding = flutterPluginBinding
    mnemonicHelper = MnemonicStorageHelper(flutterPluginBinding.applicationContext)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {

    when (call.method) {
        "getPlatformVersion" -> {
          result.success("Android ${android.os.Build.VERSION.RELEASE}")
        }
        "getBundleId" -> {
          result.success(flutterPluginBinding.applicationContext.getPackageName())
        }
        "saveMnemonic" -> {
          saveMnemonic(call, result);
        }
        "getMnemonic" -> {
          getMnemonic(result)
        }
        "mnemonicBackedUpToCloud" -> {
          isBackedUpToCloud(result)
        }
        "deleteMnemonic" -> {
          deleteMnemonic(result)
        }
        "deleteCloudMnemonic" -> {
          deleteCloudMnemonic(result)
        }
        "generateNewMnemonic" -> {
          generateNewMnemonic(result)
        }
        "getPrivateKeyFromMnemonic" -> {
          getPrivateKeyFromMnemonic(call,result)
        }
        "refreshEndToEndEncryptionAvailability" -> {
          refreshEndToEndEncryptionAvailability(result)
        }
        else -> {
          result.notImplemented()
        }
    }
  }

  private fun getMnemonic(result: Result) {
    mnemonicHelper.read(MNEMONIC_STORAGE_KEY) { mnemonic: String?, fromBlockstore ->
      result.success(mnemonic)
    }
  }

  private fun isBackedUpToCloud(result: Result) {
    mnemonicHelper.read(MNEMONIC_STORAGE_KEY) { mnemonic, fromBlockstore ->
      result.success(mnemonic != null && fromBlockstore);
    }
  }

  private fun refreshEndToEndEncryptionAvailability(result: Result) {
    mnemonicHelper.refreshEndToEndEncryptionAvailability()
    result.success(true)
  }

  private fun generateNewMnemonic(result: Result){
    val phrase = generateMnemonic(192, WORDLIST_ENGLISH)
    result.success(phrase)
  }

  private fun saveMnemonic(call: MethodCall, result: Result) {
    val mnemonic = call.argument<String>("mnemonic") ?: ""
    val useBlockStore = call.argument<Boolean>("saveToCloud")?: false
    val forceBlockStore = call.argument<Boolean>("rejectOnCloudSaveFailure")?: false

    if (!MnemonicWords(mnemonic).validate(WORDLIST_ENGLISH)) {
      result.error("mnemonic_verification_failure", "Mnemonic is not valid", null)
    }
    mnemonicHelper.save(MNEMONIC_STORAGE_KEY, mnemonic, useBlockStore, forceBlockStore, { ->
      result.success(true)
    }, { message: String ->
      result.error("mnemonic_save_failure", message, null)
    })
  }

  private fun deleteCloudMnemonic(result: Result) {
    mnemonicHelper.deleteFromCloudKeystore(MNEMONIC_STORAGE_KEY)
    result.success(true)
  }

  private fun deleteMnemonic(result: Result) {
    mnemonicHelper.delete(MNEMONIC_STORAGE_KEY)
    result.success(true)
  }

  private fun getPrivateKeyFromMnemonic(call: MethodCall, result: Result){
    call.argument<String?>("mnemonic")?.let { mnemonic ->
      if (!MnemonicWords(mnemonic).validate(WORDLIST_ENGLISH)) {
        result.error("mnemonic_verification_failure", "mnemonic failed to pass check",null);
      }

      val words = dirtyPhraseToMnemonicWords(mnemonic)
      val seed = words.toSeed()
      val key = seed.toKey("m/44'/60'/0'/0/0")

      val privateKey = key.keyPair.privateKey.key.toByteArray()

      var intsList = mutableListOf<Int>()
      // and 0xFF fixes twos complement integer representation and
      // ensures unsigned int values pass through since
      // we cannot directly cast bytes to unsigned int
      privateKey.forEach { intsList.add(it.toInt() and 0xFF) }
      result.success(intsList)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
