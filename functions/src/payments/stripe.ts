import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

const firestore = admin.firestore();

let _stripe: any;
function getStripe() {
  if (!_stripe) {
    _stripe = require("stripe")(process.env.STRIPE_SECRET_KEY || functions.config().stripe?.secret_key || "sk_test_placeholder");
  }
  return _stripe;
}

export const createPaymentIntent = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }

    const { jobId, currency = "usd" } = data;
    if (!jobId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "jobId is required"
      );
    }

    try {
      const jobDoc = await firestore.collection("jobs").doc(jobId).get();
      if (!jobDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Job not found");
      }
      const job = jobDoc.data()!;

      if (job.customer?.id !== context.auth!.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "You can only create payments for your own jobs"
        );
      }

      const amount = job.pricing?.total;
      if (!amount || typeof amount !== "number" || amount <= 0) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Job does not have a valid computed price"
        );
      }

      const paymentIntent = await getStripe().paymentIntents.create({
        amount: Math.round(amount * 100),
        currency,
        customer: job.customer?.stripeCustomerId || undefined,
        metadata: { jobId, userId: context.auth!.uid },
        capture_method: "automatic",
      });

      await firestore.collection("jobs").doc(jobId).update({
        "payment.paymentIntentId": paymentIntent.id,
        "payment.status": "requires_payment_method",
        "payment.amount": amount,
        "payment.currency": currency,
      });

      return {
        paymentIntentId: paymentIntent.id,
        clientSecret: paymentIntent.client_secret,
        amount,
        currency,
      };
    } catch (error: any) {
      console.error("createPaymentIntent error:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  }
);

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
      const captured = await getStripe().paymentIntents.capture(paymentIntentId, {
        amount_to_capture: amountToCapture ? Math.round(amountToCapture * 100) : undefined,
      });

      const jobsSnap = await firestore
        .collection("jobs")
        .where("payment.paymentIntentId", "==", paymentIntentId)
        .limit(1)
        .get();

      if (jobsSnap.empty) {
        throw new functions.https.HttpsError("not-found", "No job found for this payment");
      }

      const jobData = jobsSnap.docs[0].data();
      const callerId = context.auth!.uid;
      const isOwner = jobData.customer?.id === callerId;
      const isAssignedHero = jobData.hero?.id === callerId;
      if (!isOwner && !isAssignedHero) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Not authorized to capture this payment"
        );
      }

      await jobsSnap.docs[0].ref.update({
        "payment.status": "succeeded",
        "payment.capturedAt": FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error: any) {
      console.error("capturePayment error:", error);
      throw new functions.https.HttpsError("internal", error.message);
    }
  }
);
