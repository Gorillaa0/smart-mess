import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { createAuditLog } from '../audit/createAuditLog';

export const cancelMessOff = onCall(async (request) => {
  if (!request.auth || request.auth.token.role !== 'student' || request.auth.token.status !== 'active') {
    throw new HttpsError('permission-denied', 'Only active students can cancel mess-off.');
  }

  const { messOffId } = request.data;
  const studentId = request.auth.token.studentId;

  if (!messOffId) {
    throw new HttpsError('invalid-argument', 'Mess-off ID is required.');
  }

  const db = getFirestore();

  try {
    return await db.runTransaction(async (transaction) => {
      const messOffRef = db.collection('messOffs').doc(messOffId);
      const messOffDoc = await transaction.get(messOffRef);

      if (!messOffDoc.exists) {
        throw new HttpsError('not-found', 'Mess-off not found.');
      }

      const messOffData = messOffDoc.data()!;

      if (messOffData.studentId !== studentId) {
        throw new HttpsError('permission-denied', 'Cannot cancel someone else\'s mess-off.');
      }

      if (messOffData.status !== 'active') {
        throw new HttpsError('failed-precondition', 'Can only cancel active mess-offs.');
      }

      const mealRef = db.collection('meals').doc(messOffData.mealId);
      const mealDoc = await transaction.get(mealRef);
      const mealData = mealDoc.data()!;

      if (new Date() >= new Date(mealData.messOffDeadline)) {
        throw new HttpsError('failed-precondition', 'Cannot cancel after deadline.');
      }

      transaction.update(messOffRef, { status: 'cancelled' });
      
      await createAuditLog(request.auth!.uid, 'CANCEL_MESS_OFF', messOffId, 'messOffs', `Mess-off cancelled for meal ${messOffData.mealId}`);

      return { success: true };
    });
  } catch (error: any) {
    throw new HttpsError('internal', `Failed to cancel mess-off: ${error.message}`);
  }
});
