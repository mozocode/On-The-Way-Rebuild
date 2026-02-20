import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApplicationStatus } from "../types/heroApplication";

const firestore = admin.firestore();

async function requireAdmin(uid: string): Promise<void> {
  const userDoc = await firestore.collection("users").doc(uid).get();
  if (userDoc.data()?.role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Admin access required");
  }
}

// ── Approve ──

export const approveHeroApplication = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }
    await requireAdmin(context.auth.uid);

    const { applicationId, notes } = data;

    return firestore.runTransaction(async (transaction) => {
      const appRef = firestore.collection("heroApplications").doc(applicationId);
      const appDoc = await transaction.get(appRef);

      if (!appDoc.exists) {
        throw new functions.https.HttpsError("not-found", "Application not found");
      }

      const application = appDoc.data()!;

      if (application.status === ApplicationStatus.APPROVED) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Already approved"
        );
      }

      const now = admin.firestore.FieldValue.serverTimestamp();
      const tsNow = admin.firestore.Timestamp.now();

      // Create hero profile
      const heroRef = firestore.collection("heroes").doc();
      const profilePhotoUrl =
        (application.documents || []).find(
          (d: any) => d.type === "profilePhoto"
        )?.url || null;

      const serviceEntries = Object.entries(application.serviceCapabilities?.services || {});
      const equipEntries = Object.entries(application.serviceCapabilities?.equipment || {});

      transaction.set(heroRef, {
        userId: application.userId,
        email: application.userEmail,
        displayName: `${application.personalInfo?.firstName || ""} ${application.personalInfo?.lastName || ""}`.trim(),
        phone: application.personalInfo?.phone || null,
        photoUrl: profilePhotoUrl,
        status: {
          isOnline: false,
          isVerified: true,
          isApproved: true,
          currentJobId: null,
        },
        vehicle: {
          make: application.vehicleInfo?.make,
          model: application.vehicleInfo?.model,
          year: application.vehicleInfo?.year,
          color: application.vehicleInfo?.color,
          licensePlate: application.vehicleInfo?.licensePlate,
        },
        services: {
          offered: serviceEntries.filter(([, v]) => v).map(([k]) => k),
          equipment: equipEntries.filter(([, v]) => v).map(([k]) => k),
        },
        settings: {
          pushEnabled: true,
          maxRadius: application.serviceCapabilities?.maxServiceRadius || 15,
        },
        ratings: { average: 5.0, count: 0 },
        earnings: { totalEarned: 0, pendingPayout: 0 },
        stats: { totalJobs: 0, completionRate: 0, acceptanceRate: 0 },
        createdAt: now,
        updatedAt: now,
      });

      // Update application
      const updateData: Record<string, any> = {
        status: ApplicationStatus.APPROVED,
        approvedAt: now,
        updatedAt: now,
        heroProfileId: heroRef.id,
        statusHistory: admin.firestore.FieldValue.arrayUnion([
          {
            status: ApplicationStatus.APPROVED,
            changedAt: tsNow,
            changedBy: context.auth!.uid,
            reason: notes || "Approved",
          },
        ]),
      };

      if (notes) {
        updateData.reviewNotes = admin.firestore.FieldValue.arrayUnion([
          {
            id: firestore.collection("_").doc().id,
            authorId: context.auth!.uid,
            content: notes,
            isInternal: true,
            createdAt: tsNow,
          },
        ]);
      }

      transaction.update(appRef, updateData);

      // Promote user to hero role
      transaction.update(
        firestore.collection("users").doc(application.userId),
        {
          role: "hero",
          heroProfileId: heroRef.id,
          updatedAt: now,
        }
      );

      return { success: true, heroProfileId: heroRef.id };
    });
  }
);

// ── Reject ──

export const rejectHeroApplication = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }
    await requireAdmin(context.auth.uid);

    const { applicationId, reason } = data;

    if (!reason) {
      throw new functions.https.HttpsError("invalid-argument", "Rejection reason is required");
    }

    const appRef = firestore.collection("heroApplications").doc(applicationId);
    const appDoc = await appRef.get();

    if (!appDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Application not found");
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const tsNow = admin.firestore.Timestamp.now();

    await appRef.update({
      status: ApplicationStatus.REJECTED,
      rejectedAt: now,
      updatedAt: now,
      statusHistory: admin.firestore.FieldValue.arrayUnion([
        {
          status: ApplicationStatus.REJECTED,
          changedAt: tsNow,
          changedBy: context.auth.uid,
          reason,
        },
      ]),
      reviewNotes: admin.firestore.FieldValue.arrayUnion([
        {
          id: firestore.collection("_").doc().id,
          authorId: context.auth.uid,
          content: reason,
          isInternal: false,
          createdAt: tsNow,
        },
      ]),
    });

    // Notify applicant
    const application = appDoc.data()!;
    await firestore.collection("notifications").add({
      userId: application.userId,
      type: "application_rejected",
      title: "Application Update",
      body: "Your Hero application was not approved at this time.",
      data: { applicationId },
      read: false,
      createdAt: now,
    });

    return { success: true };
  }
);

// ── Request More Info ──

export const requestMoreInfo = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }
    await requireAdmin(context.auth.uid);

    const { applicationId, message } = data;

    if (!message) {
      throw new functions.https.HttpsError("invalid-argument", "Message is required");
    }

    const appRef = firestore.collection("heroApplications").doc(applicationId);
    const appDoc = await appRef.get();

    if (!appDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Application not found");
    }

    const now = admin.firestore.FieldValue.serverTimestamp();
    const tsNow = admin.firestore.Timestamp.now();

    await appRef.update({
      status: ApplicationStatus.NEEDS_INFO,
      updatedAt: now,
      statusHistory: admin.firestore.FieldValue.arrayUnion([
        {
          status: ApplicationStatus.NEEDS_INFO,
          changedAt: tsNow,
          changedBy: context.auth.uid,
          reason: message,
        },
      ]),
      reviewNotes: admin.firestore.FieldValue.arrayUnion([
        {
          id: firestore.collection("_").doc().id,
          authorId: context.auth.uid,
          content: message,
          isInternal: false,
          createdAt: tsNow,
        },
      ]),
    });

    // Notify applicant
    const application = appDoc.data()!;
    await firestore.collection("notifications").add({
      userId: application.userId,
      type: "application_needs_info",
      title: "Application Update",
      body: "We need additional information for your Hero application.",
      data: { applicationId },
      read: false,
      createdAt: now,
    });

    return { success: true };
  }
);
