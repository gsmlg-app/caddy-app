import 'package:app_locale/app_locale.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caddy_app/screens/caddy/caddy_config_screen.dart';

class MockCaddyService extends CaddyService {
  MockCaddyService() : super.forTesting();

  @override
  Future<CaddyStatus> start(
    CaddyConfig config, {
    bool adminEnabled = false,
    Map<String, String> environment = const {},
  }) async =>
      CaddyRunning(config: '{}', startedAt: DateTime.now());

  @override
  Future<CaddyStatus> stop() async => const CaddyStopped();

  @override
  Future<CaddyStatus> reload(
    CaddyConfig config, {
    bool adminEnabled = false,
    Map<String, String> environment = const {},
  }) async =>
      CaddyRunning(config: '{}', startedAt: DateTime.now());

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
      child: const CaddyConfigScreen(),
    ),
  );
}

void main() {
  group('CaddyConfigScreen', () {
    testWidgets('renders correctly with tabs', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CaddyConfigScreen), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('shows simple config form by default', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows listen address field with default value', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'localhost:2015');
    });

    testWidgets('shows save and apply buttons', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });

    testWidgets('shows validate button', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Validate'), findsOneWidget);
    });

    testWidgets('shows preset menu button', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.snippet_folder), findsOneWidget);
    });

    testWidgets('shows add route button', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('switching to raw JSON tab shows text editor', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Raw JSON'));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsOneWidget);
    });

    testWidgets('validate button shows success for valid config', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Validate'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('save updates bloc config', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'localhost:9090');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(bloc.state.config.listenAddress, 'localhost:9090');
      bloc.close();
    });

    testWidgets('shows save as button', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save_as), findsOneWidget);
    });

    testWidgets('save as button opens name dialog', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save_as));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Save As'), findsOneWidget);
    });
  });
}
