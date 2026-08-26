import { Router, Response } from 'express';
import { getFirestore } from 'firebase-admin/firestore';
import { verifyToken, requireRole, AuthRequest } from '../middleware/verifyToken';
import { createAuditLog } from '../utils/audit';

const router = Router();
const BASE_FEE = 3000;
const DEDUCTION_PER_MEAL = 40;

async function runBilling(messId: string, month: string, actorUid: string) {
  const db = getFirestore();
  const studentsQuery = await db.collection('students').where('messId', '==', messId).get();
  const results = [];
  const batch = db.batch();
  for (const studentDoc of studentsQuery.docs) {
    const student = studentDoc.data();
    const startOfMonth = new Date(`${month}-01T00:00:00Z`).toISOString();
    const endOfMonth = new Date(new Date(startOfMonth).getFullYear(), new Date(startOfMonth).getMonth() + 1, 0, 23, 59, 59).toISOString();
    const messOffsQuery = await db.collection('messOffs').where('studentId', '==', student.studentId).where('date', '>=', startOfMonth).where('date', '<=', endOfMonth).where('status', '==', 'active').get();
    const deductions = messOffsQuery.size * DEDUCTION_PER_MEAL;
    const totalAmount = BASE_FEE - deductions;
    const billRef = db.collection('bills').doc();
    batch.set(billRef, { billId: billRef.id, studentId: student.studentId, messId, month, baseFee: BASE_FEE, messOffDeductions: deductions, extraCharges: 0, totalAmount, status: 'pending', createdAt: new Date().toISOString() });
    const notifRef = db.collection('notifications').doc();
    batch.set(notifRef, { notificationId: notifRef.id, recipientUid: student.uid, title: 'New Bill Generated', body: `Your mess bill for ${month} is Rs. ${totalAmount}`, type: 'alert', read: false, createdAt: new Date().toISOString() });
    results.push(billRef.id);
  }
  await batch.commit();
  if (actorUid !== 'system') await createAuditLog(actorUid, 'CALCULATE_BILLING', messId, 'bills', `Generated bills for ${month}`);
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
