import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { PricingConfig, ServicePricing, SurgeConfig } from "../types/pricing";
import { DEFAULT_PRICING_CONFIG } from "../config/pricing";

const firestore = admin.firestore();

export interface PriceCalculationRequest {
  serviceType: string;
  serviceSubType?: string;
  pickupLocation: { latitude: number; longitude: number };
  destinationLocation?: { latitude: number; longitude: number };
  heroLocation?: { latitude: number; longitude: number };
  heroToPickupMiles?: number;
  pickupToDestinationMiles?: number;
  isPriority?: boolean;
  needsWinch?: boolean;
  additionalGallons?: number;
  customerId?: string;
  membershipTier?: string;
  promoCode?: string;
  referralCode?: string;
  activeJobsInArea?: number;
  availableHeroesInArea?: number;
}

export interface PriceBreakdown {
  basePrice: number;
  subTypeModifier: number;
  subTypeAdditionalFee: number;
  heroTravelFee: number;
  heroTravelMiles: number;
  towingDistanceFee: number;
  towingDistanceMiles: number;
  freeIncludedMiles: number;
  surgePricing: {
    timeMultiplier: number;
    dayMultiplier: number;
    demandMultiplier: number;
    holidayMultiplier: number;
    combinedMultiplier: number;
    surgeAmount: number;
  };
  addOns: {
    priorityFee: number;
    winchFee: number;
    fuelFee: number;
    afterHoursFee: number;
    weekendFee: number;
    holidayFee: number;
    total: number;
  };
  subtotalBeforeDiscounts: number;
  discounts: {
    promoDiscount: number;
    promoCode?: string;
    membershipDiscount: number;
    membershipTier?: string;
    referralDiscount: number;
    loyaltyPointsUsed: number;
    loyaltyDiscount: number;
    totalDiscount: number;
  };
  subtotalAfterDiscounts: number;
  serviceFee: number;
  serviceFeePercent: number;
  taxRate: number;
  taxAmount: number;
  total: number;
  estimatedRange: { min: number; max: number };
  heroPayout: {
    basePayout: number;
    distancePayout: number;
    tierBonus: number;
    performanceBonus: number;
    totalPayout: number;
  };
  currency: string;
  calculatedAt: string;
  configVersion: string;
  // Legacy fields for backward compatibility with existing mobile app screens
  mileagePrice: number;
  subtotal: number;
  priorityFee: number;
  winchFee: number;
}

async function loadConfig(): Promise<PricingConfig> {
  try {
    const doc = await firestore.collection("pricingConfig").doc("default").get();
    if (doc.exists) return doc.data() as PricingConfig;
  } catch (e) {
    console.warn("Failed to load pricing config, using defaults:", e);
  }
  return DEFAULT_PRICING_CONFIG;
}

export class PricingEngine {
  constructor(private config: PricingConfig) {}

