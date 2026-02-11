import 'package:bloc_test/bloc_test.dart';
import 'package:error_handler_bloc/error_handler_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorSeverity', () {
    test('has four values', () {
      expect(ErrorSeverity.values, hasLength(4));
    });

    test('values are ordered low, medium, high, critical', () {
      expect(ErrorSeverity.values, [
        ErrorSeverity.low,
        ErrorSeverity.medium,
        ErrorSeverity.high,
        ErrorSeverity.critical,
      ]);
    });
  });

  group('AppError', () {
    test('creates with required fields', () {
      final error = AppError(
        id: 'err_1',
        error: 'test error',
        severity: ErrorSeverity.high,
      );
      expect(error.id, 'err_1');
      expect(error.error, 'test error');
      expect(error.severity, ErrorSeverity.high);
      expect(error.isResolved, isFalse);
      expect(error.stackTrace, isNull);
      expect(error.context, isNull);
    });

    test('timestamp defaults to now', () {
      final before = DateTime.now();
      final error = AppError(
        id: 'err_1',
        error: 'test',
        severity: ErrorSeverity.low,
      );
      final after = DateTime.now();
      expect(
        error.timestamp.millisecondsSinceEpoch,
        greaterThanOrEqualTo(before.millisecondsSinceEpoch),
      );
      expect(
        error.timestamp.millisecondsSinceEpoch,
        lessThanOrEqualTo(after.millisecondsSinceEpoch),
      );
    });

    test('displayMessage returns userMessage when set', () {
      final error = AppError(
        id: 'err_1',
        error: Exception('internal'),
        severity: ErrorSeverity.high,
        userMessage: 'User-friendly message',
      );
      expect(error.displayMessage, 'User-friendly message');
    });

    test('displayMessage returns string error directly', () {
      final error = AppError(
        id: 'err_1',
        error: 'Something failed',
        severity: ErrorSeverity.medium,
      );
      expect(error.displayMessage, 'Something failed');
    });

    test('displayMessage returns exception toString', () {
      final error = AppError(
        id: 'err_1',
        error: Exception('oops'),
        severity: ErrorSeverity.medium,
      );
      expect(error.displayMessage, contains('oops'));
    });

    test('displayMessage returns default for non-string non-exception', () {
      final error = AppError(
        id: 'err_1',
        error: 42,
        severity: ErrorSeverity.medium,
      );
      expect(error.displayMessage, 'An unexpected error occurred');
    });

    test('copyWith creates modified copy', () {
      final original = AppError(
        id: 'err_1',
        error: 'test',
        severity: ErrorSeverity.low,
      );
      final copy = original.copyWith(
        isResolved: true,
        severity: ErrorSeverity.high,
      );
      expect(copy.id, 'err_1');
      expect(copy.isResolved, isTrue);
      expect(copy.severity, ErrorSeverity.high);
      expect(copy.error, 'test');
    });

    test('equality by id and fields', () {
      final timestamp = DateTime(2024, 1, 1);
      final a = AppError(
        id: 'err_1',
        error: 'test',
        severity: ErrorSeverity.high,
        timestamp: timestamp,
      );
      final b = AppError(
        id: 'err_1',
        error: 'test',
        severity: ErrorSeverity.high,
        timestamp: timestamp,
      );
      expect(a, equals(b));
    });

    test('inequality when id differs', () {
      final timestamp = DateTime(2024, 1, 1);
      final a = AppError(
        id: 'err_1',
        error: 'test',
        severity: ErrorSeverity.high,
        timestamp: timestamp,
      );
      final b = AppError(
        id: 'err_2',
        error: 'test',
        severity: ErrorSeverity.high,
        timestamp: timestamp,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('ErrorState', () {
    test('default state has empty lists and no errors', () {
      const state = ErrorState();
      expect(state.activeErrors, isEmpty);
      expect(state.resolvedErrors, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.lastErrorMessage, isNull);
      expect(state.hasErrors, isFalse);
      expect(state.hasCriticalErrors, isFalse);
    });

    test('hasErrors is true when activeErrors is non-empty', () {
      final state = ErrorState(
        activeErrors: [
          AppError(id: 'err_1', error: 'x', severity: ErrorSeverity.low),
        ],
      );
      expect(state.hasErrors, isTrue);
    });

    test('hasCriticalErrors detects critical severity', () {
      final state = ErrorState(
        activeErrors: [
          AppError(id: 'err_1', error: 'x', severity: ErrorSeverity.critical),
        ],
      );
      expect(state.hasCriticalErrors, isTrue);
    });

    test('hasCriticalErrors is false for non-critical errors', () {
      final state = ErrorState(
        activeErrors: [
          AppError(id: 'err_1', error: 'x', severity: ErrorSeverity.high),
        ],
      );
      expect(state.hasCriticalErrors, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final state = ErrorState(
        activeErrors: [
          AppError(id: 'err_1', error: 'x', severity: ErrorSeverity.low),
        ],
        lastErrorMessage: 'old msg',
      );
      final copied = state.copyWith(isLoading: true);
      expect(copied.activeErrors, hasLength(1));
      expect(copied.lastErrorMessage, 'old msg');
      expect(copied.isLoading, isTrue);
    });

    test('equality between identical states', () {
      const a = ErrorState();
      const b = ErrorState();
      expect(a, equals(b));
    });
  });

  group('ErrorEvent', () {
    test('ErrorReported equality with same props', () {
      const a = ErrorReported(error: 'test', severity: ErrorSeverity.high);
      const b = ErrorReported(error: 'test', severity: ErrorSeverity.high);
      expect(a, equals(b));
    });

    test('ErrorDismissed equality', () {
      const a = ErrorDismissed('err_1');
      const b = ErrorDismissed('err_1');
      expect(a, equals(b));
    });

    test('ErrorsCleared equality', () {
      const a = ErrorsCleared();
      const b = ErrorsCleared();
      expect(a, equals(b));
    });

    test('ErrorRecovered equality', () {
      const a = ErrorRecovered('err_1');
      const b = ErrorRecovered('err_1');
      expect(a, equals(b));
    });

    test('ErrorReported default values', () {
      const event = ErrorReported(error: 'test');
      expect(event.showToUser, isTrue);
      expect(event.severity, ErrorSeverity.high);
      expect(event.stackTrace, isNull);
      expect(event.context, isNull);
    });
  });

  group('ErrorBloc', () {
    blocTest<ErrorBloc, ErrorState>(
      'initial state is empty ErrorState',
      build: () => ErrorBloc(),
      verify: (bloc) {
        expect(bloc.state, const ErrorState());
        expect(bloc.state.hasErrors, isFalse);
      },
    );

    blocTest<ErrorBloc, ErrorState>(
      'ErrorReported adds error to activeErrors',
      build: () => ErrorBloc(),
      act: (bloc) => bloc.add(
        const ErrorReported(error: 'test error', severity: ErrorSeverity.high),
      ),
      expect: () => [
        isA<ErrorState>()
            .having((s) => s.activeErrors, 'activeErrors', hasLength(1))
            .having((s) => s.activeErrors.first.error, 'error', 'test error')
            .having(
              (s) => s.activeErrors.first.severity,
              'severity',
              ErrorSeverity.high,
            )
            .having((s) => s.activeErrors.first.id, 'id', startsWith('err_')),
      ],
    );

    blocTest<ErrorBloc, ErrorState>(
      'ErrorReported sets lastErrorMessage for high severity',
      build: () => ErrorBloc(),
      act: (bloc) => bloc.add(
        ErrorReported(error: Exception('fail'), severity: ErrorSeverity.high),
      ),
      expect: () => [
        isA<ErrorState>().having(
          (s) => s.lastErrorMessage,
          'lastErrorMessage',
          'Something went wrong. Please try again.',
        ),
      ],
    );

    blocTest<ErrorBloc, ErrorState>(
      'ErrorReported sets critical user message',
      build: () => ErrorBloc(),
      act: (bloc) => bloc.add(
        ErrorReported(
          error: Exception('crash'),
          severity: ErrorSeverity.critical,
        ),
      ),
      expect: () => [
        isA<ErrorState>().having(
          (s) => s.lastErrorMessage,
          'lastErrorMessage',
          'A critical error occurred. Please restart the app.',
        ),
      ],
    );

    blocTest<ErrorBloc, ErrorState>(
      'ErrorReported sets medium user message',
      build: () => ErrorBloc(),
      act: (bloc) => bloc.add(
        ErrorReported(
          error: Exception('hiccup'),
          severity: ErrorSeverity.medium,
        ),
      ),
      expect: () => [
        isA<ErrorState>().having(
          (s) => s.lastErrorMessage,
          'lastErrorMessage',
          'We encountered a small issue. It should resolve shortly.',
        ),
      ],
    );

    blocTest<ErrorBloc, ErrorState>(
      'ErrorReported with low severity sets null user message',
      build: () => ErrorBloc(),
      act: (bloc) => bloc.add(
        ErrorReported(error: Exception('minor'), severity: ErrorSeverity.low),
      ),
      expect: () => [
        isA<ErrorState>().having(
          (s) => s.activeErrors.first.userMessage,
          'userMessage',
          isNull,
        ),
      ],
    );

    blocTest<ErrorBloc, ErrorState>(
      'ErrorReported with string error uses string as user message',
      build: () => ErrorBloc(),
      act: (bloc) => bloc.add(
        const ErrorReported(
          error: 'Custom message',
          severity: ErrorSeverity.high,
        ),
      ),
      expect: () => [
        isA<ErrorState>().having(
          (s) => s.activeErrors.first.userMessage,
          'userMessage',
          'Custom message',
        ),
      ],
    );

    blocTest<ErrorBloc, ErrorState>(
      'ErrorReported stores stack trace and context',
      build: () => ErrorBloc(),
      act: (bloc) => bloc.add(
        ErrorReported(
          error: 'test',
          stackTrace: StackTrace.current,
          context: 'network call',
          severity: ErrorSeverity.medium,
        ),
      ),
      expect: () => [
        isA<ErrorState>()
            .having(
              (s) => s.activeErrors.first.stackTrace,
              'stackTrace',
              isNotNull,
            )
            .having(
              (s) => s.activeErrors.first.context,
              'context',
              'network call',
            ),
      ],
    );

    blocTest<ErrorBloc, ErrorState>(
      'multiple ErrorReported events accumulate in activeErrors',
      build: () => ErrorBloc(),
      act: (bloc) {
        bloc.add(
          const ErrorReported(error: 'first', severity: ErrorSeverity.low),
        );
        bloc.add(
          const ErrorReported(error: 'second', severity: ErrorSeverity.high),
        );
        bloc.add(
          const ErrorReported(error: 'third', severity: ErrorSeverity.critical),
        );
      },
      expect: () => [
        isA<ErrorState>().having(
          (s) => s.activeErrors,
          'activeErrors',
          hasLength(1),
        ),
        isA<ErrorState>().having(
          (s) => s.activeErrors,
          'activeErrors',
          hasLength(2),
        ),
        isA<ErrorState>().having(
          (s) => s.activeErrors,
          'activeErrors',
          hasLength(3),
        ),
      ],
    );

    blocTest<ErrorBloc, ErrorState>(
      'ErrorDismissed removes error by id',
      build: () => ErrorBloc(),
      seed: () => ErrorState(
        activeErrors: [
          AppError(
            id: 'err_1',
            error: 'test',
            severity: ErrorSeverity.high,
            timestamp: DateTime(2024),
          ),
          AppError(
            id: 'err_2',
            error: 'other',
            severity: ErrorSeverity.low,
            timestamp: DateTime(2024),
          ),
        ],
      ),
      act: (bloc) => bloc.add(const ErrorDismissed('err_1')),
      expect: () => [
        isA<ErrorState>()
            .having((s) => s.activeErrors, 'activeErrors', hasLength(1))
            .having((s) => s.activeErrors.first.id, 'remaining id', 'err_2'),
      ],
    );

    blocTest<ErrorBloc, ErrorState>(
      'ErrorDismissed with unknown id emits state with same active error',
      build: () => ErrorBloc(),
      seed: () => ErrorState(
        activeErrors: [
          AppError(
            id: 'err_1',
            error: 'test',
            severity: ErrorSeverity.high,
            timestamp: DateTime(2024),
          ),
        ],
      ),
      act: (bloc) => bloc.add(const ErrorDismissed('unknown_id')),
      verify: (bloc) {
        // State still has the original error since unknown_id didn't match
        expect(bloc.state.activeErrors, hasLength(1));
        expect(bloc.state.activeErrors.first.id, 'err_1');
      },
    );

    blocTest<ErrorBloc, ErrorState>(
      'ErrorsCleared empties activeErrors',
      build: () => ErrorBloc(),
      seed: () => ErrorState(
        activeErrors: [
          AppError(
            id: 'err_1',
            error: 'a',
            severity: ErrorSeverity.high,
            timestamp: DateTime(2024),
          ),
          AppError(
            id: 'err_2',
            error: 'b',
            severity: ErrorSeverity.low,
            timestamp: DateTime(2024),
          ),
        ],
      ),
      act: (bloc) => bloc.add(const ErrorsCleared()),
      expect: () => [
        isA<ErrorState>().having(
          (s) => s.activeErrors,
          'activeErrors',
          isEmpty,
        ),
      ],
    );

    blocTest<ErrorBloc, ErrorState>(
      'ErrorRecovered moves error from active to resolved',
      build: () => ErrorBloc(),
      seed: () => ErrorState(
        activeErrors: [
          AppError(
            id: 'err_1',
            error: 'recoverable',
            severity: ErrorSeverity.medium,
            timestamp: DateTime(2024),
          ),
        ],
      ),
      act: (bloc) => bloc.add(const ErrorRecovered('err_1')),
      expect: () => [
        isA<ErrorState>()
            .having((s) => s.activeErrors, 'activeErrors', isEmpty)
            .having((s) => s.resolvedErrors, 'resolvedErrors', hasLength(1))
            .having(
              (s) => s.resolvedErrors.first.isResolved,
              'isResolved',
              isTrue,
            )
            .having((s) => s.resolvedErrors.first.id, 'resolved id', 'err_1'),
      ],
    );

    blocTest<ErrorBloc, ErrorState>(
      'ErrorRecovered preserves existing resolved errors',
      build: () => ErrorBloc(),
      seed: () => ErrorState(
        activeErrors: [
          AppError(
            id: 'err_2',
            error: 'new',
            severity: ErrorSeverity.low,
            timestamp: DateTime(2024),
          ),
        ],
        resolvedErrors: [
          AppError(
            id: 'err_1',
            error: 'old',
            severity: ErrorSeverity.high,
            timestamp: DateTime(2024),
            isResolved: true,
          ),
        ],
      ),
      act: (bloc) => bloc.add(const ErrorRecovered('err_2')),
      expect: () => [
        isA<ErrorState>().having(
          (s) => s.resolvedErrors,
          'resolvedErrors',
          hasLength(2),
        ),
      ],
    );

    group('helper methods', () {
      blocTest<ErrorBloc, ErrorState>(
        'reportError dispatches ErrorReported with correct severity',
        build: () => ErrorBloc(),
        act: (bloc) => bloc.reportError(
          'test error',
          severity: ErrorSeverity.medium,
          context: 'test context',
        ),
        expect: () => [
          isA<ErrorState>()
              .having(
                (s) => s.activeErrors.first.severity,
                'severity',
                ErrorSeverity.medium,
              )
              .having(
                (s) => s.activeErrors.first.context,
                'context',
                'test context',
              ),
        ],
      );

      blocTest<ErrorBloc, ErrorState>(
        'reportNetworkError uses medium severity',
        build: () => ErrorBloc(),
        act: (bloc) => bloc.reportNetworkError(Exception('timeout')),
        expect: () => [
          isA<ErrorState>().having(
            (s) => s.activeErrors.first.severity,
            'severity',
            ErrorSeverity.medium,
          ),
        ],
      );

      blocTest<ErrorBloc, ErrorState>(
        'reportNetworkError uses default context when not provided',
        build: () => ErrorBloc(),
        act: (bloc) => bloc.reportNetworkError(Exception('timeout')),
        expect: () => [
          isA<ErrorState>().having(
            (s) => s.activeErrors.first.context,
            'context',
            'Network request failed',
          ),
        ],
      );

      blocTest<ErrorBloc, ErrorState>(
        'reportValidationError uses low severity with string message',
        build: () => ErrorBloc(),
        act: (bloc) => bloc.reportValidationError('Field required'),
        expect: () => [
          isA<ErrorState>()
              .having(
                (s) => s.activeErrors.first.severity,
                'severity',
                ErrorSeverity.low,
              )
              .having(
                (s) => s.activeErrors.first.error,
                'error',
                'Field required',
              ),
        ],
      );

      blocTest<ErrorBloc, ErrorState>(
        'reportUnexpectedError uses high severity',
        build: () => ErrorBloc(),
        act: (bloc) => bloc.reportUnexpectedError(Exception('crash')),
        expect: () => [
          isA<ErrorState>()
              .having(
                (s) => s.activeErrors.first.severity,
                'severity',
                ErrorSeverity.high,
              )
              .having(
                (s) => s.activeErrors.first.context,
                'context',
                'Unexpected error',
              ),
        ],
      );
    });
  });
}
