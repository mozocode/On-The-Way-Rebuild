import '../models/job_model.dart';

/// Local pricing fallback used when Cloud Functions are unreachable.
/// Mirrors the base rates from `pricingConfig/default` but does not
/// apply surge, discounts, or hero payout calculations.
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  static const _basePrices = <String, int>{
    'flat_tire': 5000,
    'dead_battery': 4500,
    'lockout': 6500,
    'fuel_delivery': 5500,
    'towing': 9500,
    'winch_out': 8500,
  };

  static const _perMile = <String, int>{
    'flat_tire': 200,
    'dead_battery': 200,
    'lockout': 200,
    'fuel_delivery': 200,
    'towing': 400,
    'winch_out': 300,
  };

  JobPricing calculatePrice({
    required String serviceType,
    required double distanceMiles,
    bool isPriority = false,
    bool needsWinch = false,
  }) {
    final basePrice = _basePrices[serviceType] ?? 5000;
    final perMile = _perMile[serviceType] ?? 200;
    final heroTravelFee = (distanceMiles * perMile).round();
    final priorityFee = isPriority ? 2000 : 0;
    final winchFee = needsWinch ? 5000 : 0;

    final hour = DateTime.now().hour;
    final afterHoursFee = (hour >= 22 || hour < 6) ? 1500 : 0;

    final subtotalBeforeDiscounts =
        basePrice + heroTravelFee + priorityFee + winchFee + afterHoursFee;
    const serviceFeePercent = 15.0;
    final serviceFee = (subtotalBeforeDiscounts * serviceFeePercent / 100).round();
    final total = subtotalBeforeDiscounts + serviceFee;

    final basePayout = (basePrice * 0.80).round();
    final distancePayout = (heroTravelFee * 0.85).round();
    final heroPayout = basePayout + distancePayout;

    return JobPricing(
      currency: 'usd',
      basePrice: basePrice,
      mileagePrice: heroTravelFee,
      priorityFee: priorityFee,
      winchFee: winchFee,
      subtotal: subtotalBeforeDiscounts,
      serviceFee: serviceFee,
      total: total,
      heroTravelFee: heroTravelFee,
      heroTravelMiles: distanceMiles,
      addOns: AddOnFeesData(
        priorityFee: priorityFee,
        winchFee: winchFee,
        afterHoursFee: afterHoursFee,
        total: priorityFee + winchFee + afterHoursFee,
      ),
      subtotalBeforeDiscounts: subtotalBeforeDiscounts,
      subtotalAfterDiscounts: subtotalBeforeDiscounts,
      serviceFeePercent: serviceFeePercent,
      estimatedMin: total,
      estimatedMax: (total * 1.25).round(),
      heroPayout: HeroPayoutData(
        basePayout: basePayout,
        distancePayout: distancePayout,
        totalPayout: heroPayout < 2000 ? 2000 : heroPayout,
      ),
      configVersion: 'local-fallback',
    );
  }
}
