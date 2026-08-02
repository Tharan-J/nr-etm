import 'package:fixnum/fixnum.dart';

import '../../../../core/capture/data/app_database.dart';
import '../../../../core/capture/data/dao/durable_capture_dao.dart';
import '../../../../core/generated/proto/etm_ticket.pb.dart';
import '../../../duty/domain/models/conductor_duty.dart';
import '../../../trip/domain/models/bus_trip.dart';
import '../models/ticket.dart';
import '../models/ticket_receipt.dart';
import 'fare_engine.dart';
import 'receipt_generator.dart';
import 'ticket_validator.dart';

class TicketIssuanceResult {
  final bool isSuccess;
  final Ticket? ticket;
  final TicketReceipt? receipt;
  final String? errorCode;
  final String? errorMessage;

  const TicketIssuanceResult.success({
    required this.ticket,
    required this.receipt,
  }) : isSuccess = true,
       errorCode = null,
       errorMessage = null;

  const TicketIssuanceResult.failure({
    required this.errorCode,
    required this.errorMessage,
  }) : isSuccess = false,
       ticket = null,
       receipt = null;
}

class TicketIssuanceEngine {
  final TicketValidator validator;
  final FareEngine fareEngine;
  final ReceiptGenerator receiptGenerator;
  final DurableCaptureDao captureDao;

  TicketIssuanceEngine({
    TicketValidator? validator,
    FareEngine? fareEngine,
    ReceiptGenerator? receiptGenerator,
    required this.captureDao,
  }) : validator = validator ?? TicketValidator(),
       fareEngine = fareEngine ?? FareEngine(),
       receiptGenerator = receiptGenerator ?? ReceiptGenerator();

  Future<TicketIssuanceResult> issueTicket({
    required ConductorDuty? activeDuty,
    required BusTrip? activeTrip,
    required String sourceStopId,
    required String destStopId,
    required String sourceStopName,
    required String destStopName,
    required int sourceStage,
    required int destStage,
    required String passengerCategory,
    String deviceId = 'ETM_DEV_001',
  }) async {
    // 1. Validate Business Invariants
    final valResult = validator.validateIssuanceRequest(
      activeDuty: activeDuty,
      activeTrip: activeTrip,
      sourceStage: sourceStage,
      destStage: destStage,
    );

    if (!valResult.isValid) {
      return TicketIssuanceResult.failure(
        errorCode: valResult.errorCode,
        errorMessage: valResult.errorMessage,
      );
    }

    // 2. Calculate Fare
    final fare = fareEngine.calculateFare(
      sourceStage: sourceStage,
      destStage: destStage,
      passengerCategory: passengerCategory,
    );

    final now = DateTime.now();
    final timestampMs = now.millisecondsSinceEpoch;
    final ticketId = 'tkt_$timestampMs';
    final ticketNumber =
        'T-${activeTrip!.tripId.substring(activeTrip.tripId.length - 4)}-$timestampMs';
    final qrPayload =
        'NR-ETM:$ticketId:${activeTrip.tripId}:${fare.finalAmount}:$timestampMs';
    final farePaiseInt = (fare.finalAmount * 100).toInt();

    final ticket = Ticket(
      ticketId: ticketId,
      ticketNumber: ticketNumber,
      tripId: activeTrip.tripId,
      dutyId: activeDuty!.dutyId,
      sourceStopId: sourceStopId,
      destStopId: destStopId,
      sourceStopName: sourceStopName,
      destStopName: destStopName,
      sourceStage: sourceStage,
      destStage: destStage,
      fareAmount: fare.finalAmount,
      passengerCategory: passengerCategory,
      createdAt: now,
      qrPayload: qrPayload,
    );

    // 3. Perform Atomic Durable Capture via DAO
    final companion = TicketTableCompanion.insert(
      ticketId: ticketId,
      deviceId: deviceId,
      conductorId: activeDuty.conductorId,
      tripId: activeTrip.tripId,
      fareRuleId: 'rule_stage_v1',
      boardingStopId: sourceStopId,
      destinationStopId: destStopId,
      fareAmountPaise: BigInt.from(farePaiseInt),
      capturedAt: now,
      ticketSequenceNumber: timestampMs % 1000000,
    );

    final protoRecord = TicketRecord()
      ..ticketId = ticketId
      ..deviceId = deviceId
      ..conductorId = activeDuty.conductorId
      ..tripId = activeTrip.tripId
      ..fareRuleId = 'rule_stage_v1'
      ..boardingStopId = sourceStopId
      ..destinationStopId = destStopId
      ..fareAmountPaise = Int64(farePaiseInt)
      ..capturedAtEpochMs = Int64(timestampMs)
      ..ticketSequenceNumber = timestampMs % 1000000;

    await captureDao.captureTicketTransaction(
      ticketCompanion: companion,
      ticketRecord: protoRecord,
    );

    // 4. Generate Receipt & Thermal Bytes
    final receipt = receiptGenerator.generateReceipt(
      ticket: ticket,
      routeName: activeTrip.routeName,
      busId: activeDuty.busId,
    );

    return TicketIssuanceResult.success(ticket: ticket, receipt: receipt);
  }
}
