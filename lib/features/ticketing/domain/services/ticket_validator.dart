import '../../../duty/domain/models/conductor_duty.dart';
import '../../../trip/domain/models/bus_trip.dart';

class TicketValidationResult {
  final bool isValid;
  final String? errorCode;
  final String? errorMessage;

  const TicketValidationResult.success()
    : isValid = true,
      errorCode = null,
      errorMessage = null;

  const TicketValidationResult.failure(this.errorCode, this.errorMessage)
    : isValid = false;
}

class TicketValidator {
  TicketValidationResult validateIssuanceRequest({
    required ConductorDuty? activeDuty,
    required BusTrip? activeTrip,
    required int sourceStage,
    required int destStage,
  }) {
    // Invariant 1: Duty must exist and be active
    if (activeDuty == null || !activeDuty.isActive) {
      return const TicketValidationResult.failure(
        'ERR_DUTY_INACTIVE',
        'Cannot issue ticket without an active conductor duty session.',
      );
    }

    // Invariant 2: Trip must exist and be active
    if (activeTrip == null || !activeTrip.isActive) {
      return const TicketValidationResult.failure(
        'ERR_TRIP_INACTIVE',
        'Cannot issue ticket without an active bus trip.',
      );
    }

    // Invariant 3: Destination stage must be strictly greater than source stage
    if (destStage <= sourceStage) {
      return const TicketValidationResult.failure(
        'ERR_INVALID_STAGE',
        'Destination stage must be after the source stage.',
      );
    }

    return const TicketValidationResult.success();
  }
}
