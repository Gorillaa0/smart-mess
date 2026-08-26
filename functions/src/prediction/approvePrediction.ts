import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { createAuditLog } from '../audit/createAuditLog';
import { FoodPreparation } from '../types';

export const approvePrediction = onCall(async (request) => {
  if (!request.auth || !['admin', 'manager'].includes(request.auth.token.role)) {
    throw new HttpsError('permission-denied', 'Only managers/admins can approve predictions.');
  }

  const { predictionId, managerApprovedQuantity } = request.data;

  if (!predictionId || typeof managerApprovedQuantity !== 'number') {
    throw new HttpsError('invalid-argument', 'Valid predictionId and approved quantity required.');
  }

  const db = getFirestore();

  try {
    return await db.runTransaction(async (transaction) => {
      const predRef = db.collection('predictions').doc(predictionId);
      const predDoc = await transaction.get(predRef);

      if (!predDoc.exists) {
        throw new HttpsError('not-found', 'Prediction not found.');
      }

      const predData = predDoc.data()!;

      if (request.auth!.token.role === 'manager' && request.auth!.token.messId !== predData.messId) {
        throw new HttpsError('permission-denied', 'Cannot approve prediction for another mess.');
      }

      const prepQuery = await transaction.get(
        db.collection('foodPreparation').where('mealId', '==', predData.mealId).limit(1)
      );

      if (!prepQuery.empty) {
        throw new HttpsError('already-exists', 'Food preparation already approved for this meal.');
      }

      const prepRef = db.collection('foodPreparation').doc();
      const prep: FoodPreparation = {
        prepId: prepRef.id,
        mealId: predData.mealId,
        messId: predData.messId,
        mlPrediction: predData.predictedAttendance,
        recommendedQuantity: predData.predictedAttendance, // + buffer logic here
        managerApprovedQuantity,
        approvedBy: request.auth!.uid,
        approvedAt: new Date().toISOString()
      };

      transaction.set(prepRef, prep);
      
      await createAuditLog(request.auth!.uid, 'APPROVE_PREDICTION', prepRef.id, 'foodPreparation');

      return { success: true, prepId: prepRef.id };
    });
  } catch (error: any) {
    throw new HttpsError('internal', `Failed to approve prediction: ${error.message}`);
  }
});
