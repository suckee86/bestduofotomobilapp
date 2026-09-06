const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {
  onDocumentDeleted,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

initializeApp();

const db = getFirestore();
const region = "europe-west1";

exports.sendAnnouncement = onDocumentWritten(
  {document: "announcements/{announcementId}", region},
  async (event) => {
    if (!event.data || !event.data.after.exists) return;

    const announcementRef = event.data.after.ref;
    const after = event.data.after.data();
    const before = event.data.before.exists ? event.data.before.data() : {};
    if (!after.isPublished || before.isPublished || after.notificationSentAt) {
      return;
    }

    const claimed = await db.runTransaction(async (transaction) => {
      const current = await transaction.get(announcementRef);
      const data = current.data();
      if (!data?.isPublished || data.notificationState === "sending" ||
          data.notificationSentAt) {
        return false;
      }
      transaction.update(announcementRef, {
        notificationState: "sending",
        notificationStartedAt: FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (!claimed) return;

    try {
      const tokenSnapshot = await db.collection("pushTokens").get();
      const tokenDocuments = tokenSnapshot.docs.filter(
          (document) => Boolean(document.data().token),
      );
      let successCount = 0;
      let failureCount = 0;

      for (let offset = 0; offset < tokenDocuments.length; offset += 500) {
        const documents = tokenDocuments.slice(offset, offset + 500);
        const tokens = documents.map((document) => document.data().token);
        const response = await getMessaging().sendEachForMulticast({
          tokens,
          notification: {
            title: String(after.title || "Best Duo Fotó"),
            body: String(after.body || "Új értesítés érkezett."),
          },
          data: {
            announcementId: event.params.announcementId,
            targetUrl: String(after.targetUrl || ""),
          },
          android: {
            priority: "high",
            notification: {color: "#FF7900"},
          },
          apns: {
            payload: {aps: {sound: "default"}},
          },
        });

        successCount += response.successCount;
        failureCount += response.failureCount;

        const invalidRefs = [];
        response.responses.forEach((result, index) => {
          const code = result.error?.code;
          if (code === "messaging/registration-token-not-registered" ||
              code === "messaging/invalid-registration-token") {
            invalidRefs.push(documents[index].ref);
          }
        });

        if (invalidRefs.length > 0) {
          const batch = db.batch();
          invalidRefs.forEach((reference) => batch.delete(reference));
          await batch.commit();
        }
      }

      await announcementRef.update({
        notificationState: "sent",
        notificationSentAt: FieldValue.serverTimestamp(),
        deliverySummary: {successCount, failureCount},
      });
      logger.info("Best Duo announcement sent", {
        announcementId: event.params.announcementId,
        successCount,
        failureCount,
      });
    } catch (error) {
      logger.error("Best Duo announcement delivery failed", error);
      await announcementRef.update({
        notificationState: "error",
        notificationError: String(error?.message || error),
      });
      throw error;
    }
  },
);

exports.cleanupUserTokens = onDocumentDeleted(
  {document: "users/{userId}", region},
  async (event) => {
    const snapshot = await db.collection("pushTokens")
        .where("userId", "==", event.params.userId)
        .get();
    if (snapshot.empty) return;

    const batch = db.batch();
    snapshot.docs.forEach((document) => batch.delete(document.ref));
    await batch.commit();
  },
);
