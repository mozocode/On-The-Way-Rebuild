import * as admin from "firebase-admin";

admin.initializeApp();

export { dispatchJob } from "./dispatch/dispatchJob";
export { acceptJob } from "./dispatch/acceptJob";
export { radarLocationUpdate, radarGeofenceUpdate } from "./radar/webhooks";
export { sendPushNotification, sendJobNotification } from "./notifications/push";
export { createPaymentIntent, capturePayment } from "./payments/stripe";
export { getOrCreateCustomer, addPaymentMethod } from "./payments/customer";
export { cleanupExpiredLocations, cleanupOldJobs } from "./jobs/cleanup";
export { onJobStatusChanged } from "./jobs/triggers";
export { getRoute } from "./routing/getRoute";
