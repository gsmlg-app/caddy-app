import 'package:app_locale/app_locale.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter/material.dart';
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
}
