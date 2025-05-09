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
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
admin.initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.sendReportStatusNotification = onCall(async (request) => {
  const { userId, reportId, newStatus, location, incidentType, recipientType } = request.data;

  // Fetch user's FCM token from Firestore
  const userDoc = await admin.firestore().collection('users').doc(userId).get();
  const fcmToken = userDoc.data().fcm_token;
  if (!fcmToken) throw new Error("No FCM token for user");

  let title, body, type;
  if (recipientType === "ert") {
    title = "Dispatch Notice: New Assignment";
    body = `You have been dispatched to a ${incidentType || "case"} at ${location}. Tap to view details.`;
    type = "dispatch";
  } else {
    title = `Report Status Updated: ${newStatus}`;
    body = `Your report (${incidentType || "Incident"}) at ${location} is now: ${newStatus}`;
    type = "report_status";
  }

  const message = {
    token: fcmToken,
    notification: { title, body },
    data: {
      reportId: reportId,
      status: newStatus,
      type: type,
    }
  };

  await admin.messaging().send(message);
  return { success: true };
});

exports.announcePushNotification = onDocumentCreated("announcements/{announcementId}", async (event) => {
  const announcement = event.data.data();
  const visibilityScope = announcement.visibility_scope || [];
  const title = announcement.title || "New Announcement";
  const content = announcement.content || "";
  const announcementId = event.params.announcementId;

  // Fetch all users whose roles match the visibility scope
  const usersSnap = await admin.firestore().collection("users").get();
  const tokens = [];
  usersSnap.forEach(doc => {
    const user = doc.data();
    const userRoles = user.roles || [];
    const fcmToken = user.fcm_token;
    if (fcmToken && userRoles.some(role => visibilityScope.includes(role))) {
      tokens.push(fcmToken);
    }
  });

  console.log("Announcement push: tokens", tokens);
  if (tokens.length === 0) {
    console.log("No tokens found for announcement push notification.");
    return;
  }

  // Send notification to each token individually using send()
  for (const token of tokens) {
    const message = {
      token: token,
      notification: {
        title: "New Announcement",
        body: title,
      },
      data: {
        announcementId: announcementId,
        type: "announcement",
      },
    };
    try {
      const response = await admin.messaging().send(message);
      console.log("Announcement push: sent to", token, response);
    } catch (err) {
      console.error("Announcement push: error sending to", token, err);
    }
  }
});
