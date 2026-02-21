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
