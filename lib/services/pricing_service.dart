import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../models/job_model.dart';
import '../models/location_model.dart';

class QuickQuote {
  final String serviceType;
  final String serviceName;
  final int basePrice;
  final double estimatedMiles;
  final int distanceFee;
  final int serviceFee;
  final int total;
  final String currency;
  final String disclaimer;

  QuickQuote({
    required this.serviceType,
    required this.serviceName,
    required this.basePrice,
    required this.estimatedMiles,
    required this.distanceFee,
    required this.serviceFee,
    required this.total,
    required this.currency,
    required this.disclaimer,
  });

  factory QuickQuote.fromJson(Map<String, dynamic> json) => QuickQuote(
        serviceType: json['serviceType'] ?? '',
        serviceName: json['serviceName'] ?? '',
        basePrice: (json['basePrice'] as num?)?.toInt() ?? 0,
        estimatedMiles: (json['estimatedMiles'] as num?)?.toDouble() ?? 0,
        distanceFee: (json['distanceFee'] as num?)?.toInt() ?? 0,
        serviceFee: (json['serviceFee'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        currency: json['currency'] ?? 'usd',
        disclaimer: json['disclaimer'] ?? '',
      );

  String get formattedTotal => '\$${(total / 100).toStringAsFixed(2)}';
}

class PricingService {
  static final PricingService _instance = PricingService._internal();
  factory PricingService() => _instance;
  PricingService._internal();

  final _functions = FirebaseFunctions.instance;

  Future<JobPricing> calculatePrice({
    required String serviceType,
    String? serviceSubType,
    required LocationModel pickupLocation,
    LocationModel? destinationLocation,
    LocationModel? heroLocation,
    double? heroToPickupMiles,
    double? pickupToDestinationMiles,
    bool isPriority = false,
    bool needsWinch = false,
    int additionalGallons = 0,
    String? customerId,
    String? membershipTier,
    String? promoCode,
    String? referralCode,
  }) async {
    try {
      final callable = _functions.httpsCallable('calculateJobPrice');
      final result = await callable.call<Map<String, dynamic>>({
        'serviceType': serviceType,
        if (serviceSubType != null) 'serviceSubType': serviceSubType,
        'pickupLocation': {
          'latitude': pickupLocation.latitude,
          'longitude': pickupLocation.longitude,
        },
        if (destinationLocation != null)
          'destinationLocation': {
            'latitude': destinationLocation.latitude,
            'longitude': destinationLocation.longitude,
          },
        if (heroLocation != null)
          'heroLocation': {
            'latitude': heroLocation.latitude,
            'longitude': heroLocation.longitude,
          },
        if (heroToPickupMiles != null) 'heroToPickupMiles': heroToPickupMiles,
        if (pickupToDestinationMiles != null)
          'pickupToDestinationMiles': pickupToDestinationMiles,
        'isPriority': isPriority,
        'needsWinch': needsWinch,
        'additionalGallons': additionalGallons,
        if (customerId != null) 'customerId': customerId,
        if (membershipTier != null) 'membershipTier': membershipTier,
        if (promoCode != null) 'promoCode': promoCode,
        if (referralCode != null) 'referralCode': referralCode,
      });
      return JobPricing.fromJson(Map<String, dynamic>.from(result.data));
    } catch (e) {
      debugPrint('[PricingService] calculatePrice error: $e');
      rethrow;
    }
  }

  Future<QuickQuote> getQuickQuote({
    required String serviceType,
    double? estimatedMiles,
  }) async {
    try {
      final callable = _functions.httpsCallable('getQuickQuote');
      final result = await callable.call<Map<String, dynamic>>({
        'serviceType': serviceType,
        'estimatedMiles': estimatedMiles,
      });
      return QuickQuote.fromJson(Map<String, dynamic>.from(result.data));
    } catch (e) {
      debugPrint('[PricingService] getQuickQuote error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> validatePromoCode(String code) async {
    try {
      final callable = _functions.httpsCallable('validatePromoCode');
      final result = await callable.call<Map<String, dynamic>>({'code': code});
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('[PricingService] validatePromoCode error: $e');
      return null;
    }
  }
}
