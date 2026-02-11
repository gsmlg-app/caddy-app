import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildTestApp({required Widget child}) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('ErrorSeverity', () {
    test('has 4 values', () {
      expect(ErrorSeverity.values, hasLength(4));
    });

    test('values are ordered', () {
      expect(ErrorSeverity.low.index, 0);
      expect(ErrorSeverity.medium.index, 1);
      expect(ErrorSeverity.high.index, 2);
      expect(ErrorSeverity.critical.index, 3);
    });
  });

  group('ErrorDisplay', () {
    group('low severity', () {
      testWidgets('shows snackbar with message', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.showError(
                  context,
                  'Low error',
                  severity: ErrorSeverity.low,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        expect(find.text('Low error'), findsOneWidget);
      });

      testWidgets('shows DISMISS action without onRetry', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.showError(
                  context,
                  'Error',
                  severity: ErrorSeverity.low,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        expect(find.text('DISMISS'), findsOneWidget);
      });

      testWidgets('shows RETRY action with onRetry callback', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.showError(
                  context,
                  'Error',
                  severity: ErrorSeverity.low,
                  onRetry: () {},
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        expect(find.text('RETRY'), findsOneWidget);
      });
    });

    group('medium severity', () {
      testWidgets('shows snackbar with message', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () =>
                    ErrorDisplay.showError(context, 'Medium error'),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        expect(find.text('Medium error'), findsOneWidget);
      });
    });

    group('high severity', () {
      testWidgets('shows dialog with message', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.showError(
                  context,
                  'High error',
                  severity: ErrorSeverity.high,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Error'), findsOneWidget);
        expect(find.text('High error'), findsOneWidget);
      });

      testWidgets('shows OK button to dismiss', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.showError(
                  context,
                  'Error',
                  severity: ErrorSeverity.high,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('OK'), findsOneWidget);
      });

      testWidgets('shows RETRY button when onRetry provided', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.showError(
                  context,
                  'Error',
                  severity: ErrorSeverity.high,
                  onRetry: () {},
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('RETRY'), findsOneWidget);
      });

      testWidgets('OK dismisses dialog', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.showError(
                  context,
                  'Error',
                  severity: ErrorSeverity.high,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
      });
    });

    group('critical severity', () {
      testWidgets('shows critical error dialog', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.showError(
                  context,
                  'Critical error',
                  severity: ErrorSeverity.critical,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Critical Error'), findsOneWidget);
        expect(find.text('Critical error'), findsOneWidget);
      });

      testWidgets('shows restart message', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.showError(
                  context,
                  'Fatal',
                  severity: ErrorSeverity.critical,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(
          find.text('The app needs to restart to recover.'),
          findsOneWidget,
        );
      });

      testWidgets('shows error icon', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.showError(
                  context,
                  'Fatal',
                  severity: ErrorSeverity.critical,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('shows RESTART APP with onRetry', (tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => ErrorDisplay.showError(
                  context,
                  'Fatal',
                  severity: ErrorSeverity.critical,
                  onRetry: () {},
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('RESTART APP'), findsOneWidget);
      });
    });
  });
}
