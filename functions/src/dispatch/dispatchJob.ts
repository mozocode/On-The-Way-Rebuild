import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { DISPATCH_WAVES } from "../config/dispatch";

const firestore = admin.firestore();

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export const dispatchJob = functions
  .runWith({ timeoutSeconds: 120 })
  .firestore.document("jobs/{jobId}")
  .onCreate(async (snapshot, context) => {
    const jobId = context.params.jobId;
    const job = snapshot.data();
    console.log(`Starting dispatch for job ${jobId}`);

    await snapshot.ref.update({
      status: "searching",
      "dispatch.startedAt": FieldValue.serverTimestamp(),
    });

    await firestore.collection("dispatchWaves").doc(jobId).set({
      jobId,
      currentWave: 0,
      totalWaves: DISPATCH_WAVES.length,
      startedAt: FieldValue.serverTimestamp(),
      notifiedHeroes: [] as string[],
      status: "in_progress",
    });

    const notifiedHeroes: string[] = [];

    for (let waveIndex = 0; waveIndex < DISPATCH_WAVES.length; waveIndex++) {
      const wave = DISPATCH_WAVES[waveIndex];

      const currentJob = await snapshot.ref.get();
      if (currentJob.data()?.status === "assigned") {
        console.log(`Job ${jobId} accepted, stopping dispatch`);
        break;
      }

      console.log(`Wave ${waveIndex + 1}: radius ${wave.radius} miles`);

      await firestore.collection("dispatchWaves").doc(jobId).update({
        currentWave: waveIndex + 1,
        [`waves.${waveIndex}`]: {
          radius: wave.radius,
          startedAt: FieldValue.serverTimestamp(),
        },
      });

      const heroes = await findNearbyHeroes(
        job.pickup?.location?.latitude ?? 0,
        job.pickup?.location?.longitude ?? 0,
        wave.radius,
        job.service?.type ?? ""
      );

      const newHeroes = heroes.filter((h) => !notifiedHeroes.includes(h.id));
      console.log(`Found ${newHeroes.length} new heroes in wave ${waveIndex + 1}`);

      for (const hero of newHeroes) {
        await notifyHero(jobId, job, hero);
        notifiedHeroes.push(hero.id);
      }

      await firestore.collection("dispatchWaves").doc(jobId).update({
        notifiedHeroes,
        [`waves.${waveIndex}.notifiedCount`]: newHeroes.length,
      });

      await sleep(wave.durationMs);
    }

    const finalJob = await snapshot.ref.get();
    if (finalJob.data()?.status === "searching") {
      await snapshot.ref.update({
        status: "no_heroes_available",
        "dispatch.completedAt": FieldValue.serverTimestamp(),
      });

      await firestore.collection("dispatchWaves").doc(jobId).update({
        status: "completed",
        result: "no_heroes",
        completedAt: FieldValue.serverTimestamp(),
      });

      await notifyCustomerNoHeroes(job.customer?.id, jobId);
    }
  });

async function findNearbyHeroes(
  latitude: number,
  longitude: number,
  radiusMiles: number,
  _serviceType: string
): Promise<Array<{ id: string; pushToken?: string }>> {
  const heroesSnap = await firestore
    .collection("heroes")
    .where("status.isOnline", "==", true)
    .where("status.isVerified", "==", true)
    .get();

  const radiusMeters = radiusMiles * 1609.34;
  const results: Array<{ id: string; pushToken?: string }> = [];

  for (const doc of heroesSnap.docs) {
    const data = doc.data();
    if (data.status?.currentJobId) continue;

    const loc = data.location?.lastKnownLocation;
    if (!loc) continue;

    const dist = haversine(latitude, longitude, loc.latitude, loc.longitude);
    if (dist <= radiusMeters) {
      results.push({ id: doc.id, pushToken: data.settings?.pushToken });
    }
  }

  return results;
}

function haversine(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371000;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

async function notifyHero(
  jobId: string,
  job: FirebaseFirestore.DocumentData,
  hero: { id: string; pushToken?: string }
): Promise<void> {
  if (!hero.pushToken) {
    console.log(`Hero ${hero.id} has no push token – skipping notification`);
    return;
  }

  const serviceLabel = (job.service?.type ?? "")
    .replace(/_/g, " ")
    .toUpperCase();

  try {
    await admin.messaging().send({
      token: hero.pushToken,
      notification: {
        title: `New ${serviceLabel} Job`,
        body: "Tap to view details and accept",
      },
      data: { type: "new_job", jobId, serviceType: job.service?.type ?? "" },
      android: {
        priority: "high",
        notification: { channelId: "otw_jobs", sound: "default" },
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    });
    console.log(`Notification sent to hero ${hero.id} for job ${jobId}`);
  } catch (e) {
    console.error(`Failed to notify hero ${hero.id}:`, e);
  }
}

async function notifyCustomerNoHeroes(
  customerId: string | undefined,
  jobId: string
): Promise<void> {
  if (!customerId) return;
  const userDoc = await firestore.collection("users").doc(customerId).get();
  const token = userDoc.data()?.settings?.pushToken;
  if (!token) return;

  try {
    await admin.messaging().send({
      token,
      notification: {
        title: "No Heroes Available",
        body: "We couldn't find a hero right now. Please try again.",
      },
      data: { type: "no_heroes", jobId },
    });
  } catch (e) {
    console.error(`Failed to notify customer ${customerId}:`, e);
  }
}
