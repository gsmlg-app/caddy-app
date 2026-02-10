import 'dart:async';
import 'dart:convert';

import 'package:app_database/app_database.dart';
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:bloc/bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:equatable/equatable.dart';

part 'event.dart';
part 'state.dart';

class CaddyBloc extends Bloc<CaddyEvent, CaddyState> {
  CaddyBloc(this._service, {AppDatabase? database, VaultRepository? vault})
    : _database = database,
      _vault = vault,
      super(CaddyState.initial()) {
    on<CaddyStart>(_onStart);
    on<CaddyStop>(_onStop);
    on<CaddyReload>(_onReload);
    on<CaddyStatusCheck>(_onStatusCheck);
    on<CaddyUpdateConfig>(_onUpdateConfig);
    on<CaddyLogReceived>(_onLogReceived);
    on<CaddyClearLogs>(_onClearLogs);
    on<CaddyToggleAdmin>(_onToggleAdmin);
    on<CaddySetLogFilter>(_onSetLogFilter);
    on<CaddySetLogSearch>(_onSetLogSearch);
    on<CaddyLifecyclePause>(_onLifecyclePause);
    on<CaddyLifecycleResume>(_onLifecycleResume);
    on<CaddyLoadSavedConfig>(_onLoadSavedConfig);
    on<CaddySaveConfig>(_onSaveConfig);
    on<CaddyDeleteSavedConfig>(_onDeleteSavedConfig);
    on<CaddyLoadNamedConfig>(_onLoadNamedConfig);

    _logSubscription = _service.logStream.listen(
      (line) => add(CaddyLogReceived(line)),
    );
  }

  final CaddyService _service;
  final AppDatabase? _database;
  final VaultRepository? _vault;
  StreamSubscription<String>? _logSubscription;
  CaddyConfig? _configBeforePause;

  static const _secretPrefix = 'caddy_';

  /// Reads all caddy secrets from the vault and returns them as
  /// environment variables (without the caddy_ prefix).
  Future<Map<String, String>> _readSecrets() async {
    final vault = _vault;
    if (vault == null) return const {};
    final all = await vault.readAll();
    final env = <String, String>{};
    for (final entry in all.entries) {
      if (entry.key.startsWith(_secretPrefix)) {
        env[entry.key.substring(_secretPrefix.length)] = entry.value;
      }
    }
    return env;
  }

  static const _maxLogs = 500;

  Future<void> _onStart(CaddyStart event, Emitter<CaddyState> emit) async {
    emit(state.copyWith(status: const CaddyLoading(), config: event.config));
    final secrets = await _readSecrets();
    final status = await _service.start(
      event.config,
      adminEnabled: state.adminEnabled,
      environment: secrets,
    );
    emit(state.copyWith(status: status));
  }

  Future<void> _onStop(CaddyStop event, Emitter<CaddyState> emit) async {
    emit(state.copyWith(status: const CaddyLoading()));
    final status = await _service.stop();
    emit(state.copyWith(status: status));
  }

  Future<void> _onReload(CaddyReload event, Emitter<CaddyState> emit) async {
    emit(state.copyWith(status: const CaddyLoading(), config: event.config));
    final secrets = await _readSecrets();
    final status = await _service.reload(
      event.config,
      adminEnabled: state.adminEnabled,
      environment: secrets,
    );
    emit(state.copyWith(status: status));
  }

  Future<void> _onStatusCheck(
    CaddyStatusCheck event,
    Emitter<CaddyState> emit,
  ) async {
    final status = await _service.getStatus();
    emit(state.copyWith(status: status, lastStatusCheck: DateTime.now()));
  }

  void _onUpdateConfig(CaddyUpdateConfig event, Emitter<CaddyState> emit) {
    emit(state.copyWith(config: event.config));
  }

  void _onLogReceived(CaddyLogReceived event, Emitter<CaddyState> emit) {
    final logs = [...state.logs, event.line];
    if (logs.length > _maxLogs) {
      logs.removeRange(0, logs.length - _maxLogs);
    }
    emit(state.copyWith(logs: logs));
  }

