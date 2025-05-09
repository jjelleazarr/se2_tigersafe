/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest, onCall} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
admin.initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.sendReportStatusNotification = onCall(async (request) => {
  const { userId, reportId, newStatus, location, incidentType } = request.data;

  // Fetch user's FCM token from Firestore
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  const fcmToken = userDoc.data().fcm_token;
  if (!fcmToken) throw new Error("No FCM token for user");

  // Compose notification
  const message = {
    token: fcmToken,
    notification: {
      title: `Report Status Updated: ${newStatus}`,
      body: `Your report (${incidentType || "Incident"}) at ${location} is now: ${newStatus}`,
    },
    data: {
      reportId: reportId,
      status: newStatus,
      type: "report_status",
    }
  };

  // Send notification
  await admin.messaging().send(message);
  return { success: true };
});
