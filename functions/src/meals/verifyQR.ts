import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { createAuditLog } from '../audit/createAuditLog';
import { MealAttendance } from '../types';

export const verifyQR = onCall(async (request) => {
  if (!request.auth || request.auth.token.role !== 'student' || request.auth.token.status !== 'active') {
    throw new HttpsError('permission-denied', 'Only active students can scan QRs.');
  }

  const { token, mealId, sessionId } = request.data;
  const studentId = request.auth.token.studentId;
  const studentMessId = request.auth.token.messId;

  if (!token || !mealId || !sessionId) {
    throw new HttpsError('invalid-argument', 'Missing QR data.');
  }

  const db = getFirestore();

  try {
    return await db.runTransaction(async (transaction) => {
      const sessionRef = db.collection('qrSessions').doc(sessionId);
      const sessionDoc = await transaction.get(sessionRef);

      if (!sessionDoc.exists) {
        throw new HttpsError('not-found', 'QR session not found.');
      }

      const sessionData = sessionDoc.data()!;
      if (sessionData.token !== token || sessionData.mealId !== mealId) {
        throw new HttpsError('invalid-argument', 'Invalid QR code.');
      }

      if (new Date(sessionData.expiresAt) < new Date()) {
        throw new HttpsError('failed-precondition', 'QR code expired.');
      }

      if (sessionData.messId !== studentMessId) {
        throw new HttpsError('permission-denied', 'This meal is not in your registered mess.');
      }

      const attendanceQuery = await transaction.get(
        db.collection('mealAttendance')
          .where('mealId', '==', mealId)
          .where('studentId', '==', studentId)
          .limit(1)
      );

      if (!attendanceQuery.empty) {
        throw new HttpsError('already-exists', 'You have already attended this meal.');
      }

      const attendanceRef = db.collection('mealAttendance').doc();
      const attendance: MealAttendance = {
        attendanceId: attendanceRef.id,
        studentId,
        mealId,
        messId: studentMessId,
        scannedAt: new Date().toISOString(),
        status: 'attended'
      };

      transaction.set(attendanceRef, attendance);

      const messOffQuery = await transaction.get(
        db.collection('messOffs')
          .where('mealId', '==', mealId)
          .where('studentId', '==', studentId)
          .where('status', '==', 'active')
          .limit(1)
      );

      if (!messOffQuery.empty) {
        transaction.update(messOffQuery.docs[0].ref, { status: 'overridden' });
      }

      await createAuditLog(request.auth!.uid, 'VERIFY_QR', attendanceRef.id, 'mealAttendance', `Attendance marked via QR scan`);

      return { success: true, message: 'Attendance marked successfully.' };
    });
  } catch (error: any) {
    throw new HttpsError('internal', `Failed to verify QR: ${error.message}`);
  }
});
