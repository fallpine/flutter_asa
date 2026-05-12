import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_asa/flutter_asa.dart';
import 'package:flutter_asa/flutter_asa_platform_interface.dart';
import 'package:flutter_asa/flutter_asa_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAsaPlatform
    with MockPlatformInterfaceMixin
    implements FlutterAsaPlatform {}

void main() {
  final FlutterAsaPlatform initialPlatform = FlutterAsaPlatform.instance;

  test('$MethodChannelFlutterAsa is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterAsa>());
  });

  test('config accepts required FlutterAsa values', () {
    Asa.config(
      aesSecretKey: '1234567890123456',
      aesIv: '1234567890123456',
      aesSctToken: 'sct-token',
      userId: 'user-id',
      appVersion: '1.0.0',
      deviceType: 'ios',
      deviceModel: 'iPhone',
      deviceOSVersion: '17.0',
    );
  });
}
