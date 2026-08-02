import 'dart:async';

import 'package:drift/drift.dart';

import '../capture/data/app_database.dart';
import '../network/network_observer.dart';

abstract class TransportAdapter {
  Future<bool> publishPayload({
    required String id,
    required String payloadType,
    required List<int> payloadBytes,
  });
}

class SyncEngine {
  final AppDatabase database;
  final TransportAdapter transportAdapter;
  final NetworkObserver networkObserver;

  bool _isPaused = false;
  bool _isFlushing = false;
  Timer? _flushTimer;

  static const Map<String, int> priorityMap = {
    'ticket': 1,
    'trip': 2,
    'auth': 3,
    'telemetry': 4,
    'diagnostics': 5,
  };

  SyncEngine({
    required this.database,
    required this.transportAdapter,
    required this.networkObserver,
  }) {
    _startPeriodicFlush();
  }

  void _startPeriodicFlush() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isPaused && networkObserver.status == NetworkStatus.online) {
        flush();
      }
    });
  }

  void pause() {
    _isPaused = true;
  }

  void resume() {
    _isPaused = false;
    flush();
  }

  Future<int> getPendingQueueCount() async {
    final query = database.select(database.outboundQueueTable);
    final results = await query.get();
    return results.length;
  }

  /// Phase 4A: Flush queue sorted strictly by priority weight (Tickets first)
  Future<void> flush() async {
    if (_isFlushing || _isPaused) return;
    _isFlushing = true;

    try {
      final items = await database.select(database.outboundQueueTable).get();

      if (items.isEmpty) {
        _isFlushing = false;
        return;
      }

      // Sort by priority weight ascending (1 -> 5)
      items.sort((a, b) {
        final pA = priorityMap[a.payloadType] ?? 99;
        final pB = priorityMap[b.payloadType] ?? 99;
        if (pA != pB) return pA.compareTo(pB);
        return a.createdAt.compareTo(b.createdAt);
      });

      for (final item in items) {
        if (_isPaused || networkObserver.status == NetworkStatus.offline) break;

        final success = await transportAdapter.publishPayload(
          id: item.id,
          payloadType: item.payloadType,
          payloadBytes: item.payloadBytes,
        );

        if (success) {
          await ack(item.id);
        } else {
          await retry(item.id, item.retryCount);
          break; // Stop batch on failure and apply exponential backoff
        }
      }
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> ack(String id) async {
    await (database.delete(
      database.outboundQueueTable,
    )..where((t) => t.id.equals(id))).go();
  }

  Future<void> retry(String id, int currentRetryCount) async {
    final nextRetry = currentRetryCount + 1;

    await (database.update(database.outboundQueueTable)
          ..where((t) => t.id.equals(id)))
        .write(OutboundQueueTableCompanion(retryCount: Value(nextRetry)));
  }

  void dispose() {
    _flushTimer?.cancel();
  }
}
