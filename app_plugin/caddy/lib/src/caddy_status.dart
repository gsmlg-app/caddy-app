sealed class CaddyStatus {
  const CaddyStatus();
}

final class CaddyStopped extends CaddyStatus {
  const CaddyStopped();
}

final class CaddyRunning extends CaddyStatus {
  const CaddyRunning({required this.config, required this.startedAt});

  final String config;
  final DateTime startedAt;
}

final class CaddyError extends CaddyStatus {
  const CaddyError({required this.message});

  final String message;
}

final class CaddyLoading extends CaddyStatus {
  const CaddyLoading();
}
