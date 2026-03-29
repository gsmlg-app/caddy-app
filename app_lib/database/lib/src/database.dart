import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

@DataClassName('SavedCaddyConfig')
class CaddyConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get configJson => text()();
  BoolColumn get adminEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [CaddyConfigs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  factory AppDatabase.forTesting() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(caddyConfigs);
      }
      if (from < 3) {
        // Migrate stored configs from old CaddyConfig structured format
        // to new CaddyTextConfig {text, format} format.
        await _migrateConfigsToTextFormat();
      }
    },
  );

  /// Migrates old structured CaddyConfig JSON to new CaddyTextConfig format.
  /// Old format had either `_rawJson` key (raw JSON mode) or structured
  /// fields like `listenAddress`, `routes`, `tls`, `storage`.
  /// New format is `{"text": "<config>", "format": "caddyfile|json"}`.
  Future<void> _migrateConfigsToTextFormat() async {
    final rows = await select(caddyConfigs).get();
    for (final row in rows) {
      try {
        final old = jsonDecode(row.configJson) as Map<String, dynamic>;
        // Already in new format
        if (old.containsKey('text') && old.containsKey('format')) continue;

        String configText;
        if (old.containsKey('_rawJson')) {
          // Was stored as raw JSON
          configText = old['_rawJson'] as String;
        } else {
          // Reconstruct Caddy JSON from structured fields
          configText = _reconstructCaddyJson(old);
        }

        final newJson = jsonEncode({'text': configText, 'format': 'json'});
        await (update(caddyConfigs)..where((t) => t.id.equals(row.id))).write(
          CaddyConfigsCompanion(
            configJson: Value(newJson),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } catch (_) {
        // Skip configs that can't be migrated
      }
    }
  }

  /// Reconstructs Caddy JSON from old structured CaddyConfig format.
  /// This duplicates the essential logic of the removed CaddyConfig.toJson().
  static String _reconstructCaddyJson(Map<String, dynamic> old) {
    final listenAddress = old['listenAddress'] as String? ?? 'localhost:2015';
    final port = listenAddress.split(':').last;
    final host = listenAddress.split(':').first;
    final routes = old['routes'] as List<dynamic>? ?? [];

    final routeJson = routes.map((r) {
      final route = r as Map<String, dynamic>;
      final handler = route['handler'] as Map<String, dynamic>? ?? {};
      final handlerType = handler['handler'] as String? ?? 'file_server';

      final handleEntry = <String, dynamic>{'handler': handlerType};
      if (handlerType == 'file_server') {
        handleEntry['root'] = handler['root'] ?? '.';
      } else if (handlerType == 'reverse_proxy') {
        final upstreams = handler['upstreams'] as List<dynamic>? ?? [];
        handleEntry['upstreams'] =
            upstreams.map((u) => {'dial': u is String ? u : ''}).toList();
      }

      return {
        'match': [
          {
            'host': [host],
            'path': [route['path'] ?? '/*'],
          },
        ],
        'handle': [handleEntry],
      };
    }).toList();

    final apps = <String, dynamic>{
      'http': {
        'servers': {
          'srv0': {
            'listen': [':$port'],
            'routes': routeJson,
          },
        },
      },
    };

    return jsonEncode({'apps': apps});
  }

  // --- CaddyConfigs queries ---

  Future<List<SavedCaddyConfig>> getAllCaddyConfigs() =>
      select(caddyConfigs).get();

  Stream<List<SavedCaddyConfig>> watchAllCaddyConfigs() =>
      select(caddyConfigs).watch();

  Future<SavedCaddyConfig?> getActiveCaddyConfig() => (select(
    caddyConfigs,
  )..where((t) => t.isActive.equals(true))).getSingleOrNull();

  Future<SavedCaddyConfig?> getCaddyConfigByName(String name) => (select(
    caddyConfigs,
  )..where((t) => t.name.equals(name))).getSingleOrNull();

  Future<void> saveCaddyConfig(CaddyConfigsCompanion entry) =>
      into(caddyConfigs).insert(
        entry,
        onConflict: DoUpdate((old) => entry, target: [caddyConfigs.name]),
      );

  Future<void> upsertCaddyConfig({
    required String name,
    required String configJson,
    bool adminEnabled = false,
    bool isActive = false,
  }) => saveCaddyConfig(
    CaddyConfigsCompanion(
      name: Value(name),
      configJson: Value(configJson),
      adminEnabled: Value(adminEnabled),
      isActive: Value(isActive),
      updatedAt: Value(DateTime.now()),
    ),
  );

  Future<void> setActiveCaddyConfig(String name) async {
    await transaction(() async {
      // Deactivate all
      await (update(
        caddyConfigs,
      )).write(const CaddyConfigsCompanion(isActive: Value(false)));
      // Activate the selected one
      await (update(caddyConfigs)..where((t) => t.name.equals(name))).write(
        const CaddyConfigsCompanion(isActive: Value(true)),
      );
    });
  }

  Future<void> deleteCaddyConfig(String name) =>
      (delete(caddyConfigs)..where((t) => t.name.equals(name))).go();

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'caddy_app',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
