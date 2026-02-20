import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../models/location_model.dart';
import '../services/pricing_service.dart';

class PricingState {
  final JobPricing? pricing;
  final QuickQuote? quickQuote;
  final bool isLoading;
  final String? error;
  final String? appliedPromoCode;
  final bool promoCodeValid;

  const PricingState({
    this.pricing,
    this.quickQuote,
    this.isLoading = false,
    this.error,
    this.appliedPromoCode,
    this.promoCodeValid = false,
  });

  PricingState copyWith({
    JobPricing? pricing,
    QuickQuote? quickQuote,
    bool? isLoading,
    String? error,
    String? appliedPromoCode,
    bool? promoCodeValid,
    bool clearError = false,
  }) {
    return PricingState(
      pricing: pricing ?? this.pricing,
      quickQuote: quickQuote ?? this.quickQuote,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      appliedPromoCode: appliedPromoCode ?? this.appliedPromoCode,
      promoCodeValid: promoCodeValid ?? this.promoCodeValid,
    );
  }
}

class PricingNotifier extends StateNotifier<PricingState> {
  final PricingService _service;

  PricingNotifier({PricingService? service})
      : _service = service ?? PricingService(),
        super(const PricingState());

  Future<JobPricing?> calculatePrice({
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
    String? referralCode,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final pricing = await _service.calculatePrice(
        serviceType: serviceType,
        serviceSubType: serviceSubType,
        pickupLocation: pickupLocation,
        destinationLocation: destinationLocation,
        heroLocation: heroLocation,
        heroToPickupMiles: heroToPickupMiles,
        pickupToDestinationMiles: pickupToDestinationMiles,
        isPriority: isPriority,
        needsWinch: needsWinch,
        additionalGallons: additionalGallons,
        customerId: customerId,
        membershipTier: membershipTier,
        promoCode: state.promoCodeValid ? state.appliedPromoCode : null,
        referralCode: referralCode,
      );
      state = state.copyWith(pricing: pricing, isLoading: false);
      return pricing;
    } catch (e) {
      debugPrint('[PricingNotifier] calculatePrice error: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to calculate price');
      return null;
    }
  }

  Future<QuickQuote?> getQuickQuote({
    required String serviceType,
    double? estimatedMiles,
  }) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final quote = await _service.getQuickQuote(
        serviceType: serviceType,
        estimatedMiles: estimatedMiles,
      );
      state = state.copyWith(quickQuote: quote, isLoading: false);
      return quote;
    } catch (e) {
      debugPrint('[PricingNotifier] getQuickQuote error: $e');
      state = state.copyWith(isLoading: false, error: 'Failed to get quote');
      return null;
    }
  }

  Future<bool> applyPromoCode(String code) async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final result = await _service.validatePromoCode(code);
      if (result != null && result['valid'] == true) {
        state = state.copyWith(
          appliedPromoCode: code,
          promoCodeValid: true,
          isLoading: false,
        );
        return true;
      }
      state = state.copyWith(
        appliedPromoCode: null,
        promoCodeValid: false,
        isLoading: false,
        error: result?['message'] ?? 'Invalid promo code',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to validate promo code');
      return false;
    }
  }

  void removePromoCode() {
    state = PricingState(
      pricing: state.pricing,
      quickQuote: state.quickQuote,
      appliedPromoCode: null,
      promoCodeValid: false,
    );
  }

  void reset() => state = const PricingState();
}

final pricingProvider =
    StateNotifierProvider<PricingNotifier, PricingState>((ref) {
  return PricingNotifier();
});

final currentPricingProvider = Provider<JobPricing?>((ref) {
  return ref.watch(pricingProvider).pricing;
});

final isPricingLoadingProvider = Provider<bool>((ref) {
  return ref.watch(pricingProvider).isLoading;
});
