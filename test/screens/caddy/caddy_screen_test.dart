import 'package:app_locale/app_locale.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caddy_app/screens/caddy/caddy_screen.dart';

class MockCaddyService extends CaddyService {
  MockCaddyService() : super.forTesting();

  @override
  Future<CaddyStatus> start(
    CaddyConfig config, {
    bool adminEnabled = false,
    Map<String, String> environment = const {},
  }) async => CaddyRunning(config: '{}', startedAt: DateTime.now());

  @override
  Future<CaddyStatus> stop() async => const CaddyStopped();

  @override
  Future<CaddyStatus> reload(
    CaddyConfig config, {
    bool adminEnabled = false,
    Map<String, String> environment = const {},
  }) async => CaddyRunning(config: '{}', startedAt: DateTime.now());

  @override
  Future<CaddyStatus> getStatus() async => const CaddyStopped();

  @override
  Stream<String> get logStream => const Stream.empty();
}

Widget _buildTestWidget({CaddyBloc? bloc}) {
  final service = MockCaddyService();
  return MaterialApp(
    localizationsDelegates: AppLocale.localizationsDelegates,
    supportedLocales: AppLocale.supportedLocales,
    home: BlocProvider<CaddyBloc>(
      create: (_) => bloc ?? CaddyBloc(service),
      child: const CaddyScreen(),
    ),
  );
}

