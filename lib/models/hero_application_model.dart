import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus {
  draft,
  submitted,
  underReview,
  backgroundCheck,
  pendingDocuments,
  needsInfo,
  approved,
  rejected,
  suspended,
}

enum DocumentType {
  driversLicenseFront,
  driversLicenseBack,
  vehicleRegistration,
  insuranceCard,
  vehiclePhotoFront,
  vehiclePhotoSide,
  vehiclePhotoRear,
  vehiclePhotoInterior,
  profilePhoto,
  proofOfEquipment,
  certification,
}

// ──────────────────────────────────────────────
// Personal Info
// ──────────────────────────────────────────────

class AddressInfo {
  final String street;
  final String? apartment;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  const AddressInfo({
    required this.street,
    this.apartment,
    required this.city,
    required this.state,
    required this.zipCode,
    this.country = 'US',
  });

  factory AddressInfo.fromJson(Map<String, dynamic> json) {
    return AddressInfo(
      street: json['street'] ?? '',
      apartment: json['apartment'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      country: json['country'] ?? 'US',
    );
  }

  Map<String, dynamic> toJson() => {
        'street': street,
        'apartment': apartment,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
      };
}

class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;

  const EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'relationship': relationship,
        'phone': phone,
      };
}

class PersonalInfo {
  final String firstName;
  final String lastName;
  final String dateOfBirth;
  final String email;
  final String phone;
  final AddressInfo address;
  final EmergencyContact emergencyContact;
  final String? ssnLastFour;

  const PersonalInfo({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.email,
    required this.phone,
    required this.address,
    required this.emergencyContact,
    this.ssnLastFour,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: AddressInfo.fromJson(json['address'] ?? {}),
      emergencyContact: EmergencyContact.fromJson(json['emergencyContact'] ?? {}),
      ssnLastFour: json['ssnLastFour'],
    );
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'dateOfBirth': dateOfBirth,
        'email': email,
        'phone': phone,
        'address': address.toJson(),
        'emergencyContact': emergencyContact.toJson(),
        'ssnLastFour': ssnLastFour,
      };
}

// ──────────────────────────────────────────────
// Vehicle Info
// ──────────────────────────────────────────────

class InsuranceInfo {
  final String provider;
  final String policyNumber;
  final String expirationDate;
  final int? coverageAmount;

  const InsuranceInfo({
    required this.provider,
    required this.policyNumber,
    required this.expirationDate,
    this.coverageAmount,
  });

  factory InsuranceInfo.fromJson(Map<String, dynamic> json) {
    return InsuranceInfo(
      provider: json['provider'] ?? '',
      policyNumber: json['policyNumber'] ?? '',
      expirationDate: json['expirationDate'] ?? '',
      coverageAmount: json['coverageAmount'],
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'policyNumber': policyNumber,
        'expirationDate': expirationDate,
        'coverageAmount': coverageAmount,
      };
}

class RegistrationInfo {
  final String expirationDate;
  final String state;

  const RegistrationInfo({
    required this.expirationDate,
    required this.state,
  });

