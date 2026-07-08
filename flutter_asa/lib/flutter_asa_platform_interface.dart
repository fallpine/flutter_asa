import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_asa_method_channel.dart';

abstract class FlutterAsaPlatform extends PlatformInterface {
  /// Constructs a FlutterAsaPlatform.
  FlutterAsaPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAsaPlatform _instance = MethodChannelFlutterAsa();

  /// The default instance of [FlutterAsaPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAsa].
  static FlutterAsaPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAsaPlatform] when
  /// they register themselves.
  static set instance(FlutterAsaPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns the Apple Search Ads attribution token on iOS.
  Future<String?> attributionToken() {
    throw UnimplementedError('attributionToken() has not been implemented.');
  }

  /// Returns Apple Search Ads attribution details on iOS.
  Future<Map<String, dynamic>?> requestAttributionDetails() {
    throw UnimplementedError(
      'requestAttributionDetails() has not been implemented.',
    );
  }
}
