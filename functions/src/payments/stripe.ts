import * as functions from "firebase-functions";
import Stripe from "stripe";

function getStripe(): Stripe {
  const secretKey = process.env.STRIPE_SECRET_KEY;
  if (!secretKey) {
    throw new Error(
      "STRIPE_SECRET_KEY not set. Add STRIPE_SECRET_KEY to functions/.env (see .env.example)"
    );
  }
  return new Stripe(secretKey);
}

/**
 * Creates a PaymentIntent for the given amount (in cents).
 * Call this before creating the job; after the client confirms payment, create the job with paymentIntentId.
 * Returns clientSecret for Stripe Payment Sheet and paymentIntentId to store on the job.
 */
export const createPaymentIntent = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }

    const { amount, currency = "usd", customerId } = data;
    if (amount == null || amount < 50) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "amount is required and must be at least 50 (cents)"
      );
    }

    try {
      const stripe = getStripe();
      const params: Stripe.PaymentIntentCreateParams = {
        amount: Math.round(Number(amount)),
        currency: (currency as string).toLowerCase(),
        automatic_payment_methods: { enabled: true },
        metadata: {
          userId: context.auth.uid,
        },
      };
      if (customerId) {
        params.customer = customerId as string;
      }

      const paymentIntent = await stripe.paymentIntents.create(params);

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
        amount: paymentIntent.amount,
        currency: paymentIntent.currency,
      };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      console.error("createPaymentIntent error:", error);
      throw new functions.https.HttpsError("internal", message);
    }
  }
);

/**
 * Optional: capture is automatic when using confirm in Payment Sheet.
 * Kept for backwards compatibility or manual capture flows.
 */
export const capturePayment = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }

    const { paymentIntentId, amountToCapture } = data;
    if (!paymentIntentId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "paymentIntentId is required"
      );
    }

    try {
      const stripe = getStripe();
      await stripe.paymentIntents.capture(
        paymentIntentId as string,
        amountToCapture != null ? { amount_to_capture: amountToCapture } : undefined
      );
      return { success: true };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      console.error("capturePayment error:", error);
      throw new functions.https.HttpsError("internal", message);
    }
  }
);
