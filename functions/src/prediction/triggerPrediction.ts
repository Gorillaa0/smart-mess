import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getFirestore } from 'firebase-admin/firestore';
import { defineString } from 'firebase-functions/params';
import { createAuditLog } from '../audit/createAuditLog';
import { Prediction, Meal } from '../types';

// Read ML API URL from Firebase Functions environment parameter
const mlApiUrl = defineString('MLAPI_URL', { default: '' });

export const triggerPrediction = onCall(async (request) => {
  if (!request.auth || !['admin', 'manager'].includes(request.auth.token.role)) {
    throw new HttpsError('permission-denied', 'Only managers/admins can trigger predictions.');
  }
  
  const { mealId } = request.data;
  if (!mealId) throw new HttpsError('invalid-argument', 'Meal ID required.');

  return await runPredictionLogic(mealId, request.auth.uid, mlApiUrl.value());
});

export const scheduledPrediction = onSchedule('0 * * * *', async (event) => {
  const db = getFirestore();
  
  // Find meals starting in ~2 hours that don't have predictions yet
  const twoHoursFromNow = new Date(Date.now() + 2 * 60 * 60 * 1000);
  const threeHoursFromNow = new Date(Date.now() + 3 * 60 * 60 * 1000);

  const upcomingMeals = await db.collection('meals')
    .where('startTime', '>=', twoHoursFromNow.toISOString())
    .where('startTime', '<=', threeHoursFromNow.toISOString())
    .get();

  for (const doc of upcomingMeals.docs) {
    const meal = doc.data() as Meal;
    const predQuery = await db.collection('predictions').where('mealId', '==', meal.mealId).get();
    if (predQuery.empty) {
      try {
        await runPredictionLogic(meal.mealId, 'system', mlApiUrl.value());
      } catch (err) {
        console.error(`Failed scheduled prediction for ${meal.mealId}`, err);
      }
    }
  }
});

// ─── ML API response interface ───────────────────────────────────────────────
interface MLApiResponse {
  predicted_attendance: number;
  confidence_low: number;
  confidence_high: number;
  recommended_preparation: number;
  model_used: string;
}

// ─── Deterministic baseline fallback (no randomness) ─────────────────────────
function baselinePrediction(
  activeStudentsCount: number,
  messOffCount: number,
  dayOfWeek: number,
  mealType: string,
  isHoliday: boolean
): number {
  const base = activeStudentsCount - messOffCount;
  let dayFactor = 1.0;
  if (dayOfWeek >= 5) dayFactor = mealType === 'lunch' ? 1.05 : 0.85;
  const mealFactor: Record<string, number> = { breakfast: 0.75, lunch: 0.95, dinner: 0.85 };
  const factor = mealFactor[mealType] ?? 0.85;
  const holidayFactor = isHoliday ? 0.6 : 1.0;
  return Math.max(0, Math.round(base * dayFactor * factor * holidayFactor * 0.95));
}

