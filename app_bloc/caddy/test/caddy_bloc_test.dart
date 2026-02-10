import 'dart:convert';

import 'package:app_database/app_database.dart';
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:caddy_bloc/caddy_bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:flutter_test/flutter_test.dart';

class MockCaddyService extends CaddyService {
  MockCaddyService() : super.forTesting();

  CaddyStatus startResult = CaddyRunning(
    config: '{}',
    startedAt: DateTime(2024),
  );
  CaddyStatus stopResult = const CaddyStopped();
  CaddyStatus reloadResult = CaddyRunning(
    config: '{}',
    startedAt: DateTime(2024),
  );
  CaddyStatus statusResult = const CaddyStopped();

  /// Captures the environment passed to start/reload for verification.
  Map<String, String> lastEnvironment = {};

  /// Tracks whether stop was called (for crash recovery tests).
  bool stopCalled = false;

  @override
  Future<CaddyStatus> start(
    CaddyConfig config, {
    bool adminEnabled = false,
    Map<String, String> environment = const {},
  }) async {
    lastEnvironment = environment;
    return startResult;
  }

  @override
  Future<CaddyStatus> stop() async {
    stopCalled = true;
    return stopResult;
  }

  @override
  Future<CaddyStatus> reload(
    CaddyConfig config, {
    bool adminEnabled = false,
    Map<String, String> environment = const {},
  }) async {
    lastEnvironment = environment;
    return reloadResult;
  }

  @override
  Future<CaddyStatus> getStatus() async => statusResult;

  @override
  Stream<String> get logStream => const Stream.empty();
}

