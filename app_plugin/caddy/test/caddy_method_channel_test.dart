import 'package:caddy_service/src/caddy_method_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CaddyMethodChannel channel;
  late List<MethodCall> methodCalls;
  String? mockResult;

  setUp(() {
    channel = CaddyMethodChannel();
    methodCalls = [];
    mockResult = '';

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('com.caddy_app/caddy'), (
          call,
        ) async {
          methodCalls.add(call);
          return mockResult;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.caddy_app/caddy'),
          null,
        );
  });

  group('CaddyMethodChannel', () {
    group('start', () {
      test('invokes start method with config', () async {
        await channel.start('{"admin":{"disabled":true}}');

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, 'start');
        expect(methodCalls.first.arguments, {
          'config': '{"admin":{"disabled":true}}',
        });
      });

      test('returns result string', () async {
        mockResult = 'some error';
        final result = await channel.start('{}');
        expect(result, 'some error');
      });

      test('returns empty string when null result', () async {
        mockResult = null;
        final result = await channel.start('{}');
        expect(result, '');
      });

      test('returns empty string on success', () async {
        mockResult = '';
        final result = await channel.start('{}');
        expect(result, '');
      });
    });

    group('stop', () {
      test('invokes stop method', () async {
        await channel.stop();

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, 'stop');
        expect(methodCalls.first.arguments, isNull);
      });

      test('returns result string', () async {
        mockResult = 'not running';
        final result = await channel.stop();
        expect(result, 'not running');
      });

      test('returns empty string when null result', () async {
        mockResult = null;
        final result = await channel.stop();
        expect(result, '');
      });
    });

    group('reload', () {
      test('invokes reload method with config', () async {
        await channel.reload('{"apps":{}}');

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, 'reload');
        expect(methodCalls.first.arguments, {'config': '{"apps":{}}'});
      });

      test('returns result string', () async {
        mockResult = 'invalid config';
        final result = await channel.reload('{}');
        expect(result, 'invalid config');
      });

      test('returns empty string when null result', () async {
        mockResult = null;
        final result = await channel.reload('{}');
        expect(result, '');
      });
    });

    group('status', () {
      test('invokes status method', () async {
        mockResult = '{"status":"running"}';
        await channel.status();

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, 'status');
        expect(methodCalls.first.arguments, isNull);
      });

      test('returns status JSON', () async {
        mockResult = '{"status":"running"}';
        final result = await channel.status();
        expect(result, '{"status":"running"}');
      });

      test('returns empty string when null result', () async {
        mockResult = null;
        final result = await channel.status();
        expect(result, '');
      });
    });

    group('setEnvironment', () {
      test('invokes setEnvironment method with env JSON', () async {
        await channel.setEnvironment('{"CF_API_TOKEN":"test"}');

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, 'setEnvironment');
        expect(methodCalls.first.arguments, {'env': '{"CF_API_TOKEN":"test"}'});
      });

      test('returns result string', () async {
        mockResult = 'env error';
        final result = await channel.setEnvironment('{}');
        expect(result, 'env error');
      });

      test('returns empty string when null result', () async {
        mockResult = null;
        final result = await channel.setEnvironment('{}');
        expect(result, '');
      });
    });
  });
}
