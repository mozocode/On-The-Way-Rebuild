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

/**
 * Create a Stripe Connect Express account for a hero and return an account link for onboarding.
 * Store the Connect account id on the hero document (earnings.stripeConnectAccountId).
 */
export const createConnectAccountLink = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }

    const userId = context.auth.uid;
    const { heroId, email, refreshUrl, returnUrl } = data;
    if (!heroId || !email || !refreshUrl || !returnUrl) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "heroId, email, refreshUrl, and returnUrl are required"
      );
    }

    const heroDoc = await firestore.collection("heroes").doc(heroId).get();
    if (!heroDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Hero not found");
    }
    const heroData = heroDoc.data();
    if (heroData?.userId !== userId) {
      throw new functions.https.HttpsError("permission-denied", "Not this hero");
    }

    try {
      const stripe = getStripe();
      let accountId = heroData?.earnings?.stripeConnectAccountId as string | undefined;

      if (!accountId) {
        const account = await stripe.accounts.create({
          type: "express",
          country: "US",
          email: email as string,
          capabilities: { transfers: { requested: true } },
          metadata: { heroId, firebaseUserId: userId },
        });
        accountId = account.id;
        await firestore.collection("heroes").doc(heroId).update({
          "earnings.stripeConnectAccountId": accountId,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      const accountLink = await stripe.accountLinks.create({
        account: accountId,
        refresh_url: refreshUrl as string,
        return_url: returnUrl as string,
        type: "account_onboarding",
      });

      return { url: accountLink.url, accountId };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      console.error("createConnectAccountLink error:", error);
      throw new functions.https.HttpsError("internal", message);
    }
  }
);

/**
 * Transfer pending payout from platform to hero's Stripe Connect account (withdraw).
 * Amount in cents. Decrements hero's pendingPayout and increments totalPaidOut (or similar).
 */
export const createTransferToHero = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }

    const userId = context.auth.uid;
    const { heroId, amount } = data;
    if (!heroId || amount == null || amount < 100) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "heroId and amount (min 100 cents) are required"
      );
    }

    const heroRef = firestore.collection("heroes").doc(heroId);
    const heroDoc = await heroRef.get();
    if (!heroDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Hero not found");
    }
    const heroData = heroDoc.data()!;
    if (heroData.userId !== userId) {
      throw new functions.https.HttpsError("permission-denied", "Not this hero");
    }

    const connectAccountId = heroData?.earnings?.stripeConnectAccountId as string | undefined;
    if (!connectAccountId) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Complete Stripe Connect onboarding before withdrawing"
      );
    }

    const pendingPayout = (heroData?.earnings?.pendingPayout as number) ?? 0;
    const amountNum = Math.round(Number(amount));
    if (amountNum > pendingPayout) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Amount exceeds available balance"
      );
    }

    try {
      const stripe = getStripe();
      await stripe.transfers.create({
        amount: amountNum,
        currency: "usd",
        destination: connectAccountId,
        description: "Hero payout from On The Way",
        metadata: { heroId, firebaseUserId: userId },
      });

      await heroRef.update({
        "earnings.pendingPayout": FieldValue.increment(-amountNum),
        "earnings.totalPaidOut": FieldValue.increment(amountNum),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { success: true, amount: amountNum };
    } catch (error: unknown) {
      const message = error instanceof Error ? error.message : String(error);
      console.error("createTransferToHero error:", error);
      throw new functions.https.HttpsError("internal", message);
    }
  }
);