  factory RegistrationInfo.fromJson(Map<String, dynamic> json) {
    return RegistrationInfo(
      expirationDate: json['expirationDate'] ?? '',
      state: json['state'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'expirationDate': expirationDate,
        'state': state,
      };
}

class VehicleInfo {
  final String make;
  final String model;
  final int year;
  final String color;
  final String licensePlate;
  final String licensePlateState;
  final String? vin;
  final String vehicleType;
  final bool hasHitch;
  final bool hasTowPackage;
  final int? towingCapacity;
  final InsuranceInfo insurance;
  final RegistrationInfo registration;

  const VehicleInfo({
    required this.make,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.licensePlateState,
    this.vin,
    required this.vehicleType,
    this.hasHitch = false,
    this.hasTowPackage = false,
    this.towingCapacity,
    required this.insurance,
    required this.registration,
  });

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: json['year'] ?? 0,
      color: json['color'] ?? '',
      licensePlate: json['licensePlate'] ?? '',
      licensePlateState: json['licensePlateState'] ?? '',
      vin: json['vin'],
      vehicleType: json['vehicleType'] ?? 'car',
      hasHitch: json['hasHitch'] ?? false,
      hasTowPackage: json['hasTowPackage'] ?? false,
      towingCapacity: json['towingCapacity'],
      insurance: InsuranceInfo.fromJson(json['insurance'] ?? {}),
      registration: RegistrationInfo.fromJson(json['registration'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        'licensePlate': licensePlate,
        'licensePlateState': licensePlateState,
        'vin': vin,
        'vehicleType': vehicleType,
        'hasHitch': hasHitch,
        'hasTowPackage': hasTowPackage,
        'towingCapacity': towingCapacity,
        'insurance': insurance.toJson(),
        'registration': registration.toJson(),
      };
}

// ──────────────────────────────────────────────
// Service Capabilities
// ──────────────────────────────────────────────

class ServicesOffered {
  final bool flatTire;
  final bool deadBattery;
  final bool lockout;
  final bool fuelDelivery;
  final bool towing;
  final bool winchOut;

  const ServicesOffered({
    this.flatTire = false,
    this.deadBattery = false,
    this.lockout = false,
    this.fuelDelivery = false,
    this.towing = false,
    this.winchOut = false,
  });

  factory ServicesOffered.fromJson(Map<String, dynamic> json) {
    return ServicesOffered(
      flatTire: json['flatTire'] ?? false,
      deadBattery: json['deadBattery'] ?? false,
      lockout: json['lockout'] ?? false,
      fuelDelivery: json['fuelDelivery'] ?? false,
      towing: json['towing'] ?? false,
      winchOut: json['winchOut'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'flatTire': flatTire,
        'deadBattery': deadBattery,
        'lockout': lockout,
        'fuelDelivery': fuelDelivery,
        'towing': towing,
        'winchOut': winchOut,
      };

  bool get hasAny =>
      flatTire || deadBattery || lockout || fuelDelivery || towing || winchOut;
}

class EquipmentOwned {
  final bool jumpCables;
  final bool portableBatteryPack;
  final bool tireChangeKit;
  final bool jackAndLugWrench;
  final bool airCompressor;
  final bool lockoutKit;
  final bool fuelCan;
  final bool towStraps;
  final bool winch;
  final bool dolly;
  final bool flatbed;
  final bool safetyVest;
  final bool flashlight;
  final bool trafficCones;
  final bool firstAidKit;

  const EquipmentOwned({
    this.jumpCables = false,
    this.portableBatteryPack = false,
    this.tireChangeKit = false,
    this.jackAndLugWrench = false,
    this.airCompressor = false,
    this.lockoutKit = false,
    this.fuelCan = false,
    this.towStraps = false,
    this.winch = false,
    this.dolly = false,
    this.flatbed = false,
    this.safetyVest = false,
    this.flashlight = false,
    this.trafficCones = false,
    this.firstAidKit = false,
  });

  factory EquipmentOwned.fromJson(Map<String, dynamic> json) {
    return EquipmentOwned(
      jumpCables: json['jumpCables'] ?? false,
      portableBatteryPack: json['portableBatteryPack'] ?? false,
      tireChangeKit: json['tireChangeKit'] ?? false,
      jackAndLugWrench: json['jackAndLugWrench'] ?? false,
      airCompressor: json['airCompressor'] ?? false,
      lockoutKit: json['lockoutKit'] ?? false,
      fuelCan: json['fuelCan'] ?? false,
      towStraps: json['towStraps'] ?? false,
      winch: json['winch'] ?? false,
      dolly: json['dolly'] ?? false,
      flatbed: json['flatbed'] ?? false,
      safetyVest: json['safetyVest'] ?? false,
      flashlight: json['flashlight'] ?? false,
      trafficCones: json['trafficCones'] ?? false,
      firstAidKit: json['firstAidKit'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'jumpCables': jumpCables,
        'portableBatteryPack': portableBatteryPack,
        'tireChangeKit': tireChangeKit,
        'jackAndLugWrench': jackAndLugWrench,
        'airCompressor': airCompressor,
        'lockoutKit': lockoutKit,
        'fuelCan': fuelCan,
        'towStraps': towStraps,
        'winch': winch,
        'dolly': dolly,
        'flatbed': flatbed,
        'safetyVest': safetyVest,
        'flashlight': flashlight,
        'trafficCones': trafficCones,
        'firstAidKit': firstAidKit,
      };
}

class DayAvailability {
  final bool available;
  final String? startTime;
  final String? endTime;

  const DayAvailability({
    this.available = false,
    this.startTime,
    this.endTime,
  });

  factory DayAvailability.fromJson(Map<String, dynamic> json) {
    return DayAvailability(
      available: json['available'] ?? false,
      startTime: json['startTime'],
      endTime: json['endTime'],
    );
  }

  Map<String, dynamic> toJson() => {
        'available': available,
        'startTime': startTime,
        'endTime': endTime,
      };
}

class WeeklyAvailability {
  final DayAvailability monday;
  final DayAvailability tuesday;
  final DayAvailability wednesday;
  final DayAvailability thursday;
  final DayAvailability friday;
  final DayAvailability saturday;
  final DayAvailability sunday;

  const WeeklyAvailability({
    this.monday = const DayAvailability(),
    this.tuesday = const DayAvailability(),
    this.wednesday = const DayAvailability(),
    this.thursday = const DayAvailability(),
    this.friday = const DayAvailability(),
    this.saturday = const DayAvailability(),
    this.sunday = const DayAvailability(),
  });

  factory WeeklyAvailability.fromJson(Map<String, dynamic> json) {
    return WeeklyAvailability(
      monday: DayAvailability.fromJson(json['monday'] ?? {}),
      tuesday: DayAvailability.fromJson(json['tuesday'] ?? {}),
      wednesday: DayAvailability.fromJson(json['wednesday'] ?? {}),
      thursday: DayAvailability.fromJson(json['thursday'] ?? {}),
      friday: DayAvailability.fromJson(json['friday'] ?? {}),
      saturday: DayAvailability.fromJson(json['saturday'] ?? {}),
      sunday: DayAvailability.fromJson(json['sunday'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'monday': monday.toJson(),
        'tuesday': tuesday.toJson(),
        'wednesday': wednesday.toJson(),
        'thursday': thursday.toJson(),
        'friday': friday.toJson(),
        'saturday': saturday.toJson(),
        'sunday': sunday.toJson(),
      };
}

class ServiceCapabilities {
  final ServicesOffered services;
  final EquipmentOwned equipment;
  final int yearsExperience;
  final String? previousEmployer;
  final List<String> certifications;
  final WeeklyAvailability availability;
  final int maxServiceRadius;

  const ServiceCapabilities({
    this.services = const ServicesOffered(),
    this.equipment = const EquipmentOwned(),
    this.yearsExperience = 0,
    this.previousEmployer,
    this.certifications = const [],
    this.availability = const WeeklyAvailability(),
    this.maxServiceRadius = 15,
  });

  factory ServiceCapabilities.fromJson(Map<String, dynamic> json) {
    return ServiceCapabilities(
      services: ServicesOffered.fromJson(json['services'] ?? {}),
      equipment: EquipmentOwned.fromJson(json['equipment'] ?? {}),
      yearsExperience: json['yearsExperience'] ?? 0,
      previousEmployer: json['previousEmployer'],
      certifications: List<String>.from(json['certifications'] ?? []),
      availability: WeeklyAvailability.fromJson(json['availability'] ?? {}),
      maxServiceRadius: json['maxServiceRadius'] ?? 15,
    );
  }

  Map<String, dynamic> toJson() => {
        'services': services.toJson(),
        'equipment': equipment.toJson(),
        'yearsExperience': yearsExperience,
        'previousEmployer': previousEmployer,
        'certifications': certifications,
        'availability': availability.toJson(),
        'maxServiceRadius': maxServiceRadius,
      };
}

// ──────────────────────────────────────────────
// Uploaded Document
// ──────────────────────────────────────────────

class UploadedDocument {
  final DocumentType type;
  final String url;
  final String storagePath;
  final DateTime uploadedAt;
  final bool verified;
  final String? rejectionReason;
  final String? expirationDate;

  const UploadedDocument({
    required this.type,
    required this.url,
    required this.storagePath,
    required this.uploadedAt,
    this.verified = false,
    this.rejectionReason,
    this.expirationDate,
  });

  factory UploadedDocument.fromJson(Map<String, dynamic> json) {
    return UploadedDocument(
      type: _parseDocType(json['type']),
      url: json['url'] ?? '',
      storagePath: json['storagePath'] ?? '',
      uploadedAt: json['uploadedAt'] is Timestamp
          ? (json['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
      verified: json['verified'] ?? false,
      rejectionReason: json['rejectionReason'],
      expirationDate: json['expirationDate'],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'url': url,
        'storagePath': storagePath,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'verified': verified,
        'rejectionReason': rejectionReason,
        'expirationDate': expirationDate,
      };

  static DocumentType _parseDocType(String? type) {
    for (final dt in DocumentType.values) {
      if (dt.name == type) return dt;
    }
    return DocumentType.certification;
  }
}

// ──────────────────────────────────────────────
// Agreements
// ──────────────────────────────────────────────

class Agreements {
  final bool termsAccepted;
  final DateTime? termsAcceptedAt;
  final bool privacyAccepted;
  final DateTime? privacyAcceptedAt;
  final bool backgroundCheckConsent;
  final DateTime? backgroundCheckConsentAt;
  final bool independentContractorAgreement;
  final DateTime? independentContractorAgreementAt;
  final bool insuranceAcknowledgment;
  final DateTime? insuranceAcknowledgmentAt;
  final bool safetyPolicyAccepted;
  final DateTime? safetyPolicyAcceptedAt;

  const Agreements({
    this.termsAccepted = false,
    this.termsAcceptedAt,
    this.privacyAccepted = false,
    this.privacyAcceptedAt,
    this.backgroundCheckConsent = false,
    this.backgroundCheckConsentAt,
    this.independentContractorAgreement = false,
    this.independentContractorAgreementAt,
    this.insuranceAcknowledgment = false,
    this.insuranceAcknowledgmentAt,
    this.safetyPolicyAccepted = false,
    this.safetyPolicyAcceptedAt,
  });

  bool get allAccepted =>
      termsAccepted &&
      privacyAccepted &&
      backgroundCheckConsent &&
      independentContractorAgreement &&
      insuranceAcknowledgment &&
      safetyPolicyAccepted;

  factory Agreements.fromJson(Map<String, dynamic> json) {
    return Agreements(
      termsAccepted: json['termsAccepted'] ?? false,
      termsAcceptedAt: (json['termsAcceptedAt'] as Timestamp?)?.toDate(),
      privacyAccepted: json['privacyAccepted'] ?? false,
      privacyAcceptedAt: (json['privacyAcceptedAt'] as Timestamp?)?.toDate(),
      backgroundCheckConsent: json['backgroundCheckConsent'] ?? false,
      backgroundCheckConsentAt:
          (json['backgroundCheckConsentAt'] as Timestamp?)?.toDate(),
      independentContractorAgreement:
          json['independentContractorAgreement'] ?? false,
      independentContractorAgreementAt:
          (json['independentContractorAgreementAt'] as Timestamp?)?.toDate(),
      insuranceAcknowledgment: json['insuranceAcknowledgment'] ?? false,
      insuranceAcknowledgmentAt:
          (json['insuranceAcknowledgmentAt'] as Timestamp?)?.toDate(),
      safetyPolicyAccepted: json['safetyPolicyAccepted'] ?? false,
      safetyPolicyAcceptedAt:
          (json['safetyPolicyAcceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    final now = Timestamp.now();
    return {
      'termsAccepted': termsAccepted,
      'termsAcceptedAt': termsAccepted ? (termsAcceptedAt != null ? Timestamp.fromDate(termsAcceptedAt!) : now) : null,
      'privacyAccepted': privacyAccepted,
      'privacyAcceptedAt': privacyAccepted ? (privacyAcceptedAt != null ? Timestamp.fromDate(privacyAcceptedAt!) : now) : null,
      'backgroundCheckConsent': backgroundCheckConsent,
      'backgroundCheckConsentAt': backgroundCheckConsent ? (backgroundCheckConsentAt != null ? Timestamp.fromDate(backgroundCheckConsentAt!) : now) : null,
      'independentContractorAgreement': independentContractorAgreement,
      'independentContractorAgreementAt': independentContractorAgreement ? (independentContractorAgreementAt != null ? Timestamp.fromDate(independentContractorAgreementAt!) : now) : null,
      'insuranceAcknowledgment': insuranceAcknowledgment,
      'insuranceAcknowledgmentAt': insuranceAcknowledgment ? (insuranceAcknowledgmentAt != null ? Timestamp.fromDate(insuranceAcknowledgmentAt!) : now) : null,
      'safetyPolicyAccepted': safetyPolicyAccepted,
      'safetyPolicyAcceptedAt': safetyPolicyAccepted ? (safetyPolicyAcceptedAt != null ? Timestamp.fromDate(safetyPolicyAcceptedAt!) : now) : null,
    };
  }
}

// ──────────────────────────────────────────────
// Main Application Model
// ──────────────────────────────────────────────

class HeroApplicationModel {
  final String id;
  final String userId;
  final String userEmail;
  final ApplicationStatus status;
  final int currentStep;
  final List<int> completedSteps;
  final PersonalInfo? personalInfo;
  final VehicleInfo? vehicleInfo;
  final ServiceCapabilities? serviceCapabilities;
  final List<UploadedDocument> documents;
  final Agreements? agreements;
  final bool trainingCompleted;
  final int? quizScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final String? heroProfileId;
  final String? rejectionReason;

  const HeroApplicationModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    this.status = ApplicationStatus.draft,
    this.currentStep = 1,
    this.completedSteps = const [],
    this.personalInfo,
    this.vehicleInfo,
    this.serviceCapabilities,
    this.documents = const [],
    this.agreements,
    this.trainingCompleted = false,
    this.quizScore,
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
    this.approvedAt,
    this.heroProfileId,
    this.rejectionReason,
  });

  factory HeroApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HeroApplicationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      status: _parseStatus(data['status']),
      currentStep: data['currentStep'] ?? 1,
      completedSteps: List<int>.from(data['completedSteps'] ?? []),
      personalInfo: data['personalInfo'] != null
          ? PersonalInfo.fromJson(
              Map<String, dynamic>.from(data['personalInfo']))
          : null,
      vehicleInfo: data['vehicleInfo'] != null
          ? VehicleInfo.fromJson(
              Map<String, dynamic>.from(data['vehicleInfo']))
          : null,
      serviceCapabilities: data['serviceCapabilities'] != null
          ? ServiceCapabilities.fromJson(
              Map<String, dynamic>.from(data['serviceCapabilities']))
          : null,
      documents: (data['documents'] as List?)
              ?.map((d) =>
                  UploadedDocument.fromJson(Map<String, dynamic>.from(d)))
              .toList() ??
          [],
      agreements: data['agreements'] != null
          ? Agreements.fromJson(
              Map<String, dynamic>.from(data['agreements']))
          : null,
      trainingCompleted: data['trainingCompleted'] ?? false,
      quizScore: data['quizScore'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      heroProfileId: data['heroProfileId'],
      rejectionReason: _extractRejectionReason(data),
    );
  }

  static ApplicationStatus _parseStatus(String? status) {
    switch (status) {
      case 'draft':
        return ApplicationStatus.draft;
      case 'submitted':
        return ApplicationStatus.submitted;
      case 'under_review':
        return ApplicationStatus.underReview;
      case 'background_check':
        return ApplicationStatus.backgroundCheck;
      case 'pending_documents':
        return ApplicationStatus.pendingDocuments;
      case 'needs_info':
        return ApplicationStatus.needsInfo;
      case 'approved':
        return ApplicationStatus.approved;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'suspended':
        return ApplicationStatus.suspended;
      default:
        return ApplicationStatus.draft;
    }
  }

  static String statusToString(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.draft:
        return 'draft';
      case ApplicationStatus.submitted:
        return 'submitted';
      case ApplicationStatus.underReview:
        return 'under_review';
      case ApplicationStatus.backgroundCheck:
        return 'background_check';
      case ApplicationStatus.pendingDocuments:
        return 'pending_documents';
      case ApplicationStatus.needsInfo:
        return 'needs_info';
      case ApplicationStatus.approved:
        return 'approved';
      case ApplicationStatus.rejected:
        return 'rejected';
      case ApplicationStatus.suspended:
        return 'suspended';
    }
  }

  static String? _extractRejectionReason(Map<String, dynamic> data) {
    final notes = data['reviewNotes'] as List?;
    if (notes == null || notes.isEmpty) return null;
    for (final note in notes.reversed) {
      final isInternal = note['isInternal'] ?? true;
      if (!isInternal) return note['content'] as String?;
    }
    return null;
  }

  bool get isComplete => completedSteps.length >= 5;
  bool get canSubmit => isComplete && (agreements?.allAccepted ?? false);
  bool get isApproved => status == ApplicationStatus.approved;
  bool get isDraft => status == ApplicationStatus.draft;

  bool get isPending => const [
        ApplicationStatus.submitted,
        ApplicationStatus.underReview,
        ApplicationStatus.backgroundCheck,
      ].contains(status);

  double get progressPercent => (completedSteps.length / 5) * 100;

  String get statusLabel {
    switch (status) {
      case ApplicationStatus.draft:
        return 'In Progress';
      case ApplicationStatus.submitted:
        return 'Submitted - Under Review';
      case ApplicationStatus.underReview:
        return 'Under Review';
      case ApplicationStatus.backgroundCheck:
        return 'Background Check In Progress';
      case ApplicationStatus.pendingDocuments:
        return 'Additional Documents Needed';
      case ApplicationStatus.needsInfo:
        return 'Additional Info Requested';
      case ApplicationStatus.approved:
        return 'Approved!';
      case ApplicationStatus.rejected:
        return 'Not Approved';
      case ApplicationStatus.suspended:
        return 'Suspended';
    }
  }
}
