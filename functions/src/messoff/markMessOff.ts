import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { createAuditLog } from '../audit/createAuditLog';
import { MessOff } from '../types';

export const markMessOff = onCall(async (request) => {
  if (!request.auth || request.auth.token.role !== 'student' || request.auth.token.status !== 'active') {
    throw new HttpsError('permission-denied', 'Only active students can mark mess-off.');
  }

  const { mealId } = request.data;
  const studentId = request.auth.token.studentId;
  const messId = request.auth.token.messId;

  if (!mealId) {
    throw new HttpsError('invalid-argument', 'Meal ID is required.');
  }

  const db = getFirestore();

  try {
    return await db.runTransaction(async (transaction) => {
      const mealRef = db.collection('meals').doc(mealId);
      const mealDoc = await transaction.get(mealRef);

      if (!mealDoc.exists) {
        throw new HttpsError('not-found', 'Meal not found.');
      }

      const mealData = mealDoc.data()!;
      if (mealData.status !== 'scheduled') {
        throw new HttpsError('failed-precondition', 'Can only mark mess-off for scheduled meals.');
      }

      if (new Date() >= new Date(mealData.messOffDeadline)) {
        throw new HttpsError('failed-precondition', 'Mess-off deadline has passed.');
      }

      const attendanceQuery = await transaction.get(
        db.collection('mealAttendance')
          .where('mealId', '==', mealId)
          .where('studentId', '==', studentId)
          .limit(1)
      );

      if (!attendanceQuery.empty) {
        throw new HttpsError('failed-precondition', 'Already attended this meal.');
      }

      const messOffQuery = await transaction.get(
        db.collection('messOffs')
          .where('mealId', '==', mealId)
          .where('studentId', '==', studentId)
          .where('status', '==', 'active')
          .limit(1)
      );

      if (!messOffQuery.empty) {
        throw new HttpsError('already-exists', 'Mess-off already marked.');
      }

      const messOffRef = db.collection('messOffs').doc();
      const messOff: MessOff = {
        messOffId: messOffRef.id,
        studentId,
        mealId,
        messId,
        date: mealData.date,
        status: 'active',
        createdAt: new Date().toISOString()
      };

      transaction.set(messOffRef, messOff);
      
      await createAuditLog(request.auth!.uid, 'MARK_MESS_OFF', messOffRef.id, 'messOffs', `Mess-off marked for meal ${mealId}`);

      return { success: true, messOffId: messOffRef.id };
    });
  } catch (error: any) {
    throw new HttpsError('internal', `Failed to mark mess-off: ${error.message}`);
  }
});
