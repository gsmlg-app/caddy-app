// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CaddyConfigsTable extends CaddyConfigs
    with TableInfo<$CaddyConfigsTable, SavedCaddyConfig> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CaddyConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _adminEnabledMeta = const VerificationMeta(
    'adminEnabled',
  );
  @override
  late final GeneratedColumn<bool> adminEnabled = GeneratedColumn<bool>(
    'admin_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("admin_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    configJson,
    adminEnabled,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'caddy_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedCaddyConfig> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_configJsonMeta);
    }
    if (data.containsKey('admin_enabled')) {
      context.handle(
        _adminEnabledMeta,
        adminEnabled.isAcceptableOrUnknown(
          data['admin_enabled']!,
          _adminEnabledMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedCaddyConfig map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedCaddyConfig(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      )!,
      adminEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}admin_enabled'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CaddyConfigsTable createAlias(String alias) {
    return $CaddyConfigsTable(attachedDatabase, alias);
  }
}

class SavedCaddyConfig extends DataClass
    implements Insertable<SavedCaddyConfig> {
  final int id;
  final String name;
  final String configJson;
  final bool adminEnabled;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SavedCaddyConfig({
    required this.id,
    required this.name,
    required this.configJson,
    required this.adminEnabled,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['config_json'] = Variable<String>(configJson);
    map['admin_enabled'] = Variable<bool>(adminEnabled);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CaddyConfigsCompanion toCompanion(bool nullToAbsent) {
    return CaddyConfigsCompanion(
      id: Value(id),
      name: Value(name),
      configJson: Value(configJson),
      adminEnabled: Value(adminEnabled),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SavedCaddyConfig.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedCaddyConfig(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      configJson: serializer.fromJson<String>(json['configJson']),
      adminEnabled: serializer.fromJson<bool>(json['adminEnabled']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'configJson': serializer.toJson<String>(configJson),
      'adminEnabled': serializer.toJson<bool>(adminEnabled),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SavedCaddyConfig copyWith({
    int? id,
    String? name,
    String? configJson,
    bool? adminEnabled,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SavedCaddyConfig(
    id: id ?? this.id,
    name: name ?? this.name,
    configJson: configJson ?? this.configJson,
    adminEnabled: adminEnabled ?? this.adminEnabled,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SavedCaddyConfig copyWithCompanion(CaddyConfigsCompanion data) {
    return SavedCaddyConfig(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      adminEnabled: data.adminEnabled.present
          ? data.adminEnabled.value
          : this.adminEnabled,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedCaddyConfig(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('configJson: $configJson, ')
          ..write('adminEnabled: $adminEnabled, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    configJson,
    adminEnabled,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedCaddyConfig &&
          other.id == this.id &&
          other.name == this.name &&
          other.configJson == this.configJson &&
          other.adminEnabled == this.adminEnabled &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CaddyConfigsCompanion extends UpdateCompanion<SavedCaddyConfig> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> configJson;
  final Value<bool> adminEnabled;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CaddyConfigsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.configJson = const Value.absent(),
    this.adminEnabled = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CaddyConfigsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String configJson,
    this.adminEnabled = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       configJson = Value(configJson);
  static Insertable<SavedCaddyConfig> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? configJson,
    Expression<bool>? adminEnabled,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (configJson != null) 'config_json': configJson,
      if (adminEnabled != null) 'admin_enabled': adminEnabled,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CaddyConfigsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? configJson,
    Value<bool>? adminEnabled,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CaddyConfigsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      configJson: configJson ?? this.configJson,
      adminEnabled: adminEnabled ?? this.adminEnabled,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (adminEnabled.present) {
      map['admin_enabled'] = Variable<bool>(adminEnabled.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaddyConfigsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('configJson: $configJson, ')
          ..write('adminEnabled: $adminEnabled, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CaddyConfigsTable caddyConfigs = $CaddyConfigsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [caddyConfigs];
}

typedef $$CaddyConfigsTableCreateCompanionBuilder =
    CaddyConfigsCompanion Function({
      Value<int> id,
      required String name,
      required String configJson,
      Value<bool> adminEnabled,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CaddyConfigsTableUpdateCompanionBuilder =
    CaddyConfigsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> configJson,
      Value<bool> adminEnabled,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$CaddyConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $CaddyConfigsTable> {
  $$CaddyConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get adminEnabled => $composableBuilder(
    column: $table.adminEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CaddyConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $CaddyConfigsTable> {
  $$CaddyConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get adminEnabled => $composableBuilder(
    column: $table.adminEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CaddyConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CaddyConfigsTable> {
  $$CaddyConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get adminEnabled => $composableBuilder(
    column: $table.adminEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CaddyConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CaddyConfigsTable,
          SavedCaddyConfig,
          $$CaddyConfigsTableFilterComposer,
          $$CaddyConfigsTableOrderingComposer,
          $$CaddyConfigsTableAnnotationComposer,
          $$CaddyConfigsTableCreateCompanionBuilder,
          $$CaddyConfigsTableUpdateCompanionBuilder,
          (
            SavedCaddyConfig,
            BaseReferences<_$AppDatabase, $CaddyConfigsTable, SavedCaddyConfig>,
          ),
          SavedCaddyConfig,
          PrefetchHooks Function()
        > {
  $$CaddyConfigsTableTableManager(_$AppDatabase db, $CaddyConfigsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CaddyConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CaddyConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CaddyConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> configJson = const Value.absent(),
                Value<bool> adminEnabled = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CaddyConfigsCompanion(
                id: id,
                name: name,
                configJson: configJson,
                adminEnabled: adminEnabled,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String configJson,
                Value<bool> adminEnabled = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CaddyConfigsCompanion.insert(
                id: id,
                name: name,
                configJson: configJson,
                adminEnabled: adminEnabled,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CaddyConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CaddyConfigsTable,
      SavedCaddyConfig,
      $$CaddyConfigsTableFilterComposer,
      $$CaddyConfigsTableOrderingComposer,
      $$CaddyConfigsTableAnnotationComposer,
      $$CaddyConfigsTableCreateCompanionBuilder,
      $$CaddyConfigsTableUpdateCompanionBuilder,
      (
        SavedCaddyConfig,
        BaseReferences<_$AppDatabase, $CaddyConfigsTable, SavedCaddyConfig>,
      ),
      SavedCaddyConfig,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CaddyConfigsTableTableManager get caddyConfigs =>
      $$CaddyConfigsTableTableManager(_db, _db.caddyConfigs);
}
