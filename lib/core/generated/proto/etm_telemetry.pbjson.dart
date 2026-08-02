// This is a generated file - do not edit.
//
// Generated from etm_telemetry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use telemetryPingRecordDescriptor instead')
const TelemetryPingRecord$json = {
  '1': 'TelemetryPingRecord',
  '2': [
    {'1': 'ping_id', '3': 1, '4': 1, '5': 9, '10': 'pingId'},
    {'1': 'device_id', '3': 2, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'latitude', '3': 3, '4': 1, '5': 1, '10': 'latitude'},
    {'1': 'longitude', '3': 4, '4': 1, '5': 1, '10': 'longitude'},
    {'1': 'speed_mps', '3': 5, '4': 1, '5': 2, '10': 'speedMps'},
    {'1': 'heading_degrees', '3': 6, '4': 1, '5': 2, '10': 'headingDegrees'},
    {
      '1': 'captured_at_epoch_ms',
      '3': 7,
      '4': 1,
      '5': 3,
      '10': 'capturedAtEpochMs'
    },
    {'1': 'trip_id', '3': 8, '4': 1, '5': 9, '10': 'tripId'},
    {'1': 'battery_level_pct', '3': 9, '4': 1, '5': 5, '10': 'batteryLevelPct'},
    {'1': 'is_charging', '3': 10, '4': 1, '5': 8, '10': 'isCharging'},
  ],
};

/// Descriptor for `TelemetryPingRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List telemetryPingRecordDescriptor = $convert.base64Decode(
    'ChNUZWxlbWV0cnlQaW5nUmVjb3JkEhcKB3BpbmdfaWQYASABKAlSBnBpbmdJZBIbCglkZXZpY2'
    'VfaWQYAiABKAlSCGRldmljZUlkEhoKCGxhdGl0dWRlGAMgASgBUghsYXRpdHVkZRIcCglsb25n'
    'aXR1ZGUYBCABKAFSCWxvbmdpdHVkZRIbCglzcGVlZF9tcHMYBSABKAJSCHNwZWVkTXBzEicKD2'
    'hlYWRpbmdfZGVncmVlcxgGIAEoAlIOaGVhZGluZ0RlZ3JlZXMSLwoUY2FwdHVyZWRfYXRfZXBv'
    'Y2hfbXMYByABKANSEWNhcHR1cmVkQXRFcG9jaE1zEhcKB3RyaXBfaWQYCCABKAlSBnRyaXBJZB'
    'IqChFiYXR0ZXJ5X2xldmVsX3BjdBgJIAEoBVIPYmF0dGVyeUxldmVsUGN0Eh8KC2lzX2NoYXJn'
    'aW5nGAogASgIUgppc0NoYXJnaW5n');
