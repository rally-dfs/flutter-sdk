import Flutter
import UIKit
import Foundation


public class FlutterSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "rly_network_flutter_sdk", binaryMessenger: registrar.messenger())
    let instance = FlutterSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "getPlatformVersion":
        result("iOS " + UIDevice.current.systemVersion)
      case "getBundleId":
        result(RlyNetworkMobileSdk().getBundleId())
      case "generateNewMnemonic":
        result(RlyNetworkMobileSdk().generateMnemonic())
      case "getPrivateKeyFromMnemonic":
        if let arguments = call.arguments as? [String: Any], let data = arguments["mnemonic"] as? String {
          result(RlyNetworkMobileSdk().getPrivateKeyFromMnemonic(data))
        } else {
            // Handle the case where 'arguments' or 'data' is nil
            // You might want to return an error or a default value here.
        }
        case "getMnemonic":
          result(RlyNetworkMobileSdk().getMnemonic())
        case "mnemonicBackedUpToCloud":
          result(RlyNetworkMobileSdk().mnemonicBackedUpToCloud())
        case "deleteMnemonic":
          result(RlyNetworkMobileSdk().deleteMnemonic())
        case "deleteCloudMnemonic":
          result(RlyNetworkMobileSdk().deleteCloudMnemonic())
        case "saveMnemonic":
          if let arguments = call.arguments as? [String: Any],
            let mnemonicToSave = arguments["mnemonic"] as? String,
            let saveToCloud = arguments["saveToCloud"] as? Bool,
            let rejectOnCloudSaveFailure = arguments["rejectOnCloudSaveFailure"] as? Bool {
            result(RlyNetworkMobileSdk().saveMnemonic(mnemonicToSave, saveToCloud: saveToCloud, rejectOnCloudSaveFailure: rejectOnCloudSaveFailure))
          }

        default:
          result(FlutterMethodNotImplemented)
    }
  }
}
