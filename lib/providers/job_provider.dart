import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../models/location_model.dart';
import '../services/firestore_service.dart';
import '../services/payment_service.dart';
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
  final bool isLoading;
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
    this.isLoading = false,
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
  final Ref _ref;

  JobCreationNotifier({
    required FirestoreService firestoreService,
    required PaymentService paymentService,
    required Ref ref,
  })  : _firestoreService = firestoreService,
        _paymentService = paymentService,
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

  void _recalculatePrice() {
    if (state.serviceType == null || state.pickupLocation == null) return;
    const distance = 5.0;
    final pricing = _paymentService.calculatePrice(
      serviceType: state.serviceType!,
      distanceMiles: distance,
    );
    state = state.copyWith(pricing: pricing);
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
        'pricing': {
          'currency': state.pricing!.currency,
          'basePrice': state.pricing!.basePrice,
          'mileagePrice': state.pricing!.mileagePrice,
          'priorityFee': state.pricing!.priorityFee,
          'winchFee': state.pricing!.winchFee,
          'subtotal': state.pricing!.subtotal,
          'serviceFee': state.pricing!.serviceFee,
          'total': state.pricing!.total,
        },
      });
      state = state.copyWith(isLoading: false);
      return jobId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
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
    bool? isLoading,
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
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final jobCreationProvider =
    StateNotifierProvider<JobCreationNotifier, JobCreationState>((ref) {
  return JobCreationNotifier(
    firestoreService: FirestoreService(),
    paymentService: PaymentService(),
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
