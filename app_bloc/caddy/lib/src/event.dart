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
