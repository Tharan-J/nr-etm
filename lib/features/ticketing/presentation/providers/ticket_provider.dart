import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/capture/data/dao/durable_capture_dao.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/services/fare_engine.dart';
import '../../domain/services/receipt_generator.dart';
import '../../domain/services/ticket_issuance_engine.dart';
import '../../domain/services/ticket_validator.dart';

final durableCaptureDaoProvider = Provider<DurableCaptureDao>((ref) {
  return DurableCaptureDao(ref.watch(appDatabaseProvider));
});

final fareEngineProvider = Provider<FareEngine>((ref) {
  return FareEngine();
});

final ticketValidatorProvider = Provider<TicketValidator>((ref) {
  return TicketValidator();
});

final receiptGeneratorProvider = Provider<ReceiptGenerator>((ref) {
  return ReceiptGenerator();
});

final ticketIssuanceEngineProvider = Provider<TicketIssuanceEngine>((ref) {
  return TicketIssuanceEngine(
    validator: ref.watch(ticketValidatorProvider),
    fareEngine: ref.watch(fareEngineProvider),
    receiptGenerator: ref.watch(receiptGeneratorProvider),
    captureDao: ref.watch(durableCaptureDaoProvider),
  );
});
