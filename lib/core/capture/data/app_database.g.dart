// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $MetadataTableTable extends MetadataTable
    with TableInfo<$MetadataTableTable, MetadataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetadataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metadata_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MetadataTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MetadataTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetadataTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $MetadataTableTable createAlias(String alias) {
    return $MetadataTableTable(attachedDatabase, alias);
  }
}

class MetadataTableData extends DataClass
    implements Insertable<MetadataTableData> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const MetadataTableData({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MetadataTableCompanion toCompanion(bool nullToAbsent) {
    return MetadataTableCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory MetadataTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetadataTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MetadataTableData copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => MetadataTableData(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MetadataTableData copyWithCompanion(MetadataTableCompanion data) {
    return MetadataTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetadataTableData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetadataTableData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class MetadataTableCompanion extends UpdateCompanion<MetadataTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MetadataTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MetadataTableCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<MetadataTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MetadataTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MetadataTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetadataTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TicketTableTable extends TicketTable
    with TableInfo<$TicketTableTable, TicketTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TicketTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ticketIdMeta = const VerificationMeta(
    'ticketId',
  );
  @override
  late final GeneratedColumn<String> ticketId = GeneratedColumn<String>(
    'ticket_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conductorIdMeta = const VerificationMeta(
    'conductorId',
  );
  @override
  late final GeneratedColumn<String> conductorId = GeneratedColumn<String>(
    'conductor_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fareRuleIdMeta = const VerificationMeta(
    'fareRuleId',
  );
  @override
  late final GeneratedColumn<String> fareRuleId = GeneratedColumn<String>(
    'fare_rule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boardingStopIdMeta = const VerificationMeta(
    'boardingStopId',
  );
  @override
  late final GeneratedColumn<String> boardingStopId = GeneratedColumn<String>(
    'boarding_stop_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationStopIdMeta = const VerificationMeta(
    'destinationStopId',
  );
  @override
  late final GeneratedColumn<String> destinationStopId =
      GeneratedColumn<String>(
        'destination_stop_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _fareAmountPaiseMeta = const VerificationMeta(
    'fareAmountPaise',
  );
  @override
  late final GeneratedColumn<BigInt> fareAmountPaise = GeneratedColumn<BigInt>(
    'fare_amount_paise',
    aliasedName,
    false,
    type: DriftSqlType.bigInt,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INR'),
  );
  static const VerificationMeta _commuterIdMeta = const VerificationMeta(
    'commuterId',
  );
  @override
  late final GeneratedColumn<String> commuterId = GeneratedColumn<String>(
    'commuter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ticketSequenceNumberMeta =
      const VerificationMeta('ticketSequenceNumber');
  @override
  late final GeneratedColumn<int> ticketSequenceNumber = GeneratedColumn<int>(
    'ticket_sequence_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('buffered'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    ticketId,
    deviceId,
    conductorId,
    tripId,
    fareRuleId,
    boardingStopId,
    destinationStopId,
    fareAmountPaise,
    capturedAt,
    currency,
    commuterId,
    ticketSequenceNumber,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ticket_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TicketTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ticket_id')) {
      context.handle(
        _ticketIdMeta,
        ticketId.isAcceptableOrUnknown(data['ticket_id']!, _ticketIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ticketIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('conductor_id')) {
      context.handle(
        _conductorIdMeta,
        conductorId.isAcceptableOrUnknown(
          data['conductor_id']!,
          _conductorIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conductorIdMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('fare_rule_id')) {
      context.handle(
        _fareRuleIdMeta,
        fareRuleId.isAcceptableOrUnknown(
          data['fare_rule_id']!,
          _fareRuleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fareRuleIdMeta);
    }
    if (data.containsKey('boarding_stop_id')) {
      context.handle(
        _boardingStopIdMeta,
        boardingStopId.isAcceptableOrUnknown(
          data['boarding_stop_id']!,
          _boardingStopIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_boardingStopIdMeta);
    }
    if (data.containsKey('destination_stop_id')) {
      context.handle(
        _destinationStopIdMeta,
        destinationStopId.isAcceptableOrUnknown(
          data['destination_stop_id']!,
          _destinationStopIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationStopIdMeta);
    }
    if (data.containsKey('fare_amount_paise')) {
      context.handle(
        _fareAmountPaiseMeta,
        fareAmountPaise.isAcceptableOrUnknown(
          data['fare_amount_paise']!,
          _fareAmountPaiseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fareAmountPaiseMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    }
    if (data.containsKey('commuter_id')) {
      context.handle(
        _commuterIdMeta,
        commuterId.isAcceptableOrUnknown(data['commuter_id']!, _commuterIdMeta),
      );
    }
    if (data.containsKey('ticket_sequence_number')) {
      context.handle(
        _ticketSequenceNumberMeta,
        ticketSequenceNumber.isAcceptableOrUnknown(
          data['ticket_sequence_number']!,
          _ticketSequenceNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ticketSequenceNumberMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ticketId};
  @override
  TicketTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TicketTableData(
      ticketId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ticket_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      conductorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conductor_id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      fareRuleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fare_rule_id'],
      )!,
      boardingStopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}boarding_stop_id'],
      )!,
      destinationStopId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_stop_id'],
      )!,
      fareAmountPaise: attachedDatabase.typeMapping.read(
        DriftSqlType.bigInt,
        data['${effectivePrefix}fare_amount_paise'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      commuterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commuter_id'],
      ),
      ticketSequenceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ticket_sequence_number'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $TicketTableTable createAlias(String alias) {
    return $TicketTableTable(attachedDatabase, alias);
  }
}

class TicketTableData extends DataClass implements Insertable<TicketTableData> {
  final String ticketId;
  final String deviceId;
  final String conductorId;
  final String tripId;
  final String fareRuleId;
  final String boardingStopId;
  final String destinationStopId;
  final BigInt fareAmountPaise;
  final DateTime capturedAt;
  final String currency;
  final String? commuterId;
  final int ticketSequenceNumber;
  final String syncStatus;
  const TicketTableData({
    required this.ticketId,
    required this.deviceId,
    required this.conductorId,
    required this.tripId,
    required this.fareRuleId,
    required this.boardingStopId,
    required this.destinationStopId,
    required this.fareAmountPaise,
    required this.capturedAt,
    required this.currency,
    this.commuterId,
    required this.ticketSequenceNumber,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ticket_id'] = Variable<String>(ticketId);
    map['device_id'] = Variable<String>(deviceId);
    map['conductor_id'] = Variable<String>(conductorId);
    map['trip_id'] = Variable<String>(tripId);
    map['fare_rule_id'] = Variable<String>(fareRuleId);
    map['boarding_stop_id'] = Variable<String>(boardingStopId);
    map['destination_stop_id'] = Variable<String>(destinationStopId);
    map['fare_amount_paise'] = Variable<BigInt>(fareAmountPaise);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || commuterId != null) {
      map['commuter_id'] = Variable<String>(commuterId);
    }
    map['ticket_sequence_number'] = Variable<int>(ticketSequenceNumber);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  TicketTableCompanion toCompanion(bool nullToAbsent) {
    return TicketTableCompanion(
      ticketId: Value(ticketId),
      deviceId: Value(deviceId),
      conductorId: Value(conductorId),
      tripId: Value(tripId),
      fareRuleId: Value(fareRuleId),
      boardingStopId: Value(boardingStopId),
      destinationStopId: Value(destinationStopId),
      fareAmountPaise: Value(fareAmountPaise),
      capturedAt: Value(capturedAt),
      currency: Value(currency),
      commuterId: commuterId == null && nullToAbsent
          ? const Value.absent()
          : Value(commuterId),
      ticketSequenceNumber: Value(ticketSequenceNumber),
      syncStatus: Value(syncStatus),
    );
  }

  factory TicketTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TicketTableData(
      ticketId: serializer.fromJson<String>(json['ticketId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      conductorId: serializer.fromJson<String>(json['conductorId']),
      tripId: serializer.fromJson<String>(json['tripId']),
      fareRuleId: serializer.fromJson<String>(json['fareRuleId']),
      boardingStopId: serializer.fromJson<String>(json['boardingStopId']),
      destinationStopId: serializer.fromJson<String>(json['destinationStopId']),
      fareAmountPaise: serializer.fromJson<BigInt>(json['fareAmountPaise']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      currency: serializer.fromJson<String>(json['currency']),
      commuterId: serializer.fromJson<String?>(json['commuterId']),
      ticketSequenceNumber: serializer.fromJson<int>(
        json['ticketSequenceNumber'],
      ),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ticketId': serializer.toJson<String>(ticketId),
      'deviceId': serializer.toJson<String>(deviceId),
      'conductorId': serializer.toJson<String>(conductorId),
      'tripId': serializer.toJson<String>(tripId),
      'fareRuleId': serializer.toJson<String>(fareRuleId),
      'boardingStopId': serializer.toJson<String>(boardingStopId),
      'destinationStopId': serializer.toJson<String>(destinationStopId),
      'fareAmountPaise': serializer.toJson<BigInt>(fareAmountPaise),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'currency': serializer.toJson<String>(currency),
      'commuterId': serializer.toJson<String?>(commuterId),
      'ticketSequenceNumber': serializer.toJson<int>(ticketSequenceNumber),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  TicketTableData copyWith({
    String? ticketId,
    String? deviceId,
    String? conductorId,
    String? tripId,
    String? fareRuleId,
    String? boardingStopId,
    String? destinationStopId,
    BigInt? fareAmountPaise,
    DateTime? capturedAt,
    String? currency,
    Value<String?> commuterId = const Value.absent(),
    int? ticketSequenceNumber,
    String? syncStatus,
  }) => TicketTableData(
    ticketId: ticketId ?? this.ticketId,
    deviceId: deviceId ?? this.deviceId,
    conductorId: conductorId ?? this.conductorId,
    tripId: tripId ?? this.tripId,
    fareRuleId: fareRuleId ?? this.fareRuleId,
    boardingStopId: boardingStopId ?? this.boardingStopId,
    destinationStopId: destinationStopId ?? this.destinationStopId,
    fareAmountPaise: fareAmountPaise ?? this.fareAmountPaise,
    capturedAt: capturedAt ?? this.capturedAt,
    currency: currency ?? this.currency,
    commuterId: commuterId.present ? commuterId.value : this.commuterId,
    ticketSequenceNumber: ticketSequenceNumber ?? this.ticketSequenceNumber,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  TicketTableData copyWithCompanion(TicketTableCompanion data) {
    return TicketTableData(
      ticketId: data.ticketId.present ? data.ticketId.value : this.ticketId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      conductorId: data.conductorId.present
          ? data.conductorId.value
          : this.conductorId,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      fareRuleId: data.fareRuleId.present
          ? data.fareRuleId.value
          : this.fareRuleId,
      boardingStopId: data.boardingStopId.present
          ? data.boardingStopId.value
          : this.boardingStopId,
      destinationStopId: data.destinationStopId.present
          ? data.destinationStopId.value
          : this.destinationStopId,
      fareAmountPaise: data.fareAmountPaise.present
          ? data.fareAmountPaise.value
          : this.fareAmountPaise,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      currency: data.currency.present ? data.currency.value : this.currency,
      commuterId: data.commuterId.present
          ? data.commuterId.value
          : this.commuterId,
      ticketSequenceNumber: data.ticketSequenceNumber.present
          ? data.ticketSequenceNumber.value
          : this.ticketSequenceNumber,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TicketTableData(')
          ..write('ticketId: $ticketId, ')
          ..write('deviceId: $deviceId, ')
          ..write('conductorId: $conductorId, ')
          ..write('tripId: $tripId, ')
          ..write('fareRuleId: $fareRuleId, ')
          ..write('boardingStopId: $boardingStopId, ')
          ..write('destinationStopId: $destinationStopId, ')
          ..write('fareAmountPaise: $fareAmountPaise, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('currency: $currency, ')
          ..write('commuterId: $commuterId, ')
          ..write('ticketSequenceNumber: $ticketSequenceNumber, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ticketId,
    deviceId,
    conductorId,
    tripId,
    fareRuleId,
    boardingStopId,
    destinationStopId,
    fareAmountPaise,
    capturedAt,
    currency,
    commuterId,
    ticketSequenceNumber,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TicketTableData &&
          other.ticketId == this.ticketId &&
          other.deviceId == this.deviceId &&
          other.conductorId == this.conductorId &&
          other.tripId == this.tripId &&
          other.fareRuleId == this.fareRuleId &&
          other.boardingStopId == this.boardingStopId &&
          other.destinationStopId == this.destinationStopId &&
          other.fareAmountPaise == this.fareAmountPaise &&
          other.capturedAt == this.capturedAt &&
          other.currency == this.currency &&
          other.commuterId == this.commuterId &&
          other.ticketSequenceNumber == this.ticketSequenceNumber &&
          other.syncStatus == this.syncStatus);
}

class TicketTableCompanion extends UpdateCompanion<TicketTableData> {
  final Value<String> ticketId;
  final Value<String> deviceId;
  final Value<String> conductorId;
  final Value<String> tripId;
  final Value<String> fareRuleId;
  final Value<String> boardingStopId;
  final Value<String> destinationStopId;
  final Value<BigInt> fareAmountPaise;
  final Value<DateTime> capturedAt;
  final Value<String> currency;
  final Value<String?> commuterId;
  final Value<int> ticketSequenceNumber;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const TicketTableCompanion({
    this.ticketId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.conductorId = const Value.absent(),
    this.tripId = const Value.absent(),
    this.fareRuleId = const Value.absent(),
    this.boardingStopId = const Value.absent(),
    this.destinationStopId = const Value.absent(),
    this.fareAmountPaise = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.currency = const Value.absent(),
    this.commuterId = const Value.absent(),
    this.ticketSequenceNumber = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TicketTableCompanion.insert({
    required String ticketId,
    required String deviceId,
    required String conductorId,
    required String tripId,
    required String fareRuleId,
    required String boardingStopId,
    required String destinationStopId,
    required BigInt fareAmountPaise,
    required DateTime capturedAt,
    this.currency = const Value.absent(),
    this.commuterId = const Value.absent(),
    required int ticketSequenceNumber,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ticketId = Value(ticketId),
       deviceId = Value(deviceId),
       conductorId = Value(conductorId),
       tripId = Value(tripId),
       fareRuleId = Value(fareRuleId),
       boardingStopId = Value(boardingStopId),
       destinationStopId = Value(destinationStopId),
       fareAmountPaise = Value(fareAmountPaise),
       capturedAt = Value(capturedAt),
       ticketSequenceNumber = Value(ticketSequenceNumber);
  static Insertable<TicketTableData> custom({
    Expression<String>? ticketId,
    Expression<String>? deviceId,
    Expression<String>? conductorId,
    Expression<String>? tripId,
    Expression<String>? fareRuleId,
    Expression<String>? boardingStopId,
    Expression<String>? destinationStopId,
    Expression<BigInt>? fareAmountPaise,
    Expression<DateTime>? capturedAt,
    Expression<String>? currency,
    Expression<String>? commuterId,
    Expression<int>? ticketSequenceNumber,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ticketId != null) 'ticket_id': ticketId,
      if (deviceId != null) 'device_id': deviceId,
      if (conductorId != null) 'conductor_id': conductorId,
      if (tripId != null) 'trip_id': tripId,
      if (fareRuleId != null) 'fare_rule_id': fareRuleId,
      if (boardingStopId != null) 'boarding_stop_id': boardingStopId,
      if (destinationStopId != null) 'destination_stop_id': destinationStopId,
      if (fareAmountPaise != null) 'fare_amount_paise': fareAmountPaise,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (currency != null) 'currency': currency,
      if (commuterId != null) 'commuter_id': commuterId,
      if (ticketSequenceNumber != null)
        'ticket_sequence_number': ticketSequenceNumber,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TicketTableCompanion copyWith({
    Value<String>? ticketId,
    Value<String>? deviceId,
    Value<String>? conductorId,
    Value<String>? tripId,
    Value<String>? fareRuleId,
    Value<String>? boardingStopId,
    Value<String>? destinationStopId,
    Value<BigInt>? fareAmountPaise,
    Value<DateTime>? capturedAt,
    Value<String>? currency,
    Value<String?>? commuterId,
    Value<int>? ticketSequenceNumber,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return TicketTableCompanion(
      ticketId: ticketId ?? this.ticketId,
      deviceId: deviceId ?? this.deviceId,
      conductorId: conductorId ?? this.conductorId,
      tripId: tripId ?? this.tripId,
      fareRuleId: fareRuleId ?? this.fareRuleId,
      boardingStopId: boardingStopId ?? this.boardingStopId,
      destinationStopId: destinationStopId ?? this.destinationStopId,
      fareAmountPaise: fareAmountPaise ?? this.fareAmountPaise,
      capturedAt: capturedAt ?? this.capturedAt,
      currency: currency ?? this.currency,
      commuterId: commuterId ?? this.commuterId,
      ticketSequenceNumber: ticketSequenceNumber ?? this.ticketSequenceNumber,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ticketId.present) {
      map['ticket_id'] = Variable<String>(ticketId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (conductorId.present) {
      map['conductor_id'] = Variable<String>(conductorId.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (fareRuleId.present) {
      map['fare_rule_id'] = Variable<String>(fareRuleId.value);
    }
    if (boardingStopId.present) {
      map['boarding_stop_id'] = Variable<String>(boardingStopId.value);
    }
    if (destinationStopId.present) {
      map['destination_stop_id'] = Variable<String>(destinationStopId.value);
    }
    if (fareAmountPaise.present) {
      map['fare_amount_paise'] = Variable<BigInt>(fareAmountPaise.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (commuterId.present) {
      map['commuter_id'] = Variable<String>(commuterId.value);
    }
    if (ticketSequenceNumber.present) {
      map['ticket_sequence_number'] = Variable<int>(ticketSequenceNumber.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TicketTableCompanion(')
          ..write('ticketId: $ticketId, ')
          ..write('deviceId: $deviceId, ')
          ..write('conductorId: $conductorId, ')
          ..write('tripId: $tripId, ')
          ..write('fareRuleId: $fareRuleId, ')
          ..write('boardingStopId: $boardingStopId, ')
          ..write('destinationStopId: $destinationStopId, ')
          ..write('fareAmountPaise: $fareAmountPaise, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('currency: $currency, ')
          ..write('commuterId: $commuterId, ')
          ..write('ticketSequenceNumber: $ticketSequenceNumber, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TelemetryTableTable extends TelemetryTable
    with TableInfo<$TelemetryTableTable, TelemetryTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TelemetryTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pingIdMeta = const VerificationMeta('pingId');
  @override
  late final GeneratedColumn<String> pingId = GeneratedColumn<String>(
    'ping_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _speedMpsMeta = const VerificationMeta(
    'speedMps',
  );
  @override
  late final GeneratedColumn<double> speedMps = GeneratedColumn<double>(
    'speed_mps',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headingDegreesMeta = const VerificationMeta(
    'headingDegrees',
  );
  @override
  late final GeneratedColumn<double> headingDegrees = GeneratedColumn<double>(
    'heading_degrees',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batteryLevelPctMeta = const VerificationMeta(
    'batteryLevelPct',
  );
  @override
  late final GeneratedColumn<int> batteryLevelPct = GeneratedColumn<int>(
    'battery_level_pct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isChargingMeta = const VerificationMeta(
    'isCharging',
  );
  @override
  late final GeneratedColumn<bool> isCharging = GeneratedColumn<bool>(
    'is_charging',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_charging" IN (0, 1))',
    ),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('buffered'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    pingId,
    deviceId,
    latitude,
    longitude,
    speedMps,
    headingDegrees,
    capturedAt,
    tripId,
    batteryLevelPct,
    isCharging,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'telemetry_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<TelemetryTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ping_id')) {
      context.handle(
        _pingIdMeta,
        pingId.isAcceptableOrUnknown(data['ping_id']!, _pingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pingIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('speed_mps')) {
      context.handle(
        _speedMpsMeta,
        speedMps.isAcceptableOrUnknown(data['speed_mps']!, _speedMpsMeta),
      );
    } else if (isInserting) {
      context.missing(_speedMpsMeta);
    }
    if (data.containsKey('heading_degrees')) {
      context.handle(
        _headingDegreesMeta,
        headingDegrees.isAcceptableOrUnknown(
          data['heading_degrees']!,
          _headingDegreesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_headingDegreesMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    }
    if (data.containsKey('battery_level_pct')) {
      context.handle(
        _batteryLevelPctMeta,
        batteryLevelPct.isAcceptableOrUnknown(
          data['battery_level_pct']!,
          _batteryLevelPctMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_batteryLevelPctMeta);
    }
    if (data.containsKey('is_charging')) {
      context.handle(
        _isChargingMeta,
        isCharging.isAcceptableOrUnknown(data['is_charging']!, _isChargingMeta),
      );
    } else if (isInserting) {
      context.missing(_isChargingMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pingId};
  @override
  TelemetryTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TelemetryTableData(
      pingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ping_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      speedMps: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed_mps'],
      )!,
      headingDegrees: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heading_degrees'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      ),
      batteryLevelPct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}battery_level_pct'],
      )!,
      isCharging: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_charging'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $TelemetryTableTable createAlias(String alias) {
    return $TelemetryTableTable(attachedDatabase, alias);
  }
}

class TelemetryTableData extends DataClass
    implements Insertable<TelemetryTableData> {
  final String pingId;
  final String deviceId;
  final double latitude;
  final double longitude;
  final double speedMps;
  final double headingDegrees;
  final DateTime capturedAt;
  final String? tripId;
  final int batteryLevelPct;
  final bool isCharging;
  final String syncStatus;
  const TelemetryTableData({
    required this.pingId,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.speedMps,
    required this.headingDegrees,
    required this.capturedAt,
    this.tripId,
    required this.batteryLevelPct,
    required this.isCharging,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ping_id'] = Variable<String>(pingId);
    map['device_id'] = Variable<String>(deviceId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['speed_mps'] = Variable<double>(speedMps);
    map['heading_degrees'] = Variable<double>(headingDegrees);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    if (!nullToAbsent || tripId != null) {
      map['trip_id'] = Variable<String>(tripId);
    }
    map['battery_level_pct'] = Variable<int>(batteryLevelPct);
    map['is_charging'] = Variable<bool>(isCharging);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  TelemetryTableCompanion toCompanion(bool nullToAbsent) {
    return TelemetryTableCompanion(
      pingId: Value(pingId),
      deviceId: Value(deviceId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      speedMps: Value(speedMps),
      headingDegrees: Value(headingDegrees),
      capturedAt: Value(capturedAt),
      tripId: tripId == null && nullToAbsent
          ? const Value.absent()
          : Value(tripId),
      batteryLevelPct: Value(batteryLevelPct),
      isCharging: Value(isCharging),
      syncStatus: Value(syncStatus),
    );
  }

  factory TelemetryTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TelemetryTableData(
      pingId: serializer.fromJson<String>(json['pingId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      speedMps: serializer.fromJson<double>(json['speedMps']),
      headingDegrees: serializer.fromJson<double>(json['headingDegrees']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      tripId: serializer.fromJson<String?>(json['tripId']),
      batteryLevelPct: serializer.fromJson<int>(json['batteryLevelPct']),
      isCharging: serializer.fromJson<bool>(json['isCharging']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pingId': serializer.toJson<String>(pingId),
      'deviceId': serializer.toJson<String>(deviceId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'speedMps': serializer.toJson<double>(speedMps),
      'headingDegrees': serializer.toJson<double>(headingDegrees),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'tripId': serializer.toJson<String?>(tripId),
      'batteryLevelPct': serializer.toJson<int>(batteryLevelPct),
      'isCharging': serializer.toJson<bool>(isCharging),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  TelemetryTableData copyWith({
    String? pingId,
    String? deviceId,
    double? latitude,
    double? longitude,
    double? speedMps,
    double? headingDegrees,
    DateTime? capturedAt,
    Value<String?> tripId = const Value.absent(),
    int? batteryLevelPct,
    bool? isCharging,
    String? syncStatus,
  }) => TelemetryTableData(
    pingId: pingId ?? this.pingId,
    deviceId: deviceId ?? this.deviceId,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    speedMps: speedMps ?? this.speedMps,
    headingDegrees: headingDegrees ?? this.headingDegrees,
    capturedAt: capturedAt ?? this.capturedAt,
    tripId: tripId.present ? tripId.value : this.tripId,
    batteryLevelPct: batteryLevelPct ?? this.batteryLevelPct,
    isCharging: isCharging ?? this.isCharging,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  TelemetryTableData copyWithCompanion(TelemetryTableCompanion data) {
    return TelemetryTableData(
      pingId: data.pingId.present ? data.pingId.value : this.pingId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      speedMps: data.speedMps.present ? data.speedMps.value : this.speedMps,
      headingDegrees: data.headingDegrees.present
          ? data.headingDegrees.value
          : this.headingDegrees,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      batteryLevelPct: data.batteryLevelPct.present
          ? data.batteryLevelPct.value
          : this.batteryLevelPct,
      isCharging: data.isCharging.present
          ? data.isCharging.value
          : this.isCharging,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TelemetryTableData(')
          ..write('pingId: $pingId, ')
          ..write('deviceId: $deviceId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('speedMps: $speedMps, ')
          ..write('headingDegrees: $headingDegrees, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('tripId: $tripId, ')
          ..write('batteryLevelPct: $batteryLevelPct, ')
          ..write('isCharging: $isCharging, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    pingId,
    deviceId,
    latitude,
    longitude,
    speedMps,
    headingDegrees,
    capturedAt,
    tripId,
    batteryLevelPct,
    isCharging,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TelemetryTableData &&
          other.pingId == this.pingId &&
          other.deviceId == this.deviceId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.speedMps == this.speedMps &&
          other.headingDegrees == this.headingDegrees &&
          other.capturedAt == this.capturedAt &&
          other.tripId == this.tripId &&
          other.batteryLevelPct == this.batteryLevelPct &&
          other.isCharging == this.isCharging &&
          other.syncStatus == this.syncStatus);
}

class TelemetryTableCompanion extends UpdateCompanion<TelemetryTableData> {
  final Value<String> pingId;
  final Value<String> deviceId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> speedMps;
  final Value<double> headingDegrees;
  final Value<DateTime> capturedAt;
  final Value<String?> tripId;
  final Value<int> batteryLevelPct;
  final Value<bool> isCharging;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const TelemetryTableCompanion({
    this.pingId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.speedMps = const Value.absent(),
    this.headingDegrees = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.tripId = const Value.absent(),
    this.batteryLevelPct = const Value.absent(),
    this.isCharging = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TelemetryTableCompanion.insert({
    required String pingId,
    required String deviceId,
    required double latitude,
    required double longitude,
    required double speedMps,
    required double headingDegrees,
    required DateTime capturedAt,
    this.tripId = const Value.absent(),
    required int batteryLevelPct,
    required bool isCharging,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : pingId = Value(pingId),
       deviceId = Value(deviceId),
       latitude = Value(latitude),
       longitude = Value(longitude),
       speedMps = Value(speedMps),
       headingDegrees = Value(headingDegrees),
       capturedAt = Value(capturedAt),
       batteryLevelPct = Value(batteryLevelPct),
       isCharging = Value(isCharging);
  static Insertable<TelemetryTableData> custom({
    Expression<String>? pingId,
    Expression<String>? deviceId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? speedMps,
    Expression<double>? headingDegrees,
    Expression<DateTime>? capturedAt,
    Expression<String>? tripId,
    Expression<int>? batteryLevelPct,
    Expression<bool>? isCharging,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pingId != null) 'ping_id': pingId,
      if (deviceId != null) 'device_id': deviceId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (speedMps != null) 'speed_mps': speedMps,
      if (headingDegrees != null) 'heading_degrees': headingDegrees,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (tripId != null) 'trip_id': tripId,
      if (batteryLevelPct != null) 'battery_level_pct': batteryLevelPct,
      if (isCharging != null) 'is_charging': isCharging,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TelemetryTableCompanion copyWith({
    Value<String>? pingId,
    Value<String>? deviceId,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? speedMps,
    Value<double>? headingDegrees,
    Value<DateTime>? capturedAt,
    Value<String?>? tripId,
    Value<int>? batteryLevelPct,
    Value<bool>? isCharging,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return TelemetryTableCompanion(
      pingId: pingId ?? this.pingId,
      deviceId: deviceId ?? this.deviceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedMps: speedMps ?? this.speedMps,
      headingDegrees: headingDegrees ?? this.headingDegrees,
      capturedAt: capturedAt ?? this.capturedAt,
      tripId: tripId ?? this.tripId,
      batteryLevelPct: batteryLevelPct ?? this.batteryLevelPct,
      isCharging: isCharging ?? this.isCharging,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pingId.present) {
      map['ping_id'] = Variable<String>(pingId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (speedMps.present) {
      map['speed_mps'] = Variable<double>(speedMps.value);
    }
    if (headingDegrees.present) {
      map['heading_degrees'] = Variable<double>(headingDegrees.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (batteryLevelPct.present) {
      map['battery_level_pct'] = Variable<int>(batteryLevelPct.value);
    }
    if (isCharging.present) {
      map['is_charging'] = Variable<bool>(isCharging.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TelemetryTableCompanion(')
          ..write('pingId: $pingId, ')
          ..write('deviceId: $deviceId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('speedMps: $speedMps, ')
          ..write('headingDegrees: $headingDegrees, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('tripId: $tripId, ')
          ..write('batteryLevelPct: $batteryLevelPct, ')
          ..write('isCharging: $isCharging, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboundQueueTableTable extends OutboundQueueTable
    with TableInfo<$OutboundQueueTableTable, OutboundQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboundQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadTypeMeta = const VerificationMeta(
    'payloadType',
  );
  @override
  late final GeneratedColumn<String> payloadType = GeneratedColumn<String>(
    'payload_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadBytesMeta = const VerificationMeta(
    'payloadBytes',
  );
  @override
  late final GeneratedColumn<Uint8List> payloadBytes =
      GeneratedColumn<Uint8List>(
        'payload_bytes',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payloadType,
    payloadBytes,
    createdAt,
    retryCount,
    lastAttemptAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbound_queue_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboundQueueTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload_type')) {
      context.handle(
        _payloadTypeMeta,
        payloadType.isAcceptableOrUnknown(
          data['payload_type']!,
          _payloadTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadTypeMeta);
    }
    if (data.containsKey('payload_bytes')) {
      context.handle(
        _payloadBytesMeta,
        payloadBytes.isAcceptableOrUnknown(
          data['payload_bytes']!,
          _payloadBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadBytesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboundQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboundQueueTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payloadType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_type'],
      )!,
      payloadBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload_bytes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $OutboundQueueTableTable createAlias(String alias) {
    return $OutboundQueueTableTable(attachedDatabase, alias);
  }
}

class OutboundQueueTableData extends DataClass
    implements Insertable<OutboundQueueTableData> {
  final String id;
  final String payloadType;
  final Uint8List payloadBytes;
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final String status;
  const OutboundQueueTableData({
    required this.id,
    required this.payloadType,
    required this.payloadBytes,
    required this.createdAt,
    required this.retryCount,
    this.lastAttemptAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload_type'] = Variable<String>(payloadType);
    map['payload_bytes'] = Variable<Uint8List>(payloadBytes);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  OutboundQueueTableCompanion toCompanion(bool nullToAbsent) {
    return OutboundQueueTableCompanion(
      id: Value(id),
      payloadType: Value(payloadType),
      payloadBytes: Value(payloadBytes),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      status: Value(status),
    );
  }

  factory OutboundQueueTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboundQueueTableData(
      id: serializer.fromJson<String>(json['id']),
      payloadType: serializer.fromJson<String>(json['payloadType']),
      payloadBytes: serializer.fromJson<Uint8List>(json['payloadBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payloadType': serializer.toJson<String>(payloadType),
      'payloadBytes': serializer.toJson<Uint8List>(payloadBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'status': serializer.toJson<String>(status),
    };
  }

  OutboundQueueTableData copyWith({
    String? id,
    String? payloadType,
    Uint8List? payloadBytes,
    DateTime? createdAt,
    int? retryCount,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    String? status,
  }) => OutboundQueueTableData(
    id: id ?? this.id,
    payloadType: payloadType ?? this.payloadType,
    payloadBytes: payloadBytes ?? this.payloadBytes,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    status: status ?? this.status,
  );
  OutboundQueueTableData copyWithCompanion(OutboundQueueTableCompanion data) {
    return OutboundQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      payloadType: data.payloadType.present
          ? data.payloadType.value
          : this.payloadType,
      payloadBytes: data.payloadBytes.present
          ? data.payloadBytes.value
          : this.payloadBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboundQueueTableData(')
          ..write('id: $id, ')
          ..write('payloadType: $payloadType, ')
          ..write('payloadBytes: $payloadBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    payloadType,
    $driftBlobEquality.hash(payloadBytes),
    createdAt,
    retryCount,
    lastAttemptAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboundQueueTableData &&
          other.id == this.id &&
          other.payloadType == this.payloadType &&
          $driftBlobEquality.equals(other.payloadBytes, this.payloadBytes) &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.status == this.status);
}

class OutboundQueueTableCompanion
    extends UpdateCompanion<OutboundQueueTableData> {
  final Value<String> id;
  final Value<String> payloadType;
  final Value<Uint8List> payloadBytes;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<DateTime?> lastAttemptAt;
  final Value<String> status;
  final Value<int> rowid;
  const OutboundQueueTableCompanion({
    this.id = const Value.absent(),
    this.payloadType = const Value.absent(),
    this.payloadBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboundQueueTableCompanion.insert({
    required String id,
    required String payloadType,
    required Uint8List payloadBytes,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payloadType = Value(payloadType),
       payloadBytes = Value(payloadBytes),
       createdAt = Value(createdAt);
  static Insertable<OutboundQueueTableData> custom({
    Expression<String>? id,
    Expression<String>? payloadType,
    Expression<Uint8List>? payloadBytes,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadType != null) 'payload_type': payloadType,
      if (payloadBytes != null) 'payload_bytes': payloadBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboundQueueTableCompanion copyWith({
    Value<String>? id,
    Value<String>? payloadType,
    Value<Uint8List>? payloadBytes,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<DateTime?>? lastAttemptAt,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return OutboundQueueTableCompanion(
      id: id ?? this.id,
      payloadType: payloadType ?? this.payloadType,
      payloadBytes: payloadBytes ?? this.payloadBytes,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payloadType.present) {
      map['payload_type'] = Variable<String>(payloadType.value);
    }
    if (payloadBytes.present) {
      map['payload_bytes'] = Variable<Uint8List>(payloadBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboundQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('payloadType: $payloadType, ')
          ..write('payloadBytes: $payloadBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionStateTableTable extends SessionStateTable
    with TableInfo<$SessionStateTableTable, SessionStateTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionStateTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conductorIdMeta = const VerificationMeta(
    'conductorId',
  );
  @override
  late final GeneratedColumn<String> conductorId = GeneratedColumn<String>(
    'conductor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _busIdMeta = const VerificationMeta('busId');
  @override
  late final GeneratedColumn<String> busId = GeneratedColumn<String>(
    'bus_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authStateMeta = const VerificationMeta(
    'authState',
  );
  @override
  late final GeneratedColumn<String> authState = GeneratedColumn<String>(
    'auth_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unknown'),
  );
  static const VerificationMeta _isConnectedMeta = const VerificationMeta(
    'isConnected',
  );
  @override
  late final GeneratedColumn<bool> isConnected = GeneratedColumn<bool>(
    'is_connected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_connected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    deviceId,
    conductorId,
    tripId,
    busId,
    authState,
    isConnected,
    lastSyncAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_state_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionStateTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('conductor_id')) {
      context.handle(
        _conductorIdMeta,
        conductorId.isAcceptableOrUnknown(
          data['conductor_id']!,
          _conductorIdMeta,
        ),
      );
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    }
    if (data.containsKey('bus_id')) {
      context.handle(
        _busIdMeta,
        busId.isAcceptableOrUnknown(data['bus_id']!, _busIdMeta),
      );
    }
    if (data.containsKey('auth_state')) {
      context.handle(
        _authStateMeta,
        authState.isAcceptableOrUnknown(data['auth_state']!, _authStateMeta),
      );
    }
    if (data.containsKey('is_connected')) {
      context.handle(
        _isConnectedMeta,
        isConnected.isAcceptableOrUnknown(
          data['is_connected']!,
          _isConnectedMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  SessionStateTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionStateTableData(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      conductorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conductor_id'],
      ),
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      ),
      busId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bus_id'],
      ),
      authState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_state'],
      )!,
      isConnected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_connected'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SessionStateTableTable createAlias(String alias) {
    return $SessionStateTableTable(attachedDatabase, alias);
  }
}

class SessionStateTableData extends DataClass
    implements Insertable<SessionStateTableData> {
  final String sessionId;
  final String deviceId;
  final String? conductorId;
  final String? tripId;
  final String? busId;
  final String authState;
  final bool isConnected;
  final DateTime? lastSyncAt;
  final DateTime updatedAt;
  const SessionStateTableData({
    required this.sessionId,
    required this.deviceId,
    this.conductorId,
    this.tripId,
    this.busId,
    required this.authState,
    required this.isConnected,
    this.lastSyncAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || conductorId != null) {
      map['conductor_id'] = Variable<String>(conductorId);
    }
    if (!nullToAbsent || tripId != null) {
      map['trip_id'] = Variable<String>(tripId);
    }
    if (!nullToAbsent || busId != null) {
      map['bus_id'] = Variable<String>(busId);
    }
    map['auth_state'] = Variable<String>(authState);
    map['is_connected'] = Variable<bool>(isConnected);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SessionStateTableCompanion toCompanion(bool nullToAbsent) {
    return SessionStateTableCompanion(
      sessionId: Value(sessionId),
      deviceId: Value(deviceId),
      conductorId: conductorId == null && nullToAbsent
          ? const Value.absent()
          : Value(conductorId),
      tripId: tripId == null && nullToAbsent
          ? const Value.absent()
          : Value(tripId),
      busId: busId == null && nullToAbsent
          ? const Value.absent()
          : Value(busId),
      authState: Value(authState),
      isConnected: Value(isConnected),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SessionStateTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionStateTableData(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      conductorId: serializer.fromJson<String?>(json['conductorId']),
      tripId: serializer.fromJson<String?>(json['tripId']),
      busId: serializer.fromJson<String?>(json['busId']),
      authState: serializer.fromJson<String>(json['authState']),
      isConnected: serializer.fromJson<bool>(json['isConnected']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'deviceId': serializer.toJson<String>(deviceId),
      'conductorId': serializer.toJson<String?>(conductorId),
      'tripId': serializer.toJson<String?>(tripId),
      'busId': serializer.toJson<String?>(busId),
      'authState': serializer.toJson<String>(authState),
      'isConnected': serializer.toJson<bool>(isConnected),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SessionStateTableData copyWith({
    String? sessionId,
    String? deviceId,
    Value<String?> conductorId = const Value.absent(),
    Value<String?> tripId = const Value.absent(),
    Value<String?> busId = const Value.absent(),
    String? authState,
    bool? isConnected,
    Value<DateTime?> lastSyncAt = const Value.absent(),
    DateTime? updatedAt,
  }) => SessionStateTableData(
    sessionId: sessionId ?? this.sessionId,
    deviceId: deviceId ?? this.deviceId,
    conductorId: conductorId.present ? conductorId.value : this.conductorId,
    tripId: tripId.present ? tripId.value : this.tripId,
    busId: busId.present ? busId.value : this.busId,
    authState: authState ?? this.authState,
    isConnected: isConnected ?? this.isConnected,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SessionStateTableData copyWithCompanion(SessionStateTableCompanion data) {
    return SessionStateTableData(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      conductorId: data.conductorId.present
          ? data.conductorId.value
          : this.conductorId,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      busId: data.busId.present ? data.busId.value : this.busId,
      authState: data.authState.present ? data.authState.value : this.authState,
      isConnected: data.isConnected.present
          ? data.isConnected.value
          : this.isConnected,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionStateTableData(')
          ..write('sessionId: $sessionId, ')
          ..write('deviceId: $deviceId, ')
          ..write('conductorId: $conductorId, ')
          ..write('tripId: $tripId, ')
          ..write('busId: $busId, ')
          ..write('authState: $authState, ')
          ..write('isConnected: $isConnected, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    deviceId,
    conductorId,
    tripId,
    busId,
    authState,
    isConnected,
    lastSyncAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionStateTableData &&
          other.sessionId == this.sessionId &&
          other.deviceId == this.deviceId &&
          other.conductorId == this.conductorId &&
          other.tripId == this.tripId &&
          other.busId == this.busId &&
          other.authState == this.authState &&
          other.isConnected == this.isConnected &&
          other.lastSyncAt == this.lastSyncAt &&
          other.updatedAt == this.updatedAt);
}

class SessionStateTableCompanion
    extends UpdateCompanion<SessionStateTableData> {
  final Value<String> sessionId;
  final Value<String> deviceId;
  final Value<String?> conductorId;
  final Value<String?> tripId;
  final Value<String?> busId;
  final Value<String> authState;
  final Value<bool> isConnected;
  final Value<DateTime?> lastSyncAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SessionStateTableCompanion({
    this.sessionId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.conductorId = const Value.absent(),
    this.tripId = const Value.absent(),
    this.busId = const Value.absent(),
    this.authState = const Value.absent(),
    this.isConnected = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionStateTableCompanion.insert({
    required String sessionId,
    required String deviceId,
    this.conductorId = const Value.absent(),
    this.tripId = const Value.absent(),
    this.busId = const Value.absent(),
    this.authState = const Value.absent(),
    this.isConnected = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       deviceId = Value(deviceId),
       updatedAt = Value(updatedAt);
  static Insertable<SessionStateTableData> custom({
    Expression<String>? sessionId,
    Expression<String>? deviceId,
    Expression<String>? conductorId,
    Expression<String>? tripId,
    Expression<String>? busId,
    Expression<String>? authState,
    Expression<bool>? isConnected,
    Expression<DateTime>? lastSyncAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (deviceId != null) 'device_id': deviceId,
      if (conductorId != null) 'conductor_id': conductorId,
      if (tripId != null) 'trip_id': tripId,
      if (busId != null) 'bus_id': busId,
      if (authState != null) 'auth_state': authState,
      if (isConnected != null) 'is_connected': isConnected,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionStateTableCompanion copyWith({
    Value<String>? sessionId,
    Value<String>? deviceId,
    Value<String?>? conductorId,
    Value<String?>? tripId,
    Value<String?>? busId,
    Value<String>? authState,
    Value<bool>? isConnected,
    Value<DateTime?>? lastSyncAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SessionStateTableCompanion(
      sessionId: sessionId ?? this.sessionId,
      deviceId: deviceId ?? this.deviceId,
      conductorId: conductorId ?? this.conductorId,
      tripId: tripId ?? this.tripId,
      busId: busId ?? this.busId,
      authState: authState ?? this.authState,
      isConnected: isConnected ?? this.isConnected,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (conductorId.present) {
      map['conductor_id'] = Variable<String>(conductorId.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (busId.present) {
      map['bus_id'] = Variable<String>(busId.value);
    }
    if (authState.present) {
      map['auth_state'] = Variable<String>(authState.value);
    }
    if (isConnected.present) {
      map['is_connected'] = Variable<bool>(isConnected.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionStateTableCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('deviceId: $deviceId, ')
          ..write('conductorId: $conductorId, ')
          ..write('tripId: $tripId, ')
          ..write('busId: $busId, ')
          ..write('authState: $authState, ')
          ..write('isConnected: $isConnected, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MetadataTableTable metadataTable = $MetadataTableTable(this);
  late final $TicketTableTable ticketTable = $TicketTableTable(this);
  late final $TelemetryTableTable telemetryTable = $TelemetryTableTable(this);
  late final $OutboundQueueTableTable outboundQueueTable =
      $OutboundQueueTableTable(this);
  late final $SessionStateTableTable sessionStateTable =
      $SessionStateTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    metadataTable,
    ticketTable,
    telemetryTable,
    outboundQueueTable,
    sessionStateTable,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$MetadataTableTableCreateCompanionBuilder =
    MetadataTableCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$MetadataTableTableUpdateCompanionBuilder =
    MetadataTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MetadataTableTableFilterComposer
    extends Composer<_$AppDatabase, $MetadataTableTable> {
  $$MetadataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MetadataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MetadataTableTable> {
  $$MetadataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MetadataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MetadataTableTable> {
  $$MetadataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MetadataTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetadataTableTable,
          MetadataTableData,
          $$MetadataTableTableFilterComposer,
          $$MetadataTableTableOrderingComposer,
          $$MetadataTableTableAnnotationComposer,
          $$MetadataTableTableCreateCompanionBuilder,
          $$MetadataTableTableUpdateCompanionBuilder,
          (
            MetadataTableData,
            BaseReferences<
              _$AppDatabase,
              $MetadataTableTable,
              MetadataTableData
            >,
          ),
          MetadataTableData,
          PrefetchHooks Function()
        > {
  $$MetadataTableTableTableManager(_$AppDatabase db, $MetadataTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MetadataTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MetadataTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MetadataTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MetadataTableCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => MetadataTableCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetadataTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetadataTableTable,
      MetadataTableData,
      $$MetadataTableTableFilterComposer,
      $$MetadataTableTableOrderingComposer,
      $$MetadataTableTableAnnotationComposer,
      $$MetadataTableTableCreateCompanionBuilder,
      $$MetadataTableTableUpdateCompanionBuilder,
      (
        MetadataTableData,
        BaseReferences<_$AppDatabase, $MetadataTableTable, MetadataTableData>,
      ),
      MetadataTableData,
      PrefetchHooks Function()
    >;
typedef $$TicketTableTableCreateCompanionBuilder =
    TicketTableCompanion Function({
      required String ticketId,
      required String deviceId,
      required String conductorId,
      required String tripId,
      required String fareRuleId,
      required String boardingStopId,
      required String destinationStopId,
      required BigInt fareAmountPaise,
      required DateTime capturedAt,
      Value<String> currency,
      Value<String?> commuterId,
      required int ticketSequenceNumber,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$TicketTableTableUpdateCompanionBuilder =
    TicketTableCompanion Function({
      Value<String> ticketId,
      Value<String> deviceId,
      Value<String> conductorId,
      Value<String> tripId,
      Value<String> fareRuleId,
      Value<String> boardingStopId,
      Value<String> destinationStopId,
      Value<BigInt> fareAmountPaise,
      Value<DateTime> capturedAt,
      Value<String> currency,
      Value<String?> commuterId,
      Value<int> ticketSequenceNumber,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$TicketTableTableFilterComposer
    extends Composer<_$AppDatabase, $TicketTableTable> {
  $$TicketTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ticketId => $composableBuilder(
    column: $table.ticketId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conductorId => $composableBuilder(
    column: $table.conductorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fareRuleId => $composableBuilder(
    column: $table.fareRuleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boardingStopId => $composableBuilder(
    column: $table.boardingStopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationStopId => $composableBuilder(
    column: $table.destinationStopId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<BigInt> get fareAmountPaise => $composableBuilder(
    column: $table.fareAmountPaise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commuterId => $composableBuilder(
    column: $table.commuterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ticketSequenceNumber => $composableBuilder(
    column: $table.ticketSequenceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TicketTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TicketTableTable> {
  $$TicketTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ticketId => $composableBuilder(
    column: $table.ticketId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conductorId => $composableBuilder(
    column: $table.conductorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fareRuleId => $composableBuilder(
    column: $table.fareRuleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boardingStopId => $composableBuilder(
    column: $table.boardingStopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationStopId => $composableBuilder(
    column: $table.destinationStopId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<BigInt> get fareAmountPaise => $composableBuilder(
    column: $table.fareAmountPaise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commuterId => $composableBuilder(
    column: $table.commuterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ticketSequenceNumber => $composableBuilder(
    column: $table.ticketSequenceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TicketTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TicketTableTable> {
  $$TicketTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ticketId =>
      $composableBuilder(column: $table.ticketId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get conductorId => $composableBuilder(
    column: $table.conductorId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get fareRuleId => $composableBuilder(
    column: $table.fareRuleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boardingStopId => $composableBuilder(
    column: $table.boardingStopId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationStopId => $composableBuilder(
    column: $table.destinationStopId,
    builder: (column) => column,
  );

  GeneratedColumn<BigInt> get fareAmountPaise => $composableBuilder(
    column: $table.fareAmountPaise,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get commuterId => $composableBuilder(
    column: $table.commuterId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ticketSequenceNumber => $composableBuilder(
    column: $table.ticketSequenceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$TicketTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TicketTableTable,
          TicketTableData,
          $$TicketTableTableFilterComposer,
          $$TicketTableTableOrderingComposer,
          $$TicketTableTableAnnotationComposer,
          $$TicketTableTableCreateCompanionBuilder,
          $$TicketTableTableUpdateCompanionBuilder,
          (
            TicketTableData,
            BaseReferences<_$AppDatabase, $TicketTableTable, TicketTableData>,
          ),
          TicketTableData,
          PrefetchHooks Function()
        > {
  $$TicketTableTableTableManager(_$AppDatabase db, $TicketTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TicketTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TicketTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TicketTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ticketId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> conductorId = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<String> fareRuleId = const Value.absent(),
                Value<String> boardingStopId = const Value.absent(),
                Value<String> destinationStopId = const Value.absent(),
                Value<BigInt> fareAmountPaise = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String?> commuterId = const Value.absent(),
                Value<int> ticketSequenceNumber = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TicketTableCompanion(
                ticketId: ticketId,
                deviceId: deviceId,
                conductorId: conductorId,
                tripId: tripId,
                fareRuleId: fareRuleId,
                boardingStopId: boardingStopId,
                destinationStopId: destinationStopId,
                fareAmountPaise: fareAmountPaise,
                capturedAt: capturedAt,
                currency: currency,
                commuterId: commuterId,
                ticketSequenceNumber: ticketSequenceNumber,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ticketId,
                required String deviceId,
                required String conductorId,
                required String tripId,
                required String fareRuleId,
                required String boardingStopId,
                required String destinationStopId,
                required BigInt fareAmountPaise,
                required DateTime capturedAt,
                Value<String> currency = const Value.absent(),
                Value<String?> commuterId = const Value.absent(),
                required int ticketSequenceNumber,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TicketTableCompanion.insert(
                ticketId: ticketId,
                deviceId: deviceId,
                conductorId: conductorId,
                tripId: tripId,
                fareRuleId: fareRuleId,
                boardingStopId: boardingStopId,
                destinationStopId: destinationStopId,
                fareAmountPaise: fareAmountPaise,
                capturedAt: capturedAt,
                currency: currency,
                commuterId: commuterId,
                ticketSequenceNumber: ticketSequenceNumber,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TicketTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TicketTableTable,
      TicketTableData,
      $$TicketTableTableFilterComposer,
      $$TicketTableTableOrderingComposer,
      $$TicketTableTableAnnotationComposer,
      $$TicketTableTableCreateCompanionBuilder,
      $$TicketTableTableUpdateCompanionBuilder,
      (
        TicketTableData,
        BaseReferences<_$AppDatabase, $TicketTableTable, TicketTableData>,
      ),
      TicketTableData,
      PrefetchHooks Function()
    >;
typedef $$TelemetryTableTableCreateCompanionBuilder =
    TelemetryTableCompanion Function({
      required String pingId,
      required String deviceId,
      required double latitude,
      required double longitude,
      required double speedMps,
      required double headingDegrees,
      required DateTime capturedAt,
      Value<String?> tripId,
      required int batteryLevelPct,
      required bool isCharging,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$TelemetryTableTableUpdateCompanionBuilder =
    TelemetryTableCompanion Function({
      Value<String> pingId,
      Value<String> deviceId,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> speedMps,
      Value<double> headingDegrees,
      Value<DateTime> capturedAt,
      Value<String?> tripId,
      Value<int> batteryLevelPct,
      Value<bool> isCharging,
      Value<String> syncStatus,
      Value<int> rowid,
    });

class $$TelemetryTableTableFilterComposer
    extends Composer<_$AppDatabase, $TelemetryTableTable> {
  $$TelemetryTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pingId => $composableBuilder(
    column: $table.pingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get headingDegrees => $composableBuilder(
    column: $table.headingDegrees,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batteryLevelPct => $composableBuilder(
    column: $table.batteryLevelPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCharging => $composableBuilder(
    column: $table.isCharging,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TelemetryTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TelemetryTableTable> {
  $$TelemetryTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pingId => $composableBuilder(
    column: $table.pingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speedMps => $composableBuilder(
    column: $table.speedMps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get headingDegrees => $composableBuilder(
    column: $table.headingDegrees,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batteryLevelPct => $composableBuilder(
    column: $table.batteryLevelPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCharging => $composableBuilder(
    column: $table.isCharging,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TelemetryTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TelemetryTableTable> {
  $$TelemetryTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pingId =>
      $composableBuilder(column: $table.pingId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get speedMps =>
      $composableBuilder(column: $table.speedMps, builder: (column) => column);

  GeneratedColumn<double> get headingDegrees => $composableBuilder(
    column: $table.headingDegrees,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<int> get batteryLevelPct => $composableBuilder(
    column: $table.batteryLevelPct,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCharging => $composableBuilder(
    column: $table.isCharging,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );
}

class $$TelemetryTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TelemetryTableTable,
          TelemetryTableData,
          $$TelemetryTableTableFilterComposer,
          $$TelemetryTableTableOrderingComposer,
          $$TelemetryTableTableAnnotationComposer,
          $$TelemetryTableTableCreateCompanionBuilder,
          $$TelemetryTableTableUpdateCompanionBuilder,
          (
            TelemetryTableData,
            BaseReferences<
              _$AppDatabase,
              $TelemetryTableTable,
              TelemetryTableData
            >,
          ),
          TelemetryTableData,
          PrefetchHooks Function()
        > {
  $$TelemetryTableTableTableManager(
    _$AppDatabase db,
    $TelemetryTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TelemetryTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TelemetryTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TelemetryTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pingId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> speedMps = const Value.absent(),
                Value<double> headingDegrees = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                Value<int> batteryLevelPct = const Value.absent(),
                Value<bool> isCharging = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TelemetryTableCompanion(
                pingId: pingId,
                deviceId: deviceId,
                latitude: latitude,
                longitude: longitude,
                speedMps: speedMps,
                headingDegrees: headingDegrees,
                capturedAt: capturedAt,
                tripId: tripId,
                batteryLevelPct: batteryLevelPct,
                isCharging: isCharging,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pingId,
                required String deviceId,
                required double latitude,
                required double longitude,
                required double speedMps,
                required double headingDegrees,
                required DateTime capturedAt,
                Value<String?> tripId = const Value.absent(),
                required int batteryLevelPct,
                required bool isCharging,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TelemetryTableCompanion.insert(
                pingId: pingId,
                deviceId: deviceId,
                latitude: latitude,
                longitude: longitude,
                speedMps: speedMps,
                headingDegrees: headingDegrees,
                capturedAt: capturedAt,
                tripId: tripId,
                batteryLevelPct: batteryLevelPct,
                isCharging: isCharging,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TelemetryTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TelemetryTableTable,
      TelemetryTableData,
      $$TelemetryTableTableFilterComposer,
      $$TelemetryTableTableOrderingComposer,
      $$TelemetryTableTableAnnotationComposer,
      $$TelemetryTableTableCreateCompanionBuilder,
      $$TelemetryTableTableUpdateCompanionBuilder,
      (
        TelemetryTableData,
        BaseReferences<_$AppDatabase, $TelemetryTableTable, TelemetryTableData>,
      ),
      TelemetryTableData,
      PrefetchHooks Function()
    >;
typedef $$OutboundQueueTableTableCreateCompanionBuilder =
    OutboundQueueTableCompanion Function({
      required String id,
      required String payloadType,
      required Uint8List payloadBytes,
      required DateTime createdAt,
      Value<int> retryCount,
      Value<DateTime?> lastAttemptAt,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$OutboundQueueTableTableUpdateCompanionBuilder =
    OutboundQueueTableCompanion Function({
      Value<String> id,
      Value<String> payloadType,
      Value<Uint8List> payloadBytes,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<DateTime?> lastAttemptAt,
      Value<String> status,
      Value<int> rowid,
    });

class $$OutboundQueueTableTableFilterComposer
    extends Composer<_$AppDatabase, $OutboundQueueTableTable> {
  $$OutboundQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get payloadBytes => $composableBuilder(
    column: $table.payloadBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboundQueueTableTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboundQueueTableTable> {
  $$OutboundQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get payloadBytes => $composableBuilder(
    column: $table.payloadBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboundQueueTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboundQueueTableTable> {
  $$OutboundQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payloadType => $composableBuilder(
    column: $table.payloadType,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get payloadBytes => $composableBuilder(
    column: $table.payloadBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$OutboundQueueTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboundQueueTableTable,
          OutboundQueueTableData,
          $$OutboundQueueTableTableFilterComposer,
          $$OutboundQueueTableTableOrderingComposer,
          $$OutboundQueueTableTableAnnotationComposer,
          $$OutboundQueueTableTableCreateCompanionBuilder,
          $$OutboundQueueTableTableUpdateCompanionBuilder,
          (
            OutboundQueueTableData,
            BaseReferences<
              _$AppDatabase,
              $OutboundQueueTableTable,
              OutboundQueueTableData
            >,
          ),
          OutboundQueueTableData,
          PrefetchHooks Function()
        > {
  $$OutboundQueueTableTableTableManager(
    _$AppDatabase db,
    $OutboundQueueTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboundQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboundQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboundQueueTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payloadType = const Value.absent(),
                Value<Uint8List> payloadBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboundQueueTableCompanion(
                id: id,
                payloadType: payloadType,
                payloadBytes: payloadBytes,
                createdAt: createdAt,
                retryCount: retryCount,
                lastAttemptAt: lastAttemptAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payloadType,
                required Uint8List payloadBytes,
                required DateTime createdAt,
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboundQueueTableCompanion.insert(
                id: id,
                payloadType: payloadType,
                payloadBytes: payloadBytes,
                createdAt: createdAt,
                retryCount: retryCount,
                lastAttemptAt: lastAttemptAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboundQueueTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboundQueueTableTable,
      OutboundQueueTableData,
      $$OutboundQueueTableTableFilterComposer,
      $$OutboundQueueTableTableOrderingComposer,
      $$OutboundQueueTableTableAnnotationComposer,
      $$OutboundQueueTableTableCreateCompanionBuilder,
      $$OutboundQueueTableTableUpdateCompanionBuilder,
      (
        OutboundQueueTableData,
        BaseReferences<
          _$AppDatabase,
          $OutboundQueueTableTable,
          OutboundQueueTableData
        >,
      ),
      OutboundQueueTableData,
      PrefetchHooks Function()
    >;
typedef $$SessionStateTableTableCreateCompanionBuilder =
    SessionStateTableCompanion Function({
      required String sessionId,
      required String deviceId,
      Value<String?> conductorId,
      Value<String?> tripId,
      Value<String?> busId,
      Value<String> authState,
      Value<bool> isConnected,
      Value<DateTime?> lastSyncAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SessionStateTableTableUpdateCompanionBuilder =
    SessionStateTableCompanion Function({
      Value<String> sessionId,
      Value<String> deviceId,
      Value<String?> conductorId,
      Value<String?> tripId,
      Value<String?> busId,
      Value<String> authState,
      Value<bool> isConnected,
      Value<DateTime?> lastSyncAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SessionStateTableTableFilterComposer
    extends Composer<_$AppDatabase, $SessionStateTableTable> {
  $$SessionStateTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conductorId => $composableBuilder(
    column: $table.conductorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get busId => $composableBuilder(
    column: $table.busId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authState => $composableBuilder(
    column: $table.authState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isConnected => $composableBuilder(
    column: $table.isConnected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionStateTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionStateTableTable> {
  $$SessionStateTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conductorId => $composableBuilder(
    column: $table.conductorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripId => $composableBuilder(
    column: $table.tripId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get busId => $composableBuilder(
    column: $table.busId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authState => $composableBuilder(
    column: $table.authState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isConnected => $composableBuilder(
    column: $table.isConnected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionStateTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionStateTableTable> {
  $$SessionStateTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get conductorId => $composableBuilder(
    column: $table.conductorId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get busId =>
      $composableBuilder(column: $table.busId, builder: (column) => column);

  GeneratedColumn<String> get authState =>
      $composableBuilder(column: $table.authState, builder: (column) => column);

  GeneratedColumn<bool> get isConnected => $composableBuilder(
    column: $table.isConnected,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SessionStateTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionStateTableTable,
          SessionStateTableData,
          $$SessionStateTableTableFilterComposer,
          $$SessionStateTableTableOrderingComposer,
          $$SessionStateTableTableAnnotationComposer,
          $$SessionStateTableTableCreateCompanionBuilder,
          $$SessionStateTableTableUpdateCompanionBuilder,
          (
            SessionStateTableData,
            BaseReferences<
              _$AppDatabase,
              $SessionStateTableTable,
              SessionStateTableData
            >,
          ),
          SessionStateTableData,
          PrefetchHooks Function()
        > {
  $$SessionStateTableTableTableManager(
    _$AppDatabase db,
    $SessionStateTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionStateTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionStateTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionStateTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String?> conductorId = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                Value<String?> busId = const Value.absent(),
                Value<String> authState = const Value.absent(),
                Value<bool> isConnected = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionStateTableCompanion(
                sessionId: sessionId,
                deviceId: deviceId,
                conductorId: conductorId,
                tripId: tripId,
                busId: busId,
                authState: authState,
                isConnected: isConnected,
                lastSyncAt: lastSyncAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required String deviceId,
                Value<String?> conductorId = const Value.absent(),
                Value<String?> tripId = const Value.absent(),
                Value<String?> busId = const Value.absent(),
                Value<String> authState = const Value.absent(),
                Value<bool> isConnected = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SessionStateTableCompanion.insert(
                sessionId: sessionId,
                deviceId: deviceId,
                conductorId: conductorId,
                tripId: tripId,
                busId: busId,
                authState: authState,
                isConnected: isConnected,
                lastSyncAt: lastSyncAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionStateTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionStateTableTable,
      SessionStateTableData,
      $$SessionStateTableTableFilterComposer,
      $$SessionStateTableTableOrderingComposer,
      $$SessionStateTableTableAnnotationComposer,
      $$SessionStateTableTableCreateCompanionBuilder,
      $$SessionStateTableTableUpdateCompanionBuilder,
      (
        SessionStateTableData,
        BaseReferences<
          _$AppDatabase,
          $SessionStateTableTable,
          SessionStateTableData
        >,
      ),
      SessionStateTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MetadataTableTableTableManager get metadataTable =>
      $$MetadataTableTableTableManager(_db, _db.metadataTable);
  $$TicketTableTableTableManager get ticketTable =>
      $$TicketTableTableTableManager(_db, _db.ticketTable);
  $$TelemetryTableTableTableManager get telemetryTable =>
      $$TelemetryTableTableTableManager(_db, _db.telemetryTable);
  $$OutboundQueueTableTableTableManager get outboundQueueTable =>
      $$OutboundQueueTableTableTableManager(_db, _db.outboundQueueTable);
  $$SessionStateTableTableTableManager get sessionStateTable =>
      $$SessionStateTableTableTableManager(_db, _db.sessionStateTable);
}
