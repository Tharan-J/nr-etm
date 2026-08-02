class PairingRequest {
  final String deviceId;
  final String conductorPin;
  final String busId;

  const PairingRequest({
    required this.deviceId,
    required this.conductorPin,
    required this.busId,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'conductor_pin': conductorPin,
      'bus_id': busId,
    };
  }
}

class PairingResponse {
  final String token;
  final String conductorId;
  final String sessionId;
  final String? refreshToken;

  const PairingResponse({
    required this.token,
    required this.conductorId,
    required this.sessionId,
    this.refreshToken,
  });

  factory PairingResponse.fromJson(Map<String, dynamic> json) {
    return PairingResponse(
      token: json['token'] as String,
      conductorId: json['conductor_id'] as String,
      sessionId: json['session_id'] as String,
      refreshToken: json['refresh_token'] as String?,
    );
  }
}
