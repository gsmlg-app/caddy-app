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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(caddyConfigs);
      }
    },
  );

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
