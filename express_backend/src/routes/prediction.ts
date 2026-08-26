import { Router, Response } from 'express';
import { getFirestore } from 'firebase-admin/firestore';
import { verifyToken, requireRole, AuthRequest } from '../middleware/verifyToken';
import { createAuditLog } from '../utils/audit';

const router = Router();

function baselinePrediction(active: number, messOff: number, day: number, mealType: string, isHoliday: boolean): number {
  const base = active - messOff;
  let dayFactor = 1.0;
  if (day >= 5) dayFactor = mealType === 'lunch' ? 1.05 : 0.85;
  const mealFactor: Record<string, number> = { breakfast: 0.75, lunch: 0.95, dinner: 0.85 };
  return Math.max(0, Math.round(base * dayFactor * (mealFactor[mealType] ?? 0.85) * (isHoliday ? 0.6 : 1.0) * 0.95));
}

async function runPrediction(mealId: string, actorUid: string) {
  const db = getFirestore();
  const ML_API_URL = process.env.MLAPI_URL || '';
  const mealDoc = await db.collection('meals').doc(mealId).get();
  if (!mealDoc.exists) throw new Error('Meal not found.');
  const meal = mealDoc.data()!;
  const studentsCount = (await db.collection('students').where('messId', '==', meal.messId).get()).size;
  const messOffCount = (await db.collection('messOffs').where('mealId', '==', mealId).where('status', '==', 'active').get()).size;
  const dayOfWeek = new Date(meal.date).getDay();
  const eventsQuery = await db.collection('events').where('startDate', '<=', meal.date).where('endDate', '>=', meal.date).get();
  const events = eventsQuery.docs.map(d => d.id);
  const isHoliday = eventsQuery.docs.some(d => d.data().type === 'holiday');
  const isExamDay = eventsQuery.docs.some(d => d.data().type === 'exam');
  const historyQuery = await db.collection('wastage').where('messId', '==', meal.messId).orderBy('enteredAt', 'desc').limit(30).get();
  const historicalAttendance = historyQuery.docs.map(d => d.data().actualAttendance as number).slice(0, 5);
  const histAvg = historicalAttendance.length > 0 ? historicalAttendance.reduce((a, b) => a + b, 0) / historicalAttendance.length : studentsCount * 0.85;
  const histWastage = historyQuery.docs.length > 0 ? historyQuery.docs.reduce((a, d) => a + (d.data().wastedQuantity ?? 0), 0) / historyQuery.docs.length : 5;
  const prevDay = historicalAttendance[0] ?? Math.round(studentsCount * 0.82);
  let predictedAttendance: number;
  let confidenceInterval: [number, number];
  let modelUsed = 'baseline';
  if (ML_API_URL) {
    try {
      const r = await fetch(`${ML_API_URL}/predict`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ day_of_week: dayOfWeek, total_active_students: studentsCount, mess_off_count: messOffCount, is_exam_day: isExamDay, is_holiday: isHoliday, is_special_event: events.length > 0, event_impact: isHoliday ? 'high' : isExamDay ? 'medium' : events.length > 0 ? 'low' : 'none', historical_avg_attendance: histAvg, historical_avg_wastage: histWastage, prev_day_attendance: prevDay, hostel_occupancy_rate: 0.95, meal_type: meal.type }), signal: AbortSignal.timeout(8000) });
      if (r.ok) {
        const mlData = await r.json() as any;
        predictedAttendance = Math.max(0, Math.min(mlData.predicted_attendance, studentsCount));
        confidenceInterval = [mlData.confidence_low, mlData.confidence_high];
        modelUsed = mlData.model_used ?? 'random_forest';
      } else { throw new Error(`HTTP ${r.status}`); }
    } catch { predictedAttendance = baselinePrediction(studentsCount, messOffCount, dayOfWeek, meal.type, isHoliday); confidenceInterval = [Math.max(0, predictedAttendance - 8), Math.min(studentsCount, predictedAttendance + 8)]; }
  } else {
    predictedAttendance = baselinePrediction(studentsCount, messOffCount, dayOfWeek, meal.type, isHoliday);
    confidenceInterval = [Math.max(0, predictedAttendance - 8), Math.min(studentsCount, predictedAttendance + 8)];
  }
  const predRef = db.collection('predictions').doc();
  await predRef.set({ predictionId: predRef.id, mealId, messId: meal.messId, date: meal.date, type: meal.type, activeStudentsCount: studentsCount, messOffCount, dayOfWeek, events, historicalAttendance, predictedAttendance, confidenceInterval, modelUsed, createdAt: new Date().toISOString() });
  const managerQuery = await db.collection('managers').where('messId', '==', meal.messId).get();
  if (!managerQuery.empty) {
    const manager = managerQuery.docs[0].data();
    const notifRef = db.collection('notifications').doc();
    await notifRef.set({ notificationId: notifRef.id, recipientUid: manager.uid, title: '📊 Prediction Ready', body: `AI prediction for ${meal.type} on ${meal.date}: ${predictedAttendance} students. Model: ${modelUsed}.`, type: 'update', read: false, createdAt: new Date().toISOString() });
  }
  if (actorUid !== 'system') await createAuditLog(actorUid, 'TRIGGER_PREDICTION', predRef.id, 'predictions');
  return { success: true, predictionId: predRef.id, predictedAttendance, modelUsed };
}

router.post('/trigger', verifyToken, requireRole('admin', 'manager'), async (req: AuthRequest, res: Response) => {
  const { mealId } = req.body;
  if (!mealId) return res.status(400).json({ error: 'Meal ID required.' });
  try {
    const result = await runPrediction(mealId, req.user.uid);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/approve', verifyToken, requireRole('admin', 'manager'), async (req: AuthRequest, res: Response) => {
  const { predictionId, managerApprovedQuantity } = req.body;
  if (!predictionId || typeof managerApprovedQuantity !== 'number') return res.status(400).json({ error: 'Valid predictionId and approved quantity required.' });
  const db = getFirestore();
  try {
    const result = await db.runTransaction(async (transaction) => {
      const predRef = db.collection('predictions').doc(predictionId);
      const predDoc = await transaction.get(predRef);
      if (!predDoc.exists) throw new Error('Prediction not found.');
      const predData = predDoc.data()!;
      if (req.user.role === 'manager' && req.user.messId !== predData.messId) throw new Error('Cannot approve for another mess.');
      const prepQuery = await transaction.get(db.collection('foodPreparation').where('mealId', '==', predData.mealId).limit(1));
      if (!prepQuery.empty) throw new Error('Food preparation already approved.');
      const prepRef = db.collection('foodPreparation').doc();
      transaction.set(prepRef, { prepId: prepRef.id, mealId: predData.mealId, messId: predData.messId, mlPrediction: predData.predictedAttendance, recommendedQuantity: predData.predictedAttendance, managerApprovedQuantity, approvedBy: req.user.uid, approvedAt: new Date().toISOString() });
      await createAuditLog(req.user.uid, 'APPROVE_PREDICTION', prepRef.id, 'foodPreparation');
      return { success: true, prepId: prepRef.id };
    });
    res.json(result);
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
});

export { runPrediction };
export default router;
