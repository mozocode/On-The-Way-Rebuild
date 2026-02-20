import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const firestore = admin.firestore();

export const sendPushNotification = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }

    const { userId, title, body, notificationData } = data;
    if (!userId || !title || !body) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "userId, title, and body are required"
      );
    }

    const userDoc = await firestore.collection("users").doc(userId).get();
    const token = userDoc.data()?.settings?.pushToken;

    if (!token) {
      return { success: false, reason: "no_token" };
    }

    try {
      await admin.messaging().send({
        token,
        notification: { title, body },
        data: notificationData ?? {},
        android: {
          priority: "high",
          notification: { channelId: "otw_jobs", sound: "default" },
        },
        apns: { payload: { aps: { sound: "default", badge: 1 } } },
      });
      return { success: true };
    } catch (error: any) {
      console.error("Push notification error:", error);
      return { success: false, reason: error.message };
    }
  }
);

export const sendJobNotification = functions.firestore
  .document("jobs/{jobId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const jobId = context.params.jobId;

    if (before.status === after.status) return;

    const newStatus = after.status;
    let targetUserId: string | undefined;
    let title = "";
    let body = "";

    switch (newStatus) {
      case "assigned":
        targetUserId = after.customer?.id;
        title = "Hero Assigned!";
        body = `${after.hero?.name ?? "A hero"} is on the way.`;
        break;
      case "en_route":
        targetUserId = after.customer?.id;
        title = "Hero En Route";
        body = "Your hero is heading to your location.";
        break;
      case "arrived":
        targetUserId = after.customer?.id;
        title = "Your Hero Has Arrived!";
        body = `${after.hero?.name ?? "Your hero"} has arrived at your location.`;
        break;
      case "in_progress":
        targetUserId = after.customer?.id;
        title = "Your Hero Has Started Your Service";
        body = `${after.hero?.name ?? "Your hero"} is now working on your ${after.service?.type?.replace(/_/g, " ") ?? "service"}.`;
        break;
      case "completed":
        targetUserId = after.customer?.id;
        title = "Service Complete";
        body = "Your service has been completed. Please rate your hero!";
        break;
      case "cancelled":
        // Notify both parties
        if (after.hero?.id) {
          await sendToUser(after.hero.id, "Job Cancelled", "The job has been cancelled.", {
            type: "job_cancelled",
            jobId,
          });
        }
        targetUserId = after.customer?.id;
        title = "Request Cancelled";
        body = "Your service request has been cancelled.";
        break;
      default:
        return;
    }

    if (targetUserId) {
      await sendToUser(targetUserId, title, body, {
        type: `job_${newStatus}`,
        jobId,
      });
    }
  });

async function sendToUser(
  userId: string,
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  const userDoc = await firestore.collection("users").doc(userId).get();
  const token = userDoc.data()?.settings?.pushToken;
  if (!token) return;

  try {
    await admin.messaging().send({
      token,
      notification: { title, body },
      data,
      android: {
        priority: "high",
        notification: { channelId: "otw_jobs", sound: "default" },
      },
      apns: { payload: { aps: { sound: "default", badge: 1 } } },
    });
  } catch (error) {
    console.error(`Failed to send to user ${userId}:`, error);
  }
}
