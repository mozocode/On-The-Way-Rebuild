import * as admin from "firebase-admin";

export interface ServiceSubType {
  name: string;
  priceModifier: number;
  additionalFee: number;
}

export interface ServicePricing {
  id: string;
  name: string;
  description: string;
  basePrice: number;
  pricePerMile: number;
  minimumMiles: number;
  freeIncludedMiles: number;
  estimatedDurationMinutes: number;
  subTypes?: { [key: string]: ServiceSubType };
  requiresDestination: boolean;
  requiresWinch: boolean;
  isActive: boolean;
}

export interface SurgeConfig {
  hourlyMultipliers: { [hour: number]: number };
  dayMultipliers: {
    sunday: number;
    monday: number;
    tuesday: number;
    wednesday: number;
    thursday: number;
    friday: number;
    saturday: number;
  };
  holidayMultiplier: number;
  holidays: string[];
  demandThresholds: {
    low: { ratio: number; multiplier: number };
    normal: { ratio: number; multiplier: number };
    high: { ratio: number; multiplier: number };
    surge: { ratio: number; multiplier: number };
  };
  maxSurgeMultiplier: number;
}

export interface PlatformFees {
  serviceFeePercent: number;
  minServiceFee: number;
  maxServiceFee: number;
  paymentProcessingPercent: number;
  paymentProcessingFixed: number;
}

export interface AddOnPricing {
  priorityFee: number;
  winchFee: number;
  fuelGallonPrice: number;
  afterHoursFee: number;
  weekendFee: number;
  holidayFee: number;
}

export interface PromoCodeConfig {
  type: "percent" | "fixed";
  value: number;
  maxDiscount?: number;
  minOrderValue?: number;
  expiresAt?: string;
  maxUses?: number;
  currentUses?: number;
  applicableServices?: string[];
}

export interface MembershipTierConfig {
  discountPercent: number;
  freeServices?: number;
  priorityFree?: boolean;
}

export interface DiscountConfig {
  promoCodeDiscounts: { [code: string]: PromoCodeConfig };
  membershipDiscounts: { [tier: string]: MembershipTierConfig };
  referralDiscount: {
    referrerCredit: number;
    refereeDiscount: number;
  };
  loyaltyProgram: {
    pointsPerDollar: number;
    pointsRedemptionRate: number;
  };
}

export interface HeroPayoutConfig {
  basePayoutPercent: number;
  distancePayoutPercent: number;
  tierBonuses: {
    standard: number;
    silver: number;
    gold: number;
    platinum: number;
  };
  performanceBonuses: {
    highRating: { threshold: number; bonus: number };
    fastAcceptance: { threshold: number; bonus: number };
    consecutiveJobs: { threshold: number; bonus: number };
  };
  minimumPayout: number;
}

export interface PricingConfig {
  services: ServicePricing[];
  surge: SurgeConfig;
  platformFees: PlatformFees;
  addOns: AddOnPricing;
  discounts: DiscountConfig;
  heroPayout: HeroPayoutConfig;
  updatedAt: admin.firestore.Timestamp | null;
}
