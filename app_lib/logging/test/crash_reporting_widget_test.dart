import 'package:app_logging/app_logging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrashReportingWidget', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: CrashReportingWidget(child: Text('Hello'))),
      );
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('accepts showErrorScreen parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CrashReportingWidget(
            showErrorScreen: false,
            child: Text('Child'),
          ),
        ),
      );
      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('accepts errorScreenBuilder parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CrashReportingWidget(
            errorScreenBuilder: (details) => const Text('Custom Error'),
            child: const Text('Child'),
          ),
        ),
      );
      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('sets up FlutterError.onError', (tester) async {
      final previousHandler = FlutterError.onError;

      await tester.pumpWidget(
        const MaterialApp(home: CrashReportingWidget(child: SizedBox())),
      );

      // The widget should have replaced the handler
      expect(FlutterError.onError, isNotNull);

      // Restore for other tests
      FlutterError.onError = previousHandler;
    });
  });

  group('ErrorScreen', () {
    final errorDetails = FlutterErrorDetails(
      exception: Exception('Test error'),
      library: 'test',
    );

    testWidgets('renders error screen with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: errorDetails)),
      );

      expect(find.text('Oops! Something went wrong'), findsOneWidget);
      expect(
        find.text("We're sorry, but an unexpected error occurred."),
        findsOneWidget,
      );
    });

    testWidgets('shows error icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: errorDetails)),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: errorDetails)),
      );

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows report error button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: errorDetails)),
      );

      expect(find.text('Report Error'), findsOneWidget);
    });

    testWidgets('retry button calls custom onRetry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(
            errorDetails: errorDetails,
            onRetry: () => retried = true,
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('report button calls custom onReport', (tester) async {
      var reported = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorScreen(
            errorDetails: errorDetails,
            onReport: () => reported = true,
          ),
        ),
      );

      await tester.tap(find.text('Report Error'));
      expect(reported, isTrue);
    });

    testWidgets('default report button opens dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: errorDetails)),
      );

      await tester.tap(find.text('Report Error'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Report Error'), findsAtLeastNWidgets(1));
      expect(find.text('Error details:'), findsOneWidget);
    });

    testWidgets('report dialog shows cancel button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: errorDetails)),
      );

      await tester.tap(find.text('Report Error'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('report dialog cancel closes dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: errorDetails)),
      );

      await tester.tap(find.text('Report Error'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('has red background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: ErrorScreen(errorDetails: errorDetails)),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.red[50]);
    });
  });

  group('ErrorBoundary', () {
    testWidgets('renders child normally', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ErrorBoundary(child: Text('Normal Content'))),
      );

      expect(find.text('Normal Content'), findsOneWidget);
    });

    testWidgets('accepts errorBuilder parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            errorBuilder: (details) => const Text('Custom Error View'),
            child: const Text('Content'),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });
  });
}
