import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hero_application_model.dart';
import '../services/hero_application_service.dart';
import 'auth_provider.dart';

class HeroApplicationState {
  final HeroApplicationModel? application;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final int currentStep;

  const HeroApplicationState({
    this.application,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.currentStep = 1,
  });

  HeroApplicationState copyWith({
    HeroApplicationModel? application,
    bool? isLoading,
    bool? isSaving,
    String? error,
    int? currentStep,
  }) {
    return HeroApplicationState(
      application: application ?? this.application,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class HeroApplicationNotifier extends StateNotifier<HeroApplicationState> {
  final HeroApplicationService _service;
  final Ref _ref;

  HeroApplicationNotifier({
    required HeroApplicationService service,
    required Ref ref,
  })  : _service = service,
        _ref = ref,
        super(const HeroApplicationState(isLoading: true)) {
    _initialize();
  }

  Future<void> _initialize() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    try {
      final application =
          await _service.getOrCreateApplication(user.id, user.email);
      state = state.copyWith(
        application: application,
        currentStep: application.currentStep,
        isLoading: false,
      );
    } catch (e, stack) {
      debugPrint('[HeroApplication] Failed to load: $e');
      debugPrint('[HeroApplication] Stack: $stack');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load application: $e',
      );
    }
  }

  Future<void> refresh() async {
    if (state.application == null) {
      state = state.copyWith(isLoading: true, error: null);
      await _initialize();
      return;
    }
    try {
      final application =
          await _service.getApplication(state.application!.id);
      if (application != null) {
        state = state.copyWith(application: application);
      }
    } catch (_) {}
  }

  void setCurrentStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // ── Step 1 ──

  Future<bool> savePersonalInfo(PersonalInfo info) async {
    if (state.application == null) return false;
    try {
      state = state.copyWith(isSaving: true, error: null);
      await _service.updatePersonalInfo(state.application!.id, info);
      await refresh();
      state = state.copyWith(isSaving: false);
      nextStep();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Failed to save: $e');
      return false;
    }
  }

  // ── Step 2 ──

  Future<bool> saveVehicleInfo(VehicleInfo info) async {
    if (state.application == null) return false;
    try {
      state = state.copyWith(isSaving: true, error: null);
      await _service.updateVehicleInfo(state.application!.id, info);
      await refresh();
      state = state.copyWith(isSaving: false);
      nextStep();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Failed to save: $e');
      return false;
    }
  }

  // ── Step 3 ──

  Future<bool> saveServiceCapabilities(ServiceCapabilities caps) async {
    if (state.application == null) return false;
    try {
      state = state.copyWith(isSaving: true, error: null);
      await _service.updateServiceCapabilities(state.application!.id, caps);
      await refresh();
      state = state.copyWith(isSaving: false);
      nextStep();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Failed to save: $e');
      return false;
    }
  }

  // ── Step 4 ──

  Future<UploadedDocument?> uploadDocument(
    DocumentType type,
    File file, {
    String? expirationDate,
  }) async {
    if (state.application == null) return null;
    final user = _ref.read(currentUserProvider);
    if (user == null) return null;

    try {
      state = state.copyWith(isSaving: true, error: null);
      final document = await _service.uploadDocument(
        state.application!.id,
        user.id,
        type,
        file,
        expirationDate: expirationDate,
      );
      await refresh();
      state = state.copyWith(isSaving: false);
      return document;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Upload failed: $e');
      return null;
    }
  }

  Future<void> deleteDocument(UploadedDocument document) async {
    if (state.application == null) return;
    try {
      state = state.copyWith(isSaving: true, error: null);
      await _service.removeDocument(state.application!.id, document);
      await refresh();
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Delete failed: $e');
    }
  }

  Future<bool> completeDocumentsStep() async {
    if (state.application == null) return false;

    final docs = state.application!.documents;
    final required = [
      DocumentType.driversLicenseFront,
      DocumentType.driversLicenseBack,
      DocumentType.insuranceCard,
      DocumentType.vehicleRegistration,
      DocumentType.profilePhoto,
    ];

    for (final type in required) {
      if (!docs.any((d) => d.type == type)) {
        state = state.copyWith(error: 'Please upload all required documents');
        return false;
      }
    }

    try {
      state = state.copyWith(isSaving: true, error: null);
      await _service.completeDocumentsStep(state.application!.id);
      await refresh();
      state = state.copyWith(isSaving: false);
      nextStep();
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Failed to continue: $e');
      return false;
    }
  }

  // ── Step 5 ──

  Future<bool> saveAgreements(Agreements agreements) async {
    if (state.application == null) return false;
    try {
      state = state.copyWith(isSaving: true, error: null);
      await _service.updateAgreements(state.application!.id, agreements);
      await refresh();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Failed to save: $e');
      return false;
    }
  }

  Future<bool> submitApplication() async {
    if (state.application == null) return false;
    try {
      state = state.copyWith(isSaving: true, error: null);
      final result =
          await _service.submitApplication(state.application!.id);

      if (result['success'] == true) {
        await refresh();
        state = state.copyWith(isSaving: false);
        return true;
      } else {
        state = state.copyWith(
          isSaving: false,
          error: result['message'] as String? ?? 'Submission failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isSaving: false, error: 'Submission failed: $e');
      return false;
    }
  }
}

// ── Providers ──

final heroApplicationProvider =
    StateNotifierProvider<HeroApplicationNotifier, HeroApplicationState>(
        (ref) {
  return HeroApplicationNotifier(
    service: HeroApplicationService(),
    ref: ref,
  );
});

final applicationStepProvider = Provider<int>((ref) {
  return ref.watch(heroApplicationProvider).currentStep;
});

final isApplicationSavingProvider = Provider<bool>((ref) {
  return ref.watch(heroApplicationProvider).isSaving;
});

final applicationErrorProvider = Provider<String?>((ref) {
  return ref.watch(heroApplicationProvider).error;
});
