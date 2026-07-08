import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_asa_platform_interface.dart';

/// An implementation of [FlutterAsaPlatform] that uses method channels.
class MethodChannelFlutterAsa extends FlutterAsaPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_asa');

  @override
  Future<String?> attributionToken() {
    return methodChannel.invokeMethod<String>('attributionToken');
  }

  @override
  Future<Map<String, dynamic>?> requestAttributionDetails() async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'requestAttributionDetails',
    );
    return result;
  }
}
