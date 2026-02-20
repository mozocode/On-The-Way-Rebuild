import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { HERO_LOCATION_TTL_MS } from "../config/dispatch";

const firestore = admin.firestore();

function getRealtimeDb() {
  return admin.database();
}

export const cleanupExpiredLocations = functions.pubsub
  .schedule("every 5 minutes")
  .onRun(async () => {
    const now = Date.now();
    const realtimeDb = getRealtimeDb();
    const heroLocationsRef = realtimeDb.ref("heroLocations");
    const snapshot = await heroLocationsRef.once("value");

    if (!snapshot.exists()) return null;

    const updates: Record<string, null> = {};
    snapshot.forEach((child) => {
      const data = child.val();
      if (data.expiresAt && data.expiresAt < now) {
        updates[`heroLocations/${child.key}`] = null;
        console.log(`Cleaned up expired location for hero ${child.key}`);
      }
    });

    if (Object.keys(updates).length > 0) {
      await realtimeDb.ref().update(updates);
      console.log(`Cleaned up ${Object.keys(updates).length} expired locations`);
    }

    return null;
  });

export const cleanupOldJobs = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const oldJobs = await firestore
      .collection("jobs")
      .where("status", "in", ["completed", "cancelled", "no_heroes_available"])
      .where("timestamps.createdAt", "<", thirtyDaysAgo)
      .limit(100)
      .get();

    const batch = firestore.batch();
    let count = 0;

    for (const doc of oldJobs.docs) {
      const jobId = doc.id;

      // Clean up realtime DB tracking data
      await getRealtimeDb().ref(`jobTracking/${jobId}`).remove();

      // Clean up dispatch wave docs
      const dispatchRef = firestore.collection("dispatchWaves").doc(jobId);
      batch.delete(dispatchRef);

      count++;
    }

    if (count > 0) {
      await batch.commit();
      console.log(`Cleaned up ${count} old job artifacts`);
    }

    return null;
  });
