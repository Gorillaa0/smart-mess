import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { getFirestore } from 'firebase-admin/firestore';
import { createAuditLog } from '../audit/createAuditLog';
import { Bill } from '../types';

const RATE_PER_MEAL = 40; // Testing consumption rate: charged strictly per QR scan

export const calculateBilling = onCall(async (request) => {
  if (!request.auth || !['admin', 'manager'].includes(request.auth.token.role)) {
    throw new HttpsError('permission-denied', 'Only managers/admins can calculate billing.');
  }

  const { messId, month } = request.data; 

  if (!messId || !month) {
    throw new HttpsError('invalid-argument', 'MessId and month required.');
  }

  return await runBillingCalculation(messId, month, request.auth.uid);
});

export const scheduledBilling = onSchedule('0 0 1 * *', async (event) => {
  const db = getFirestore();
  
  const lastMonth = new Date();
  lastMonth.setMonth(lastMonth.getMonth() - 1);
  const monthStr = lastMonth.toISOString().slice(0, 7); 

  const messes = await db.collection('messes').get();
  for (const mess of messes.docs) {
    try {
      await runBillingCalculation(mess.id, monthStr, 'system');
    } catch (err) {
      console.error(`Failed billing for mess ${mess.id}`, err);
    }
  }
});

async function runBillingCalculation(messId: string, month: string, actorUid: string) {
  const db = getFirestore();
  const studentsQuery = await db.collection('students').where('messId', '==', messId).get();
  
  const results = [];
  const batch = db.batch();

  for (const studentDoc of studentsQuery.docs) {
    const student = studentDoc.data();
    
    const startOfMonth = new Date(`${month}-01T00:00:00Z`).toISOString();
    const endOfMonth = new Date(new Date(startOfMonth).getFullYear(), new Date(startOfMonth).getMonth() + 1, 0, 23, 59, 59).toISOString();

    // Query strictly scanned QR meal attendance records
    const attendanceQuery = await db.collection('mealAttendance')
      .where('studentId', '==', student.studentId)
      .where('scannedAt', '>=', startOfMonth)
      .where('scannedAt', '<=', endOfMonth)
      .where('status', '==', 'attended')
      .get();

    const scannedMealsCount = attendanceQuery.size;
    const totalAmount = scannedMealsCount * RATE_PER_MEAL;

    const billRef = db.collection('bills').doc();
    const bill: Bill = {
      billId: billRef.id,
      studentId: student.studentId,
      messId,
      month,
      baseFee: 0,
      messOffDeductions: 0,
      extraCharges: 0,
      totalAmount,
      status: 'pending',
      createdAt: new Date().toISOString()
    };

    batch.set(billRef, bill);
    
    const notifRef = db.collection('notifications').doc();
    batch.set(notifRef, {
      notificationId: notifRef.id,
      recipientUid: student.uid,
      title: 'Monthly Mess Bill (QR Consumption)',
      body: `Your mess bill for ${month} (${scannedMealsCount} QR scanned meals) is Rs. ${totalAmount}`,
      type: 'alert',
      read: false,
      createdAt: new Date().toISOString()
    });

    results.push(billRef.id);
  }

  await batch.commit();

  if (actorUid !== 'system') {
    await createAuditLog(actorUid, 'CALCULATE_BILLING', messId, 'bills', `Generated consumption bills for ${month} (QR Scan Only)`);
  }

  return { success: true, count: results.length };
}
