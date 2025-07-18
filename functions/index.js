const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.deleteOldStories = functions.pubsub.schedule("every 30 minutes").onRun((context) => {
    const cutoffTime = new Date(Date.now() - 30 * 60000); // 30 minutes ago
    const storiesRef = admin.firestore().collection("stories");

    return storiesRef.where("timestamp", "<=", cutoffTime).get()
        .then((snapshot) => {
            const batch = admin.firestore().batch();
            snapshot.docs.forEach((doc) => batch.delete(doc.ref));
            return batch.commit();
        })
        .then(() => console.log("Old stories successfully deleted"))
        .catch((error) => console.error("Error deleting old stories:", error));
});

exports.aggregateStories = functions.pubsub.schedule("every 24 hours").onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const twentyFourHoursAgo = new admin.firestore.Timestamp(
        now.seconds - 24 * 3600, 
        now.nanoseconds
    );

    const storiesQuery = await admin.firestore().collection("stories")
        .where("timestamp", ">=", twentyFourHoursAgo)
        .get();

    const storylines = {};
    storiesQuery.forEach((doc) => {
        const story = doc.data();
        const userId = story.userId;
        storylines[userId] = storylines[userId] || [];
        storylines[userId].push(story);
    });

    for (const userId in storylines) {
        if (Object.hasOwnProperty.call(storylines, userId)) { // Added to fix guard-for-in.
            await admin.firestore().collection("storylines").add({
                userId: userId,
                created: now,
                stories: storylines[userId],
            });
        }
    }

    console.log("Storylines successfully aggregated");
});

exports.sendMessageNotification = functions.firestore
  .document('messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();

    // 1️⃣ Ensure we have a recipient
    if (!message.recipientId) {
      console.log('No recipient ID found.');
      return null;
    }

    try {
      // 2️⃣ Look up the recipient’s FCM token
      const userDoc = await admin
        .firestore()
        .collection('users')
        .doc(message.recipientId)
        .get();

      if (!userDoc.exists) {
        console.log('Recipient user not found.');
        return null;
      }

      const userData = userDoc.data();
      const token    = userData.fcmToken;
      if (!token) {
        console.log('No FCM token found for recipient.');
        return null;
      }

      // 3️⃣ Build the notification body
      const bodyText = message.text && message.text.trim().length > 0
        ? message.text
        : "📸 Photo message";

      // 4️⃣ Assemble payload with both notification + data
      const payload = {
        notification: {
          title: `New message from ${message.senderName || "Unknown"}`,
          body:  bodyText,
        },
        data: {
          chatPartnerId: message.senderId,        // <–– deep-link target
          // you can add more keys here if you like, e.g.
          // senderName: message.senderName || ""
        },
        android: {
          notification: { sound: "default" }
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            }
          }
        },
        token: token
      };

      // 5️⃣ Send it
      const response = await admin.messaging().send(payload);
      console.log('✅ Successfully sent message notification:', response);
      return response;

    } catch (error) {
      console.error('❌ Error sending message notification:', error);
      return null;
    }
  });


exports.sendLikeNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();

    if (!data || data.type !== 'like') {
      console.log('Notification is not a "like" type, skipping...');
      return null;
    }

    const recipientId = data.userId;
    const senderId = data.fromUserId;

    if (!recipientId || !senderId) {
      console.log('Missing recipient or sender ID');
      return null;
    }

    const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
    const recipientDoc = await admin.firestore().collection('users').doc(recipientId).get();

    if (!senderDoc.exists || !recipientDoc.exists) {
      console.log('Sender or recipient not found');
      return null;
    }

    const recipient = recipientDoc.data();
    const sender = senderDoc.data();

    const token = recipient.fcmToken;
    if (!token) {
      console.log('No FCM token for recipient');
      return null;
    }

    const payload = {
      notification: {
        title: `${sender.name} liked your caption ❤️`,
        body: 'Tap to view it!',
      },
      token: token,
    };

    try {
      const response = await admin.messaging().send(payload);
      console.log('✅ Notification sent:', response);
      return response;
    } catch (error) {
      console.error('❌ Error sending notification:', error);
      return null;
    }
  });


 
  exports.sendCommentNotification = functions.firestore
  .document('captions/{captionId}/comments/{commentId}')
  .onCreate(async (snap, context) => {
    const comment = snap.data();
    const captionId = context.params.captionId;

    try {
      // Get the caption document to find the original poster
      const captionSnap = await admin.firestore().collection('captions').doc(captionId).get();
      if (!captionSnap.exists) {
        console.log("❌ Caption not found.");
        return null;
      }

      const caption = captionSnap.data();
      const recipientId = caption.userId;

      // Don't notify if the commenter is the same as the recipient
      if (!recipientId || recipientId === comment.userId) {
        console.log("ℹ️ No notification needed (same user or missing recipient).");
        return null;
      }

      // Get recipient's FCM token
      const userSnap = await admin.firestore().collection('users').doc(recipientId).get();
      const userData = userSnap.data();

      if (!userData || !userData.fcmToken) {
        console.log("❌ No FCM token found for recipient.");
        return null;
      }

      const payload = {
        notification: {
          title: `${comment.userName} commented on your caption`,
          body: comment.text || "New comment!",
        },
        data: {
          captionId: captionId,  // Added for deep linking
        },
        android: {
          notification: {
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
        token: userData.fcmToken,
      };

      const response = await admin.messaging().send(payload);
      console.log("✅ Successfully sent comment notification:", response);
      return response;

    } catch (error) {
      console.error("❌ Error sending comment notification:", error);
      return null;
    }
  });






