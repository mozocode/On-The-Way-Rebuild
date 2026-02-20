import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { DEFAULT_PRICING_CONFIG } from "../config/pricing";

const firestore = admin.firestore();

/**
 * One-time callable function to seed the default pricing config.
 * Call once after deployment: firebase functions:call seedPricingConfig
 */
export const seedPricingConfig = functions.https.onCall(
  async (_data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated"
      );
    }

    const docRef = firestore.collection("pricingConfig").doc("default");
    const existing = await docRef.get();

    if (existing.exists) {
      return { success: false, message: "Config already exists. Delete it first to re-seed." };
    }

    await docRef.set({
      ...DEFAULT_PRICING_CONFIG,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: context.auth.uid,
    });

    return { success: true, message: "Default pricing config seeded successfully." };
  }
);