class MockVaultRepository implements VaultRepository {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _store[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => _store[key];

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<bool> containsKey({required String key}) async =>
      _store.containsKey(key);

  @override
  Future<void> deleteAll() async => _store.clear();

  @override
  Future<Map<String, String>> readAll() async => Map.of(_store);
}

void main() {
  late MockCaddyService mockService;

  setUp(() {
    mockService = MockCaddyService();
  });

  group('CaddyBloc', () {
    test('initial state is CaddyStopped with default config', () {
      final bloc = CaddyBloc(mockService);
      expect(bloc.state.isStopped, isTrue);
      expect(bloc.state.config.listenAddress, 'localhost:2015');
      expect(bloc.state.logs, isEmpty);
      expect(bloc.state.adminEnabled, isFalse);
      expect(bloc.state.logFilter, CaddyLogLevel.all);
      expect(bloc.state.logSearchQuery, isEmpty);
      bloc.close();
    });

    blocTest<CaddyBloc, CaddyState>(
      'CaddyStart emits loading then running',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddyStart(CaddyConfig())),
      expect: () => [
        isA<CaddyState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CaddyState>().having((s) => s.isRunning, 'isRunning', true),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyStop emits loading then stopped',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddyStop()),
      expect: () => [
        isA<CaddyState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CaddyState>().having((s) => s.isStopped, 'isStopped', true),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyStart with error emits loading then error',
      build: () {
        mockService.startResult = const CaddyError(
          message: 'bind: address already in use',
        );
        return CaddyBloc(mockService);
      },
      act: (bloc) => bloc.add(const CaddyStart(CaddyConfig())),
      expect: () => [
        isA<CaddyState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CaddyState>().having((s) => s.hasError, 'hasError', true),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyReload emits loading then running',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddyReload(CaddyConfig())),
      expect: () => [
        isA<CaddyState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CaddyState>().having((s) => s.isRunning, 'isRunning', true),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyUpdateConfig updates config without status change',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(
        const CaddyUpdateConfig(CaddyConfig(listenAddress: 'localhost:9090')),
      ),
      expect: () => [
        isA<CaddyState>().having(
          (s) => s.config.listenAddress,
          'listenAddress',
          'localhost:9090',
        ),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyLogReceived appends log line',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddyLogReceived('test log line')),
      expect: () => [
        isA<CaddyState>().having((s) => s.logs, 'logs', ['test log line']),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyClearLogs clears all logs',
      build: () => CaddyBloc(mockService),
      seed: () => CaddyState.initial().copyWith(logs: ['log1', 'log2']),
      act: (bloc) => bloc.add(const CaddyClearLogs()),
      expect: () => [isA<CaddyState>().having((s) => s.logs, 'logs', isEmpty)],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyStatusCheck updates lastStatusCheck',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddyStatusCheck()),
      expect: () => [
        isA<CaddyState>().having(
          (s) => s.lastStatusCheck,
          'lastStatusCheck',
          isNotNull,
        ),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyToggleAdmin toggles admin state',
      build: () => CaddyBloc(mockService),
      act: (bloc) {
        bloc.add(const CaddyToggleAdmin());
        bloc.add(const CaddyToggleAdmin());
      },
      expect: () => [
        isA<CaddyState>().having((s) => s.adminEnabled, 'adminEnabled', true),
        isA<CaddyState>().having((s) => s.adminEnabled, 'adminEnabled', false),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddySetLogFilter updates log filter level',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddySetLogFilter(CaddyLogLevel.error)),
      expect: () => [
        isA<CaddyState>().having(
          (s) => s.logFilter,
          'logFilter',
          CaddyLogLevel.error,
        ),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddySetLogSearch updates search query',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddySetLogSearch('error')),
      expect: () => [
        isA<CaddyState>().having(
          (s) => s.logSearchQuery,
          'logSearchQuery',
          'error',
        ),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyLifecyclePause stops running server',
      build: () => CaddyBloc(mockService),
      seed: () => CaddyState.initial().copyWith(
        status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
      ),
      act: (bloc) => bloc.add(const CaddyLifecyclePause()),
      expect: () => [
        isA<CaddyState>().having((s) => s.isStopped, 'isStopped', true),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyLifecyclePause does nothing when stopped',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddyLifecyclePause()),
      expect: () => [],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyLifecycleResume does nothing without prior pause',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddyLifecycleResume()),
      expect: () => [],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyToggleAutoRestart toggles auto-restart state',
      build: () => CaddyBloc(mockService),
      act: (bloc) {
        bloc.add(const CaddyToggleAutoRestart());
        bloc.add(const CaddyToggleAutoRestart());
      },
      expect: () => [
        isA<CaddyState>().having(
          (s) => s.autoRestartOnResume,
          'autoRestartOnResume',
          false,
        ),
        isA<CaddyState>().having(
          (s) => s.autoRestartOnResume,
          'autoRestartOnResume',
          true,
        ),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyLifecycleResume does not restart when autoRestartOnResume is false',
      build: () => CaddyBloc(mockService),
      seed: () => CaddyState.initial().copyWith(
        status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
        autoRestartOnResume: false,
      ),
      act: (bloc) async {
        bloc.add(const CaddyLifecyclePause());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const CaddyLifecycleResume());
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<CaddyState>().having((s) => s.isStopped, 'isStopped', true),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyLogReceived increments requestCount for handled requests',
      build: () => CaddyBloc(mockService),
      act: (bloc) {
        bloc.add(
          const CaddyLogReceived(
            '{"level":"info","msg":"handled request","status":200}',
          ),
        );
        bloc.add(const CaddyLogReceived('INFO: some other log'));
        bloc.add(
          const CaddyLogReceived(
            '{"level":"info","msg":"handled request","status":301}',
          ),
        );
      },
      verify: (bloc) {
        expect(bloc.state.requestCount, 2);
        expect(bloc.state.logs, hasLength(3));
      },
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyStart resets requestCount to zero',
      build: () => CaddyBloc(mockService),
      seed: () => CaddyState.initial().copyWith(requestCount: 42),
      act: (bloc) => bloc.add(const CaddyStart(CaddyConfig())),
      expect: () => [
        isA<CaddyState>()
            .having((s) => s.isLoading, 'isLoading', true)
            .having((s) => s.requestCount, 'requestCount', 0),
        isA<CaddyState>().having((s) => s.isRunning, 'isRunning', true),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'Log rolling buffer caps at 10000 entries',
      build: () => CaddyBloc(mockService),
      seed: () => CaddyState.initial().copyWith(
        logs: List.generate(10000, (i) => 'log $i'),
      ),
      act: (bloc) => bloc.add(const CaddyLogReceived('new log')),
      expect: () => [
        isA<CaddyState>()
            .having((s) => s.logs.length, 'logs.length', 10000)
            .having((s) => s.logs.last, 'logs.last', 'new log')
            .having((s) => s.logs.first, 'logs.first', 'log 1'),
      ],
    );
  });

  group('CaddyState', () {
    test('startedAt returns DateTime when running', () {
      final now = DateTime.now();
      final state = CaddyState.initial().copyWith(
        status: CaddyRunning(config: '{}', startedAt: now),
      );
      expect(state.startedAt, now);
    });

    test('startedAt returns null when not running', () {
      expect(CaddyState.initial().startedAt, isNull);
    });

    test('filteredLogs returns all logs when filter is all', () {
      final state = CaddyState.initial().copyWith(
        logs: ['INFO msg', 'ERROR msg', 'DEBUG msg'],
      );
      expect(state.filteredLogs, hasLength(3));
    });

    test('filteredLogs filters by level', () {
      final state = CaddyState.initial().copyWith(
        logs: ['INFO msg', 'ERROR msg', 'DEBUG msg'],
        logFilter: CaddyLogLevel.error,
      );
      expect(state.filteredLogs, hasLength(1));
      expect(state.filteredLogs.first, contains('ERROR'));
    });

    test('filteredLogs filters by search query', () {
      final state = CaddyState.initial().copyWith(
        logs: [
          'connection established',
          'request received',
          'connection closed',
        ],
        logSearchQuery: 'connection',
      );
      expect(state.filteredLogs, hasLength(2));
    });

    test('filteredLogs combines level and search filters', () {
      final state = CaddyState.initial().copyWith(
        logs: [
          'INFO connection established',
          'ERROR connection refused',
          'INFO request received',
          'ERROR timeout',
        ],
        logFilter: CaddyLogLevel.error,
        logSearchQuery: 'connection',
      );
      expect(state.filteredLogs, hasLength(1));
      expect(state.filteredLogs.first, contains('ERROR'));
      expect(state.filteredLogs.first, contains('connection'));
    });

    test('filteredLogs search is case insensitive', () {
      final state = CaddyState.initial().copyWith(
        logs: ['ERROR: Connection Failed', 'INFO: connection ok'],
        logSearchQuery: 'CONNECTION',
      );
      expect(state.filteredLogs, hasLength(2));
    });
  });

  group('Config persistence', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting();
    });

    tearDown(() async {
      await db.close();
    });

    blocTest<CaddyBloc, CaddyState>(
      'CaddySaveConfig persists config to database',
      build: () => CaddyBloc(mockService, database: db),
      seed: () => CaddyState.initial().copyWith(
        config: const CaddyConfig(listenAddress: 'localhost:9090'),
        adminEnabled: true,
      ),
      act: (bloc) => bloc.add(const CaddySaveConfig('production')),
      verify: (bloc) async {
        expect(bloc.state.savedConfigNames, contains('production'));
        expect(bloc.state.activeConfigName, 'production');
        final saved = await db.getCaddyConfigByName('production');
        expect(saved, isNotNull);
        expect(saved!.adminEnabled, isTrue);
        final json = jsonDecode(saved.configJson) as Map<String, dynamic>;
        expect(json, isNotEmpty);
      },
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyLoadSavedConfig loads active config from database',
      build: () => CaddyBloc(mockService, database: db),
      setUp: () async {
        await db.upsertCaddyConfig(
          name: 'saved-config',
          configJson: jsonEncode(
            const CaddyConfig(listenAddress: 'localhost:4000').toStorageJson(),
          ),
          adminEnabled: true,
          isActive: true,
        );
      },
      act: (bloc) => bloc.add(const CaddyLoadSavedConfig()),
      verify: (bloc) {
        expect(bloc.state.config.listenAddress, 'localhost:4000');
        expect(bloc.state.adminEnabled, isTrue);
        expect(bloc.state.savedConfigNames, contains('saved-config'));
        expect(bloc.state.activeConfigName, 'saved-config');
      },
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyLoadNamedConfig switches to named config',
      build: () => CaddyBloc(mockService, database: db),
      setUp: () async {
        await db.upsertCaddyConfig(
          name: 'config-a',
          configJson: jsonEncode(
            const CaddyConfig(listenAddress: 'localhost:3000').toStorageJson(),
          ),
        );
        await db.upsertCaddyConfig(
          name: 'config-b',
          configJson: jsonEncode(
            const CaddyConfig(listenAddress: 'localhost:4000').toStorageJson(),
          ),
          adminEnabled: true,
        );
      },
      act: (bloc) => bloc.add(const CaddyLoadNamedConfig('config-b')),
      verify: (bloc) {
        expect(bloc.state.config.listenAddress, 'localhost:4000');
        expect(bloc.state.adminEnabled, isTrue);
        expect(bloc.state.activeConfigName, 'config-b');
      },
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyDeleteSavedConfig removes config from database',
      build: () => CaddyBloc(mockService, database: db),
      setUp: () async {
        await db.upsertCaddyConfig(
          name: 'to-delete',
          configJson: jsonEncode(const CaddyConfig().toStorageJson()),
        );
      },
      seed: () => CaddyState.initial().copyWith(
        savedConfigNames: ['to-delete'],
        activeConfigName: 'to-delete',
      ),
      act: (bloc) => bloc.add(const CaddyDeleteSavedConfig('to-delete')),
      verify: (bloc) async {
        expect(bloc.state.savedConfigNames, isNot(contains('to-delete')));
        expect(bloc.state.activeConfigName, isNull);
        final saved = await db.getCaddyConfigByName('to-delete');
        expect(saved, isNull);
      },
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyLoadSavedConfig with no database does nothing',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddyLoadSavedConfig()),
      expect: () => [],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddySaveConfig with no database does nothing',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddySaveConfig('test')),
      expect: () => [],
    );
  });

  group('Crash recovery', () {
    late AppDatabase db;

    blocTest<CaddyBloc, CaddyState>(
      'CaddyInitialize stops orphaned Caddy instance',
      build: () {
        mockService.statusResult = CaddyRunning(
          config: '{}',
          startedAt: DateTime(2024),
        );
        return CaddyBloc(mockService);
      },
      act: (bloc) => bloc.add(const CaddyInitialize()),
      verify: (bloc) {
        expect(mockService.stopCalled, isTrue);
        expect(bloc.state.isStopped, isTrue);
      },
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyInitialize does not stop when Caddy is not running',
      build: () {
        mockService.statusResult = const CaddyStopped();
        return CaddyBloc(mockService);
      },
      act: (bloc) => bloc.add(const CaddyInitialize()),
      verify: (bloc) {
        expect(mockService.stopCalled, isFalse);
      },
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyInitialize loads saved configs from database',
      build: () => CaddyBloc(mockService, database: db),
      setUp: () async {
        db = AppDatabase.forTesting();
        await db.upsertCaddyConfig(
          name: 'init-config',
          configJson: jsonEncode(
            const CaddyConfig(listenAddress: 'localhost:5000').toStorageJson(),
          ),
          adminEnabled: true,
          isActive: true,
        );
      },
      act: (bloc) => bloc.add(const CaddyInitialize()),
      verify: (bloc) {
        expect(bloc.state.config.listenAddress, 'localhost:5000');
        expect(bloc.state.adminEnabled, isTrue);
        expect(bloc.state.savedConfigNames, contains('init-config'));
        expect(bloc.state.activeConfigName, 'init-config');
      },
      tearDown: () async {
        await db.close();
      },
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyInitialize cleans up orphan then loads config',
      build: () {
        mockService.statusResult = CaddyRunning(
          config: '{}',
          startedAt: DateTime(2024),
        );
        return CaddyBloc(mockService, database: db);
      },
      setUp: () async {
        db = AppDatabase.forTesting();
        await db.upsertCaddyConfig(
          name: 'recovered',
          configJson: jsonEncode(
            const CaddyConfig(listenAddress: 'localhost:7777').toStorageJson(),
          ),
          isActive: true,
        );
      },
      act: (bloc) => bloc.add(const CaddyInitialize()),
      verify: (bloc) {
        expect(mockService.stopCalled, isTrue);
        expect(bloc.state.config.listenAddress, 'localhost:7777');
        expect(bloc.state.activeConfigName, 'recovered');
      },
      tearDown: () async {
        await db.close();
      },
    );
  });

  group('Secrets injection', () {
    late MockVaultRepository mockVault;

    setUp(() {
      mockVault = MockVaultRepository();
    });

    blocTest<CaddyBloc, CaddyState>(
      'CaddyStart injects caddy_ prefixed secrets as environment variables',
      setUp: () async {
        await mockVault.write(key: 'caddy_CF_API_TOKEN', value: 'cf-token-123');
        await mockVault.write(key: 'caddy_AWS_ACCESS_KEY_ID', value: 'aws-key');
        await mockVault.write(key: 'other_secret', value: 'ignored');
      },
      build: () => CaddyBloc(mockService, vault: mockVault),
      act: (bloc) => bloc.add(const CaddyStart(CaddyConfig())),
      expect: () => [
        isA<CaddyState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CaddyState>().having((s) => s.isRunning, 'isRunning', true),
      ],
      verify: (_) {
        expect(mockService.lastEnvironment, {
          'CF_API_TOKEN': 'cf-token-123',
          'AWS_ACCESS_KEY_ID': 'aws-key',
        });
      },
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyReload injects caddy_ prefixed secrets as environment variables',
      setUp: () async {
        await mockVault.write(key: 'caddy_DUCKDNS_TOKEN', value: 'duck-token');
      },
      build: () => CaddyBloc(mockService, vault: mockVault),
      act: (bloc) => bloc.add(const CaddyReload(CaddyConfig())),
      expect: () => [
        isA<CaddyState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CaddyState>().having((s) => s.isRunning, 'isRunning', true),
      ],
      verify: (_) {
        expect(mockService.lastEnvironment, {'DUCKDNS_TOKEN': 'duck-token'});
      },
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyStart with no vault passes empty environment',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddyStart(CaddyConfig())),
      expect: () => [
        isA<CaddyState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CaddyState>().having((s) => s.isRunning, 'isRunning', true),
      ],
      verify: (_) {
        expect(mockService.lastEnvironment, isEmpty);
      },
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyLifecycleResume injects secrets on restart',
      setUp: () async {
        await mockVault.write(key: 'caddy_S3_ACCESS_KEY', value: 's3-key');
      },
      build: () => CaddyBloc(mockService, vault: mockVault),
      seed: () => CaddyState.initial().copyWith(
        status: CaddyRunning(config: '{}', startedAt: DateTime.now()),
      ),
      act: (bloc) async {
        bloc.add(const CaddyLifecyclePause());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const CaddyLifecycleResume());
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<CaddyState>().having((s) => s.isStopped, 'isStopped', true),
        isA<CaddyState>().having((s) => s.isLoading, 'isLoading', true),
        isA<CaddyState>().having((s) => s.isRunning, 'isRunning', true),
      ],
      verify: (_) {
        expect(mockService.lastEnvironment, {'S3_ACCESS_KEY': 's3-key'});
      },
    );
  });
}
