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
    on<CaddyToggleAutoRestart>(_onToggleAutoRestart);
    on<CaddyInitialize>(_onInitialize);

    _logSubscription = _service.logStream.listen(
      (line) => add(CaddyLogReceived(line)),
    );
  }

  final CaddyService _service;
  final AppDatabase? _database;
  final VaultRepository? _vault;
  StreamSubscription<String>? _logSubscription;
  CaddyTextConfig? _configBeforePause;

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

  /// Converts a [CaddyTextConfig] to Caddy JSON, handling Caddyfile
  /// adaptation and admin config injection.
  Future<String> _prepareConfigJson(CaddyTextConfig config) async {
    String json;
    if (config.format == ConfigFormat.caddyfile) {
      final String result;
      try {
        result = await _service.adaptCaddyfile(config.text);
      } catch (e) {
        throw Exception(
          'Failed to convert Caddyfile to JSON. '
          'Rebuild the Go bridge: cd go/caddy_bridge && make linux\n'
          'Detail: $e',
        );
      }
      // Check if the adapter returned an error
      if (result.contains('"error"')) {
        try {
          final parsed = jsonDecode(result) as Map<String, dynamic>;
          if (parsed.containsKey('error')) {
            throw Exception(parsed['error']);
          }
        } on FormatException {
          // Not a JSON error response, treat as valid JSON output
        }
      }
      json = result;
    } else {
      json = config.text;
    }
    return _injectAdmin(json, state.adminEnabled);
  }

  /// Injects or disables the admin API in a Caddy JSON config string.
  String _injectAdmin(String configJson, bool adminEnabled) {
    try {
      final map = jsonDecode(configJson) as Map<String, dynamic>;
      if (adminEnabled) {
        map['admin'] = {'listen': 'localhost:2019'};
      } else {
        map['admin'] = {'disabled': true};
      }
      return jsonEncode(map);
    } catch (_) {
      // If JSON is invalid, return as-is — the error will surface at load time
      return configJson;
    }
  }

  static const _maxLogs = 10000;

  Future<void> _onStart(CaddyStart event, Emitter<CaddyState> emit) async {
    if (event.config.isEmpty) {
      emit(
        state.copyWith(
          status: const CaddyError(message: 'Configuration is empty'),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: const CaddyLoading(),
        config: event.config,
        requestCount: 0,
      ),
    );
    try {
      final configJson = await _prepareConfigJson(event.config);
      final secrets = await _readSecrets();
      final status = await _service.start(configJson, environment: secrets);
      emit(state.copyWith(status: status));
    } catch (e) {
      emit(state.copyWith(status: CaddyError(message: e.toString())));
    }
  }

  Future<void> _onStop(CaddyStop event, Emitter<CaddyState> emit) async {
    emit(state.copyWith(status: const CaddyLoading()));
    final status = await _service.stop();
    emit(state.copyWith(status: status));
  }

  Future<void> _onReload(CaddyReload event, Emitter<CaddyState> emit) async {
    emit(state.copyWith(status: const CaddyLoading(), config: event.config));
    try {
      final configJson = await _prepareConfigJson(event.config);
      final secrets = await _readSecrets();
      final status = await _service.reload(configJson, environment: secrets);
      emit(state.copyWith(status: status));
    } catch (e) {
      emit(state.copyWith(status: CaddyError(message: e.toString())));
    }
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
    // Caddy logs HTTP requests with "handled request" message
    final isRequest =
        event.line.contains('"handled request"') ||
        event.line.contains('handled request');
    emit(
      state.copyWith(
        logs: logs,
        requestCount: isRequest ? state.requestCount + 1 : null,
      ),
    );
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

  void _onToggleAutoRestart(
    CaddyToggleAutoRestart event,
    Emitter<CaddyState> emit,
  ) {
    emit(state.copyWith(autoRestartOnResume: !state.autoRestartOnResume));
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
    if (config != null && state.autoRestartOnResume) {
      _configBeforePause = null;
      emit(state.copyWith(status: const CaddyLoading()));
      try {
        final configJson = await _prepareConfigJson(config);
        final secrets = await _readSecrets();
        final status = await _service.start(configJson, environment: secrets);
        emit(state.copyWith(status: status));
      } catch (e) {
        emit(state.copyWith(status: CaddyError(message: e.toString())));
      }
    } else {
      _configBeforePause = null;
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
      final config = CaddyTextConfig.fromJson(
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

    final configJson = jsonEncode(state.config.toJson());
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

    final config = CaddyTextConfig.fromJson(
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

  /// Checks Caddy status at initialization to detect orphaned instances
  /// from unclean shutdowns. If Caddy is found already running, it is
  /// stopped to ensure a clean state. Also loads saved configs from DB.
  Future<void> _onInitialize(
    CaddyInitialize event,
    Emitter<CaddyState> emit,
  ) async {
    final status = await _service.getStatus();
    if (status is CaddyRunning) {
      // Orphaned Caddy instance detected — stop it for a clean start.
      await _service.stop();
    }

    // Load saved configs from database.
    final db = _database;
    if (db != null) {
      final configs = await db.getAllCaddyConfigs();
      final names = configs.map((c) => c.name).toList();
      final active = configs.where((c) => c.isActive).firstOrNull;

      if (active != null) {
        final config = CaddyTextConfig.fromJson(
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
  }

  @override
  Future<void> close() {
    _logSubscription?.cancel();
    return super.close();
  }
}
