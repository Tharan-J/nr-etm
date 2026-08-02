class Fare {
  final int sourceStage;
  final int destStage;
  final double baseAmount;
  final double discountAmount;
  final double finalAmount;

  const Fare({
    required this.sourceStage,
    required this.destStage,
    required this.baseAmount,
    this.discountAmount = 0.0,
    required this.finalAmount,
  });

  factory Fare.calculate({
    required int sourceStage,
    required int destStage,
    required double baseRatePerStage,
    double concessionPercent = 0.0,
    double minFare = 5.0,
  }) {
    final stages = (destStage - sourceStage).abs();
    final rawBase = (stages == 0 ? 1 : stages) * baseRatePerStage;
    final discount = (rawBase * (concessionPercent / 100.0));
    final calculated = rawBase - discount;
    final finalFare = calculated < minFare ? minFare : calculated;

    return Fare(
      sourceStage: sourceStage,
      destStage: destStage,
      baseAmount: rawBase,
      discountAmount: discount,
      finalAmount: finalFare,
    );
  }
}
