import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";

const firestore = admin.firestore();

function getRealtimeDb() {
  return admin.database();
}

export const onJobStatusChanged = functions.firestore
  .document("jobs/{jobId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const jobId = context.params.jobId;

    if (before.status === after.status) return;

    const newStatus = after.status;
    console.log(`Job ${jobId} status: ${before.status} -> ${newStatus}`);

    switch (newStatus) {
      case "en_route":
        await change.after.ref.update({
          "timestamps.heroEnRouteAt": FieldValue.serverTimestamp(),
          statusHistory: FieldValue.arrayUnion([
            {
              status: "en_route",
              at: FieldValue.serverTimestamp(),
            },
          ]),
        });
        break;

      case "arrived":
        await change.after.ref.update({
          "timestamps.heroArrivedAt": FieldValue.serverTimestamp(),
          statusHistory: FieldValue.arrayUnion([
            {
              status: "arrived",
              at: FieldValue.serverTimestamp(),
            },
          ]),
        });
        break;

      case "in_progress":
        await change.after.ref.update({
          "timestamps.serviceStartedAt":
            FieldValue.serverTimestamp(),
          statusHistory: FieldValue.arrayUnion([
            {
              status: "in_progress",
              at: FieldValue.serverTimestamp(),
            },
          ]),
        });
        break;

      case "completed": {
        await change.after.ref.update({
          "timestamps.completedAt": FieldValue.serverTimestamp(),
          statusHistory: FieldValue.arrayUnion([
            {
              status: "completed",
              at: FieldValue.serverTimestamp(),
            },
          ]),
        });

        // Free the hero
        const heroId = after.hero?.id;
        if (heroId) {
          await firestore.collection("heroes").doc(heroId).update({
            "status.currentJobId": FieldValue.delete(),
            "stats.totalJobs": FieldValue.increment(1),
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        // Clean up realtime tracking
        await getRealtimeDb().ref(`jobTracking/${jobId}`).remove();
        break;
      }

      case "cancelled": {
        await change.after.ref.update({
          "timestamps.cancelledAt": FieldValue.serverTimestamp(),
          statusHistory: FieldValue.arrayUnion([
            {
              status: "cancelled",
              at: FieldValue.serverTimestamp(),
            },
          ]),
        });

        // Free the hero if assigned
        const cancelledHeroId = after.hero?.id;
        if (cancelledHeroId) {
          await firestore.collection("heroes").doc(cancelledHeroId).update({
            "status.currentJobId": FieldValue.delete(),
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        // Clean up
        await getRealtimeDb().ref(`jobTracking/${jobId}`).remove();
        break;
      }
    }
  });
