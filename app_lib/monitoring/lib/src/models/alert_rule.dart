import 'package:equatable/equatable.dart';

/// Types of alert conditions
enum AlertCondition {
  serverDown,
  highErrorRate,
  highMemoryUsage,
  slowResponse,
  lowUptime,
}

/// Severity levels for alerts
enum AlertSeverity { critical, warning, info }

/// A rule that triggers alerts based on conditions
class AlertRule extends Equatable {
  const AlertRule({
    required this.id,
    required this.name,
    required this.condition,
    required this.severity,
    required this.threshold,
    required this.enabled,
    this.cooldownMinutes = 5,
  });

  /// Unique identifier
  final String id;

  /// Human-readable name
  final String name;

  /// The condition that triggers the alert
  final AlertCondition condition;

  /// How severe the alert is
  final AlertSeverity severity;

  /// The threshold value that triggers the alert
  final double threshold;

  /// Whether this rule is active
  final bool enabled;

  /// Minimum minutes between alerts for this rule
  final int cooldownMinutes;

  /// Get a description of what this alert monitors
  String get description => switch (condition) {
    AlertCondition.serverDown => 'Server is not running',
    AlertCondition.highErrorRate =>
      'Error rate exceeds ${threshold.toStringAsFixed(1)}%',
    AlertCondition.highMemoryUsage =>
      'Memory usage exceeds ${threshold.toStringAsFixed(0)} MB',
    AlertCondition.slowResponse =>
      'Average response time exceeds ${threshold.toStringAsFixed(0)} ms',
    AlertCondition.lowUptime =>
      'Uptime drops below ${threshold.toStringAsFixed(1)}%',
  };

  /// Create a copy with modified fields
  AlertRule copyWith({
    String? id,
    String? name,
    AlertCondition? condition,
    AlertSeverity? severity,
    double? threshold,
    bool? enabled,
    int? cooldownMinutes,
  }) {
    return AlertRule(
      id: id ?? this.id,
      name: name ?? this.name,
      condition: condition ?? this.condition,
      severity: severity ?? this.severity,
      threshold: threshold ?? this.threshold,
      enabled: enabled ?? this.enabled,
      cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    condition,
    severity,
    threshold,
    enabled,
    cooldownMinutes,
  ];
}
