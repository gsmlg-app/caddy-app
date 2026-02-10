part of 'bloc.dart';

class CaddyState extends Equatable {
  const CaddyState({
    required this.status,
    required this.config,
    this.logs = const [],
    this.lastStatusCheck,
  });

  factory CaddyState.initial() {
    return const CaddyState(status: CaddyStopped(), config: CaddyConfig());
  }

  final CaddyStatus status;
  final CaddyConfig config;
  final List<String> logs;
  final DateTime? lastStatusCheck;

  bool get isRunning => status is CaddyRunning;
  bool get isStopped => status is CaddyStopped;
  bool get hasError => status is CaddyError;
  bool get isLoading => status is CaddyLoading;

  CaddyState copyWith({
    CaddyStatus? status,
    CaddyConfig? config,
    List<String>? logs,
    DateTime? lastStatusCheck,
  }) {
    return CaddyState(
      status: status ?? this.status,
      config: config ?? this.config,
      logs: logs ?? this.logs,
      lastStatusCheck: lastStatusCheck ?? this.lastStatusCheck,
    );
  }

  @override
  List<Object?> get props => [status, config, logs, lastStatusCheck];
}
