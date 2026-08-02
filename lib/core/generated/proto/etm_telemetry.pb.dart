// This is a generated file - do not edit.
//
// Generated from etm_telemetry.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class TelemetryPingRecord extends $pb.GeneratedMessage {
  factory TelemetryPingRecord({
    $core.String? pingId,
    $core.String? deviceId,
    $core.double? latitude,
    $core.double? longitude,
    $core.double? speedMps,
    $core.double? headingDegrees,
    $fixnum.Int64? capturedAtEpochMs,
    $core.String? tripId,
    $core.int? batteryLevelPct,
    $core.bool? isCharging,
  }) {
    final result = create();
    if (pingId != null) result.pingId = pingId;
    if (deviceId != null) result.deviceId = deviceId;
    if (latitude != null) result.latitude = latitude;
    if (longitude != null) result.longitude = longitude;
    if (speedMps != null) result.speedMps = speedMps;
    if (headingDegrees != null) result.headingDegrees = headingDegrees;
    if (capturedAtEpochMs != null) result.capturedAtEpochMs = capturedAtEpochMs;
    if (tripId != null) result.tripId = tripId;
    if (batteryLevelPct != null) result.batteryLevelPct = batteryLevelPct;
    if (isCharging != null) result.isCharging = isCharging;
    return result;
  }

  TelemetryPingRecord._();

  factory TelemetryPingRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TelemetryPingRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TelemetryPingRecord',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'etm.contracts'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'pingId')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aD(3, _omitFieldNames ? '' : 'latitude')
    ..aD(4, _omitFieldNames ? '' : 'longitude')
    ..aD(5, _omitFieldNames ? '' : 'speedMps', fieldType: $pb.PbFieldType.OF)
    ..aD(6, _omitFieldNames ? '' : 'headingDegrees',
        fieldType: $pb.PbFieldType.OF)
    ..aInt64(7, _omitFieldNames ? '' : 'capturedAtEpochMs')
    ..aOS(8, _omitFieldNames ? '' : 'tripId')
    ..aI(9, _omitFieldNames ? '' : 'batteryLevelPct')
    ..aOB(10, _omitFieldNames ? '' : 'isCharging')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TelemetryPingRecord clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TelemetryPingRecord copyWith(void Function(TelemetryPingRecord) updates) =>
      super.copyWith((message) => updates(message as TelemetryPingRecord))
          as TelemetryPingRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TelemetryPingRecord create() => TelemetryPingRecord._();
  @$core.override
  TelemetryPingRecord createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TelemetryPingRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TelemetryPingRecord>(create);
  static TelemetryPingRecord? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get pingId => $_getSZ(0);
  @$pb.TagNumber(1)
  set pingId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPingId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPingId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get latitude => $_getN(2);
  @$pb.TagNumber(3)
  set latitude($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLatitude() => $_has(2);
  @$pb.TagNumber(3)
  void clearLatitude() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.double get longitude => $_getN(3);
  @$pb.TagNumber(4)
  set longitude($core.double value) => $_setDouble(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLongitude() => $_has(3);
  @$pb.TagNumber(4)
  void clearLongitude() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.double get speedMps => $_getN(4);
  @$pb.TagNumber(5)
  set speedMps($core.double value) => $_setFloat(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSpeedMps() => $_has(4);
  @$pb.TagNumber(5)
  void clearSpeedMps() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.double get headingDegrees => $_getN(5);
  @$pb.TagNumber(6)
  set headingDegrees($core.double value) => $_setFloat(5, value);
  @$pb.TagNumber(6)
  $core.bool hasHeadingDegrees() => $_has(5);
  @$pb.TagNumber(6)
  void clearHeadingDegrees() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get capturedAtEpochMs => $_getI64(6);
  @$pb.TagNumber(7)
  set capturedAtEpochMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCapturedAtEpochMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearCapturedAtEpochMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get tripId => $_getSZ(7);
  @$pb.TagNumber(8)
  set tripId($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasTripId() => $_has(7);
  @$pb.TagNumber(8)
  void clearTripId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.int get batteryLevelPct => $_getIZ(8);
  @$pb.TagNumber(9)
  set batteryLevelPct($core.int value) => $_setSignedInt32(8, value);
  @$pb.TagNumber(9)
  $core.bool hasBatteryLevelPct() => $_has(8);
  @$pb.TagNumber(9)
  void clearBatteryLevelPct() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isCharging => $_getBF(9);
  @$pb.TagNumber(10)
  set isCharging($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsCharging() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsCharging() => $_clearField(10);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
