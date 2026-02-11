import 'package:app_client_info_platform_interface/app_client_info_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// A proper mock that uses MockPlatformInterfaceMixin to pass verification
class MockClientInfoPlatform extends ClientInfoPlatform
    with MockPlatformInterfaceMixin {
  Map<String, dynamic>? getDataResult;
  bool refreshCalled = false;

  @override
  Future<Map<String, dynamic>> getData() async {
    if (getDataResult != null) return getDataResult!;
    return {'platform': 'mock', 'timestamp': '2024-01-01T00:00:00.000Z'};
  }

  @override
  Future<void> refresh() async {
    refreshCalled = true;
  }
}

// A fake that does NOT use MockPlatformInterfaceMixin — should fail verification.
// It extends the mock (which has the mixin) but tries to bypass via a different
// concrete class to test the verify behavior.
class FakeClientInfoPlatform implements ClientInfoPlatform {
  @override
  Future<Map<String, dynamic>> getData() async => {};

  @override
  Future<void> refresh() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClientInfoPlatform', () {
    test('default instance is MethodChannelClientInfo', () {
      expect(ClientInfoPlatform.instance, isA<MethodChannelClientInfo>());
    });

    test('can set mock instance with MockPlatformInterfaceMixin', () {
      final mock = MockClientInfoPlatform();
      ClientInfoPlatform.instance = mock;
      expect(ClientInfoPlatform.instance, same(mock));

      // Reset to default
      ClientInfoPlatform.instance = MethodChannelClientInfo();
    });

    test('rejects fake implementation without MockPlatformInterfaceMixin', () {
      expect(
        () => ClientInfoPlatform.instance = FakeClientInfoPlatform(),
        throwsA(isA<AssertionError>()),
      );
    });

    test('default instance delegates to MethodChannelClientInfo', () {
      final platform = ClientInfoPlatform.instance;
      expect(platform, isA<MethodChannelClientInfo>());
    });
  });

  group('MethodChannelClientInfo', () {
    late MethodChannelClientInfo methodChannel;
    late List<MethodCall> log;

    setUp(() {
      methodChannel = MethodChannelClientInfo();
      log = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel.methodChannel,
        (MethodCall call) async {
          log.add(call);
          switch (call.method) {
            case 'getData':
              return <String, dynamic>{
                'platform': 'test',
                'version': '1.0',
              };
            case 'refresh':
              return null;
            default:
              throw MissingPluginException();
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel.methodChannel, null);
    });

    test('getData invokes correct method channel', () async {
      final result = await methodChannel.getData();
      expect(log, hasLength(1));
      expect(log.first.method, 'getData');
      expect(result, {'platform': 'test', 'version': '1.0'});
    });

    test('getData returns Map<String, dynamic>', () async {
      final result = await methodChannel.getData();
      expect(result, isA<Map<String, dynamic>>());
    });

    test('getData throws PlatformException when null result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannel.methodChannel,
        (MethodCall call) async => null,
      );

      expect(
        () => methodChannel.getData(),
        throwsA(isA<PlatformException>()),
      );
    });

    test('refresh invokes correct method channel', () async {
      await methodChannel.refresh();
      expect(log, hasLength(1));
      expect(log.first.method, 'refresh');
    });

    test('method channel uses correct channel name', () {
      expect(methodChannel.methodChannel.name, 'app_client_info');
    });
  });

  group('MockClientInfoPlatform', () {
    test('getData returns mock data', () async {
      final mock = MockClientInfoPlatform();
      final data = await mock.getData();
      expect(data['platform'], 'mock');
    });

    test('getData returns custom data when set', () async {
      final mock = MockClientInfoPlatform();
      mock.getDataResult = {'platform': 'custom', 'test': true};
      final data = await mock.getData();
      expect(data['platform'], 'custom');
      expect(data['test'], isTrue);
    });

    test('refresh sets called flag', () async {
      final mock = MockClientInfoPlatform();
      expect(mock.refreshCalled, isFalse);
      await mock.refresh();
      expect(mock.refreshCalled, isTrue);
    });

    test('can be set as platform instance', () {
      final mock = MockClientInfoPlatform();
      ClientInfoPlatform.instance = mock;
      expect(ClientInfoPlatform.instance, isA<MockClientInfoPlatform>());

      // Reset
      ClientInfoPlatform.instance = MethodChannelClientInfo();
    });
  });
}
