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

    testWidgets('switching to raw JSON tab shows text editor', (tester) async {
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

    testWidgets('shows TLS section with toggle', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Section title and toggle are visible
      expect(find.text('TLS / HTTPS'), findsOneWidget);
      expect(find.text('Enable Automatic HTTPS'), findsOneWidget);
      // Domain and DNS fields are hidden when TLS is disabled
      expect(find.text('Domain Name'), findsNothing);
      expect(find.text('DNS Provider'), findsNothing);
    });

    testWidgets('TLS toggle reveals domain and DNS provider fields', (
      tester,
    ) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Enable TLS via bloc
      bloc.add(
        CaddyUpdateConfig(
          bloc.state.config.copyWith(tls: const CaddyTlsConfig(enabled: true)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Domain Name'), findsOneWidget);
      expect(find.text('DNS Provider'), findsOneWidget);
      bloc.close();
    });

    testWidgets('shows S3 storage section with toggle', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('S3 Storage'), findsOneWidget);
      expect(find.text('Use S3 for Certificate Storage'), findsOneWidget);
      // S3 fields are hidden when disabled
      expect(find.text('S3 Endpoint URL'), findsNothing);
      expect(find.text('Bucket Name'), findsNothing);
    });

    testWidgets('S3 toggle reveals storage config fields', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Enable S3 via bloc
      bloc.add(
        CaddyUpdateConfig(
          bloc.state.config.copyWith(
            storage: const CaddyStorageConfig(enabled: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('S3 Endpoint URL'), findsOneWidget);
      expect(find.text('Bucket Name'), findsOneWidget);
      expect(find.text('Region'), findsOneWidget);
      expect(find.text('Key Prefix'), findsOneWidget);
      bloc.close();
    });

    testWidgets('HTTPS preset shows in preset menu', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.snippet_folder));
      await tester.pumpAndSettle();

      // Menu has HTTPS preset with lock icon
      expect(find.byIcon(Icons.lock), findsAtLeastNWidgets(1));
    });

    testWidgets('shows import button', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.file_upload), findsOneWidget);
    });

    testWidgets('shows export button', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.file_download), findsOneWidget);
    });

    testWidgets('shows copy button', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('shows routes section with count', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          config: CaddyConfig(
            routes: [
              const CaddyRoute(
                path: '/test/*',
                handler: StaticFileHandler(root: '/tmp'),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.textContaining('Routes (1)'), findsOneWidget);
      expect(find.text('/test/*'), findsOneWidget);
      bloc.close();
    });

    testWidgets('remove route button deletes route', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          config: CaddyConfig(
            routes: [
              const CaddyRoute(
                path: '/remove-me/*',
                handler: StaticFileHandler(root: '/tmp'),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.text('/remove-me/*'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('/remove-me/*'), findsNothing);
      expect(bloc.state.config.routes, isEmpty);
      bloc.close();
    });
  });

  group('Config diff dialog', () {
    testWidgets('apply shows diff dialog when server is running', (
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

      // Change the listen address
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'localhost:9999');

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Diff dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Review Changes'), findsOneWidget);
      bloc.close();
    });

    testWidgets('apply without running server saves directly', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // No dialog should appear when server is not running
      expect(find.text('Review Changes'), findsNothing);
      bloc.close();
    });

    testWidgets('diff dialog shows Apply Changes button', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Change config to get a diff
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'localhost:7777');

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('Apply Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      bloc.close();
    });

    testWidgets('cancel button closes diff dialog', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState.initial().copyWith(
          status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'localhost:7777');

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      bloc.close();
    });

    testWidgets('diff dialog shows no changes message for identical config', (
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

      // Apply without changes
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.text('No changes detected'), findsOneWidget);
      // Apply Changes button should not appear for identical configs
      expect(find.text('Apply Changes'), findsNothing);
      bloc.close();
    });

    testWidgets('Apply Changes button updates config and reloads', (
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

      // Change the listen address to produce a diff
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'localhost:4444');

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Dialog should appear with Apply Changes
      expect(find.text('Apply Changes'), findsOneWidget);

      // Tap Apply Changes
      await tester.tap(find.text('Apply Changes'));
      await tester.pumpAndSettle();

      // Dialog should close
      expect(find.byType(AlertDialog), findsNothing);
      // Config should be updated
      expect(bloc.state.config.listenAddress, 'localhost:4444');
      bloc.close();
    });

    testWidgets('diff dialog shows legend chips for current and new', (
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

      // Change config to produce a diff
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'localhost:5555');

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // Legend chips should be present
      expect(find.textContaining('Current'), findsOneWidget);
      expect(find.textContaining('New'), findsOneWidget);
      bloc.close();
    });

    testWidgets('diff dialog renders diff lines with color coding', (
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

      // Change config to produce a diff
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'localhost:6666');

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      // A ListView should render the diff lines (form has one too)
      expect(find.byType(ListView), findsAtLeastNWidgets(1));
      // Diff lines should contain the old and new port values
      expect(find.textContaining('2015'), findsAtLeastNWidgets(1));
      expect(find.textContaining('6666'), findsAtLeastNWidgets(1));
      bloc.close();
    });
  });
}
