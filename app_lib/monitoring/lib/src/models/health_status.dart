import 'package:equatable/equatable.dart';

/// Enum representing the health status of the Caddy server
enum HealthStatusType { healthy, degraded, unhealthy, unknown }

/// Represents the health status of the Caddy server with details
class HealthStatus extends Equatable {
  const HealthStatus({
    required this.type,
    required this.timestamp,
    required this.isRunning,
    this.errorMessage,
    this.uptime = Duration.zero,
    this.uptimePercent = 100.0,
  });

  /// The type of health status
  final HealthStatusType type;

  /// When this status was recorded
  final DateTime timestamp;

  /// Whether the server is currently running
  final bool isRunning;

  /// Error message if unhealthy
  final String? errorMessage;

  /// How long the server has been running
  final Duration uptime;

  /// Uptime percentage (0-100)
  final double uptimePercent;

  /// Whether the server is in a healthy state
  bool get isHealthy => type == HealthStatusType.healthy;

  /// Whether the server is in a degraded state
  bool get isDegraded => type == HealthStatusType.degraded;

  /// Whether the server is in an unhealthy state
  bool get isUnhealthy => type == HealthStatusType.unhealthy;

  /// Create a copy with modified fields
  HealthStatus copyWith({
    HealthStatusType? type,
    DateTime? timestamp,
    bool? isRunning,
    String? errorMessage,
    Duration? uptime,
    double? uptimePercent,
  }) {
    return HealthStatus(
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRunning: isRunning ?? this.isRunning,
      errorMessage: errorMessage ?? this.errorMessage,
      uptime: uptime ?? this.uptime,
      uptimePercent: uptimePercent ?? this.uptimePercent,
    );
  }

  @override
  List<Object?> get props => [
    type,
    timestamp,
    isRunning,
    errorMessage,
    uptime,
    uptimePercent,
  ];
}
