import 'package:app_locale/app_locale.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caddy_app/screens/home/home_screen.dart';

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
      child: const HomeScreen(),
    ),
  );
}

void main() {
  group('HomeScreen', () {
    testWidgets('renders correctly with basic components', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SafeArea), findsAtLeastNWidgets(1));
      expect(find.byType(ListView), findsAtLeastNWidgets(1));
    });

    testWidgets('displays welcome text', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.text('Welcome to Caddy App'), findsOneWidget);
    });

    testWidgets('displays server status card', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.text('Server Status'), findsOneWidget);
    });

    testWidgets('displays quick actions section', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('displays 4 quick action cards', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.text('Server'), findsOneWidget);
      expect(find.text('Config'), findsOneWidget);
      expect(find.text('Logs'), findsOneWidget);
      expect(find.text('Secrets'), findsOneWidget);
    });

    testWidgets('shows stopped status chip initially', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.text('Stopped'), findsOneWidget);
    });

    testWidgets('shows start button when stopped', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.text('Start'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows running status with details', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState(
          status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
          config: const CaddyConfig(
            listenAddress: ':8080',
            routes: [
              CaddyRoute(
                path: '/api',
                handler: ReverseProxyHandler(upstreams: ['localhost:3000']),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pump();

      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Listen: :8080'), findsOneWidget);
      expect(find.textContaining('1 active routes'), findsOneWidget);
    });

    testWidgets('shows error status with message', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.emit(
        CaddyState(
          status: const CaddyError(message: 'port in use'),
          config: const CaddyConfig(),
        ),
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pump();

      expect(find.text('Error'), findsOneWidget);
      expect(find.text('port in use'), findsOneWidget);
    });

    testWidgets('has correct static name and path', (tester) async {
      expect(HomeScreen.name, 'Home Screen');
      expect(HomeScreen.path, '/home');
    });

    testWidgets('handles landscape orientation', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('quick action icons are present', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.dns), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.settings_applications), findsOneWidget);
      expect(find.byIcon(Icons.article), findsOneWidget);
      expect(find.byIcon(Icons.vpn_key), findsOneWidget);
    });

    testWidgets('GridView uses 2 columns', (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pump();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });
  });
}