  async calculatePrice(req: PriceCalculationRequest): Promise<PriceBreakdown> {
    const now = new Date();

    const service = this.config.services.find(
      (s) => s.id === req.serviceType && s.isActive
    );
    if (!service) throw new Error(`Unknown service type: ${req.serviceType}`);

    // Step 1: Base price with sub-type
    let subTypeModifier = 1.0;
    let subTypeAdditionalFee = 0;
    if (req.serviceSubType && service.subTypes?.[req.serviceSubType]) {
      const st = service.subTypes[req.serviceSubType];
      subTypeModifier = st.priceModifier;
      subTypeAdditionalFee = st.additionalFee;
    }
    const basePrice =
      Math.round(service.basePrice * subTypeModifier) + subTypeAdditionalFee;

    // Step 2: Hero travel distance
    const heroTravelMiles = req.heroToPickupMiles ?? 5;
    const heroTravelFee = Math.round(heroTravelMiles * service.pricePerMile);

    // Step 3: Towing/destination distance
    let towingDistanceMiles = 0;
    let towingDistanceFee = 0;
    if (service.requiresDestination && req.pickupToDestinationMiles) {
      towingDistanceMiles = req.pickupToDestinationMiles;
      const chargeable = Math.max(
        0,
        towingDistanceMiles - service.freeIncludedMiles
      );
      towingDistanceFee = Math.round(chargeable * service.pricePerMile);
    }

    // Step 4: Surge
    const surge = this.calculateSurge(now, req);

    // Step 5: Add-ons
    const addOns = this.calculateAddOns(service, req, now);

    // Step 6: Subtotal with surge
    const priceBeforeSurge =
      basePrice + heroTravelFee + towingDistanceFee + addOns.total;
    const surgeAmount = Math.round(
      priceBeforeSurge * (surge.combinedMultiplier - 1)
    );
    const subtotalBeforeDiscounts = priceBeforeSurge + surgeAmount;

    // Step 7: Discounts
    const discounts = this.calculateDiscounts(
      req,
      subtotalBeforeDiscounts
    );
    const subtotalAfterDiscounts = Math.max(
      0,
      subtotalBeforeDiscounts - discounts.totalDiscount
    );

    // Step 8: Service fee (clamped)
    const { platformFees } = this.config;
    let serviceFee = Math.round(
      subtotalAfterDiscounts * (platformFees.serviceFeePercent / 100)
    );
    serviceFee = Math.max(serviceFee, platformFees.minServiceFee);
    serviceFee = Math.min(serviceFee, platformFees.maxServiceFee);

    // Step 9: Tax (0 for now)
    const taxRate = 0;
    const taxAmount = 0;

    // Step 10: Total
    const total = subtotalAfterDiscounts + serviceFee + taxAmount;

    // Hero payout
    const heroPayout = this.calculateHeroPayout(
      Math.round(service.basePrice * subTypeModifier) + subTypeAdditionalFee,
      heroTravelFee + towingDistanceFee
    );

    return {
      basePrice,
      subTypeModifier,
      subTypeAdditionalFee,
      heroTravelFee,
      heroTravelMiles,
      towingDistanceFee,
      towingDistanceMiles,
      freeIncludedMiles: service.freeIncludedMiles,
      surgePricing: { ...surge, surgeAmount },
      addOns,
      subtotalBeforeDiscounts,
      discounts,
      subtotalAfterDiscounts,
      serviceFee,
      serviceFeePercent: platformFees.serviceFeePercent,
      taxRate,
      taxAmount,
      total,
      estimatedRange: { min: total, max: Math.round(total * 1.25) },
      heroPayout,
      currency: "usd",
      calculatedAt: now.toISOString(),
      configVersion: "2.0.0",
      // Legacy fields so existing screens don't break
      mileagePrice: heroTravelFee + towingDistanceFee,
      subtotal: subtotalAfterDiscounts,
      priorityFee: addOns.priorityFee,
      winchFee: addOns.winchFee,
    };
  }

  private calculateSurge(
    now: Date,
    req: PriceCalculationRequest
  ): Omit<PriceBreakdown["surgePricing"], "surgeAmount"> {
    const { surge } = this.config;
    const hour = now.getHours();
    const timeMultiplier = surge.hourlyMultipliers[hour] ?? 1.0;

    const days: (keyof SurgeConfig["dayMultipliers"])[] = [
      "sunday", "monday", "tuesday", "wednesday",
      "thursday", "friday", "saturday",
    ];
    const dayMultiplier = surge.dayMultipliers[days[now.getDay()]] ?? 1.0;

    const dateStr = now.toISOString().split("T")[0];
    const isHoliday = surge.holidays.includes(dateStr);
    const holidayMultiplier = isHoliday ? surge.holidayMultiplier : 1.0;

    let demandMultiplier = 1.0;
    if (
      req.activeJobsInArea !== undefined &&
      req.availableHeroesInArea !== undefined
    ) {
      const ratio =
        req.availableHeroesInArea > 0
          ? req.activeJobsInArea / req.availableHeroesInArea
          : 1.0;
      const { demandThresholds: dt } = surge;
      if (ratio <= dt.low.ratio) demandMultiplier = dt.low.multiplier;
      else if (ratio <= dt.normal.ratio) demandMultiplier = dt.normal.multiplier;
      else if (ratio <= dt.high.ratio) demandMultiplier = dt.high.multiplier;
      else demandMultiplier = dt.surge.multiplier;
    }

    let combinedMultiplier = timeMultiplier * dayMultiplier * demandMultiplier;
    if (isHoliday)
      combinedMultiplier = Math.max(combinedMultiplier, holidayMultiplier);
    combinedMultiplier = Math.min(combinedMultiplier, surge.maxSurgeMultiplier);

    return {
      timeMultiplier,
      dayMultiplier,
      demandMultiplier,
      holidayMultiplier,
      combinedMultiplier,
    };
  }

