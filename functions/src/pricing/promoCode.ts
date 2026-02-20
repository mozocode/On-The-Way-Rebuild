import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { DEFAULT_PRICING_CONFIG } from "../config/pricing";

const firestore = admin.firestore();

export const validatePromoCode = functions.https.onCall(
  async (data: { code: string }) => {
    const { code } = data;
    if (!code) return { valid: false, message: "No code provided" };

    try {
      const doc = await firestore.collection("pricingConfig").doc("default").get();
      const config = doc.exists ? doc.data() : DEFAULT_PRICING_CONFIG;
      const promo =
        config?.discounts?.promoCodeDiscounts?.[code.toUpperCase()];

      if (!promo) return { valid: false, message: "Invalid promo code" };
      if (promo.expiresAt && new Date(promo.expiresAt) < new Date())
        return { valid: false, message: "This promo code has expired" };
      if (promo.maxUses && (promo.currentUses ?? 0) >= promo.maxUses)
        return { valid: false, message: "This promo code has reached its usage limit" };

      return {
        valid: true,
        code: code.toUpperCase(),
        type: promo.type,
        value: promo.value,
        maxDiscount: promo.maxDiscount,
        minOrderValue: promo.minOrderValue,
        applicableServices: promo.applicableServices,
        message:
          promo.type === "percent"
            ? `${promo.value}% off your order!`
            : `\$${(promo.value / 100).toFixed(2)} off your order!`,
      };
    } catch (error: any) {
      console.error("validatePromoCode error:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  }
);

export const getServicePricing = functions.https.onCall(async () => {
  try {
    const doc = await firestore.collection("pricingConfig").doc("default").get();
    const config = doc.exists ? doc.data() : DEFAULT_PRICING_CONFIG;
    return config?.services?.filter((s: any) => s.isActive) ?? [];
  } catch (error: any) {
    console.error("getServicePricing error:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});

export const incrementPromoCodeUsage = functions.firestore
  .document("jobs/{jobId}")
  .onCreate(async (snapshot) => {
    const promoCode = snapshot.data()?.discounts?.promoCode;
    if (!promoCode) return;
    try {
      await firestore
        .collection("pricingConfig")
        .doc("default")
        .update({
          [`discounts.promoCodeDiscounts.${promoCode}.currentUses`]:
            admin.firestore.FieldValue.increment(1),
        });
    } catch (error) {
      console.error("incrementPromoCodeUsage error:", error);
    }
  });
