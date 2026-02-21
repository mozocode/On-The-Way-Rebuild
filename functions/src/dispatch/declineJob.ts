import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

const firestore = admin.firestore();

export const declineJob = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
  }

  const { jobId, reason } = data;
  const heroId = context.auth.uid;

  if (!jobId) {
    throw new functions.https.HttpsError("invalid-argument", "jobId is required");
  }

  try {
    await firestore.collection("jobs").doc(jobId).update({
      "dispatch.declinedHeroes": FieldValue.arrayUnion(heroId),
    });

    await firestore.collection("dispatchWaves").doc(jobId).update({
      declinedHeroes: FieldValue.arrayUnion(heroId),
    });

    const heroRef = firestore.collection("heroes").doc(heroId);
    const heroDoc = await heroRef.get();
    if (heroDoc.exists) {
      const stats = heroDoc.data()?.stats || {};
      const totalJobs = (stats.totalOffered || 0) + 1;
      const totalAccepted = stats.totalAccepted || 0;
      await heroRef.update({
        "stats.totalOffered": totalJobs,
        "stats.acceptanceRate": totalAccepted / totalJobs,
        "stats.lastDeclinedAt": FieldValue.serverTimestamp(),
      });
    }

    return { success: true };
  } catch (error: any) {
    console.error("Error declining job:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
