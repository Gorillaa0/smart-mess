import { Router, Response } from 'express';
import { getFirestore } from 'firebase-admin/firestore';
import { verifyToken, requireRole, AuthRequest } from '../middleware/verifyToken';
import { createAuditLog } from '../utils/audit';
import * as crypto from 'crypto';

const router = Router();

// POST /meals/createMeal
router.post('/createMeal', verifyToken, requireRole('admin', 'manager'), async (req: AuthRequest, res: Response) => {
  const { messId, type, date, startTime, endTime, messOffDeadline } = req.body;
  if (req.user.role === 'manager' && req.user.messId !== messId) {
    return res.status(403).json({ error: 'Cannot create meal for another mess.' });
  }
  if (!messId || !type || !date || !startTime || !endTime || !messOffDeadline) {
    return res.status(400).json({ error: 'Missing required meal fields.' });
  }
  try {
    const db = getFirestore();
    const mealRef = db.collection('meals').doc();
    const meal = { mealId: mealRef.id, messId, type, date, startTime, endTime, messOffDeadline, status: 'scheduled' };
    await mealRef.set(meal);
    await createAuditLog(req.user.uid, 'CREATE_MEAL', meal.mealId, 'meals', `Created ${type} for ${date}`);
    res.json({ success: true, mealId: meal.mealId });
  } catch (err: any) {
    res.status(500).json({ error: `Failed to create meal: ${err.message}` });
  }
});

// POST /meals/generateQR
router.post('/generateQR', verifyToken, requireRole('admin', 'manager'), async (req: AuthRequest, res: Response) => {
  const { mealId, messId } = req.body;
  if (req.user.role === 'manager' && req.user.messId !== messId) {
    return res.status(403).json({ error: 'Cannot generate QR for another mess.' });
  }
  try {
    const db = getFirestore();
    const existingSessions = await db.collection('qrSessions').where('mealId', '==', mealId).where('expiresAt', '>', new Date().toISOString()).get();
    const batch = db.batch();
    existingSessions.docs.forEach(doc => batch.update(doc.ref, { expiresAt: new Date().toISOString() }));
    const sessionRef = db.collection('qrSessions').doc();
    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 1000).toISOString();
    const session = { sessionId: sessionRef.id, token, mealId, messId, expiresAt, createdBy: req.user.uid, createdAt: new Date().toISOString() };
    batch.set(sessionRef, session);
    await batch.commit();
    await createAuditLog(req.user.uid, 'GENERATE_QR', session.sessionId, 'qrSessions');
    res.json({ token, expiresAt, sessionId: session.sessionId });
  } catch (err: any) {
    res.status(500).json({ error: `Failed to generate QR: ${err.message}` });
  }
});

// POST /meals/verifyQR
router.post('/verifyQR', verifyToken, requireRole('student'), async (req: AuthRequest, res: Response) => {
  if (req.user.status !== 'active') return res.status(403).json({ error: 'Only active students can scan QRs.' });
  const { token, mealId, sessionId } = req.body;
  const studentId = req.user.studentId;
  const studentMessId = req.user.messId;
  if (!token || !mealId || !sessionId) return res.status(400).json({ error: 'Missing QR data.' });
  const db = getFirestore();
  try {
    const result = await db.runTransaction(async (transaction) => {
      const sessionRef = db.collection('qrSessions').doc(sessionId);
      const sessionDoc = await transaction.get(sessionRef);
      if (!sessionDoc.exists) throw new Error('QR session not found.');
      const sessionData = sessionDoc.data()!;
      if (sessionData.token !== token || sessionData.mealId !== mealId) throw new Error('Invalid QR code.');
      if (new Date(sessionData.expiresAt) < new Date()) throw new Error('QR code expired.');
      if (sessionData.messId !== studentMessId) throw new Error('This meal is not in your registered mess.');
      const attendanceQuery = await transaction.get(db.collection('mealAttendance').where('mealId', '==', mealId).where('studentId', '==', studentId).limit(1));
      if (!attendanceQuery.empty) throw new Error('Already attended this meal.');
      const attendanceRef = db.collection('mealAttendance').doc();
      transaction.set(attendanceRef, { attendanceId: attendanceRef.id, studentId, mealId, messId: studentMessId, scannedAt: new Date().toISOString(), status: 'attended' });
      const messOffQuery = await transaction.get(db.collection('messOffs').where('mealId', '==', mealId).where('studentId', '==', studentId).where('status', '==', 'active').limit(1));
      if (!messOffQuery.empty) transaction.update(messOffQuery.docs[0].ref, { status: 'overridden' });
      await createAuditLog(req.user.uid, 'VERIFY_QR', attendanceRef.id, 'mealAttendance', 'Attendance via QR scan');
      return { success: true };
    });
    res.json(result);
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
});

export default router;
