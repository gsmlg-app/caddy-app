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
  });
}
