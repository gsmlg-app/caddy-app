import 'package:app_database/app_database.dart';

import '../models/metrics_snapshot.dart';

/// Repository for storing and retrieving metrics snapshots
abstract class MetricsRepository {
  /// Record a new metrics snapshot
  Future<void> recordMetrics(MetricsSnapshot snapshot);

  /// Get the latest metrics snapshot
  Future<MetricsSnapshot?> getLatestMetrics();

  /// Get metrics snapshots within a time range
  Future<List<MetricsSnapshot>> getMetricsInRange(DateTime start, DateTime end);

  /// Get metrics snapshots from the last N hours
  Future<List<MetricsSnapshot>> getMetricsLastHours(int hours);

  /// Get metrics snapshots from the last N days
  Future<List<MetricsSnapshot>> getMetricsLastDays(int days);

  /// Clear old metrics snapshots (older than specified duration)
  Future<void> clearOldMetrics(Duration olderThan);

  /// Watch the latest metrics snapshot
  Stream<MetricsSnapshot?> watchLatestMetrics();
}

/// In-memory implementation of MetricsRepository
class InMemoryMetricsRepository implements MetricsRepository {
  final List<MetricsSnapshot> _metrics = [];

  @override
  Future<void> recordMetrics(MetricsSnapshot snapshot) async {
    _metrics.add(snapshot);
    // Keep only last 10,000 metrics
    if (_metrics.length > 10000) {
      _metrics.removeRange(0, _metrics.length - 10000);
    }
  }

  @override
  Future<MetricsSnapshot?> getLatestMetrics() async {
    return _metrics.isEmpty ? null : _metrics.last;
  }

  @override
  Future<List<MetricsSnapshot>> getMetricsInRange(
    DateTime start,
    DateTime end,
  ) async {
    return _metrics
        .where((m) => m.timestamp.isAfter(start) && m.timestamp.isBefore(end))
        .toList();
  }

  @override
  Future<List<MetricsSnapshot>> getMetricsLastHours(int hours) async {
    final since = DateTime.now().subtract(Duration(hours: hours));
    return _metrics.where((m) => m.timestamp.isAfter(since)).toList();
  }

  @override
  Future<List<MetricsSnapshot>> getMetricsLastDays(int days) async {
    final since = DateTime.now().subtract(Duration(days: days));
    return _metrics.where((m) => m.timestamp.isAfter(since)).toList();
  }

  @override
  Future<void> clearOldMetrics(Duration olderThan) async {
    final cutoff = DateTime.now().subtract(olderThan);
    _metrics.removeWhere((m) => m.timestamp.isBefore(cutoff));
  }

  @override
  Stream<MetricsSnapshot?> watchLatestMetrics() async* {
    for (final metric in _metrics) {
      yield metric;
    }
  }
}

/// Database-backed implementation of MetricsRepository
class DatabaseMetricsRepository implements MetricsRepository {
  DatabaseMetricsRepository(this._database);

  final AppDatabase _database;

  @override
  Future<void> recordMetrics(MetricsSnapshot snapshot) async {
    // TODO: Implement database storage for metrics
    // This requires adding a metrics table to the database schema
  }

  @override
  Future<MetricsSnapshot?> getLatestMetrics() async {
    // TODO: Implement database retrieval
    return null;
  }

  @override
  Future<List<MetricsSnapshot>> getMetricsInRange(
    DateTime start,
    DateTime end,
  ) async {
    // TODO: Implement database query
    return [];
  }

  @override
  Future<List<MetricsSnapshot>> getMetricsLastHours(int hours) async {
    // TODO: Implement database query
    return [];
  }

  @override
  Future<List<MetricsSnapshot>> getMetricsLastDays(int days) async {
    // TODO: Implement database query
    return [];
  }

  @override
  Future<void> clearOldMetrics(Duration olderThan) async {
    // TODO: Implement database cleanup
  }

  @override
  Stream<MetricsSnapshot?> watchLatestMetrics() async* {
    // TODO: Implement database watch
  }
}
