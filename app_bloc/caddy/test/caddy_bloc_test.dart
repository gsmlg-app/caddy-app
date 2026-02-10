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
  });
}
