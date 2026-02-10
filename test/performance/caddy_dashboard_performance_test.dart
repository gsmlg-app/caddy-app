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
  group('CaddyScreen Performance', () {
    testWidgets('dashboard renders efficiently with running server', (
      tester,
    ) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.add(CaddyStart(const CaddyConfig()));
      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Measure rebuild performance
      final stopwatch = Stopwatch()..start();
      await tester.pump();
      stopwatch.stop();

      // Rebuilds should be fast (< 16ms for 60fps)
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(16),
        reason: 'Dashboard rebuild should be under 16ms for smooth 60fps',
      );
    });

    testWidgets('handles many log entries efficiently', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);

      // Measure performance of adding many log entries
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 1000; i++) {
        bloc.add(CaddyLogReceived('[INFO] Log entry $i'));
      }
      stopwatch.stop();

      // Adding logs should be fast (< 100ms for 1000 entries)
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'Adding 1000 log entries should be under 100ms',
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();
    });

    testWidgets('state transitions are efficient', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Measure state transition performance
      final stopwatch = Stopwatch()..start();
      bloc.add(CaddyStart(const CaddyConfig()));
      await tester.pump();
      await tester.pump();
      stopwatch.stop();

      // State transition should be fast
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(100),
        reason: 'State transition should be under 100ms',
      );
    });

    testWidgets('uptime counter updates efficiently', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);
      bloc.add(CaddyStart(const CaddyConfig()));

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Measure timer-based rebuild performance
      final stopwatch = Stopwatch()..start();
      await tester.pump(const Duration(seconds: 1));
      stopwatch.stop();

      // Timer update should be efficient
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(16),
        reason: 'Uptime update should be under 16ms',
      );
    });

    testWidgets('handles large configs efficiently', (tester) async {
      final service = MockCaddyService();
      final bloc = CaddyBloc(service);

      // Create large config with many routes
      final routes = List.generate(
        100,
        (i) => CaddyRoute(
          path: '/route$i/*',
          handler: const StaticFileHandler(root: '.'),
        ),
      );
      final config = CaddyConfig(routes: routes);

      // Measure performance of updating large config
      final stopwatch = Stopwatch()..start();
      bloc.add(CaddyUpdateConfig(config));
      stopwatch.stop();

      // Config update should be fast
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(50),
        reason: 'Updating config with 100 routes should be under 50ms',
      );

      await tester.pumpWidget(_buildTestWidget(bloc: bloc));
      await tester.pumpAndSettle();

      // Verify config was updated
      expect(bloc.state.config.routes.length, 100);
    });
  });
}
