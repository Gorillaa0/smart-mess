import { Router, Response } from 'express';
import { getFirestore } from 'firebase-admin/firestore';
import { verifyToken, requireRole, AuthRequest } from '../middleware/verifyToken';
import { createAuditLog } from '../utils/audit';

const router = Router();

router.post('/enter', verifyToken, requireRole('admin', 'manager'), async (req: AuthRequest, res: Response) => {
  const { mealId, wastedQuantity } = req.body;
  if (!mealId || typeof wastedQuantity !== 'number' || wastedQuantity < 0) return res.status(400).json({ error: 'Valid mealId and wasted quantity required.' });
  const db = getFirestore();
  try {
    const result = await db.runTransaction(async (transaction) => {
      const mealRef = db.collection('meals').doc(mealId);
      const mealDoc = await transaction.get(mealRef);
      if (!mealDoc.exists) throw new Error('Meal not found.');
      const mealData = mealDoc.data()!;
      if (req.user.role === 'manager' && req.user.messId !== mealData.messId) throw new Error('Cannot enter wastage for another mess.');
      const prepQuery = await transaction.get(db.collection('foodPreparation').where('mealId', '==', mealId).limit(1));
      if (prepQuery.empty) throw new Error('No food preparation record found.');
      const preparedQuantity = prepQuery.docs[0].data().managerApprovedQuantity;
      const attendanceQuery = await transaction.get(db.collection('mealAttendance').where('mealId', '==', mealId));
      const actualAttendance = attendanceQuery.size;
      const wastageRef = db.collection('wastage').doc();
      transaction.set(wastageRef, { wastageId: wastageRef.id, mealId, messId: mealData.messId, preparedQuantity, actualAttendance, wastedQuantity, enteredBy: req.user.uid, enteredAt: new Date().toISOString() });
      transaction.update(mealRef, { status: 'completed' });
      await createAuditLog(req.user.uid, 'ENTER_WASTAGE', wastageRef.id, 'wastage');
      return { success: true, wastageId: wastageRef.id };
    });
    res.json(result);
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
});

export default router;
