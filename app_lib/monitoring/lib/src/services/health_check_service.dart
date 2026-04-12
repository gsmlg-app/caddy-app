import 'dart:async';

import '../models/health_status.dart';

/// Service for monitoring server health
abstract class HealthCheckService {
  /// Start periodic health checks
  void start({Duration interval = const Duration(seconds: 30)});

  /// Stop health checks
  void stop();

  /// Check health immediately
  Future<HealthStatus> checkHealth();

  /// Stream of health status changes
  Stream<HealthStatus> get statusStream;

  /// Get the current health status
  HealthStatus get currentStatus;

  /// Whether health checks are currently running
  bool get isRunning;
}

/// Mock implementation of HealthCheckService for development
class MockHealthCheckService implements HealthCheckService {
  MockHealthCheckService({this.isRunning = false});

  @override
  bool isRunning;

  final _statusController = StreamController<HealthStatus>.broadcast();
  HealthStatus _currentStatus = HealthStatus(
    type: HealthStatusType.healthy,
    timestamp: DateTime.now(),
    isRunning: true,
    uptime: Duration.zero,
    uptimePercent: 100.0,
  );
  Timer? _timer;

  @override
  void start({Duration interval = const Duration(seconds: 30)}) {
    if (isRunning) return;
    isRunning = true;

    _timer = Timer.periodic(interval, (_) async {
      final status = await checkHealth();
      _statusController.add(status);
    });
  }

  @override
  void stop() {
    if (!isRunning) return;
    isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<HealthStatus> checkHealth() async {
    // Simulate a health check
    final now = DateTime.now();
    _currentStatus = _currentStatus.copyWith(timestamp: now);
    return _currentStatus;
  }

  @override
  Stream<HealthStatus> get statusStream => _statusController.stream;

  @override
  HealthStatus get currentStatus => _currentStatus;

  /// Set the mock status (for testing)
  void setStatus(HealthStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void dispose() {
    _timer?.cancel();
    _statusController.close();
  }
}

/// Real implementation that checks actual Caddy server health
class RealHealthCheckService implements HealthCheckService {
  RealHealthCheckService({
    required this.isRunningCallback,
    required this.getUptimeCallback,
    required this.getErrorCallback,
  });

  @override
  bool isRunning = false;

  final bool Function() isRunningCallback;
  final Duration Function() getUptimeCallback;
  final String? Function() getErrorCallback;

  final _statusController = StreamController<HealthStatus>.broadcast();
  late HealthStatus _currentStatus;
  Timer? _timer;

  RealHealthCheckService._internal({
    required this.isRunningCallback,
    required this.getUptimeCallback,
    required this.getErrorCallback,
  });

  @override
  void start({Duration interval = const Duration(seconds: 30)}) {
    if (isRunning) return;
    isRunning = true;

    _timer = Timer.periodic(interval, (_) async {
      final status = await checkHealth();
      _statusController.add(status);
    });

    // Perform initial check
    checkHealth().then(_statusController.add);
  }

  @override
  void stop() {
    if (!isRunning) return;
    isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<HealthStatus> checkHealth() async {
    final running = isRunningCallback();
    final uptime = getUptimeCallback();
    final error = getErrorCallback();

    HealthStatusType type;
    if (!running) {
      type = HealthStatusType.unhealthy;
    } else if (error != null) {
      type = HealthStatusType.degraded;
    } else {
      type = HealthStatusType.healthy;
    }

    // Calculate uptime percentage (assuming max 7 days as 100%)
    const maxUptimeDays = 7;
    final daysElapsed = uptime.inDays;
    final uptimePercent = daysElapsed > maxUptimeDays
        ? 100.0
        : (daysElapsed / maxUptimeDays) * 100;

    _currentStatus = HealthStatus(
      type: type,
      timestamp: DateTime.now(),
      isRunning: running,
      errorMessage: error,
      uptime: uptime,
      uptimePercent: uptimePercent,
    );

    return _currentStatus;
  }

  @override
  Stream<HealthStatus> get statusStream => _statusController.stream;

  @override
  HealthStatus get currentStatus => _currentStatus;

  void dispose() {
    _timer?.cancel();
    _statusController.close();
  }
}
