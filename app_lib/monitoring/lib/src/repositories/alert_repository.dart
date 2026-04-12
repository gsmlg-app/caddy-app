import '../models/alert_event.dart';
import '../models/alert_rule.dart';

/// Repository for managing alert rules and events
abstract class AlertRepository {
  /// Save or update an alert rule
  Future<void> saveRule(AlertRule rule);

  /// Get a rule by ID
  Future<AlertRule?> getRule(String id);

  /// Get all alert rules
  Future<List<AlertRule>> getAllRules();

  /// Delete a rule by ID
  Future<void> deleteRule(String id);

  /// Record an alert event
  Future<void> recordEvent(AlertEvent event);

  /// Get alert events
  Future<List<AlertEvent>> getEvents({int limit = 100});

  /// Get active (unresolved) alert events
  Future<List<AlertEvent>> getActiveEvents();

  /// Resolve an alert event
  Future<void> resolveEvent(String eventId);

  /// Watch all rules
  Stream<List<AlertRule>> watchAllRules();

  /// Watch active events
  Stream<List<AlertEvent>> watchActiveEvents();
}

/// In-memory implementation of AlertRepository
class InMemoryAlertRepository implements AlertRepository {
  final Map<String, AlertRule> _rules = {};
  final List<AlertEvent> _events = [];

  @override
  Future<void> saveRule(AlertRule rule) async {
    _rules[rule.id] = rule;
  }

  @override
  Future<AlertRule?> getRule(String id) async {
    return _rules[id];
  }

  @override
  Future<List<AlertRule>> getAllRules() async {
    return _rules.values.toList();
  }

  @override
  Future<void> deleteRule(String id) async {
    _rules.remove(id);
  }

  @override
  Future<void> recordEvent(AlertEvent event) async {
    _events.add(event);
    // Keep only last 1000 events
    if (_events.length > 1000) {
      _events.removeRange(0, _events.length - 1000);
    }
  }

  @override
  Future<List<AlertEvent>> getEvents({int limit = 100}) async {
    return _events.take(limit).toList();
  }

  @override
  Future<List<AlertEvent>> getActiveEvents() async {
    return _events.where((e) => !e.resolved).toList();
  }

  @override
  Future<void> resolveEvent(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final event = _events[index];
      _events[index] = event.copyWith(
        resolved: true,
        resolvedAt: DateTime.now(),
      );
    }
  }

  @override
  Stream<List<AlertRule>> watchAllRules() async* {
    yield _rules.values.toList();
  }

  @override
  Stream<List<AlertEvent>> watchActiveEvents() async* {
    yield _events.where((e) => !e.resolved).toList();
  }
}
