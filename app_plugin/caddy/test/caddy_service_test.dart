import 'dart:async';

import 'package:caddy_service/caddy_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A testable CaddyService that simulates start/stop/reload behavior
/// without requiring FFI or MethodChannel.
class TestCaddyService extends CaddyService {
  TestCaddyService() : super.forTesting();

  String? startError;
  String? stopError;
  String? reloadError;
  String? statusJson;
  bool throwOnStart = false;
  bool throwOnStop = false;
  bool throwOnReload = false;
  bool throwOnStatus = false;
  final List<String> logMessages = [];

  final StreamController<String> _testLogController =
      StreamController<String>.broadcast();

  @override
  Stream<String> get logStream => _testLogController.stream;

  void addLog(String message) {
    _testLogController.add(message);
    logMessages.add(message);
  }

  @override
  Future<CaddyStatus> start(
    CaddyConfig config, {
    bool adminEnabled = false,
    Map<String, String> environment = const {},
  }) async {
    if (throwOnStart) throw Exception('FFI crash');
    if (startError != null) {
      if (startError!.contains('address already in use') ||
          startError!.contains('bind:')) {
        return CaddyError(
          message: 'Port ${config.listenAddress} is already in use',
        );
      }
      return CaddyError(message: startError!);
    }
    return CaddyRunning(
      config: config.toJsonString(adminEnabled: adminEnabled),
      startedAt: DateTime.now(),
    );
  }

  @override
  Future<CaddyStatus> stop() async {
    if (throwOnStop) throw Exception('FFI crash');
    if (stopError != null) return CaddyError(message: stopError!);
    return const CaddyStopped();
  }

  @override
  Future<CaddyStatus> reload(
    CaddyConfig config, {
    bool adminEnabled = false,
    Map<String, String> environment = const {},
  }) async {
    if (throwOnReload) throw Exception('FFI crash');
    if (reloadError != null) {
      if (reloadError!.contains('address already in use') ||
          reloadError!.contains('bind:')) {
        return CaddyError(
          message: 'Port ${config.listenAddress} is already in use',
        );
      }
      return CaddyError(message: reloadError!);
    }
    return CaddyRunning(
      config: config.toJsonString(adminEnabled: adminEnabled),
      startedAt: DateTime.now(),
    );
  }

  @override
  Future<CaddyStatus> getStatus() async {
    if (throwOnStatus) throw Exception('FFI crash');
    if (statusJson == 'running') {
      return CaddyRunning(config: '', startedAt: DateTime.now());
    }
    return const CaddyStopped();
  }

  Future<void> closeTestLog() async {
    await _testLogController.close();
  }
}

