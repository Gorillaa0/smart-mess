import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getFirestore } from 'firebase-admin/firestore';
import { sendNotification } from './sendNotification';

export const scheduledReminders = onSchedule('*/30 * * * *', async (event) => {
  const db = getFirestore();
  
  const now = new Date();
  const in30Mins = new Date(now.getTime() + 30 * 60 * 1000);
  const in35Mins = new Date(now.getTime() + 35 * 60 * 1000); 

  const mealsQuery = await db.collection('meals')
    .where('messOffDeadline', '>=', in30Mins.toISOString())
    .where('messOffDeadline', '<=', in35Mins.toISOString())
    .get();

  for (const mealDoc of mealsQuery.docs) {
    const meal = mealDoc.data();

    const studentsQuery = await db.collection('students')
      .where('messId', '==', meal.messId)
      .get();

    for (const studentDoc of studentsQuery.docs) {
      const student = studentDoc.data();

      const messOffQuery = await db.collection('messOffs')
        .where('mealId', '==', meal.mealId)
        .where('studentId', '==', student.studentId)
        .where('status', '==', 'active')
        .limit(1)
        .get();

      if (messOffQuery.empty) {
        await sendNotification(
          student.uid,
          'Mess-off Deadline Approaching',
          `The deadline to mark mess-off for ${meal.type} is in 30 minutes.`,
          'reminder'
        );
      }
    }
  }
});
