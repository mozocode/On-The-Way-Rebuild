import * as functions from "firebase-functions";

// Radar secret key should be set via:
//   firebase functions:config:set radar.secret_key="prj_live_sk_..."
// const RADAR_SECRET_KEY = functions.config().radar?.secret_key;
const RADAR_BASE_URL = "https://api.radar.io/v1";

export const getRoute = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
  }

  const { originLat, originLng, destLat, destLng, mode = "car", units = "imperial" } =
    data;

  if (!originLat || !originLng || !destLat || !destLng) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Origin and destination coordinates are required"
    );
  }

  const radarKey = functions.config().radar?.secret_key;
  if (!radarKey) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Radar API key not configured"
    );
  }

  try {
    const url =
      `${RADAR_BASE_URL}/route/directions` +
      `?origin=${originLat},${originLng}` +
      `&destination=${destLat},${destLng}` +
      `&modes=${mode}` +
      `&units=${units}`;

    const response = await fetch(url, {
      headers: { Authorization: radarKey },
    });

    if (!response.ok) {
      const errorBody = await response.text();
      console.error("Radar API error:", response.status, errorBody);
      throw new functions.https.HttpsError(
        "internal",
        `Radar API returned ${response.status}`
      );
    }

    const result = await response.json();
    return result;
  } catch (error: any) {
    if (error instanceof functions.https.HttpsError) throw error;
    console.error("getRoute error:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
