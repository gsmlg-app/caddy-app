import 'dart:async';

import 'package:app_logging/app_logging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger', () {
    late AppLogger logger;

    setUp(() {
      logger = AppLogger();
    });

    test('is a singleton', () {
      final a = AppLogger();
      final b = AppLogger();
      expect(identical(a, b), isTrue);
    });

    test('logStream emits records after initialize', () async {
      logger.initialize(level: LogLevel.verbose);

      final completer = Completer<LogRecord>();
      final sub = logger.logStream.listen((record) {
        if (!completer.isCompleted) {
          completer.complete(record);
        }
      });

      logger.i('test info message');

      final record = await completer.future.timeout(const Duration(seconds: 2));
      expect(record.message, 'test info message');
      expect(record.level, LogLevel.info);

      await sub.cancel();
    });

    test('filters messages below current level', () async {
      logger.initialize(level: LogLevel.warning);

      final records = <LogRecord>[];
      final sub = logger.logStream.listen(records.add);

      logger.d('debug message');
      logger.i('info message');

      // Give time for any messages to arrive
      await Future.delayed(const Duration(milliseconds: 100));

      // Debug and info are below warning level
      final appLoggerRecords = records
          .where((r) => r.message == 'debug message')
          .toList();
      expect(appLoggerRecords, isEmpty);

      await sub.cancel();
    });

    test('warning level passes through at warning level', () async {
      logger.initialize(level: LogLevel.warning);

      final completer = Completer<LogRecord>();
      final sub = logger.logStream.listen((record) {
        if (record.message == 'a warning' && !completer.isCompleted) {
          completer.complete(record);
        }
      });

      logger.w('a warning');

      final record = await completer.future.timeout(const Duration(seconds: 2));
      expect(record.level, LogLevel.warning);

      await sub.cancel();
    });

    test('error level passes through', () async {
      logger.initialize(level: LogLevel.verbose);

      final completer = Completer<LogRecord>();
      final sub = logger.logStream.listen((record) {
        if (record.message == 'an error' && !completer.isCompleted) {
          completer.complete(record);
        }
      });

      logger.e('an error', Exception('test'), StackTrace.current);

      final record = await completer.future.timeout(const Duration(seconds: 2));
      expect(record.level, LogLevel.error);

      await sub.cancel();
    });

    test('fatal level maps correctly', () async {
      logger.initialize(level: LogLevel.verbose);

      final completer = Completer<LogRecord>();
      final sub = logger.logStream.listen((record) {
        if (record.message == 'fatal error' && !completer.isCompleted) {
          completer.complete(record);
        }
      });

      logger.f('fatal error');

      final record = await completer.future.timeout(const Duration(seconds: 2));
      expect(record.level, LogLevel.fatal);

      await sub.cancel();
    });

    test('verbose method logs at verbose level', () async {
      logger.initialize(level: LogLevel.verbose);

      final completer = Completer<LogRecord>();
      final sub = logger.logStream.listen((record) {
        if (record.message == 'verbose msg' && !completer.isCompleted) {
          completer.complete(record);
        }
      });

      logger.v('verbose msg');

      final record = await completer.future.timeout(const Duration(seconds: 2));
      expect(record.level, LogLevel.verbose);

      await sub.cancel();
    });

    test('initialize with includeStackTrace false omits traces', () async {
      logger.initialize(level: LogLevel.verbose, includeStackTrace: false);

      final completer = Completer<LogRecord>();
      final sub = logger.logStream.listen((record) {
        if (record.message == 'no trace' && !completer.isCompleted) {
          completer.complete(record);
        }
      });

      logger.e('no trace', Exception('err'), StackTrace.current);

      final record = await completer.future.timeout(const Duration(seconds: 2));
      expect(record.stackTrace, isNull);

      await sub.cancel();
    });
  });
}
