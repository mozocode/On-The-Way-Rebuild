import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

let _stripe: any;
function getStripe() {
  if (!_stripe) {
    _stripe = require("stripe")(functions.config().stripe?.secret_key || "sk_test_placeholder");
  }
  return _stripe;
}
const firestore = admin.firestore();

export const getOrCreateCustomer = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }

    const { userId, email, name, phone } = data;
    if (!userId || !email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userId and email are required"
      );
    }

    try {
      const userDoc = await firestore.collection("users").doc(userId).get();
      const existingCustomerId = userDoc.data()?.stripeCustomerId;

      if (existingCustomerId) {
        return { customerId: existingCustomerId };
      }

      const customer = await getStripe().customers.create({
        email,
        name: name || undefined,
        phone: phone || undefined,
        metadata: { firebaseUid: userId },
      });
      const customerId = customer.id;

      await firestore.collection("users").doc(userId).update({
        stripeCustomerId: customerId,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { customerId };
    } catch (error: any) {
      console.error("getOrCreateCustomer error:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  }
);

export const listPaymentMethods = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }

    const userId = context.auth.uid;

    try {
      const userDoc = await firestore.collection("users").doc(userId).get();
      const customerId = userDoc.data()?.stripeCustomerId;

      if (!customerId) {
        return { paymentMethods: [] };
      }

      const methods = await getStripe().paymentMethods.list({
        customer: customerId,
        type: "card",
      });

      const cards = methods.data.map((pm: any) => ({
        id: pm.id,
        brand: pm.card?.brand ?? "unknown",
        last4: pm.card?.last4 ?? "0000",
        expMonth: pm.card?.exp_month ?? 0,
        expYear: pm.card?.exp_year ?? 0,
      }));

      return { paymentMethods: cards };
    } catch (error: any) {
      console.error("listPaymentMethods error:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  }
);

export const addPaymentMethod = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }

    const { customerId, paymentMethodId, setAsDefault = false } = data;
    if (!customerId || !paymentMethodId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "customerId and paymentMethodId are required"
      );
    }

    try {
      await getStripe().paymentMethods.attach(paymentMethodId, { customer: customerId });
      if (setAsDefault) {
        await getStripe().customers.update(customerId, {
          invoice_settings: { default_payment_method: paymentMethodId },
        });
      }

      return { success: true, paymentMethodId };
    } catch (error: any) {
      console.error("addPaymentMethod error:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  }
);
