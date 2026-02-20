const admin = require("../functions/node_modules/firebase-admin");

admin.initializeApp({ projectId: "on-the-way-rebuild" });
const db = admin.firestore();

const DEFAULT_CONFIG = {
  services: [
    {
      id: "flat_tire", name: "Flat Tire", description: "Tire change or repair",
      basePrice: 5000, pricePerMile: 200, minimumMiles: 0, freeIncludedMiles: 0,
      estimatedDurationMinutes: 30,
      subTypes: {
        spare_mount: { name: "Mount Spare Tire", priceModifier: 1.0, additionalFee: 0 },
        tire_repair: { name: "Tire Repair (Plug/Patch)", priceModifier: 1.0, additionalFee: 1500 },
        tire_inflation: { name: "Tire Inflation Only", priceModifier: 0.6, additionalFee: 0 },
      },
      requiresDestination: false, requiresWinch: false, isActive: true,
    },
    {
      id: "dead_battery", name: "Dead Battery", description: "Jump start or battery replacement",
      basePrice: 4500, pricePerMile: 200, minimumMiles: 0, freeIncludedMiles: 0,
      estimatedDurationMinutes: 20,
      subTypes: {
        jump_start: { name: "Jump Start", priceModifier: 1.0, additionalFee: 0 },
        battery_test: { name: "Battery Test & Jump", priceModifier: 1.0, additionalFee: 500 },
        battery_replacement: { name: "Battery Replacement", priceModifier: 1.0, additionalFee: 0 },
      },
      requiresDestination: false, requiresWinch: false, isActive: true,
    },
    {
      id: "lockout", name: "Lockout", description: "Locked out of vehicle",
      basePrice: 6500, pricePerMile: 200, minimumMiles: 0, freeIncludedMiles: 0,
      estimatedDurationMinutes: 25,
      subTypes: {
        door_unlock: { name: "Door Unlock", priceModifier: 1.0, additionalFee: 0 },
        trunk_unlock: { name: "Trunk Unlock", priceModifier: 1.0, additionalFee: 1000 },
        smart_key: { name: "Smart Key Vehicle", priceModifier: 1.3, additionalFee: 0 },
      },
      requiresDestination: false, requiresWinch: false, isActive: true,
    },
    {
      id: "fuel_delivery", name: "Fuel Delivery", description: "Out of gas",
      basePrice: 5500, pricePerMile: 200, minimumMiles: 0, freeIncludedMiles: 0,
      estimatedDurationMinutes: 30,
      subTypes: {
        gasoline: { name: "Gasoline (2 gallons)", priceModifier: 1.0, additionalFee: 800 },
        diesel: { name: "Diesel (2 gallons)", priceModifier: 1.0, additionalFee: 1000 },
        premium: { name: "Premium Gasoline (2 gallons)", priceModifier: 1.0, additionalFee: 1200 },
      },
      requiresDestination: false, requiresWinch: false, isActive: true,
    },
    {
      id: "towing", name: "Towing", description: "Vehicle towing service",
      basePrice: 9500, pricePerMile: 400, minimumMiles: 0, freeIncludedMiles: 5,
      estimatedDurationMinutes: 60,
      subTypes: {
        flatbed: { name: "Flatbed Tow", priceModifier: 1.0, additionalFee: 0 },
        wheel_lift: { name: "Wheel Lift Tow", priceModifier: 0.85, additionalFee: 0 },
        motorcycle: { name: "Motorcycle Tow", priceModifier: 0.7, additionalFee: 0 },
        heavy_duty: { name: "Heavy Duty / Truck", priceModifier: 2.0, additionalFee: 5000 },
      },
      requiresDestination: true, requiresWinch: false, isActive: true,
    },
    {
      id: "winch_out", name: "Winch Out", description: "Vehicle stuck in ditch/mud/snow",
      basePrice: 8500, pricePerMile: 300, minimumMiles: 0, freeIncludedMiles: 0,
      estimatedDurationMinutes: 45,
      subTypes: {
        light: { name: "Light Winch (mud/grass)", priceModifier: 1.0, additionalFee: 0 },
        medium: { name: "Medium Winch (ditch)", priceModifier: 1.2, additionalFee: 0 },
        heavy: { name: "Heavy Winch (embankment)", priceModifier: 1.5, additionalFee: 2500 },
        snow_ice: { name: "Snow/Ice Recovery", priceModifier: 1.3, additionalFee: 0 },
      },
      requiresDestination: false, requiresWinch: true, isActive: true,
    },
  ],
  surge: {
    hourlyMultipliers: {
      0: 1.3, 1: 1.3, 2: 1.3, 3: 1.3, 4: 1.3, 5: 1.2,
      6: 1.0, 7: 1.1, 8: 1.2, 9: 1.1, 10: 1.0, 11: 1.0,
      12: 1.0, 13: 1.0, 14: 1.0, 15: 1.0, 16: 1.1, 17: 1.2,
      18: 1.2, 19: 1.1, 20: 1.1, 21: 1.2, 22: 1.3, 23: 1.3,
    },
    dayMultipliers: {
      sunday: 1.1, monday: 1.0, tuesday: 1.0, wednesday: 1.0,
      thursday: 1.0, friday: 1.1, saturday: 1.15,
    },
    holidayMultiplier: 1.5,
    holidays: ["2025-01-01","2025-07-04","2025-11-27","2025-12-25",
               "2026-01-01","2026-07-04","2026-11-26","2026-12-25"],
    demandThresholds: {
      low: { ratio: 0.3, multiplier: 0.95 },
      normal: { ratio: 0.7, multiplier: 1.0 },
      high: { ratio: 0.9, multiplier: 1.25 },
      surge: { ratio: 1.0, multiplier: 1.5 },
    },
    maxSurgeMultiplier: 2.0,
  },
  platformFees: {
    serviceFeePercent: 15,
    minServiceFee: 500,
    maxServiceFee: 5000,
    paymentProcessingPercent: 2.9,
    paymentProcessingFixed: 30,
  },
  addOns: {
    priorityFee: 2000,
    winchFee: 5000,
    fuelGallonPrice: 400,
    afterHoursFee: 1500,
    weekendFee: 1000,
    holidayFee: 2500,
  },
  discounts: {
    promoCodeDiscounts: {
      FIRST10: { type: "percent", value: 10, maxDiscount: 2000, minOrderValue: 5000, expiresAt: "2026-12-31", maxUses: 10000, currentUses: 0 },
      SAVE20: { type: "fixed", value: 2000, minOrderValue: 7500, expiresAt: "2026-06-30" },
      HERO50: { type: "percent", value: 50, maxDiscount: 5000, applicableServices: ["dead_battery", "flat_tire"] },
    },
    membershipDiscounts: {
      basic: { discountPercent: 0, freeServices: 0, priorityFree: false },
      plus: { discountPercent: 10, freeServices: 1, priorityFree: false },
      premium: { discountPercent: 15, freeServices: 3, priorityFree: true },
    },
    referralDiscount: { referrerCredit: 1500, refereeDiscount: 15 },
    loyaltyProgram: { pointsPerDollar: 10, pointsRedemptionRate: 1 },
  },
  heroPayout: {
    basePayoutPercent: 80,
    distancePayoutPercent: 85,
    tierBonuses: { standard: 0, silver: 2, gold: 5, platinum: 10 },
    performanceBonuses: {
      highRating: { threshold: 4.9, bonus: 200 },
      fastAcceptance: { threshold: 30, bonus: 100 },
      consecutiveJobs: { threshold: 5, bonus: 500 },
    },
    minimumPayout: 2000,
  },
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
};

async function seed() {
  const ref = db.collection("pricingConfig").doc("default");
  const doc = await ref.get();
  if (doc.exists) {
    console.log("pricingConfig/default already exists. Overwriting...");
  }
  await ref.set(DEFAULT_CONFIG);
  console.log("Successfully seeded pricingConfig/default");
  process.exit(0);
}

seed().catch((e) => {
  console.error("Seed failed:", e);
  process.exit(1);
});
