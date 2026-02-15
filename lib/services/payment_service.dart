import '../models/job_model.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  JobPricing calculatePrice({
    required String serviceType,
    required double distanceMiles,
    bool isPriority = false,
    bool needsWinch = false,
  }) {
    final basePrices = <String, int>{
      'flat_tire': 5000,
      'dead_battery': 4500,
      'lockout': 6500,
      'fuel_delivery': 5500,
      'towing': 9500,
      'winch_out': 8500,
    };
    final pricePerMile = <String, int>{
      'flat_tire': 200,
      'dead_battery': 200,
      'lockout': 200,
      'fuel_delivery': 200,
      'towing': 400,
      'winch_out': 300,
    };
    final basePrice = basePrices[serviceType] ?? 5000;
    final perMile = pricePerMile[serviceType] ?? 200;
    final mileagePrice = (distanceMiles * perMile).round();
    final priorityFee = isPriority ? 2000 : 0;
    final winchFee = needsWinch ? 5000 : 0;
    final subtotal = basePrice + mileagePrice + priorityFee + winchFee;
    final serviceFee = (subtotal * 0.1).round();
    final total = subtotal + serviceFee;
    return JobPricing(
      currency: 'usd',
      basePrice: basePrice,
      mileagePrice: mileagePrice,
      priorityFee: priorityFee,
      winchFee: winchFee,
      subtotal: subtotal,
      serviceFee: serviceFee,
      total: total,
    );
  }
}
