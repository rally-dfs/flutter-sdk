import 'flutter_sdk_platform_interface.dart';

class FlutterSdk {
  Future<String?> getPlatformVersion() {
    return FlutterSdkPlatform.instance.getPlatformVersion();
  }
}
