import * as admin from "firebase-admin";
import {
  onDocumentCreated,
  FirestoreEvent,
  QueryDocumentSnapshot,
} from "firebase-functions/v2/firestore";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// ─── Helpers ──────────────────────────────────────────────────────────────────

/** Fetches the FCM token for a given UID from the users collection. */
async function getToken(uid: string): Promise<string | null> {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) return null;
  return (snap.data()?.fcmToken as string) ?? null;
}

/** Sends an FCM message. Silently ignores missing tokens. */
async function sendNotification({
  token,
  title,
  body,
  data,
}: {
  token: string;
  title: string;
  body: string;
  data: Record<string, string>;
}): Promise<void> {
  try {
    await messaging.send({
      token,
      notification: { title, body },
      data,
      android: {
        // High-priority so the notification wakes the device screen.
        priority: "high",
        notification: {
          // Use the app icon.  Replace with your actual icon resource name
          // if you add a custom one in android/app/src/main/res/.
          icon: "ic_notification",
          color: "#E8516A", // VailColors.rose
          channelId: "vail_default",
        },
      },
    });
  } catch (err) {
    console.error("[FCM] send failed:", err);
  }
}

// ─── 1. New Vail Request → notify receiver ────────────────────────────────────

export const onNewVailRequest = onDocumentCreated(
  "vailRequests/{requestId}",
  async (
    event: FirestoreEvent<QueryDocumentSnapshot | undefined>
  ) => {
    const data = event.data?.data();
    if (!data) return;

    const receiverId = data.receiverId as string;
    const senderAlias = data.senderAlias as string ?? "Someone";
    const heartCount = (data.heartCount as number) ?? 1;

    const token = await getToken(receiverId);
    if (!token) return;

    const heartLabel = heartCount === 1 ? "1 heart" : `${heartCount} hearts`;

    await sendNotification({
      token,
      title: "Someone is waiting behind the veil ❤️",
      body: `${senderAlias} sent you a Vail Request with ${heartLabel}.`,
      data: {
        type: "vail_request",
        requestId: event.params.requestId,
      },
    });
  }
);

// ─── 2. New chat message → notify the other participant ───────────────────────

export const onNewMessage = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (
    event: FirestoreEvent<QueryDocumentSnapshot | undefined>
  ) => {
    const msgData = event.data?.data();
    if (!msgData) return;

    // Skip system messages — they are written server-side, not by a user.
    if (msgData.isSystem === true) return;

    const senderId = msgData.senderId as string;
    const text = (msgData.text as string) ?? "";

    // Get the conversation to find the other participant.
    const convoSnap = await db
      .collection("conversations")
      .doc(event.params.conversationId)
      .get();

    if (!convoSnap.exists) return;

    const participants = (convoSnap.data()?.participants as string[]) ?? [];
    const recipientId = participants.find((p) => p !== senderId);
    if (!recipientId) return;

    // Fetch sender alias for the notification title.
    const senderSnap = await db.collection("users").doc(senderId).get();
    const senderAlias =
      (senderSnap.data()?.nickname as string) ?? "Stranger";

    const token = await getToken(recipientId);
    if (!token) return;

    // Truncate long messages for the notification body.
    const preview = text.length > 80 ? `${text.substring(0, 80)}…` : text;

    await sendNotification({
      token,
      title: senderAlias,
      body: preview,
      data: {
        type: "message",
        conversationId: event.params.conversationId,
        messageId: event.params.messageId,
      },
    });
  }
);

// ─── 3. Mutual chemistry → notify both participants ───────────────────────────
// Triggered when a conversation document is updated and mutualChemistry
// flips from false to true.

import {
  onDocumentUpdated,
  Change,
} from "firebase-functions/v2/firestore";

export const onMutualChemistry = onDocumentUpdated(
  "conversations/{conversationId}",
  async (
    event: FirestoreEvent<
      Change<QueryDocumentSnapshot> | undefined
    >
  ) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Only fire when mutualChemistry just flipped to true.
    if (before.mutualChemistry === true) return;
    if (after.mutualChemistry !== true) return;

    const participants = (after.participants as string[]) ?? [];

    await Promise.all(
      participants.map(async (uid) => {
        const token = await getToken(uid);
        if (!token) return;
        await sendNotification({
          token,
          title: "It's mutual! ✨",
          body:
            "Both of you felt the spark. Time to plan your blind date.",
          data: {
            type: "chemistry",
            conversationId: event.params.conversationId,
          },
        });
      })
    );
  }
);
