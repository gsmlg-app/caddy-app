import 'package:app_logging/app_logging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogLevel', () {
    test('ordering is verbose < debug < info < warning < error < fatal', () {
      expect(LogLevel.verbose < LogLevel.debug, isTrue);
      expect(LogLevel.debug < LogLevel.info, isTrue);
      expect(LogLevel.info < LogLevel.warning, isTrue);
      expect(LogLevel.warning < LogLevel.error, isTrue);
      expect(LogLevel.error < LogLevel.fatal, isTrue);
    });

    test('comparison operators work correctly', () {
      expect(LogLevel.info >= LogLevel.info, isTrue);
      expect(LogLevel.info >= LogLevel.debug, isTrue);
      expect(LogLevel.info <= LogLevel.warning, isTrue);
      expect(LogLevel.info > LogLevel.debug, isTrue);
      expect(LogLevel.debug < LogLevel.info, isTrue);
    });

    test('each level has correct name', () {
      expect(LogLevel.verbose.name, 'VERBOSE');
      expect(LogLevel.debug.name, 'DEBUG');
      expect(LogLevel.info.name, 'INFO');
      expect(LogLevel.warning.name, 'WARNING');
      expect(LogLevel.error.name, 'ERROR');
      expect(LogLevel.fatal.name, 'FATAL');
    });

    test('each level has incrementing value', () {
      expect(LogLevel.verbose.value, 0);
      expect(LogLevel.debug.value, 1);
      expect(LogLevel.info.value, 2);
      expect(LogLevel.warning.value, 3);
      expect(LogLevel.error.value, 4);
      expect(LogLevel.fatal.value, 5);
    });
  });

  group('LogRecord', () {
    test('creates record with required fields', () {
      final time = DateTime(2024, 1, 1);
      final record = LogRecord(
        level: LogLevel.info,
        message: 'test message',
        loggerName: 'TestLogger',
        time: time,
      );

      expect(record.level, LogLevel.info);
      expect(record.message, 'test message');
      expect(record.loggerName, 'TestLogger');
      expect(record.time, time);
      expect(record.error, isNull);
      expect(record.stackTrace, isNull);
    });

    test('defaults time to now when not provided', () {
      final before = DateTime.now();
      final record = LogRecord(
        level: LogLevel.info,
        message: 'test',
        loggerName: 'Test',
      );
      final after = DateTime.now();

      expect(record.time.isAfter(before) || record.time == before, isTrue);
      expect(record.time.isBefore(after) || record.time == after, isTrue);
    });

    test('stores error and stack trace', () {
      final error = Exception('test error');
      final stackTrace = StackTrace.current;
      final record = LogRecord(
        level: LogLevel.error,
        message: 'error occurred',
        loggerName: 'Test',
        error: error,
        stackTrace: stackTrace,
      );

      expect(record.error, error);
      expect(record.stackTrace, stackTrace);
    });

    test('copyWith updates specified fields', () {
      final record = LogRecord(
        level: LogLevel.info,
        message: 'original',
        loggerName: 'Test',
      );
      final updated = record.copyWith(
        level: LogLevel.error,
        message: 'updated',
      );

      expect(updated.level, LogLevel.error);
      expect(updated.message, 'updated');
      expect(updated.loggerName, 'Test');
    });

    test('copyWith with no args returns equal record', () {
      final time = DateTime(2024, 1, 1);
      final record = LogRecord(
        level: LogLevel.info,
        message: 'test',
        loggerName: 'Test',
        time: time,
      );
      final copy = record.copyWith();

      expect(copy, equals(record));
    });

    test('equality with same fields', () {
      final time = DateTime(2024, 1, 1);
      final a = LogRecord(
        level: LogLevel.info,
        message: 'test',
        loggerName: 'Test',
        time: time,
      );
      final b = LogRecord(
        level: LogLevel.info,
        message: 'test',
        loggerName: 'Test',
        time: time,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('inequality with different message', () {
      final time = DateTime(2024, 1, 1);
      final a = LogRecord(
        level: LogLevel.info,
        message: 'a',
        loggerName: 'Test',
        time: time,
      );
      final b = LogRecord(
        level: LogLevel.info,
        message: 'b',
        loggerName: 'Test',
        time: time,
      );

      expect(a, isNot(equals(b)));
    });

    test('inequality with different level', () {
      final time = DateTime(2024, 1, 1);
      final a = LogRecord(
        level: LogLevel.info,
        message: 'test',
        loggerName: 'Test',
        time: time,
      );
      final b = LogRecord(
        level: LogLevel.error,
        message: 'test',
        loggerName: 'Test',
        time: time,
      );

      expect(a, isNot(equals(b)));
    });

    test('toString contains level and message', () {
      final record = LogRecord(
        level: LogLevel.warning,
        message: 'a warning',
        loggerName: 'MyLogger',
      );
      final str = record.toString();

      expect(str, contains('WARNING'));
      expect(str, contains('a warning'));
      expect(str, contains('MyLogger'));
    });
  });
}