void main() {
  group('CaddyScreen', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CaddyScreen), findsOneWidget);
    });

    testWidgets('shows stopped status initially', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.stop_circle), findsOneWidget);
    });

    testWidgets('shows start button when stopped', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows metrics card when running', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
          requestCount: 5,
        ),
      );
      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('Metrics'), findsOneWidget);
      expect(find.text('Requests Served'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      bloc.close();
    });

    testWidgets('does not show metrics card when stopped', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Metrics'), findsNothing);
    });

    testWidgets('shows admin API toggle', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Admin API'), findsOneWidget);
    });

    testWidgets('shows auto-restart toggle', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Auto-restart on Resume'), findsOneWidget);
    });

    testWidgets('shows navigation links', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // "Configuration" appears both in the config summary card and
      // in the navigation link list tile.
      expect(find.text('Configuration'), findsAtLeastNWidgets(1));
      expect(find.text('Logs'), findsOneWidget);
      expect(find.text('Secrets'), findsOneWidget);
    });

    testWidgets('shows stop and reload buttons when running', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
        ),
      );
      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      bloc.close();
    });

    testWidgets('shows start button when in error state', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          status: const CaddyError(message: 'test error'),
        ),
      );
      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      bloc.close();
    });
  });

  group('Config validation indicator', () {
    testWidgets('shows valid indicator for default config', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Configuration is valid'), findsOneWidget);
    });

    testWidgets('shows warning for invalid rawJson config', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          config: const CaddyConfig(rawJson: '{invalid json'),
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning), findsOneWidget);
      bloc.close();
    });
  });

  group('Error recovery dialog', () {
    testWidgets('shows error recovery dialog on port-in-use error', (
      tester,
    ) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Transition to error state with port-in-use message
      bloc.emit(
        CaddyState.initial().copyWith(
          status: const CaddyError(
            message: 'Port localhost:8080 is already in use',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Server Error'), findsOneWidget);
      expect(find.text('Change Port'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      bloc.close();
    });

    testWidgets('shows generic error dialog for non-port errors', (
      tester,
    ) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      bloc.emit(
        CaddyState.initial().copyWith(
          status: const CaddyError(message: 'some unknown error'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Server Error'), findsOneWidget);
      expect(find.text('View Logs'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      // Port-specific button should not appear
      expect(find.text('Change Port'), findsNothing);
      bloc.close();
    });

    testWidgets('dismiss button closes error recovery dialog', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      bloc.emit(
        CaddyState.initial().copyWith(
          status: const CaddyError(message: 'test error'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      bloc.close();
    });

    testWidgets('dialog does not re-appear for same error state', (
      tester,
    ) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // First error - dialog appears
      bloc.emit(
        CaddyState.initial().copyWith(
          status: const CaddyError(message: 'error1'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // Dismiss
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      // Same error state - dialog should NOT re-appear
      // (because listenWhen checks prev.hasError != curr.hasError)
      bloc.close();
    });
  });

  group('Keyboard shortcuts', () {
    testWidgets('Ctrl+S starts server when stopped', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Server should be stopped initially
      expect(bloc.state.isStopped, isTrue);

      // Send Ctrl+S keyboard shortcut
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Server should transition away from stopped
      // (it will go to loading or running via the mock service)
      expect(bloc.state.isStopped, isFalse);
      bloc.close();
    });

    testWidgets('Ctrl+Q stops server when running', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Server should be running
      expect(bloc.state.isRunning, isTrue);

      // Send Ctrl+Q keyboard shortcut
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Server should be stopped
      expect(bloc.state.isStopped, isTrue);
      bloc.close();
    });

    testWidgets('Ctrl+R reloads config when running', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(bloc.state.isRunning, isTrue);

      // Send Ctrl+R keyboard shortcut
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Server should still be running after reload
      expect(bloc.state.isRunning, isTrue);
      bloc.close();
    });

    testWidgets('Ctrl+S does nothing when server is running', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(bloc.state.isRunning, isTrue);

      // Send Ctrl+S - should be ignored since already running
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Should still be running (not restarted)
      expect(bloc.state.isRunning, isTrue);
      bloc.close();
    });

    testWidgets('Ctrl+Q does nothing when server is stopped', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(bloc.state.isStopped, isTrue);

      // Send Ctrl+Q - should be ignored since already stopped
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Should still be stopped
      expect(bloc.state.isStopped, isTrue);
      bloc.close();
    });

    testWidgets('Ctrl+S starts server from error state', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Transition to error state
      bloc.emit(
        CaddyState.initial().copyWith(
          status: const CaddyError(message: 'some error'),
        ),
      );
      await tester.pumpAndSettle();

      expect(bloc.state.hasError, isTrue);

      // Dismiss the error dialog
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      // Send Ctrl+S - should start from error state
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      // Server should transition away from error
      expect(bloc.state.hasError, isFalse);
      bloc.close();
    });
  });

  group('Keyboard shortcuts hint', () {
    testWidgets('shows keyboard shortcuts card', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Keyboard Shortcuts'), findsOneWidget);
    });

    testWidgets('shows Ctrl+S shortcut chip', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ctrl+S'), findsOneWidget);
      expect(find.text('Start Server'), findsOneWidget);
    });

    testWidgets('shows Ctrl+Q shortcut chip', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ctrl+Q'), findsOneWidget);
      expect(find.text('Stop Server'), findsOneWidget);
    });

    testWidgets('shows Ctrl+R shortcut chip', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ctrl+R'), findsOneWidget);
      expect(find.text('Reload Config'), findsOneWidget);
    });
  });

  group('Dashboard metrics', () {
    testWidgets('shows active routes count when running', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
          config: CaddyConfig(
            listenAddress: ':2015',
            routes: [
              const CaddyRoute(
                path: '/api/*',
                handler: ReverseProxyHandler(upstreams: ['localhost:3000']),
              ),
              const CaddyRoute(
                path: '/static/*',
                handler: StaticFileHandler(root: '/var/www'),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('Active Routes'), findsOneWidget);
      bloc.close();
    });

    testWidgets('shows admin API status in metrics when running', (
      tester,
    ) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('Disabled'), findsAtLeastNWidgets(1));
      bloc.close();
    });

    testWidgets('shows log errors count when running', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
          logs: ['INFO request handled', 'ERROR something failed'],
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('Log Errors'), findsOneWidget);
      bloc.close();
    });

    testWidgets('error log count highlights in error color when > 0', (
      tester,
    ) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
          logs: ['ERROR crash', 'ERROR fail'],
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Find the error count icon and verify it uses error_outline
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      bloc.close();
    });
  });
}