void main() {
  group('CaddyService contract', () {
    late TestCaddyService service;

    setUp(() {
      service = TestCaddyService();
    });

    tearDown(() async {
      await service.closeTestLog();
    });

    group('start', () {
      test('returns CaddyRunning on success', () async {
        const config = CaddyConfig(listenAddress: 'localhost:8080');
        final status = await service.start(config);
        expect(status, isA<CaddyRunning>());
        final running = status as CaddyRunning;
        expect(running.config, contains('"listen"'));
      });

      test('returns CaddyRunning with admin enabled', () async {
        const config = CaddyConfig(listenAddress: 'localhost:8080');
        final status = await service.start(config, adminEnabled: true);
        expect(status, isA<CaddyRunning>());
        final running = status as CaddyRunning;
        expect(running.config, contains('localhost:2019'));
      });

      test('returns CaddyError with port-in-use message', () async {
        service.startError = 'address already in use';
        const config = CaddyConfig(listenAddress: 'localhost:8080');
        final status = await service.start(config);
        expect(status, isA<CaddyError>());
        expect((status as CaddyError).message, contains('already in use'));
      });

      test('returns CaddyError with bind error', () async {
        service.startError = 'bind: address already in use';
        const config = CaddyConfig(listenAddress: ':443');
        final status = await service.start(config);
        expect(status, isA<CaddyError>());
        expect((status as CaddyError).message, contains(':443'));
      });

      test('returns CaddyError for generic errors', () async {
        service.startError = 'permission denied';
        const config = CaddyConfig();
        final status = await service.start(config);
        expect(status, isA<CaddyError>());
        expect((status as CaddyError).message, 'permission denied');
      });
    });

    group('stop', () {
      test('returns CaddyStopped on success', () async {
        final status = await service.stop();
        expect(status, isA<CaddyStopped>());
      });

      test('returns CaddyError on failure', () async {
        service.stopError = 'not running';
        final status = await service.stop();
        expect(status, isA<CaddyError>());
        expect((status as CaddyError).message, 'not running');
      });
    });

    group('reload', () {
      test('returns CaddyRunning on success', () async {
        const config = CaddyConfig(listenAddress: 'localhost:9090');
        final status = await service.reload(config);
        expect(status, isA<CaddyRunning>());
      });

      test('returns CaddyError with port-in-use message', () async {
        service.reloadError = 'address already in use';
        const config = CaddyConfig(listenAddress: 'localhost:8080');
        final status = await service.reload(config);
        expect(status, isA<CaddyError>());
        expect((status as CaddyError).message, contains('already in use'));
      });

      test('returns CaddyError for generic errors', () async {
        service.reloadError = 'invalid config';
        const config = CaddyConfig();
        final status = await service.reload(config);
        expect(status, isA<CaddyError>());
        expect((status as CaddyError).message, 'invalid config');
      });

      test('passes admin enabled flag', () async {
        const config = CaddyConfig(listenAddress: 'localhost:8080');
        final status = await service.reload(config, adminEnabled: true);
        expect(status, isA<CaddyRunning>());
        final running = status as CaddyRunning;
        expect(running.config, contains('localhost:2019'));
      });
    });

    group('getStatus', () {
      test('returns CaddyStopped when not running', () async {
        final status = await service.getStatus();
        expect(status, isA<CaddyStopped>());
      });

      test('returns CaddyRunning when running', () async {
        service.statusJson = 'running';
        final status = await service.getStatus();
        expect(status, isA<CaddyRunning>());
      });
    });

    group('logStream', () {
      test('emits log messages', () async {
        final logs = <String>[];
        final sub = service.logStream.listen(logs.add);

        service.addLog('INFO: Server started');
        service.addLog('DEBUG: Request received');
        await Future<void>.delayed(Duration.zero);

        expect(logs, ['INFO: Server started', 'DEBUG: Request received']);
        await sub.cancel();
      });

      test('is a broadcast stream', () {
        final sub1 = service.logStream.listen((_) {});
        final sub2 = service.logStream.listen((_) {});

        // Both subscriptions should work without error
        sub1.cancel();
        sub2.cancel();
      });
    });

    group('lifecycle', () {
      test('start then stop returns to stopped', () async {
        const config = CaddyConfig();
        final startStatus = await service.start(config);
        expect(startStatus, isA<CaddyRunning>());

        final stopStatus = await service.stop();
        expect(stopStatus, isA<CaddyStopped>());
      });

      test('start then reload updates config', () async {
        const config1 = CaddyConfig(listenAddress: 'localhost:8080');
        final start = await service.start(config1);
        expect(start, isA<CaddyRunning>());

        const config2 = CaddyConfig(listenAddress: 'localhost:9090');
        final reload = await service.reload(config2);
        expect(reload, isA<CaddyRunning>());
        expect((reload as CaddyRunning).config, contains(':9090'));
      });

      test('error on start does not prevent retry', () async {
        service.startError = 'port in use';
        const config = CaddyConfig();

        final fail = await service.start(config);
        expect(fail, isA<CaddyError>());

        service.startError = null;
        final success = await service.start(config);
        expect(success, isA<CaddyRunning>());
      });
    });

    group('exception handling', () {
      test('start throws on FFI crash', () async {
        service.throwOnStart = true;
        const config = CaddyConfig();
        expect(
          () => service.start(config),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('FFI crash'),
            ),
          ),
        );
      });

      test('stop throws on FFI crash', () async {
        service.throwOnStop = true;
        expect(
          () => service.stop(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('FFI crash'),
            ),
          ),
        );
      });

      test('reload throws on FFI crash', () async {
        service.throwOnReload = true;
        const config = CaddyConfig();
        expect(
          () => service.reload(config),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('FFI crash'),
            ),
          ),
        );
      });

      test('getStatus throws on FFI crash', () async {
        service.throwOnStatus = true;
        expect(
          () => service.getStatus(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('FFI crash'),
            ),
          ),
        );
      });
    });

    group('environment', () {
      test('start passes environment variables', () async {
        const config = CaddyConfig();
        final env = {'CF_API_TOKEN': 'test-token'};
        final status = await service.start(config, environment: env);
        expect(status, isA<CaddyRunning>());
      });

      test('reload passes environment variables', () async {
        const config = CaddyConfig();
        final env = {'S3_ACCESS_KEY': 'key-123'};
        final status = await service.reload(config, environment: env);
        expect(status, isA<CaddyRunning>());
      });

      test('start with empty environment succeeds', () async {
        const config = CaddyConfig();
        final status = await service.start(config, environment: {});
        expect(status, isA<CaddyRunning>());
      });
    });

    group('dispose', () {
      test('close test log controller completes cleanly', () async {
        // Ensure log controller can be closed without error
        await service.closeTestLog();
        // Further emissions should not throw
      });

      test('log messages are recorded in order', () {
        service.addLog('first');
        service.addLog('second');
        service.addLog('third');

        expect(
          service.logMessages,
          orderedEquals(['first', 'second', 'third']),
        );
      });
    });
  });
}
