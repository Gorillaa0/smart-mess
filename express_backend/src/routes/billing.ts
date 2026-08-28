import { Router, Response } from 'express';
import { getFirestore } from 'firebase-admin/firestore';
import { verifyToken, requireRole, AuthRequest } from '../middleware/verifyToken';
import { createAuditLog } from '../utils/audit';

const router = Router();

/**
 * Institutional Meal Pricing Chart:
 * - Breakfast: ₹25 (Mon-Sat), ₹0 on Sunday
 * - Lunch: ₹50 (Mon-Sat), ₹100 on Sunday (Special Feast)
 * - Dinner: ₹50 (Mon, Tue, Thu, Fri, Sat, Sun), ₹100 on Wednesday (Special Feast)
 */
function getMealPrice(mealType: string, date: Date): number {
  const day = date.getDay(); // 0 = Sunday, 1 = Monday, 2 = Tuesday, 3 = Wednesday, ...
  const type = (mealType || '').toLowerCase();

  if (type.includes('breakfast')) {
    return day === 0 ? 0 : 25;
  }
  if (type.includes('lunch')) {
    return day === 0 ? 100 : 50;
  }
  if (type.includes('dinner')) {
    return day === 3 ? 100 : 50;
  }
  return 50;
}

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

    let totalAmount = 0;
    let breakfastCount = 0;
    let lunchCount = 0;
    let dinnerCount = 0;

    for (const doc of attendanceQuery.docs) {
      const data = doc.data();
      const scanDate = new Date(data.scannedAt);
      const mealType = data.mealType || data.mealId || 'lunch';
      const cost = getMealPrice(mealType, scanDate);
      totalAmount += cost;

      if (mealType.toLowerCase().includes('breakfast')) breakfastCount++;
      else if (mealType.toLowerCase().includes('lunch')) lunchCount++;
      else if (mealType.toLowerCase().includes('dinner')) dinnerCount++;
    }

    const billRef = db.collection('bills').doc();
    batch.set(billRef, {
      billId: billRef.id,
      studentId: student.studentId,
      messId,
      month,
      scannedMealsCount: attendanceQuery.size,
      breakfastCount,
      lunchCount,
      dinnerCount,
      baseFee: 0,
      messOffDeductions: 0,
      extraCharges: 0,
      totalAmount,
      billingModel: 'itemized_menu_chart',
      status: 'pending',
      createdAt: new Date().toISOString()
    });

    const notifRef = db.collection('notifications').doc();
    batch.set(notifRef, {
      notificationId: notifRef.id,
      recipientUid: student.uid,
      title: 'Monthly Mess Bill (QR Itemized Consumption)',
      body: `Your mess bill for ${month} (${attendanceQuery.size} scanned meals) is Rs. ${totalAmount}`,
      type: 'alert',
      read: false,
      createdAt: new Date().toISOString()
    });

    results.push(billRef.id);
  }

  await batch.commit();
  if (actorUid !== 'system') {
    await createAuditLog(actorUid, 'CALCULATE_BILLING', messId, 'bills', `Generated itemized consumption bills for ${month}`);
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
