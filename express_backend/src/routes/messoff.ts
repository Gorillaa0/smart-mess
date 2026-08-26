import { Router, Response } from 'express';
import { getFirestore } from 'firebase-admin/firestore';
import { verifyToken, requireRole, AuthRequest } from '../middleware/verifyToken';
import { createAuditLog } from '../utils/audit';

const router = Router();

// POST /messoff/mark
router.post('/mark', verifyToken, requireRole('student'), async (req: AuthRequest, res: Response) => {
  if (req.user.status !== 'active') return res.status(403).json({ error: 'Only active students can mark mess-off.' });
  const { mealId } = req.body;
  const studentId = req.user.studentId;
  const messId = req.user.messId;
  if (!mealId) return res.status(400).json({ error: 'Meal ID is required.' });
  const db = getFirestore();
  try {
    const result = await db.runTransaction(async (transaction) => {
      const mealRef = db.collection('meals').doc(mealId);
      const mealDoc = await transaction.get(mealRef);
      if (!mealDoc.exists) throw new Error('Meal not found.');
      const mealData = mealDoc.data()!;
      if (mealData.status !== 'scheduled') throw new Error('Can only mark mess-off for scheduled meals.');
      if (new Date() >= new Date(mealData.messOffDeadline)) throw new Error('Mess-off deadline has passed.');
      const attendanceQuery = await transaction.get(db.collection('mealAttendance').where('mealId', '==', mealId).where('studentId', '==', studentId).limit(1));
      if (!attendanceQuery.empty) throw new Error('Already attended this meal.');
      const messOffQuery = await transaction.get(db.collection('messOffs').where('mealId', '==', mealId).where('studentId', '==', studentId).where('status', '==', 'active').limit(1));
      if (!messOffQuery.empty) throw new Error('Mess-off already marked.');
      const messOffRef = db.collection('messOffs').doc();
      transaction.set(messOffRef, { messOffId: messOffRef.id, studentId, mealId, messId, date: mealData.date, status: 'active', createdAt: new Date().toISOString() });
      await createAuditLog(req.user.uid, 'MARK_MESS_OFF', messOffRef.id, 'messOffs', `Mess-off for meal ${mealId}`);
      return { success: true, messOffId: messOffRef.id };
    });
    res.json(result);
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
});

// POST /messoff/cancel
router.post('/cancel', verifyToken, requireRole('student'), async (req: AuthRequest, res: Response) => {
  if (req.user.status !== 'active') return res.status(403).json({ error: 'Only active students can cancel mess-off.' });
  const { messOffId } = req.body;
  const studentId = req.user.studentId;
  if (!messOffId) return res.status(400).json({ error: 'Mess-off ID is required.' });
  const db = getFirestore();
  try {
    const result = await db.runTransaction(async (transaction) => {
      const messOffRef = db.collection('messOffs').doc(messOffId);
      const messOffDoc = await transaction.get(messOffRef);
      if (!messOffDoc.exists) throw new Error('Mess-off not found.');
      const messOffData = messOffDoc.data()!;
      if (messOffData.studentId !== studentId) throw new Error('Cannot cancel someone else\'s mess-off.');
      if (messOffData.status !== 'active') throw new Error('Can only cancel active mess-offs.');
      const mealDoc = await transaction.get(db.collection('meals').doc(messOffData.mealId));
      const mealData = mealDoc.data()!;
      if (new Date() >= new Date(mealData.messOffDeadline)) throw new Error('Cannot cancel after deadline.');
      transaction.update(messOffRef, { status: 'cancelled' });
      await createAuditLog(req.user.uid, 'CANCEL_MESS_OFF', messOffId, 'messOffs', `Cancelled for meal ${messOffData.mealId}`);
      return { success: true };
    });
    res.json(result);
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
});

export default router;
