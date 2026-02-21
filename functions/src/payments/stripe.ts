import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

const firestore = admin.firestore();

// Placeholder for Stripe integration.
// Replace `STRIPE_SECRET_KEY` with your actual key in Firebase config:
//   firebase functions:config:set stripe.secret_key="sk_..."
// Then: const stripe = require('stripe')(functions.config().stripe.secret_key);

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

      // TODO: Create actual Stripe PaymentIntent
      // const paymentIntent = await stripe.paymentIntents.create({
      //   amount,
      //   currency,
      //   metadata: { jobId, userId: context.auth.uid },
      // });

      const paymentIntentId = `pi_placeholder_${Date.now()}`;

      await firestore.collection("jobs").doc(jobId).update({
        "payment.paymentIntentId": paymentIntentId,
        "payment.status": "requires_payment_method",
        "payment.amount": amount,
        "payment.currency": currency,
      });

      return {
        paymentIntentId,
        // clientSecret: paymentIntent.client_secret,
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
      // TODO: Capture actual Stripe PaymentIntent
      // await stripe.paymentIntents.capture(paymentIntentId, {
      //   amount_to_capture: amountToCapture,
      // });

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