  void _onClearLogs(CaddyClearLogs event, Emitter<CaddyState> emit) {
    emit(state.copyWith(logs: []));
  }

  void _onToggleAdmin(CaddyToggleAdmin event, Emitter<CaddyState> emit) {
    emit(state.copyWith(adminEnabled: !state.adminEnabled));
  }

  void _onSetLogFilter(CaddySetLogFilter event, Emitter<CaddyState> emit) {
    emit(state.copyWith(logFilter: event.level));
  }

  void _onSetLogSearch(CaddySetLogSearch event, Emitter<CaddyState> emit) {
    emit(state.copyWith(logSearchQuery: event.query));
  }

  Future<void> _onLifecyclePause(
    CaddyLifecyclePause event,
    Emitter<CaddyState> emit,
  ) async {
    if (state.isRunning) {
      _configBeforePause = state.config;
      final status = await _service.stop();
      emit(state.copyWith(status: status));
    }
  }

  Future<void> _onLifecycleResume(
    CaddyLifecycleResume event,
    Emitter<CaddyState> emit,
  ) async {
    final config = _configBeforePause;
    if (config != null) {
      _configBeforePause = null;
      emit(state.copyWith(status: const CaddyLoading()));
      final secrets = await _readSecrets();
      final status = await _service.start(config, environment: secrets);
      emit(state.copyWith(status: status));
    }
  }

  Future<void> _onLoadSavedConfig(
    CaddyLoadSavedConfig event,
    Emitter<CaddyState> emit,
  ) async {
    final db = _database;
    if (db == null) return;

    final configs = await db.getAllCaddyConfigs();
    final names = configs.map((c) => c.name).toList();
    final active = configs.where((c) => c.isActive).firstOrNull;

    if (active != null) {
      final config = CaddyConfig.fromJson(
        jsonDecode(active.configJson) as Map<String, dynamic>,
      );
      emit(
        state.copyWith(
          config: config,
          adminEnabled: active.adminEnabled,
          savedConfigNames: names,
          activeConfigName: active.name,
        ),
      );
    } else {
      emit(state.copyWith(savedConfigNames: names));
    }
  }

  Future<void> _onSaveConfig(
    CaddySaveConfig event,
    Emitter<CaddyState> emit,
  ) async {
    final db = _database;
    if (db == null) return;

    final configJson = jsonEncode(state.config.toStorageJson());
    await db.upsertCaddyConfig(
      name: event.name,
      configJson: configJson,
      adminEnabled: state.adminEnabled,
      isActive: true,
    );
    await db.setActiveCaddyConfig(event.name);

    final configs = await db.getAllCaddyConfigs();
    final names = configs.map((c) => c.name).toList();
    emit(state.copyWith(savedConfigNames: names, activeConfigName: event.name));
  }

  Future<void> _onDeleteSavedConfig(
    CaddyDeleteSavedConfig event,
    Emitter<CaddyState> emit,
  ) async {
    final db = _database;
    if (db == null) return;

    await db.deleteCaddyConfig(event.name);
    final configs = await db.getAllCaddyConfigs();
    final names = configs.map((c) => c.name).toList();
    final newActive = state.activeConfigName == event.name
        ? null
        : state.activeConfigName;
    emit(state.copyWith(savedConfigNames: names, activeConfigName: newActive));
  }

  Future<void> _onLoadNamedConfig(
    CaddyLoadNamedConfig event,
    Emitter<CaddyState> emit,
  ) async {
    final db = _database;
    if (db == null) return;

    final saved = await db.getCaddyConfigByName(event.name);
    if (saved == null) return;

    final config = CaddyConfig.fromJson(
      jsonDecode(saved.configJson) as Map<String, dynamic>,
    );
    await db.setActiveCaddyConfig(event.name);
    emit(
      state.copyWith(
        config: config,
        adminEnabled: saved.adminEnabled,
        activeConfigName: event.name,
      ),
    );
  }

  @override
  Future<void> close() {
    _logSubscription?.cancel();
    return super.close();
  }
}
