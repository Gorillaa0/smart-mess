import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { createAuditLog } from '../audit/createAuditLog';
import { Meal } from '../types';

export const createMeal = onCall(async (request) => {
  if (!request.auth || !['admin', 'manager'].includes(request.auth.token.role)) {
    throw new HttpsError('permission-denied', 'Only managers/admins can create meals.');
  }

  const { messId, type, date, startTime, endTime, messOffDeadline } = request.data;

  if (request.auth.token.role === 'manager' && request.auth.token.messId !== messId) {
    throw new HttpsError('permission-denied', 'Cannot create meal for another mess.');
  }

  if (!messId || !type || !date || !startTime || !endTime || !messOffDeadline) {
    throw new HttpsError('invalid-argument', 'Missing required meal fields.');
  }

  try {
    const db = getFirestore();
    const mealRef = db.collection('meals').doc();
    
    const meal: Meal = {
      mealId: mealRef.id,
      messId,
      type,
      date,
      startTime,
      endTime,
      messOffDeadline,
      status: 'scheduled'
    };

    await mealRef.set(meal);
    await createAuditLog(request.auth.uid, 'CREATE_MEAL', meal.mealId, 'meals', `Created ${type} for ${date}`);

    return { success: true, mealId: meal.mealId };
  } catch (error: any) {
    throw new HttpsError('internal', `Failed to create meal: ${error.message}`);
  }
});
