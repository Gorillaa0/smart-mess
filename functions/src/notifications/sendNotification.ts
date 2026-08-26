import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

export const sendNotification = async (uid: string, title: string, body: string, type: 'reminder' | 'update' | 'alert') => {
  const db = getFirestore();
  
  const notifRef = db.collection('notifications').doc();
  await notifRef.set({
    notificationId: notifRef.id,
    recipientUid: uid,
    title,
    body,
    type,
    read: false,
    createdAt: new Date().toISOString()
  });

  const tokensQuery = await db.collection('devices').doc(uid).collection('tokens').get();
  const tokens = tokensQuery.docs.map(doc => doc.data().token);

  if (tokens.length > 0) {
    try {
      await getMessaging().sendEachForMulticast({
        tokens,
        notification: { title, body },
        data: { type, notificationId: notifRef.id }
      });
    } catch (err) {
      console.error(`Failed to send FCM to ${uid}`, err);
    }
  }
};