  private calculateAddOns(
    service: ServicePricing,
    req: PriceCalculationRequest,
    now: Date
  ): PriceBreakdown["addOns"] {
    const { addOns: cfg } = this.config;
    const priorityFee = req.isPriority ? cfg.priorityFee : 0;
    const winchFee =
      req.needsWinch && service.id !== "winch_out" ? cfg.winchFee : 0;
    const fuelFee = (req.additionalGallons ?? 0) * cfg.fuelGallonPrice;
    const hour = now.getHours();
    const afterHoursFee = hour >= 22 || hour < 6 ? cfg.afterHoursFee : 0;
    // Weekend/holiday already captured in surge multiplier
    const weekendFee = 0;
    const holidayFee = 0;
    const total =
      priorityFee + winchFee + fuelFee + afterHoursFee + weekendFee + holidayFee;
    return { priorityFee, winchFee, fuelFee, afterHoursFee, weekendFee, holidayFee, total };
  }

  private calculateDiscounts(
    req: PriceCalculationRequest,
    subtotal: number
  ): PriceBreakdown["discounts"] {
    const { discounts: cfg } = this.config;
    let promoDiscount = 0;
    let membershipDiscount = 0;
    let referralDiscount = 0;

    if (req.promoCode) {
      const promo = cfg.promoCodeDiscounts[req.promoCode.toUpperCase()];
      if (promo) {
        const expired = promo.expiresAt && new Date(promo.expiresAt) < new Date();
        const meetsMin = !promo.minOrderValue || subtotal >= promo.minOrderValue;
        const hasUses = !promo.maxUses || (promo.currentUses ?? 0) < promo.maxUses;
        const applicable =
          !promo.applicableServices ||
          promo.applicableServices.includes(req.serviceType);
        if (!expired && meetsMin && hasUses && applicable) {
          promoDiscount =
            promo.type === "percent"
              ? Math.min(
                  Math.round(subtotal * (promo.value / 100)),
                  promo.maxDiscount ?? Infinity
                )
              : promo.value;
        }
      }
    }

    if (req.membershipTier) {
      const mem = cfg.membershipDiscounts[req.membershipTier];
      if (mem?.discountPercent > 0) {
        membershipDiscount = Math.round(
          subtotal * (mem.discountPercent / 100)
        );
      }
    }

    if (req.referralCode) {
      referralDiscount = Math.round(
        subtotal * (cfg.referralDiscount.refereeDiscount / 100)
      );
    }

    const bestBase = Math.max(promoDiscount, membershipDiscount);
    const totalDiscount = bestBase + referralDiscount;
    const usedPromo = bestBase === promoDiscount && promoDiscount > 0;

    return {
      promoDiscount: usedPromo ? promoDiscount : 0,
      promoCode: usedPromo ? req.promoCode : undefined,
      membershipDiscount: !usedPromo ? membershipDiscount : 0,
      membershipTier: !usedPromo && membershipDiscount > 0 ? req.membershipTier : undefined,
      referralDiscount,
      loyaltyPointsUsed: 0,
      loyaltyDiscount: 0,
      totalDiscount,
    };
  }

  private calculateHeroPayout(
    baseAmount: number,
    distanceAmount: number
  ): PriceBreakdown["heroPayout"] {
    const cfg = this.config.heroPayout;
    const basePayout = Math.round(
      baseAmount * (cfg.basePayoutPercent / 100)
    );
    const distancePayout = Math.round(
      distanceAmount * (cfg.distancePayoutPercent / 100)
    );
    const totalPayout = Math.max(
      basePayout + distancePayout,
      cfg.minimumPayout
    );
    return { basePayout, distancePayout, tierBonus: 0, performanceBonus: 0, totalPayout };
  }
}

// ── Cloud Function: Full price calculation ──

export const calculateJobPrice = functions.https.onCall(
  async (data: PriceCalculationRequest) => {
    try {
      const config = await loadConfig();
      const engine = new PricingEngine(config);
      return await engine.calculatePrice(data);
    } catch (error: any) {
      console.error("calculateJobPrice error:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  }
);

// ── Cloud Function: Quick quote (simplified, no discounts/surge) ──

export const getQuickQuote = functions.https.onCall(
  async (data: { serviceType: string; estimatedMiles?: number }) => {
    const config = await loadConfig();
    const service = config.services.find(
      (s) => s.id === data.serviceType && s.isActive
    );
    if (!service) {
      throw new functions.https.HttpsError("not-found", "Service not found");
    }
    const miles = data.estimatedMiles ?? 5;
    const distanceFee = Math.round(miles * service.pricePerMile);
    const subtotal = service.basePrice + distanceFee;
    const serviceFee = Math.round(
      subtotal * (config.platformFees.serviceFeePercent / 100)
    );
    return {
      serviceType: data.serviceType,
      serviceName: service.name,
      basePrice: service.basePrice,
      estimatedMiles: miles,
      distanceFee,
      serviceFee,
      total: subtotal + serviceFee,
      currency: "usd",
      disclaimer: "Final price may vary based on actual distance and conditions",
    };
  }
);
