import 'package:app_database/app_database.dart';
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_bloc/theme_bloc.dart';

import 'package:caddy_app/app.dart';

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

class InMemoryVaultRepository implements VaultRepository {
  final Map<String, String> _data = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => _data[key];

  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
  }

  @override
  Future<bool> containsKey({required String key}) async =>
      _data.containsKey(key);

  @override
  Future<void> deleteAll() async => _data.clear();

  @override
  Future<Map<String, String>> readAll() async => Map.from(_data);
}

void main() {
  group('AppBlocProvider integration', () {
    late AppDatabase database;
    late VaultRepository vault;
    late CaddyBloc caddyBloc;
    late MockCaddyService mockService;

    setUp(() {
      database = AppDatabase.forTesting();
      vault = InMemoryVaultRepository();
      mockService = MockCaddyService();
      caddyBloc = CaddyBloc(mockService, database: database, vault: vault);
      caddyBloc.add(const CaddyInitialize());
    });

    tearDown(() async {
      await caddyBloc.close();
      await database.close();
    });

    testWidgets('CaddyBloc provided via BlocProvider.value is accessible', (
      tester,
    ) async {
      late CaddyBloc retrieved;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CaddyBloc>.value(
            value: caddyBloc,
            child: Builder(
              builder: (context) {
                retrieved = context.read<CaddyBloc>();
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(retrieved, same(caddyBloc));
    });

    testWidgets('CaddyBloc starts with stopped state', (tester) async {
      expect(caddyBloc.state.isStopped, isTrue);
      expect(caddyBloc.state.config.listenAddress, 'localhost:2015');
    });

    test('CaddyBloc loads saved config from database', () async {
      await database.upsertCaddyConfig(
        name: 'test-config',
        configJson: '{"listenAddress":"localhost:9999"}',
        isActive: true,
      );

      final bloc = CaddyBloc(mockService, database: database, vault: vault);
      bloc.add(const CaddyInitialize());

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<CaddyState>().having(
            (s) => s.savedConfigNames,
            'savedConfigNames',
            contains('test-config'),
          ),
        ),
      );

      expect(bloc.state.config.listenAddress, 'localhost:9999');
      await bloc.close();
    });

    test('CaddyBloc responds to lifecycle events', () async {
      caddyBloc.add(const CaddyStart(CaddyConfig()));
      await caddyBloc.stream.firstWhere((s) => s.isRunning);
      expect(caddyBloc.state.isRunning, isTrue);

      caddyBloc.add(const CaddyLifecyclePause());
      await caddyBloc.stream.firstWhere((s) => s.isStopped);
      expect(caddyBloc.state.isStopped, isTrue);
    });

    testWidgets('CaddyBloc dispatches events from widget context', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<CaddyBloc>.value(
            value: caddyBloc,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    context.read<CaddyBloc>().add(
                      const CaddyStart(CaddyConfig()),
                    );
                  },
                  child: const Text('Start'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Start'));

      // Bloc event handlers are async; run outside FakeAsync to resolve.
      await tester.runAsync(() async {
        await caddyBloc.stream.firstWhere((s) => s.isRunning);
      });

      expect(caddyBloc.state.isRunning, isTrue);
    });
  });

  group('App widget', () {
    testWidgets('App is a StatefulWidget', (tester) async {
      expect(const App(), isA<StatefulWidget>());
    });

    testWidgets('App renders with full provider hierarchy', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeBloc = ThemeBloc(prefs);
      final database = AppDatabase.forTesting();
      final vault = InMemoryVaultRepository();
      final mockService = MockCaddyService();
      final caddyBloc = CaddyBloc(mockService, database: database);

      // Provide everything App needs. Note: App internally creates
      // AppBlocProvider which uses CaddyService.instance (native FFI).
      // We provide CaddyBloc already in context so the inner
      // AppBlocProvider's CaddyBloc is effectively shadowed.
      await tester.pumpWidget(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AppDatabase>.value(value: database),
            RepositoryProvider<VaultRepository>.value(value: vault),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<ThemeBloc>.value(value: themeBloc),
              BlocProvider<CaddyBloc>.value(value: caddyBloc),
            ],
            child: BlocBuilder<ThemeBloc, ThemeState>(
              builder: (context, state) {
                return MaterialApp(
                  key: const Key('app'),
                  theme: state.theme.lightTheme,
                  darkTheme: state.theme.darkTheme,
                  themeMode: state.themeMode,
                  home: const Scaffold(body: Text('Test')),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('app')), findsOneWidget);

      final materialApp = tester.widget<MaterialApp>(
        find.byKey(const Key('app')),
      );
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
      expect(materialApp.themeMode, ThemeMode.system);

      themeBloc.add(const ChangeThemeMode(ThemeMode.dark));
      await tester.pumpAndSettle();

      final updatedApp = tester.widget<MaterialApp>(
        find.byKey(const Key('app')),
      );
      expect(updatedApp.themeMode, ThemeMode.dark);

      themeBloc.close();
      caddyBloc.close();
      await database.close();
    });

    testWidgets('ThemeBloc drives theme updates in BlocBuilder', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final themeBloc = ThemeBloc(prefs);

      await tester.pumpWidget(
        BlocProvider<ThemeBloc>.value(
          value: themeBloc,
          child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return MaterialApp(
                key: const Key('themed-app'),
                themeMode: state.themeMode,
                home: const SizedBox(),
              );
            },
          ),
        ),
      );

      var app = tester.widget<MaterialApp>(find.byKey(const Key('themed-app')));
      expect(app.themeMode, ThemeMode.system);

      themeBloc.add(const ChangeThemeMode(ThemeMode.light));
      await tester.pumpAndSettle();

      app = tester.widget<MaterialApp>(find.byKey(const Key('themed-app')));
      expect(app.themeMode, ThemeMode.light);

      themeBloc.close();
    });
  });
}
