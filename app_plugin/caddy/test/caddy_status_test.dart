import 'package:caddy_service/caddy_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaddyStatus', () {
    test('CaddyStopped is sealed CaddyStatus', () {
      const status = CaddyStopped();
      expect(status, isA<CaddyStatus>());
    });

    test('CaddyRunning stores config and startedAt', () {
      final now = DateTime(2024, 1, 1);
      final status = CaddyRunning(config: '{"apps":{}}', startedAt: now);
      expect(status.config, '{"apps":{}}');
      expect(status.startedAt, now);
    });

    test('CaddyError stores message', () {
      const status = CaddyError(message: 'port in use');
      expect(status.message, 'port in use');
    });

    test('CaddyLoading is sealed CaddyStatus', () {
      const status = CaddyLoading();
      expect(status, isA<CaddyStatus>());
    });

    test('switch exhaustively matches all CaddyStatus types', () {
      final statuses = <CaddyStatus>[
        const CaddyStopped(),
        CaddyRunning(config: '{}', startedAt: DateTime.now()),
        const CaddyError(message: 'test'),
        const CaddyLoading(),
      ];

      for (final status in statuses) {
        final result = switch (status) {
          CaddyStopped() => 'stopped',
          CaddyRunning() => 'running',
          CaddyError() => 'error',
          CaddyLoading() => 'loading',
        };
        expect(result, isNotEmpty);
      }
    });
  });
}
