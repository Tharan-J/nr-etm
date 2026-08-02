enum AuthStatus {
  unpaired,
  authenticating,
  authenticated,
  sessionExpired,
  denied,
}

class ConductorSession {
  final String sessionId;
  final String deviceId;
  final String? conductorId;
  final String? busId;
  final String? tripId;
  final AuthStatus status;
  final DateTime lastSyncAt;

  const ConductorSession({
    required this.sessionId,
    required this.deviceId,
    this.conductorId,
    this.busId,
    this.tripId,
    required this.status,
    required this.lastSyncAt,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  ConductorSession copyWith({
    String? sessionId,
    String? deviceId,
    String? conductorId,
    String? busId,
    String? tripId,
    AuthStatus? status,
    DateTime? lastSyncAt,
  }) {
    return ConductorSession(
      sessionId: sessionId ?? this.sessionId,
      deviceId: deviceId ?? this.deviceId,
      conductorId: conductorId ?? this.conductorId,
      busId: busId ?? this.busId,
      tripId: tripId ?? this.tripId,
      status: status ?? this.status,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}
