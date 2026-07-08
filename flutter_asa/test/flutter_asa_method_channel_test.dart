import 'package:flutter/services.dart';
import 'package:flutter_asa/flutter_asa_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter_asa');
  final platform = MethodChannelFlutterAsa();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'attributionToken':
              return 'token';
            case 'requestAttributionDetails':
              return <String, dynamic>{
                'attribution': true,
                'campaignId': 542370539,
              };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('attributionToken returns native token', () async {
    expect(await platform.attributionToken(), 'token');
  });

  test('requestAttributionDetails returns native attribution map', () async {
    final result = await platform.requestAttributionDetails();

    expect(result, isNotNull);
    expect(result?['attribution'], isTrue);
    expect(result?['campaignId'], 542370539);
  });
}
