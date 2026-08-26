import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { createAuditLog } from '../audit/createAuditLog';
import { Wastage } from '../types';

export const enterWastage = onCall(async (request) => {
  if (!request.auth || !['admin', 'manager'].includes(request.auth.token.role)) {
    throw new HttpsError('permission-denied', 'Only managers/admins can enter wastage.');
  }

  const { mealId, wastedQuantity } = request.data;

  if (!mealId || typeof wastedQuantity !== 'number' || wastedQuantity < 0) {
    throw new HttpsError('invalid-argument', 'Valid mealId and wasted quantity required.');
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
      if (request.auth!.token.role === 'manager' && request.auth!.token.messId !== mealData.messId) {
        throw new HttpsError('permission-denied', 'Cannot enter wastage for another mess.');
      }

      // Get preparation data
      const prepQuery = await transaction.get(
        db.collection('foodPreparation').where('mealId', '==', mealId).limit(1)
      );
      
      if (prepQuery.empty) {
         throw new HttpsError('failed-precondition', 'No food preparation record found for this meal.');
      }
      const preparedQuantity = prepQuery.docs[0].data().managerApprovedQuantity;

      // Get actual attendance
      const attendanceQuery = await transaction.get(
        db.collection('mealAttendance').where('mealId', '==', mealId)
      );
      const actualAttendance = attendanceQuery.size;

      const wastageRef = db.collection('wastage').doc();
      const wastage: Wastage = {
        wastageId: wastageRef.id,
        mealId,
        messId: mealData.messId,
        preparedQuantity,
        actualAttendance,
        wastedQuantity,
        enteredBy: request.auth!.uid,
        enteredAt: new Date().toISOString()
      };

      transaction.set(wastageRef, wastage);
      transaction.update(mealRef, { status: 'completed' });
      
      await createAuditLog(request.auth!.uid, 'ENTER_WASTAGE', wastageRef.id, 'wastage');

      return { success: true, wastageId: wastageRef.id };
    });
  } catch (error: any) {
    throw new HttpsError('internal', `Failed to enter wastage: ${error.message}`);
  }
});
