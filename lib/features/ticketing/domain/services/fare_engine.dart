import '../models/fare.dart';

class FareEngine {
  static const double baseStageRate = 10.0;
  static const double minimumFare = 5.0;

  Fare calculateFare({
    required int sourceStage,
    required int destStage,
    required String passengerCategory,
  }) {
    double concessionPercent = 0.0;

    switch (passengerCategory.toLowerCase()) {
      case 'senior':
        concessionPercent = 40.0;
        break;
      case 'child':
        concessionPercent = 50.0;
        break;
      case 'pass':
        concessionPercent = 100.0;
        break;
      case 'adult':
      default:
        concessionPercent = 0.0;
        break;
    }

    return Fare.calculate(
      sourceStage: sourceStage,
      destStage: destStage,
      baseRatePerStage: baseStageRate,
      concessionPercent: concessionPercent,
      minFare: passengerCategory.toLowerCase() == 'pass' ? 0.0 : minimumFare,
    );
  }
}
