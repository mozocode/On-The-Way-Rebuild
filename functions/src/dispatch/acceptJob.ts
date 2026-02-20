import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

const firestore = admin.firestore();

export const acceptJob = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
  }

  const { jobId } = data;
  const heroId = context.auth.uid;

  if (!jobId) {
    throw new functions.https.HttpsError("invalid-argument", "jobId is required");
  }

  try {
    await firestore.runTransaction(async (transaction) => {
      const jobRef = firestore.collection("jobs").doc(jobId);
      const heroRef = firestore.collection("heroes").doc(heroId);

      const [jobDoc, heroDoc] = await Promise.all([
        transaction.get(jobRef),
        transaction.get(heroRef),
      ]);

      if (!jobDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Job not found");
      }
      if (!heroDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Hero profile not found");
      }

      const job = jobDoc.data()!;
      const hero = heroDoc.data()!;

      if (job.status !== "searching") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Job is no longer available"
        );
      }

      if (hero.status?.currentJobId) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "You already have an active job"
        );
      }

      const now = FieldValue.serverTimestamp();

      transaction.update(jobRef, {
        status: "assigned",
        hero: {
          id: heroId,
          name: hero.displayName ?? "",
          phone: hero.phone ?? null,
          photoUrl: hero.photoUrl ?? null,
          vehicleMake: hero.vehicle?.make ?? null,
          vehicleModel: hero.vehicle?.model ?? null,
          vehicleColor: hero.vehicle?.color ?? null,
          licensePlate: hero.vehicle?.licensePlate ?? null,
        },
        "dispatch.acceptedBy": heroId,
        "dispatch.acceptedAt": now,
        "timestamps.assignedAt": now,
        statusHistory: FieldValue.arrayUnion([
          { status: "assigned", at: now, heroId },
        ]),
      });

      transaction.update(heroRef, {
        "status.currentJobId": jobId,
        updatedAt: now,
      });

      const dispatchRef = firestore.collection("dispatchWaves").doc(jobId);
      transaction.update(dispatchRef, {
        status: "completed",
        result: "accepted",
        acceptedBy: heroId,
        completedAt: now,
      });
    });

    // Notify customer
    const job = await firestore.collection("jobs").doc(jobId).get();
    const customerId = job.data()?.customer?.id;
    if (customerId) {
      const userDoc = await firestore.collection("users").doc(customerId).get();
      const pushToken = userDoc.data()?.settings?.pushToken;
      if (pushToken) {
        await admin.messaging().send({
          token: pushToken,
          notification: {
            title: "Hero Assigned!",
            body: "Your hero is on the way. Track their progress in the app.",
          },
          data: { type: "job_accepted", jobId },
        });
      }
    }

    return { success: true };
  } catch (error: any) {
    console.error("Error accepting job:", error);
    if (error instanceof functions.https.HttpsError) throw error;
    throw new functions.https.HttpsError("internal", error.message);
  }
});
