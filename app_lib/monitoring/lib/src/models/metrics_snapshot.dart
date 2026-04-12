import 'package:equatable/equatable.dart';

/// A snapshot of server metrics at a specific point in time
class MetricsSnapshot extends Equatable {
  const MetricsSnapshot({
    required this.timestamp,
    required this.requestCount,
    required this.requestRate,
    this.successRate = 100.0,
    this.errorRate = 0.0,
    this.avgResponseTime = 0.0,
    this.memoryUsageMb = 0.0,
    this.cpuPercent = 0.0,
  });

  /// When this metrics snapshot was recorded
  final DateTime timestamp;

  /// Total number of requests handled
  final int requestCount;

  /// Requests per second
  final double requestRate;

  /// Success rate percentage (0-100)
  final double successRate;

  /// Error rate percentage (0-100)
  final double errorRate;

  /// Average response time in milliseconds
  final double avgResponseTime;

  /// Memory usage in megabytes
  final double memoryUsageMb;

  /// CPU usage percentage (0-100)
  final double cpuPercent;

  /// Whether there are high error rates
  bool get hasHighErrorRate => errorRate > 10.0;

  /// Whether response times are slow
  bool get hasSlowResponse => avgResponseTime > 1000.0; // > 1 second

  /// Create a copy with modified fields
  MetricsSnapshot copyWith({
    DateTime? timestamp,
    int? requestCount,
    double? requestRate,
    double? successRate,
    double? errorRate,
    double? avgResponseTime,
    double? memoryUsageMb,
    double? cpuPercent,
  }) {
    return MetricsSnapshot(
      timestamp: timestamp ?? this.timestamp,
      requestCount: requestCount ?? this.requestCount,
      requestRate: requestRate ?? this.requestRate,
      successRate: successRate ?? this.successRate,
      errorRate: errorRate ?? this.errorRate,
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
      memoryUsageMb: memoryUsageMb ?? this.memoryUsageMb,
      cpuPercent: cpuPercent ?? this.cpuPercent,
    );
  }

  @override
  List<Object?> get props => [
    timestamp,
    requestCount,
    requestRate,
    successRate,
    errorRate,
    avgResponseTime,
    memoryUsageMb,
    cpuPercent,
  ];
}
