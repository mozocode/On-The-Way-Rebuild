import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import Stripe from "stripe";

const firestore = admin.firestore();

function getStripe(): Stripe {
  const secretKey = process.env.STRIPE_SECRET_KEY;
  if (!secretKey) {
    throw new Error(
      "STRIPE_SECRET_KEY not set. Add STRIPE_SECRET_KEY to functions/.env (see .env.example)"
    );
  }
  return new Stripe(secretKey);
}

export const getOrCreateCustomer = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }

    const userId = context.auth.uid;
    const { email, name, phone } = data;
    if (!email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "email is required"
      );
    }

    try {
      const userDoc = await firestore.collection("users").doc(userId).get();
      const existingCustomerId = userDoc.data()?.stripeCustomerId as string | undefined;

      if (existingCustomerId) {
        return { customerId: existingCustomerId };
      }

      const stripe = getStripe();
      const customer = await stripe.customers.create({
        email: email as string,
        name: (name as string) || undefined,
        phone: (phone as string) || undefined,
        metadata: { firebaseUserId: userId },
      });

      await firestore.collection("users").doc(userId).update({
        stripeCustomerId: customer.id,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { customerId: customer.id };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      console.error("getOrCreateCustomer error:", error);
      throw new functions.https.HttpsError("internal", message);
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
      const stripe = getStripe();
      await stripe.paymentMethods.attach(paymentMethodId as string, {
        customer: customerId as string,
      });
      if (setAsDefault) {
        await stripe.customers.update(customerId as string, {
          invoice_settings: { default_payment_method: paymentMethodId as string },
        });
      }
      return { success: true, paymentMethodId };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      console.error("addPaymentMethod error:", error);
      throw new functions.https.HttpsError("internal", message);
    }
  }
);
