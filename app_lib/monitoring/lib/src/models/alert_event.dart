import 'package:equatable/equatable.dart';

import 'alert_rule.dart';

/// An alert event triggered by a rule
class AlertEvent extends Equatable {
  const AlertEvent({
    required this.id,
    required this.rule,
    required this.message,
    required this.timestamp,
    required this.resolved,
    this.resolvedAt,
    this.value,
  });

  /// Unique identifier for this alert event
  final String id;

  /// The rule that triggered this alert
  final AlertRule rule;

  /// Human-readable message
  final String message;

  /// When the alert was triggered
  final DateTime timestamp;

  /// Whether this alert has been resolved
  final bool resolved;

  /// When the alert was resolved (if applicable)
  final DateTime? resolvedAt;

  /// The actual value that triggered the alert
  final double? value;

  /// How long the alert has been active
  Duration get duration {
    final end = resolvedAt ?? DateTime.now();
    return end.difference(timestamp);
  }

  /// Create a copy with modified fields
  AlertEvent copyWith({
    String? id,
    AlertRule? rule,
    String? message,
    DateTime? timestamp,
    bool? resolved,
    DateTime? resolvedAt,
    double? value,
  }) {
    return AlertEvent(
      id: id ?? this.id,
      rule: rule ?? this.rule,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      resolved: resolved ?? this.resolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [
    id,
    rule,
    message,
    timestamp,
    resolved,
    resolvedAt,
    value,
  ];
}
