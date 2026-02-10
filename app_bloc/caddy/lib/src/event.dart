part of 'bloc.dart';

sealed class CaddyEvent {
  const CaddyEvent();
}

final class CaddyStart extends CaddyEvent {
  const CaddyStart(this.config);

  final CaddyConfig config;
}

final class CaddyStop extends CaddyEvent {
  const CaddyStop();
}

final class CaddyReload extends CaddyEvent {
  const CaddyReload(this.config);

  final CaddyConfig config;
}

final class CaddyStatusCheck extends CaddyEvent {
  const CaddyStatusCheck();
}

final class CaddyUpdateConfig extends CaddyEvent {
  const CaddyUpdateConfig(this.config);

  final CaddyConfig config;
}

final class CaddyLogReceived extends CaddyEvent {
  const CaddyLogReceived(this.line);

  final String line;
}

final class CaddyClearLogs extends CaddyEvent {
  const CaddyClearLogs();
}

final class CaddyToggleAdmin extends CaddyEvent {
  const CaddyToggleAdmin();
}

final class CaddySetLogFilter extends CaddyEvent {
  const CaddySetLogFilter(this.level);

  final CaddyLogLevel level;
}

final class CaddySetLogSearch extends CaddyEvent {
  const CaddySetLogSearch(this.query);

  final String query;
}

final class CaddyLifecyclePause extends CaddyEvent {
  const CaddyLifecyclePause();
}

final class CaddyLifecycleResume extends CaddyEvent {
  const CaddyLifecycleResume();
}

final class CaddyLoadSavedConfig extends CaddyEvent {
  const CaddyLoadSavedConfig();
}

final class CaddySaveConfig extends CaddyEvent {
  const CaddySaveConfig(this.name);

  final String name;
}

final class CaddyDeleteSavedConfig extends CaddyEvent {
  const CaddyDeleteSavedConfig(this.name);

  final String name;
}

final class CaddyLoadNamedConfig extends CaddyEvent {
  const CaddyLoadNamedConfig(this.name);

  final String name;
}
