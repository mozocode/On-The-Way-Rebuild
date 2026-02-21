import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../models/location_model.dart';
import '../services/firestore_service.dart';
import '../services/payment_service.dart';
import '../services/pricing_service.dart';
import '../services/stripe_service.dart';
import 'auth_provider.dart';

class JobCreationState {
  final String? serviceType;
  final String? serviceSubType;
  final LocationModel? pickupLocation;
  final String? pickupAddress;
  final String? pickupNotes;
  final LocationModel? destinationLocation;
  final String? destinationAddress;
  final JobPricing? pricing;
  final bool isPriority;
  final bool needsWinch;
  final String? promoCode;
  final bool isLoading;
  final bool isPriceLoading;
  final String? error;

  const JobCreationState({
    this.serviceType,
    this.serviceSubType,
    this.pickupLocation,
    this.pickupAddress,
    this.pickupNotes,
    this.destinationLocation,
    this.destinationAddress,
    this.pricing,
    this.isPriority = false,
    this.needsWinch = false,
    this.promoCode,
    this.isLoading = false,
    this.isPriceLoading = false,
    this.error,
  });

  bool get isValid =>
      serviceType != null &&
      pickupLocation != null &&
      pickupAddress != null &&
      pricing != null;
}

class JobCreationNotifier extends StateNotifier<JobCreationState> {
  final FirestoreService _firestoreService;
  final PaymentService _paymentService;
  final PricingService _pricingService;
  final StripeService _stripeService;
  final Ref _ref;

  JobCreationNotifier({
    required FirestoreService firestoreService,
    required PaymentService paymentService,
    required PricingService pricingService,
    required StripeService stripeService,
    required Ref ref,
  })  : _firestoreService = firestoreService,
        _paymentService = paymentService,
        _pricingService = pricingService,
        _stripeService = stripeService,
        _ref = ref,
        super(const JobCreationState());

  void setServiceType(String serviceType, {String? subType}) {
    state = state.copyWith(serviceType: serviceType, serviceSubType: subType);
    _recalculatePrice();
  }

  void setPickupLocation(
      LocationModel location, String address, {String? notes}) {
    state = state.copyWith(
      pickupLocation: location,
      pickupAddress: address,
      pickupNotes: notes,
    );
    _recalculatePrice();
  }

  void setDestinationLocation(LocationModel location, String address) {
    state = state.copyWith(
      destinationLocation: location,
      destinationAddress: address,
    );
    _recalculatePrice();
  }

  void setPriority(bool value) {
    state = state.copyWith(isPriority: value);
    _recalculatePrice();
  }

  void setNeedsWinch(bool value) {
    state = state.copyWith(needsWinch: value);
    _recalculatePrice();
  }

  void setPromoCode(String? code) {
    state = state.copyWith(promoCode: code);
  }

  Future<void> _recalculatePrice() async {
    if (state.serviceType == null || state.pickupLocation == null) return;
    state = state.copyWith(isPriceLoading: true);

    try {
      final pricing = await _pricingService.calculatePrice(
        serviceType: state.serviceType!,
        serviceSubType: state.serviceSubType,
        pickupLocation: state.pickupLocation!,
        destinationLocation: state.destinationLocation,
        isPriority: state.isPriority,
        needsWinch: state.needsWinch,
        promoCode: state.promoCode,
      );
      if (!mounted) return;
      state = state.copyWith(pricing: pricing, isPriceLoading: false);
    } catch (e) {
      debugPrint('[JobCreation] Cloud pricing failed, using local fallback: $e');
      final distanceMiles = _estimateDistanceMiles();
      final pricing = _paymentService.calculatePrice(
        serviceType: state.serviceType!,
        distanceMiles: distanceMiles,
        isPriority: state.isPriority,
        needsWinch: state.needsWinch,
      );
      if (!mounted) return;
      state = state.copyWith(pricing: pricing, isPriceLoading: false);
    }
  }

