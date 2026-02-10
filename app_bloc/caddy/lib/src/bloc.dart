import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:caddy_service/caddy_service.dart';
import 'package:equatable/equatable.dart';

part 'event.dart';
part 'state.dart';

class CaddyBloc extends Bloc<CaddyEvent, CaddyState> {
  CaddyBloc(this._service) : super(CaddyState.initial()) {
    on<CaddyStart>(_onStart);
    on<CaddyStop>(_onStop);
    on<CaddyReload>(_onReload);
    on<CaddyStatusCheck>(_onStatusCheck);
    on<CaddyUpdateConfig>(_onUpdateConfig);
    on<CaddyLogReceived>(_onLogReceived);
    on<CaddyClearLogs>(_onClearLogs);

    _logSubscription = _service.logStream.listen(
      (line) => add(CaddyLogReceived(line)),
    );
  }

  final CaddyService _service;
  StreamSubscription<String>? _logSubscription;

  static const _maxLogs = 500;

  Future<void> _onStart(CaddyStart event, Emitter<CaddyState> emit) async {
    emit(state.copyWith(status: const CaddyLoading(), config: event.config));
    final status = await _service.start(event.config);
    emit(state.copyWith(status: status));
  }

  Future<void> _onStop(CaddyStop event, Emitter<CaddyState> emit) async {
    emit(state.copyWith(status: const CaddyLoading()));
    final status = await _service.stop();
    emit(state.copyWith(status: status));
  }

  Future<void> _onReload(CaddyReload event, Emitter<CaddyState> emit) async {
    emit(state.copyWith(status: const CaddyLoading(), config: event.config));
    final status = await _service.reload(event.config);
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

  @override
  Future<void> close() {
    _logSubscription?.cancel();
    return super.close();
  }
}
