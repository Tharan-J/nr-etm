// This is a generated file - do not edit.
//
// Generated from etm_ticket.proto.

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

@$core.Deprecated('Use ticketRecordDescriptor instead')
const TicketRecord$json = {
  '1': 'TicketRecord',
  '2': [
    {'1': 'ticket_id', '3': 1, '4': 1, '5': 9, '10': 'ticketId'},
    {'1': 'device_id', '3': 2, '4': 1, '5': 9, '10': 'deviceId'},
    {'1': 'conductor_id', '3': 3, '4': 1, '5': 9, '10': 'conductorId'},
    {'1': 'trip_id', '3': 4, '4': 1, '5': 9, '10': 'tripId'},
    {'1': 'fare_rule_id', '3': 5, '4': 1, '5': 9, '10': 'fareRuleId'},
    {'1': 'boarding_stop_id', '3': 6, '4': 1, '5': 9, '10': 'boardingStopId'},
    {
      '1': 'destination_stop_id',
      '3': 7,
      '4': 1,
      '5': 9,
      '10': 'destinationStopId'
    },
    {'1': 'fare_amount_paise', '3': 8, '4': 1, '5': 3, '10': 'fareAmountPaise'},
    {
      '1': 'captured_at_epoch_ms',
      '3': 9,
      '4': 1,
      '5': 3,
      '10': 'capturedAtEpochMs'
    },
    {'1': 'currency', '3': 10, '4': 1, '5': 9, '10': 'currency'},
    {'1': 'commuter_id', '3': 11, '4': 1, '5': 9, '10': 'commuterId'},
    {
      '1': 'ticket_sequence_number',
      '3': 12,
      '4': 1,
      '5': 5,
      '10': 'ticketSequenceNumber'
    },
  ],
};

/// Descriptor for `TicketRecord`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List ticketRecordDescriptor = $convert.base64Decode(
    'CgxUaWNrZXRSZWNvcmQSGwoJdGlja2V0X2lkGAEgASgJUgh0aWNrZXRJZBIbCglkZXZpY2VfaW'
    'QYAiABKAlSCGRldmljZUlkEiEKDGNvbmR1Y3Rvcl9pZBgDIAEoCVILY29uZHVjdG9ySWQSFwoH'
    'dHJpcF9pZBgEIAEoCVIGdHJpcElkEiAKDGZhcmVfcnVsZV9pZBgFIAEoCVIKZmFyZVJ1bGVJZB'
    'IoChBib2FyZGluZ19zdG9wX2lkGAYgASgJUg5ib2FyZGluZ1N0b3BJZBIuChNkZXN0aW5hdGlv'
    'bl9zdG9wX2lkGAcgASgJUhFkZXN0aW5hdGlvblN0b3BJZBIqChFmYXJlX2Ftb3VudF9wYWlzZR'
    'gIIAEoA1IPZmFyZUFtb3VudFBhaXNlEi8KFGNhcHR1cmVkX2F0X2Vwb2NoX21zGAkgASgDUhFj'
    'YXB0dXJlZEF0RXBvY2hNcxIaCghjdXJyZW5jeRgKIAEoCVIIY3VycmVuY3kSHwoLY29tbXV0ZX'
    'JfaWQYCyABKAlSCmNvbW11dGVySWQSNAoWdGlja2V0X3NlcXVlbmNlX251bWJlchgMIAEoBVIU'
    'dGlja2V0U2VxdWVuY2VOdW1iZXI=');
