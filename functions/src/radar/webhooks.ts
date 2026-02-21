import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { HERO_LOCATION_TTL_MS } from "../config/dispatch";

const firestore = admin.firestore();

function getRealtimeDb() {
  return admin.database();
}

function verifyRadarWebhook(req: functions.https.Request): boolean {
  const secret = functions.config().radar?.webhook_secret;
  if (!secret) {
    console.warn("radar.webhook_secret not configured — rejecting webhook");
    return false;
  }
  const authHeader = req.headers["authorization"];
  return authHeader === secret;
}

export const radarLocationUpdate = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (!verifyRadarWebhook(req)) {
    res.status(401).send("Unauthorized");
    return;
  }

  try {
    const event = req.body.event || req.body;
    if (!event || event.type !== "user.updated_location") {
      res.status(200).send("OK");
      return;
    }

    const { user } = event;
    if (!user?.userId || !user?.location?.coordinates) {
      res.status(200).send("OK");
      return;
    }

    const heroId = user.userId;
    const [lng, lat] = user.location.coordinates;
    const now = Date.now();

    await getRealtimeDb().ref(`heroLocations/${heroId}`).set({
      heroId,
      latitude: lat,
      longitude: lng,
      accuracy: user.location.accuracy ?? null,
      heading: user.location.heading ?? null,
      speed: user.location.speed ?? null,
      altitude: user.location.altitude ?? null,
      source: "radar_webhook",
      updatedAt: admin.database.ServerValue.TIMESTAMP,
      expiresAt: now + HERO_LOCATION_TTL_MS,
    });

    const heroDoc = await firestore.collection("heroes").doc(heroId).get();
    const hero = heroDoc.data();
    const currentJobId = hero?.status?.currentJobId;

    if (currentJobId) {
      await getRealtimeDb().ref(`jobTracking/${currentJobId}`).update({
        heroLocation: {
          latitude: lat,
          longitude: lng,
          heading: user.location.heading ?? null,
          speed: user.location.speed ?? null,
          updatedAt: admin.database.ServerValue.TIMESTAMP,
        },
      });

      await firestore
        .collection("jobs")
        .doc(currentJobId)
        .update({
          "tracking.heroLocation": {
            latitude: lat,
            longitude: lng,
            accuracy: user.location.accuracy ?? null,
            heading: user.location.heading ?? null,
            speed: user.location.speed ?? null,
            updatedAt: FieldValue.serverTimestamp(),
          },
        });
    }

    res.status(200).send("OK");
  } catch (error) {
    console.error("radarLocationUpdate error:", error);
    res.status(500).send("Internal Server Error");
  }
});

export const radarGeofenceUpdate = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (!verifyRadarWebhook(req)) {
    res.status(401).send("Unauthorized");
    return;
  }

  try {
    const event = req.body.event || req.body;
    const type = event?.type;

    if (type === "user.entered_geofence") {
      const geofence = event.geofence;
      const userId = event.user?.userId;
      const tag = geofence?.tag;
      const jobId = geofence?.metadata?.jobId;

      console.log(`User ${userId} entered geofence: ${tag}, job: ${jobId}`);

      if (tag === "job_pickup" && jobId) {
        await firestore.collection("jobs").doc(jobId).update({
          status: "arrived",
          "timestamps.heroArrivedAt": FieldValue.serverTimestamp(),
          statusHistory: FieldValue.arrayUnion([
            {
              status: "arrived",
              at: FieldValue.serverTimestamp(),
            },
          ]),
        });
      }
    } else if (type === "user.exited_geofence") {
      console.log("User exited geofence:", event.geofence?.tag);
    }

    res.status(200).send("OK");
  } catch (error) {
    console.error("radarGeofenceUpdate error:", error);
    res.status(500).send("Internal Server Error");
  }
});
