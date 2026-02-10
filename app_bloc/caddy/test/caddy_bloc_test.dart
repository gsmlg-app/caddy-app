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

  @override
  Future<CaddyStatus> start(CaddyConfig config) async => startResult;

  @override
  Future<CaddyStatus> stop() async => stopResult;

  @override
  Future<CaddyStatus> reload(CaddyConfig config) async => reloadResult;

  @override
  Future<CaddyStatus> getStatus() async => statusResult;

  @override
  Stream<String> get logStream => const Stream.empty();
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
      expect: () => [
        isA<CaddyState>().having((s) => s.logs, 'logs', isEmpty),
      ],
    );

    blocTest<CaddyBloc, CaddyState>(
      'CaddyStatusCheck updates lastStatusCheck',
      build: () => CaddyBloc(mockService),
      act: (bloc) => bloc.add(const CaddyStatusCheck()),
      expect: () => [
        isA<CaddyState>()
            .having((s) => s.lastStatusCheck, 'lastStatusCheck', isNotNull),
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
        isA<CaddyState>().having(
          (s) => s.adminEnabled,
          'adminEnabled',
          true,
        ),
        isA<CaddyState>().having(
          (s) => s.adminEnabled,
          'adminEnabled',
          false,
        ),
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
      'Log rolling buffer caps at 500 entries',
      build: () => CaddyBloc(mockService),
      seed: () => CaddyState.initial().copyWith(
        logs: List.generate(500, (i) => 'log $i'),
      ),
      act: (bloc) => bloc.add(const CaddyLogReceived('new log')),
      expect: () => [
        isA<CaddyState>()
            .having((s) => s.logs.length, 'logs.length', 500)
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
}
