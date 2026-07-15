class PrivacySafeEvent {
  const PrivacySafeEvent({required this.name, this.properties = const {}});

  final String name;
  final Map<String, Object?> properties;
}

abstract interface class AnalyticsSink {
  Future<void> record(PrivacySafeEvent event);
}
