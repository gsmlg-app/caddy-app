import 'package:app_logging/app_logging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ErrorReportingService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = ErrorReportingService();
    await service.clearErrorLogs();
  });

  group('ErrorReportingService', () {
    test('is a singleton', () {
      final a = ErrorReportingService();
      final b = ErrorReportingService();
      expect(identical(a, b), isTrue);
    });

    test('reportError stores error in SharedPreferences', () async {
      await service.reportError(error: Exception('test error'));

      final errors = await service.getRecentErrors();
      expect(errors, isNotEmpty);
    });

    test('reportError with context includes context info', () async {
      await service.reportError(
        error: Exception('ctx error'),
        context: 'test context',
      );

      final errors = await service.getRecentErrors();
      expect(errors, hasLength(1));
    });

    test('reportException delegates to reportError', () async {
      await service.reportException(
        exception: Exception('delegated'),
        context: 'test',
      );

      final errors = await service.getRecentErrors();
      expect(errors, isNotEmpty);
    });

    test('reportFlutterError stores Flutter error details', () async {
      await service.reportFlutterError(
        details: FlutterErrorDetails(
          exception: Exception('flutter error'),
          library: 'test_library',
        ),
      );

      final errors = await service.getRecentErrors();
      expect(errors, isNotEmpty);
    });

    test('getRecentErrors returns empty list initially', () async {
      final errors = await service.getRecentErrors();
      expect(errors, isEmpty);
    });

    test('clearErrorLogs removes all stored errors', () async {
      await service.reportError(error: Exception('error1'));
      await service.reportError(error: Exception('error2'));

      await service.clearErrorLogs();

      final errors = await service.getRecentErrors();
      expect(errors, isEmpty);
    });

    test('multiple errors are stored in order', () async {
      await service.reportError(error: Exception('first'));
      await service.reportError(error: Exception('second'));
      await service.reportError(error: Exception('third'));

      final errors = await service.getRecentErrors();
      expect(errors, hasLength(3));
    });

    test('exportErrorLogs does not throw', () async {
      await service.reportError(error: Exception('export test'));
      await expectLater(service.exportErrorLogs(), completes);
    });

    test('setupGlobalErrorHandler sets Flutter error handler', () {
      final originalHandler = FlutterError.onError;

      service.setupGlobalErrorHandler();

      expect(FlutterError.onError, isNotNull);
      expect(FlutterError.onError, isNot(equals(originalHandler)));
    });

    test('error records contain raw field from decoding', () async {
      await service.reportError(error: 'simple string error');

      final errors = await service.getRecentErrors();
      expect(errors, hasLength(1));
      // _decodeErrorRecord wraps stored string in {'raw': json}
      expect(errors.first, containsPair('raw', isA<String>()));
    });

    test('error record raw field contains error message', () async {
      await service.reportError(error: Exception('specific message'));

      final errors = await service.getRecentErrors();
      expect(errors.first['raw'], contains('specific message'));
    });

    test('error record preserves context in stored data', () async {
      await service.reportError(error: 'test', context: 'database operation');

      final errors = await service.getRecentErrors();
      expect(errors.first['raw'], contains('database operation'));
    });

    test('reportFlutterError stores library info', () async {
      await service.reportFlutterError(
        details: FlutterErrorDetails(
          exception: Exception('render error'),
          library: 'rendering library',
        ),
      );

      final errors = await service.getRecentErrors();
      expect(errors, hasLength(1));
      expect(errors.first['raw'], contains('render error'));
    });

    test('max stored errors limit is enforced', () async {
      // Report 110 errors (limit is 100)
      for (var i = 0; i < 110; i++) {
        await service.reportError(error: 'error_$i');
      }

      final errors = await service.getRecentErrors();
      expect(errors.length, 100);
      // Oldest errors should have been dropped
      expect(errors.first['raw'], contains('error_10'));
      expect(errors.last['raw'], contains('error_109'));
    });

    test('reportError with additionalData stores extra fields', () async {
      await service.reportError(
        error: 'test',
        additionalData: {'user_id': '123', 'action': 'submit'},
      );

      final errors = await service.getRecentErrors();
      expect(errors.first['raw'], contains('user_id'));
      expect(errors.first['raw'], contains('123'));
    });

    test('reportError with stackTrace stores trace', () async {
      final trace = StackTrace.current;
      await service.reportError(error: 'traced error', stackTrace: trace);

      final errors = await service.getRecentErrors();
      expect(errors, hasLength(1));
      expect(errors.first['raw'], contains('traced error'));
    });

    test('reportError with sendToBackend completes', () async {
      await expectLater(
        service.reportError(error: 'backend error', sendToBackend: true),
        completes,
      );
    });
  });
}
