import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { ApplicationStatus, HeroApplication } from "../types/heroApplication";

const firestore = admin.firestore();

export const submitHeroApplication = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
    }

    const { applicationId } = data;
    const userId = context.auth.uid;

    const appRef = firestore.collection("heroApplications").doc(applicationId);
    const appDoc = await appRef.get();

    if (!appDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Application not found");
    }

    const application = appDoc.data() as HeroApplication;

    if (application.userId !== userId) {
      throw new functions.https.HttpsError("permission-denied", "Not your application");
    }

    if (application.status !== ApplicationStatus.DRAFT) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Application has already been submitted"
      );
    }

    // Validate completeness
    const errors = validateApplication(application);
    if (errors.length > 0) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        `Missing required information: ${errors.join(", ")}`
      );
    }

    const now = admin.firestore.FieldValue.serverTimestamp();

    await appRef.update({
      status: ApplicationStatus.SUBMITTED,
      submittedAt: now,
      updatedAt: now,
      statusHistory: admin.firestore.FieldValue.arrayUnion([
        {
          status: ApplicationStatus.SUBMITTED,
          changedAt: admin.firestore.Timestamp.now(),
          changedBy: userId,
        },
      ]),
    });

    // Notify admins
    await notifyAdmins(applicationId, application);

    return {
      success: true,
      message: "Application submitted successfully",
    };
  }
);

function validateApplication(app: HeroApplication): string[] {
  const errors: string[] = [];

  if (!app.personalInfo) {
    errors.push("Personal information");
  } else {
    if (!app.personalInfo.firstName) errors.push("First name");
    if (!app.personalInfo.lastName) errors.push("Last name");
    if (!app.personalInfo.email) errors.push("Email");
    if (!app.personalInfo.phone) errors.push("Phone");
    if (!app.personalInfo.address?.street) errors.push("Address");
    if (!app.personalInfo.emergencyContact?.name) errors.push("Emergency contact");
  }

  if (!app.vehicleInfo) {
    errors.push("Vehicle information");
  } else {
    if (!app.vehicleInfo.make) errors.push("Vehicle make");
    if (!app.vehicleInfo.model) errors.push("Vehicle model");
    if (!app.vehicleInfo.licensePlate) errors.push("License plate");
    if (!app.vehicleInfo.insurance?.policyNumber) errors.push("Insurance info");
  }

  if (!app.serviceCapabilities) {
    errors.push("Service capabilities");
  }

  const requiredDocTypes = [
    "driversLicenseFront",
    "driversLicenseBack",
    "insuranceCard",
    "vehicleRegistration",
    "profilePhoto",
  ];
  const uploadedTypes = (app.documents || []).map((d) => d.type);
  for (const docType of requiredDocTypes) {
    if (!uploadedTypes.includes(docType)) {
      errors.push(`Document: ${docType}`);
    }
  }

  if (!app.agreements) {
    errors.push("Agreements");
  } else {
    if (!app.agreements.termsAccepted) errors.push("Terms of Service");
    if (!app.agreements.privacyAccepted) errors.push("Privacy Policy");
    if (!app.agreements.backgroundCheckConsent) errors.push("Background check consent");
    if (!app.agreements.independentContractorAgreement) errors.push("Contractor agreement");
    if (!app.agreements.insuranceAcknowledgment) errors.push("Insurance acknowledgment");
    if (!app.agreements.safetyPolicyAccepted) errors.push("Safety policy");
  }

  return errors;
}

async function notifyAdmins(
  applicationId: string,
  application: HeroApplication
): Promise<void> {
  try {
    const adminsSnap = await firestore
      .collection("users")
      .where("role", "==", "admin")
      .get();

    if (adminsSnap.empty) return;

    const batch = firestore.batch();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const name = `${application.personalInfo?.firstName || ""} ${application.personalInfo?.lastName || ""}`.trim();

    for (const adminDoc of adminsSnap.docs) {
      const notifRef = firestore.collection("notifications").doc();
      batch.set(notifRef, {
        userId: adminDoc.id,
        type: "new_hero_application",
        title: "New Hero Application",
        body: `${name || "Someone"} has applied to become a Hero.`,
        data: { applicationId },
        read: false,
        createdAt: now,
      });
    }

    await batch.commit();

    // Send push to admin tokens
    const tokens = adminsSnap.docs
      .map((d) => d.data().settings?.pushToken)
      .filter(Boolean) as string[];

    if (tokens.length > 0) {
      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "New Hero Application",
          body: `${name || "Someone"} has applied to become a Hero.`,
        },
        data: { type: "new_hero_application", applicationId },
      });
    }
  } catch (e) {
    console.error("Error notifying admins:", e);
  }
}
