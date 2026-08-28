import { Router, Response } from 'express';
import { getFirestore } from 'firebase-admin/firestore';
import { verifyToken, requireRole, AuthRequest } from '../middleware/verifyToken';
import { createAuditLog } from '../utils/audit';

const router = Router();
const RATE_PER_MEAL = 40; // Testing consumption rate: charged strictly per QR scan

async function runBilling(messId: string, month: string, actorUid: string) {
  const db = getFirestore();
  const studentsQuery = await db.collection('students').where('messId', '==', messId).get();
  const results = [];
  const batch = db.batch();

  for (const studentDoc of studentsQuery.docs) {
    const student = studentDoc.data();
    const startOfMonth = new Date(`${month}-01T00:00:00Z`).toISOString();
    const endOfMonth = new Date(new Date(startOfMonth).getFullYear(), new Date(startOfMonth).getMonth() + 1, 0, 23, 59, 59).toISOString();

    // Query all QR attendance scans verified for this student this month
    const attendanceQuery = await db.collection('mealAttendance')
      .where('studentId', '==', student.studentId)
      .where('scannedAt', '>=', startOfMonth)
      .where('scannedAt', '<=', endOfMonth)
      .where('status', '==', 'attended')
      .get();

    const scannedMealsCount = attendanceQuery.size;
    // Billing strictly by QR Scans: only scanned meals are counted
    const totalAmount = scannedMealsCount * RATE_PER_MEAL;

    const billRef = db.collection('bills').doc();
    batch.set(billRef, {
      billId: billRef.id,
      studentId: student.studentId,
      messId,
      month,
      scannedMealsCount,
      ratePerMeal: RATE_PER_MEAL,
      baseFee: 0,
      messOffDeductions: 0,
      extraCharges: 0,
      totalAmount,
      billingModel: 'scan_consumption_only',
      status: 'pending',
      createdAt: new Date().toISOString()
    });

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

router.post('/calculate', verifyToken, requireRole('admin', 'manager'), async (req: AuthRequest, res: Response) => {
  const { messId, month } = req.body;
  if (!messId || !month) return res.status(400).json({ error: 'MessId and month required.' });
  try {
    const result = await runBilling(messId, month, req.user.uid);
    res.json(result);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export { runBilling };
export default router;
