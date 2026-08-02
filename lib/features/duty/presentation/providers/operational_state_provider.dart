import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/capture/data/app_database.dart';
import '../../../../core/platform/native_service_manager.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../trip/domain/models/bus_trip.dart';
import '../../domain/models/conductor_duty.dart';

enum OperationalState {
  idle,
  ready,
  dutyActive,
  tripActive,
  paused,
  tripCompleted,
  dutyCompleted,
}

class OperationalSession {
  final OperationalState state;
  final ConductorDuty? activeDuty;
  final BusTrip? activeTrip;

  const OperationalSession({
    required this.state,
    this.activeDuty,
    this.activeTrip,
  });

  OperationalSession copyWith({
    OperationalState? state,
    ConductorDuty? activeDuty,
    BusTrip? activeTrip,
  }) {
    return OperationalSession(
      state: state ?? this.state,
      activeDuty: activeDuty ?? this.activeDuty,
      activeTrip: activeTrip ?? this.activeTrip,
    );
  }
}

class OperationalStateNotifier extends StateNotifier<OperationalSession> {
  final AppDatabase _database;
  final NativeServiceManager _nativeServiceManager;

  OperationalStateNotifier(this._database, this._nativeServiceManager)
    : super(const OperationalSession(state: OperationalState.idle)) {
    restoreStateFromStorage();
  }

  /// Phase TM-5: Automatic State Recovery after reboot or process death
  Future<void> restoreStateFromStorage() async {
    try {
      final records = await (_database.select(
        _database.metadataTable,
      )..where((t) => t.key.equals('operational_session'))).get();

      if (records.isNotEmpty) {
        final jsonStr = records.first.value;
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;

        final stateName = map['state'] as String? ?? 'idle';
        final opState = OperationalState.values.byName(stateName);

        final dutyMap = map['duty'] as Map<String, dynamic>?;
        final tripMap = map['trip'] as Map<String, dynamic>?;

        final duty = dutyMap != null ? ConductorDuty.fromJson(dutyMap) : null;
        final trip = tripMap != null ? BusTrip.fromJson(tripMap) : null;

        state = OperationalSession(
          state: opState,
          activeDuty: duty,
          activeTrip: trip,
        );

        // Resume native background service if trip was active during crash/reboot
        if (state.state == OperationalState.tripActive) {
          await _nativeServiceManager.startDutyForegroundService();
        }
      }
    } catch (_) {
      state = const OperationalSession(state: OperationalState.ready);
    }
  }

  Future<void> _persistSession() async {
    final map = {
      'state': state.state.name,
      'duty': state.activeDuty?.toJson(),
      'trip': state.activeTrip?.toJson(),
    };

    await _database
        .into(_database.metadataTable)
        .insertOnConflictUpdate(
          MetadataTableCompanion.insert(
            key: 'operational_session',
            value: jsonEncode(map),
            updatedAt: DateTime.now(),
          ),
        );
  }

  /// Phase TM-1: Duty Start
  Future<void> startDuty({
    required String conductorId,
    required String busId,
  }) async {
    final duty = ConductorDuty(
      dutyId: 'duty_${DateTime.now().millisecondsSinceEpoch}',
      conductorId: conductorId,
      busId: busId,
      startTime: DateTime.now(),
      status: DutyStatus.active,
    );

    state = OperationalSession(
      state: OperationalState.dutyActive,
      activeDuty: duty,
    );

    await _persistSession();
  }

  /// Phase TM-2: Start Trip & Phase TM-4: Native Service Integration
  Future<void> startTrip({
    required String routeId,
    required String routeName,
    required TripDirection direction,
  }) async {
    if (state.activeDuty == null) return;

    final trip = BusTrip(
      tripId: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      dutyId: state.activeDuty!.dutyId,
      routeId: routeId,
      routeName: routeName,
      direction: direction,
      currentStage: 1,
      startTime: DateTime.now(),
      status: TripStatus.active,
    );

    state = state.copyWith(
      state: OperationalState.tripActive,
      activeTrip: trip,
    );

    await _persistSession();

    // Trigger Native Foreground Service & Location Updates
    await _nativeServiceManager.startDutyForegroundService();
  }

  /// Update Current Stage
  Future<void> updateStage(int nextStage) async {
    if (state.activeTrip == null) return;

    final updatedTrip = state.activeTrip!.copyWith(currentStage: nextStage);
    state = state.copyWith(activeTrip: updatedTrip);
    await _persistSession();
  }

  /// Phase TM-2 & TM-4: End Trip & Stop Native Foreground Service
  Future<void> endTrip() async {
    if (state.activeTrip == null) return;

    final completedTrip = state.activeTrip!.copyWith(
      endTime: DateTime.now(),
      status: TripStatus.completed,
    );

    state = state.copyWith(
      state: OperationalState.tripCompleted,
      activeTrip: completedTrip,
    );

    await _persistSession();

    // Stop Native Foreground Service
    await _nativeServiceManager.stopDutyForegroundService();
  }

  /// Phase TM-1: End Duty
  Future<void> endDuty() async {
    if (state.activeDuty == null) return;

    final endedDuty = state.activeDuty!.copyWith(
      endTime: DateTime.now(),
      status: DutyStatus.ended,
    );

    state = OperationalSession(
      state: OperationalState.dutyCompleted,
      activeDuty: endedDuty,
      activeTrip: null,
    );

    await _persistSession();
    await _nativeServiceManager.stopDutyForegroundService();
  }
}

final operationalStateNotifierProvider =
    StateNotifierProvider<OperationalStateNotifier, OperationalSession>((ref) {
      return OperationalStateNotifier(
        ref.watch(appDatabaseProvider),
        ref.watch(nativeServiceManagerProvider),
      );
    });
