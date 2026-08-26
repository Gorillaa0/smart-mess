import cron from 'node-cron';
import { getFirestore } from 'firebase-admin/firestore';
import { runBilling } from '../routes/billing';
import { runPrediction } from '../routes/prediction';

export function startCronJobs() {
  cron.schedule('0 * * * *', async () => {
    console.log('[CRON] Running scheduled prediction...');
    try {
      const db = getFirestore();
      const twoHoursFromNow = new Date(Date.now() + 2 * 60 * 60 * 1000);
      const threeHoursFromNow = new Date(Date.now() + 3 * 60 * 60 * 1000);
      const upcomingMeals = await db.collection('meals').where('startTime', '>=', twoHoursFromNow.toISOString()).where('startTime', '<=', threeHoursFromNow.toISOString()).get();
      for (const doc of upcomingMeals.docs) {
        const meal = doc.data();
        const predQuery = await db.collection('predictions').where('mealId', '==', meal.mealId).get();
        if (predQuery.empty) {
          try { await runPrediction(meal.mealId, 'system'); } catch (err) { console.error(`Prediction failed for ${meal.mealId}:`, err); }
        }
      }
    } catch (err) { console.error('[CRON] Scheduled prediction error:', err); }
  });

  cron.schedule('0 0 1 * *', async () => {
    console.log('[CRON] Running scheduled billing...');
    try {
      const db = getFirestore();
      const lastMonth = new Date();
      lastMonth.setMonth(lastMonth.getMonth() - 1);
      const monthStr = lastMonth.toISOString().slice(0, 7);
      const messes = await db.collection('messes').get();
      for (const mess of messes.docs) {
        try { await runBilling(mess.id, monthStr, 'system'); } catch (err) { console.error(`Billing failed for mess ${mess.id}:`, err); }
      }
    } catch (err) { console.error('[CRON] Scheduled billing error:', err); }
  });

  console.log('[CRON] All scheduled jobs initialized.');
}