async function runPredictionLogic(mealId: string, actorUid: string, ML_API_URL: string) {
  const db = getFirestore();
  
  const mealDoc = await db.collection('meals').doc(mealId).get();
  if (!mealDoc.exists) throw new HttpsError('not-found', 'Meal not found.');
  const meal = mealDoc.data() as Meal;

  // 1. Gather features
  const studentsQuery = await db.collection('students').where('messId', '==', meal.messId).get();
  const activeStudentsCount = studentsQuery.size;

  const messOffQuery = await db.collection('messOffs')
    .where('mealId', '==', mealId)
    .where('status', '==', 'active')
    .get();
  const messOffCount = messOffQuery.size;

  const mealDate = new Date(meal.date);
  const dayOfWeek = mealDate.getDay();

  const eventsQuery = await db.collection('events')
    .where('startDate', '<=', meal.date)
    .where('endDate', '>=', meal.date)
    .get();
  const events = eventsQuery.docs.map(d => d.id);
  const isHoliday = eventsQuery.docs.some(d => d.data().type === 'holiday');
  const isExamDay = eventsQuery.docs.some(d => d.data().type === 'exam');

  // 2. Get historical attendance averages from wastage collection
  const historyQuery = await db.collection('wastage')
    .where('messId', '==', meal.messId)
    .orderBy('enteredAt', 'desc')
    .limit(30)
    .get();
    
  const historicalAttendance = historyQuery.docs.map(d => d.data().actualAttendance as number).slice(0, 5);
  const historicalAvgAttendance = historicalAttendance.length > 0
    ? historicalAttendance.reduce((a, b) => a + b, 0) / historicalAttendance.length
    : activeStudentsCount * 0.85;
  const historicalAvgWastage = historyQuery.docs.length > 0
    ? historyQuery.docs.reduce((acc, d) => acc + (d.data().wastedQuantity as number ?? 0), 0) / historyQuery.docs.length
    : 5;
  const prevDayAttendance = historicalAttendance[0] ?? Math.round(activeStudentsCount * 0.82);

  // 3. Call the Python ML API — fallback to baseline if unavailable
  let predictedAttendance: number;
  let confidenceInterval: [number, number];
  let modelUsed = 'baseline';

  if (ML_API_URL) {
    try {
      const payload = {
        day_of_week: dayOfWeek,
        total_active_students: activeStudentsCount,
        mess_off_count: messOffCount,
        is_exam_day: isExamDay,
        is_holiday: isHoliday,
        is_special_event: events.length > 0,
        event_impact: isHoliday ? 'high' : isExamDay ? 'medium' : events.length > 0 ? 'low' : 'none',
        historical_avg_attendance: historicalAvgAttendance,
        historical_avg_wastage: historicalAvgWastage,
        prev_day_attendance: prevDayAttendance,
        hostel_occupancy_rate: 0.95,
        meal_type: meal.type,
      };

      const response = await fetch(`${ML_API_URL}/predict`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(8000), // 8-second timeout
      });

      if (!response.ok) {
        throw new Error(`ML API returned HTTP ${response.status}`);
      }

      const mlData = (await response.json()) as MLApiResponse;
      predictedAttendance = Math.max(0, Math.min(mlData.predicted_attendance, activeStudentsCount));
      confidenceInterval = [mlData.confidence_low, mlData.confidence_high];
      modelUsed = mlData.model_used ?? 'random_forest';

      console.log(`ML API prediction (${modelUsed}): ${predictedAttendance} for meal ${mealId}`);
    } catch (err: any) {
      console.warn(`ML API unreachable, using deterministic baseline. Error: ${err?.message}`);
      predictedAttendance = baselinePrediction(activeStudentsCount, messOffCount, dayOfWeek, meal.type, isHoliday);
      confidenceInterval = [
        Math.max(0, predictedAttendance - 8),
        Math.min(activeStudentsCount, predictedAttendance + 8),
      ];
    }
  } else {
    // MLAPI_URL not configured — use deterministic baseline
    console.warn('MLAPI_URL not set. Using deterministic baseline prediction.');
    predictedAttendance = baselinePrediction(activeStudentsCount, messOffCount, dayOfWeek, meal.type, isHoliday);
    confidenceInterval = [
      Math.max(0, predictedAttendance - 8),
      Math.min(activeStudentsCount, predictedAttendance + 8),
    ];
  }

  // 4. Save prediction to Firestore
  const predRef = db.collection('predictions').doc();
  const prediction: Prediction & { modelUsed?: string } = {
    predictionId: predRef.id,
    mealId,
    messId: meal.messId,
    date: meal.date,
    type: meal.type,
    activeStudentsCount,
    messOffCount,
    dayOfWeek,
    events,
    historicalAttendance,
    predictedAttendance,
    confidenceInterval,
    modelUsed,
    createdAt: new Date().toISOString(),
  };

  await predRef.set(prediction);

  // 5. Notify the mess manager
  const managerQuery = await db.collection('managers').where('messId', '==', meal.messId).get();
  if (!managerQuery.empty) {
    const manager = managerQuery.docs[0].data();
    const notifRef = db.collection('notifications').doc();
    await notifRef.set({
      notificationId: notifRef.id,
      recipientUid: manager.uid,
      title: '📊 Prediction Ready',
      body: `AI prediction for ${meal.type} on ${meal.date}: ${predictedAttendance} students expected. Model: ${modelUsed}.`,
      type: 'update',
      read: false,
      createdAt: new Date().toISOString(),
    });
  }

  if (actorUid !== 'system') {
    await createAuditLog(actorUid, 'TRIGGER_PREDICTION', predRef.id, 'predictions');
  }

  return { success: true, predictionId: predRef.id, predictedAttendance, modelUsed };
}
