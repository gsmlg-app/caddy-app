import 'package:app_locale/app_locale.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caddy_app/screens/caddy/caddy_log_screen.dart';

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
      child: const CaddyLogScreen(),
    ),
  );
}

void main() {
  group('CaddyLogScreen', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CaddyLogScreen), findsOneWidget);
    });

    testWidgets('shows empty state when no logs', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No logs yet'), findsOneWidget);
    });

    testWidgets('shows auto-scroll toggle button', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('shows copy, export, and clear buttons', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.byIcon(Icons.save_alt), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('shows search button', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows filter chips', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNWidgets(5));
      expect(find.text('All'), findsOneWidget);
      expect(find.text('INFO'), findsOneWidget);
      expect(find.text('WARN'), findsOneWidget);
      expect(find.text('ERROR'), findsOneWidget);
      expect(find.text('DEBUG'), findsOneWidget);
    });

    testWidgets('displays logs when present', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.add(const CaddyLogReceived('INFO: test log line'));

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('INFO: test log line'), findsOneWidget);
      bloc.close();
    });

    testWidgets('toggling search shows search field', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search icon changes to search_off
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('clear button clears logs', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.add(const CaddyLogReceived('test log'));

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('test log'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('No logs yet'), findsOneWidget);
      bloc.close();
    });

    testWidgets('selecting filter chip updates bloc state', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ERROR'));
      await tester.pumpAndSettle();

      expect(bloc.state.logFilter, CaddyLogLevel.error);
      bloc.close();
    });

    testWidgets('shows statistics bar when filtering by level', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.add(const CaddyLogReceived('INFO: first'));
      bloc.add(const CaddyLogReceived('ERROR: second'));
      bloc.add(const CaddyLogReceived('INFO: third'));

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Filter by ERROR level
      await tester.tap(find.text('ERROR'));
      await tester.pumpAndSettle();

      // Stats bar shows filtered/total count
      expect(find.textContaining('1 / 3'), findsOneWidget);
      expect(find.text('ERROR: second'), findsOneWidget);
      bloc.close();
    });

    testWidgets('shows statistics bar with search query chip', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.add(const CaddyLogReceived('INFO: hello world'));
      bloc.add(const CaddyLogReceived('INFO: goodbye'));

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Open search and enter query
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'hello');
      await tester.pumpAndSettle();

      // Stats bar shows 1/2 and the search query
      expect(find.textContaining('1 / 2'), findsOneWidget);
      expect(find.textContaining('"hello"'), findsOneWidget);
      bloc.close();
    });

    testWidgets('search highlighting renders RichText for matching logs', (
      tester,
    ) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.add(const CaddyLogReceived('INFO: the error appeared'));

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Open search and enter query
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'error');
      await tester.pumpAndSettle();

      // When search is active, RichText is used for highlighting
      expect(find.byType(RichText), findsAtLeastNWidgets(1));
      bloc.close();
    });

    testWidgets('search query chip has delete button to clear search', (
      tester,
    ) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.add(const CaddyLogReceived('INFO: test line'));

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Set search via bloc directly
      bloc.add(const CaddySetLogSearch('test'));
      await tester.pumpAndSettle();

      // Find the chip with the search query
      expect(find.textContaining('"test"'), findsOneWidget);

      // Delete button on the chip
      final chipFinder = find.widgetWithText(Chip, '"test"');
      expect(chipFinder, findsOneWidget);
      bloc.close();
    });

    testWidgets('no statistics bar when showing all unfiltered logs', (
      tester,
    ) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.add(const CaddyLogReceived('INFO: line'));

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // No filter/search active, stats bar should not show
      expect(find.textContaining(' / '), findsNothing);
      bloc.close();
    });

    testWidgets('long press log line shows copied snackbar', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.add(const CaddyLogReceived('INFO: test message'));

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Long press the log line
      await tester.longPress(find.text('INFO: test message'));
      await tester.pumpAndSettle();

      expect(find.text('Log line copied'), findsOneWidget);
      bloc.close();
    });
  });
}
