part of 'bloc.dart';

class CaddyState extends Equatable {
  const CaddyState({
    required this.status,
    required this.config,
    this.logs = const [],
    this.lastStatusCheck,
    this.adminEnabled = false,
    this.logFilter = CaddyLogLevel.all,
    this.logSearchQuery = '',
  });

  factory CaddyState.initial() {
    return const CaddyState(status: CaddyStopped(), config: CaddyConfig());
  }

  final CaddyStatus status;
  final CaddyConfig config;
  final List<String> logs;
  final DateTime? lastStatusCheck;
  final bool adminEnabled;
  final CaddyLogLevel logFilter;
  final String logSearchQuery;

  bool get isRunning => status is CaddyRunning;
  bool get isStopped => status is CaddyStopped;
  bool get hasError => status is CaddyError;
  bool get isLoading => status is CaddyLoading;

  DateTime? get startedAt => switch (status) {
    CaddyRunning(startedAt: final t) => t,
    _ => null,
  };

  List<String> get filteredLogs {
    var filtered = logs;
    if (logFilter != CaddyLogLevel.all) {
      final level = logFilter.name.toUpperCase();
      filtered = filtered
          .where((l) => l.toUpperCase().contains(level))
          .toList();
    }
    if (logSearchQuery.isNotEmpty) {
      filtered = filtered
          .where((l) => l.toLowerCase().contains(logSearchQuery.toLowerCase()))
          .toList();
    }
    return filtered;
  }

  CaddyState copyWith({
    CaddyStatus? status,
    CaddyConfig? config,
    List<String>? logs,
    DateTime? lastStatusCheck,
    bool? adminEnabled,
    CaddyLogLevel? logFilter,
    String? logSearchQuery,
  }) {
    return CaddyState(
      status: status ?? this.status,
      config: config ?? this.config,
      logs: logs ?? this.logs,
      lastStatusCheck: lastStatusCheck ?? this.lastStatusCheck,
      adminEnabled: adminEnabled ?? this.adminEnabled,
      logFilter: logFilter ?? this.logFilter,
      logSearchQuery: logSearchQuery ?? this.logSearchQuery,
    );
  }

  @override
  List<Object?> get props => [
    status,
    config,
    logs,
    lastStatusCheck,
    adminEnabled,
    logFilter,
    logSearchQuery,
  ];
}

enum CaddyLogLevel { all, debug, info, warn, error }
