export enum ApplicationStatus {
  DRAFT = "draft",
  SUBMITTED = "submitted",
  UNDER_REVIEW = "under_review",
  BACKGROUND_CHECK = "background_check",
  PENDING_DOCUMENTS = "pending_documents",
  NEEDS_INFO = "needs_info",
  APPROVED = "approved",
  REJECTED = "rejected",
  SUSPENDED = "suspended",
}

export interface PersonalInfo {
  firstName: string;
  lastName: string;
  dateOfBirth: string;
  email: string;
  phone: string;
  address: {
    street: string;
    apartment?: string;
    city: string;
    state: string;
    zipCode: string;
    country: string;
  };
  emergencyContact: {
    name: string;
    relationship: string;
    phone: string;
  };
  ssnLastFour?: string;
}

export interface VehicleInfo {
  make: string;
  model: string;
  year: number;
  color: string;
  licensePlate: string;
  licensePlateState: string;
  vin?: string;
  vehicleType: string;
  hasHitch: boolean;
  hasTowPackage: boolean;
  towingCapacity?: number;
  insurance: {
    provider: string;
    policyNumber: string;
    expirationDate: string;
    coverageAmount?: number;
  };
  registration: {
    expirationDate: string;
    state: string;
  };
}

export interface ServiceCapabilities {
  services: {
    flatTire: boolean;
    deadBattery: boolean;
    lockout: boolean;
    fuelDelivery: boolean;
    towing: boolean;
    winchOut: boolean;
  };
  equipment: Record<string, boolean>;
  yearsExperience: number;
  previousEmployer?: string;
  certifications: string[];
  availability: Record<string, { available: boolean; startTime?: string; endTime?: string }>;
  maxServiceRadius: number;
}

export interface UploadedDoc {
  type: string;
  url: string;
  storagePath: string;
  uploadedAt: FirebaseFirestore.Timestamp;
  verified: boolean;
  expirationDate?: string;
}

export interface Agreements {
  termsAccepted: boolean;
  privacyAccepted: boolean;
  backgroundCheckConsent: boolean;
  independentContractorAgreement: boolean;
  insuranceAcknowledgment: boolean;
  safetyPolicyAccepted: boolean;
}

export interface HeroApplication {
  id: string;
  userId: string;
  userEmail: string;
  status: ApplicationStatus;
  currentStep: number;
  completedSteps: number[];
  personalInfo?: PersonalInfo;
  vehicleInfo?: VehicleInfo;
  serviceCapabilities?: ServiceCapabilities;
  documents?: UploadedDoc[];
  agreements?: Agreements;
  reviewNotes?: Array<{
    id: string;
    authorId: string;
    content: string;
    isInternal: boolean;
    createdAt: FirebaseFirestore.Timestamp;
  }>;
  statusHistory?: Array<{
    status: ApplicationStatus;
    changedAt: FirebaseFirestore.Timestamp;
    changedBy: string;
    reason?: string;
  }>;
  trainingCompleted: boolean;
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
  submittedAt?: FirebaseFirestore.Timestamp;
  approvedAt?: FirebaseFirestore.Timestamp;
  rejectedAt?: FirebaseFirestore.Timestamp;
  heroProfileId?: string;
}
