// This is a generated file - do not edit.
//
// Generated from etm_ticket.proto.

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

class TicketRecord extends $pb.GeneratedMessage {
  factory TicketRecord({
    $core.String? ticketId,
    $core.String? deviceId,
    $core.String? conductorId,
    $core.String? tripId,
    $core.String? fareRuleId,
    $core.String? boardingStopId,
    $core.String? destinationStopId,
    $fixnum.Int64? fareAmountPaise,
    $fixnum.Int64? capturedAtEpochMs,
    $core.String? currency,
    $core.String? commuterId,
    $core.int? ticketSequenceNumber,
  }) {
    final result = create();
    if (ticketId != null) result.ticketId = ticketId;
    if (deviceId != null) result.deviceId = deviceId;
    if (conductorId != null) result.conductorId = conductorId;
    if (tripId != null) result.tripId = tripId;
    if (fareRuleId != null) result.fareRuleId = fareRuleId;
    if (boardingStopId != null) result.boardingStopId = boardingStopId;
    if (destinationStopId != null) result.destinationStopId = destinationStopId;
    if (fareAmountPaise != null) result.fareAmountPaise = fareAmountPaise;
    if (capturedAtEpochMs != null) result.capturedAtEpochMs = capturedAtEpochMs;
    if (currency != null) result.currency = currency;
    if (commuterId != null) result.commuterId = commuterId;
    if (ticketSequenceNumber != null)
      result.ticketSequenceNumber = ticketSequenceNumber;
    return result;
  }

  TicketRecord._();

  factory TicketRecord.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TicketRecord.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TicketRecord',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'etm.contracts'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'ticketId')
    ..aOS(2, _omitFieldNames ? '' : 'deviceId')
    ..aOS(3, _omitFieldNames ? '' : 'conductorId')
    ..aOS(4, _omitFieldNames ? '' : 'tripId')
    ..aOS(5, _omitFieldNames ? '' : 'fareRuleId')
    ..aOS(6, _omitFieldNames ? '' : 'boardingStopId')
    ..aOS(7, _omitFieldNames ? '' : 'destinationStopId')
    ..aInt64(8, _omitFieldNames ? '' : 'fareAmountPaise')
    ..aInt64(9, _omitFieldNames ? '' : 'capturedAtEpochMs')
    ..aOS(10, _omitFieldNames ? '' : 'currency')
    ..aOS(11, _omitFieldNames ? '' : 'commuterId')
    ..aI(12, _omitFieldNames ? '' : 'ticketSequenceNumber')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TicketRecord clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TicketRecord copyWith(void Function(TicketRecord) updates) =>
      super.copyWith((message) => updates(message as TicketRecord))
          as TicketRecord;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TicketRecord create() => TicketRecord._();
  @$core.override
  TicketRecord createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TicketRecord getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TicketRecord>(create);
  static TicketRecord? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get ticketId => $_getSZ(0);
  @$pb.TagNumber(1)
  set ticketId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTicketId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTicketId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get deviceId => $_getSZ(1);
  @$pb.TagNumber(2)
  set deviceId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDeviceId() => $_has(1);
  @$pb.TagNumber(2)
  void clearDeviceId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get conductorId => $_getSZ(2);
  @$pb.TagNumber(3)
  set conductorId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConductorId() => $_has(2);
  @$pb.TagNumber(3)
  void clearConductorId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get tripId => $_getSZ(3);
  @$pb.TagNumber(4)
  set tripId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTripId() => $_has(3);
  @$pb.TagNumber(4)
  void clearTripId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get fareRuleId => $_getSZ(4);
  @$pb.TagNumber(5)
  set fareRuleId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFareRuleId() => $_has(4);
  @$pb.TagNumber(5)
  void clearFareRuleId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get boardingStopId => $_getSZ(5);
  @$pb.TagNumber(6)
  set boardingStopId($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBoardingStopId() => $_has(5);
  @$pb.TagNumber(6)
  void clearBoardingStopId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get destinationStopId => $_getSZ(6);
  @$pb.TagNumber(7)
  set destinationStopId($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasDestinationStopId() => $_has(6);
  @$pb.TagNumber(7)
  void clearDestinationStopId() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get fareAmountPaise => $_getI64(7);
  @$pb.TagNumber(8)
  set fareAmountPaise($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFareAmountPaise() => $_has(7);
  @$pb.TagNumber(8)
  void clearFareAmountPaise() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get capturedAtEpochMs => $_getI64(8);
  @$pb.TagNumber(9)
  set capturedAtEpochMs($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasCapturedAtEpochMs() => $_has(8);
  @$pb.TagNumber(9)
  void clearCapturedAtEpochMs() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get currency => $_getSZ(9);
  @$pb.TagNumber(10)
  set currency($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasCurrency() => $_has(9);
  @$pb.TagNumber(10)
  void clearCurrency() => $_clearField(10);

  @$pb.TagNumber(11)
  $core.String get commuterId => $_getSZ(10);
  @$pb.TagNumber(11)
  set commuterId($core.String value) => $_setString(10, value);
  @$pb.TagNumber(11)
  $core.bool hasCommuterId() => $_has(10);
  @$pb.TagNumber(11)
  void clearCommuterId() => $_clearField(11);

  @$pb.TagNumber(12)
  $core.int get ticketSequenceNumber => $_getIZ(11);
  @$pb.TagNumber(12)
  set ticketSequenceNumber($core.int value) => $_setSignedInt32(11, value);
  @$pb.TagNumber(12)
  $core.bool hasTicketSequenceNumber() => $_has(11);
  @$pb.TagNumber(12)
  void clearTicketSequenceNumber() => $_clearField(12);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