  Future<String?> createJob() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please fill in all required fields');
      return null;
    }
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(error: 'Please sign in to request service');
      return null;
    }
    try {
      state = state.copyWith(isLoading: true, error: null);
      final jobId = await _firestoreService.createJob({
        'customer': {
          'id': user.id,
          'name': user.fullName,
          'phone': user.phone,
          'photoUrl': user.photoUrl,
        },
        'service': {
          'type': state.serviceType,
          'subType': state.serviceSubType,
        },
        'pickup': {
          'location': {
            'latitude': state.pickupLocation!.latitude,
            'longitude': state.pickupLocation!.longitude,
          },
          'address': {'formatted': state.pickupAddress},
          'notes': state.pickupNotes,
        },
        if (state.destinationLocation != null)
          'destination': {
            'location': {
              'latitude': state.destinationLocation!.latitude,
              'longitude': state.destinationLocation!.longitude,
            },
            'address': {'formatted': state.destinationAddress},
          },
        'pricing': state.pricing!.toJson(),
        if (state.promoCode != null)
          'discounts': {'promoCode': state.promoCode},
      });

      try {
        final clientSecret = await _stripeService.createPaymentIntent(jobId);
        await _stripeService.presentPaymentSheet(clientSecret);
      } catch (e) {
        try { await _firestoreService.updateJobStatus(jobId, 'cancelled'); } catch (_) {}
        state = state.copyWith(isLoading: false, error: 'Payment failed. Please try again.');
        return null;
      }

      state = state.copyWith(isLoading: false);
      return jobId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  double _estimateDistanceMiles() {
    final pickup = state.pickupLocation;
    final dest = state.destinationLocation;
    if (pickup == null || dest == null) return 5.0;
    const r = 3958.8;
    final dLat = (dest.latitude - pickup.latitude) * math.pi / 180;
    final dLng = (dest.longitude - pickup.longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(pickup.latitude * math.pi / 180) *
            math.cos(dest.latitude * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final distance = r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return distance > 0 ? distance : 5.0;
  }

  void reset() {
    state = const JobCreationState();
  }
}

extension _JobCreationCopyWith on JobCreationState {
  JobCreationState copyWith({
    String? serviceType,
    String? serviceSubType,
    LocationModel? pickupLocation,
    String? pickupAddress,
    String? pickupNotes,
    LocationModel? destinationLocation,
    String? destinationAddress,
    JobPricing? pricing,
    bool? isPriority,
    bool? needsWinch,
    String? promoCode,
    bool? isLoading,
    bool? isPriceLoading,
    String? error,
  }) {
    return JobCreationState(
      serviceType: serviceType ?? this.serviceType,
      serviceSubType: serviceSubType ?? this.serviceSubType,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupNotes: pickupNotes ?? this.pickupNotes,
      destinationLocation: destinationLocation ?? this.destinationLocation,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      pricing: pricing ?? this.pricing,
      isPriority: isPriority ?? this.isPriority,
      needsWinch: needsWinch ?? this.needsWinch,
      promoCode: promoCode ?? this.promoCode,
      isLoading: isLoading ?? this.isLoading,
      isPriceLoading: isPriceLoading ?? this.isPriceLoading,
      error: error,
    );
  }
}

final jobCreationProvider =
    StateNotifierProvider<JobCreationNotifier, JobCreationState>((ref) {
  return JobCreationNotifier(
    firestoreService: FirestoreService(),
    paymentService: PaymentService(),
    pricingService: PricingService(),
    stripeService: StripeService(),
    ref: ref,
  );
});

final activeCustomerJobProvider = StreamProvider<JobModel?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return FirestoreService().watchActiveCustomerJob(user.id);
});

final jobStreamProvider =
    StreamProvider.family<JobModel?, String>((ref, jobId) {
  return FirestoreService().watchJob(jobId);
});

final pendingJobsProvider = StreamProvider<List<JobModel>>((ref) {
  return FirestoreService().watchPendingJobs();
});

/// Streams the sum of heroPayout.totalPayout (in cents) for today's completed jobs.
final heroDailyEarningsProvider =
    StreamProvider.family<double, String>((ref, heroId) {
  return FirestoreService().watchHeroCompletedJobsToday(heroId).map((jobs) {
    int totalCents = 0;
    for (final job in jobs) {
      totalCents += job.pricing.heroPayout.totalPayout;
    }
    return totalCents / 100.0;
  });
});
