import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_sdk_method_channel.dart';

abstract class FlutterSdkPlatform extends PlatformInterface {
  /// Constructs a FlutterSdkPlatform.
  FlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSdkPlatform _instance = MethodChannelFlutterSdk();

  /// The default instance of [FlutterSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSdk].
  static FlutterSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSdkPlatform] when
  /// they register themselves.
  static set instance(FlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
