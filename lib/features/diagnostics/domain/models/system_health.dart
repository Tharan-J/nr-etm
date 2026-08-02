enum HealthStatus { healthy, degraded, critical }

class SubsystemHealth {
  final String name;
  final HealthStatus status;
  final String message;
  final DateTime lastChecked;

  const SubsystemHealth({
    required this.name,
    required this.status,
    required this.message,
    required this.lastChecked,
  });
}

class SystemHealthReport {
  final HealthStatus overallStatus;
  final Map<String, SubsystemHealth> subsystems;
  final DateTime generatedAt;

  const SystemHealthReport({
    required this.overallStatus,
    required this.subsystems,
    required this.generatedAt,
  });
}

class SelfCheckItem {
  final String category;
  final bool isPassed;
  final String message;

  const SelfCheckItem({
    required this.category,
    required this.isPassed,
    required this.message,
  });
}

class SelfTestReport {
  final List<SelfCheckItem> items;
  final DateTime timestamp;

  bool get isAllPassed => items.every((i) => i.isPassed);

  const SelfTestReport({required this.items, required this.timestamp});
}
