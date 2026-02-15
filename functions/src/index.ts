import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();

// Export dispatch, radar webhooks, and notifications when implemented.
// Example:
// export { dispatchJob, acceptJob } from './dispatch/dispatchJob';
// export { radarLocationUpdate, radarGeofenceUpdate } from './radar/webhooks';
// export { sendPushNotification } from './notifications/push';

export const helloWorld = functions.https.onRequest((req, res) => {
  res.send('OTW Cloud Functions');
});
