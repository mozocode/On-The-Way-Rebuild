import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { FieldValue } from "firebase-admin/firestore";
import { DISPATCH_WAVES } from "../config/dispatch";

const firestore = admin.firestore();

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export const dispatchJob = functions
  .runWith({ timeoutSeconds: 540 })
  .firestore.document("jobs/{jobId}")
  .onCreate(async (snapshot, context) => {
    const jobId = context.params.jobId;
    const job = snapshot.data();
    console.log(`Starting dispatch for job ${jobId}`);

    await snapshot.ref.update({
      status: "searching",
      "dispatch.startedAt": FieldValue.serverTimestamp(),
      "dispatch.currentWave": 0,
      "dispatch.notifiedHeroes": [],
    });

    await firestore.collection("dispatchWaves").doc(jobId).set({
      jobId,
      currentWave: 0,
      totalWaves: DISPATCH_WAVES.length,
      startedAt: FieldValue.serverTimestamp(),
      notifiedHeroes: [] as string[],
      declinedHeroes: [] as string[],
      status: "in_progress",
    });

    const notifiedHeroes: string[] = [];

    for (let waveIndex = 0; waveIndex < DISPATCH_WAVES.length; waveIndex++) {
      const wave = DISPATCH_WAVES[waveIndex];

      const currentJob = await snapshot.ref.get();
      const currentData = currentJob.data();
      if (currentData?.status === "assigned") {
        console.log(`Job ${jobId} accepted, stopping dispatch`);
        break;
      }

      const declinedHeroes: string[] = currentData?.dispatch?.declinedHeroes ?? [];
      const excludeHeroIds = [...new Set([...notifiedHeroes, ...declinedHeroes])];

      console.log(`Wave ${waveIndex + 1}: ${wave.minRadiusMiles}-${wave.maxRadiusMiles} miles, timeout ${wave.timeoutSeconds}s`);

      await firestore.collection("dispatchWaves").doc(jobId).update({
        currentWave: waveIndex + 1,
        [`waves.${waveIndex}`]: {
          minRadius: wave.minRadiusMiles,
          maxRadius: wave.maxRadiusMiles,
          startedAt: FieldValue.serverTimestamp(),
        },
      });

      const heroes = await findNearbyHeroes(
        job.pickup?.location?.latitude ?? 0,
        job.pickup?.location?.longitude ?? 0,
        wave.minRadiusMiles,
        wave.maxRadiusMiles,
        job.service?.type ?? "",
        excludeHeroIds,
        wave.maxHeroesPerWave
      );

      const newHeroes = heroes.filter((h) => !notifiedHeroes.includes(h.id));
      console.log(`Found ${newHeroes.length} new heroes in wave ${waveIndex + 1}`);

      for (const hero of newHeroes) {
        await notifyHero(jobId, job, hero, waveIndex + 1);
        notifiedHeroes.push(hero.id);
      }

      await snapshot.ref.update({
        "dispatch.currentWave": waveIndex + 1,
        "dispatch.notifiedHeroes": notifiedHeroes,
      });

      await firestore.collection("dispatchWaves").doc(jobId).update({
        notifiedHeroes,
        [`waves.${waveIndex}.notifiedCount`]: newHeroes.length,
      });

      await sleep(wave.timeoutSeconds * 1000);
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

function calculateHeroScore(
  distance: number,
  maxRadius: number,
  rating: number,
  acceptanceRate: number,
  responseTime: number
): number {
  const proximityScore = Math.max(0, 1 - distance / (maxRadius * 1609.34));
  const ratingScore = ((rating || 5) - 1) / 4;
  const acceptScore = acceptanceRate || 0.5;
  const responseScore = Math.max(0, 1 - (responseTime || 30) / 60);
  return proximityScore * 0.4 + ratingScore * 0.25 + acceptScore * 0.2 + responseScore * 0.15;
}

async function findNearbyHeroes(
  latitude: number,
  longitude: number,
  minRadiusMiles: number,
  maxRadiusMiles: number,
  serviceType: string,
  excludeHeroIds: string[],
  maxResults: number
): Promise<Array<{ id: string; pushToken?: string; distance: number; rating: number; acceptanceRate: number; responseTime: number }>> {
  const heroesSnap = await firestore
    .collection("heroes")
    .where("status.isOnline", "==", true)
    .where("status.isVerified", "==", true)
    .get();

  const minRadiusMeters = minRadiusMiles * 1609.34;
  const maxRadiusMeters = maxRadiusMiles * 1609.34;
  const results: Array<{ id: string; pushToken?: string; distance: number; rating: number; acceptanceRate: number; responseTime: number; score: number }> = [];

  for (const doc of heroesSnap.docs) {
    const data = doc.data();
    if (data.status?.currentJobId) continue;
    if (excludeHeroIds.includes(doc.id)) continue;

    const loc = data.location?.lastKnownLocation;
    if (!loc) continue;

    const dist = haversine(latitude, longitude, loc.latitude, loc.longitude);
    if (dist < minRadiusMeters || dist > maxRadiusMeters) continue;

    if (serviceType && data.serviceTypes && !data.serviceTypes.includes(serviceType)) continue;

    const rating = data.stats?.rating ?? 5;
    const acceptanceRate = data.stats?.acceptanceRate ?? 0.5;
    const responseTime = data.stats?.avgResponseTime ?? 30;
    const score = calculateHeroScore(dist, maxRadiusMiles, rating, acceptanceRate, responseTime);

    results.push({
      id: doc.id,
      pushToken: data.settings?.pushToken,
      distance: dist,
      rating,
      acceptanceRate,
      responseTime,
      score,
    });
  }

  results.sort((a, b) => b.score - a.score);
  return results.slice(0, maxResults);
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
  hero: { id: string; pushToken?: string; distance: number; rating: number; acceptanceRate: number; responseTime: number },
  waveNumber: number
): Promise<void> {
  if (!hero.pushToken) {
    console.log(`Hero ${hero.id} has no push token – skipping notification`);
    return;
  }

  const serviceLabel = (job.service?.type ?? "")
    .replace(/_/g, " ")
    .toUpperCase();

  const distanceMiles = (hero.distance / 1609.34).toFixed(1);
  const estimatedPrice = String(job.pricing?.total ?? 0);

  try {
    await admin.messaging().send({
      token: hero.pushToken,
      notification: {
        title: `New ${serviceLabel} Job – $${estimatedPrice}`,
        body: `${distanceMiles} mi away · ${job.pickup?.address?.formatted ?? "Pickup location"}`,
      },
      data: {
        type: "new_job",
        jobId,
        serviceType: job.service?.type ?? "",
        pickupAddress: job.pickup?.address?.formatted ?? "",
        estimatedPrice,
        distanceMiles,
        estimatedMinutes: String(Math.ceil(hero.distance / 1000 / 30 * 60)),
        waveNumber: String(waveNumber),
      },
      android: {
        priority: "high",
        notification: { channelId: "otw_jobs", sound: "default" },
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    });
    console.log(`Notification sent to hero ${hero.id} for job ${jobId} (wave ${waveNumber})`);
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
