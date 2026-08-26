import { Router, Response } from 'express';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { verifyToken, requireRole, AuthRequest } from '../middleware/verifyToken';
import { createAuditLog } from '../utils/audit';

const router = Router();

// POST /auth/createStudent
router.post('/createStudent', verifyToken, requireRole('admin'), async (req: AuthRequest, res: Response) => {
  const { email, name, studentId, messId, hostelId, roomNumber } = req.body;
  if (!email || !name || !studentId || !messId || !hostelId) {
    return res.status(400).json({ error: 'Missing required fields.' });
  }
  try {
    const tempPassword = Math.random().toString(36).slice(-8) + 'A1!';
    const userRecord = await getAuth().createUser({ email, password: tempPassword, displayName: name });
    const uid = userRecord.uid;
    await getAuth().setCustomUserClaims(uid, { role: 'student', studentId, messId, hostelId, status: 'active' });
    const db = getFirestore();
    const batch = db.batch();
    batch.set(db.collection('users').doc(uid), { uid, email, name, role: 'student', status: 'active', createdAt: new Date().toISOString() });
    batch.set(db.collection('students').doc(studentId), { studentId, uid, name, email, messId, hostelId, roomNumber, role: 'student' });
    await batch.commit();
    await createAuditLog(req.user.uid, 'CREATE_STUDENT', studentId, 'students', 'Admin created student account');
    res.json({ uid, email, tempPassword });
  } catch (err: any) {
    res.status(500).json({ error: `Failed to create student: ${err.message}` });
  }
});

// POST /auth/createManager
router.post('/createManager', verifyToken, requireRole('admin'), async (req: AuthRequest, res: Response) => {
  const { email, name, managerId, messId } = req.body;
  if (!email || !name || !managerId || !messId) {
    return res.status(400).json({ error: 'Missing required fields.' });
  }
  try {
    const tempPassword = Math.random().toString(36).slice(-8) + 'A1!';
    const userRecord = await getAuth().createUser({ email, password: tempPassword, displayName: name });
    const uid = userRecord.uid;
    await getAuth().setCustomUserClaims(uid, { role: 'manager', managerId, messId, status: 'active' });
    const db = getFirestore();
    const batch = db.batch();
    batch.set(db.collection('users').doc(uid), { uid, email, name, role: 'manager', status: 'active', createdAt: new Date().toISOString() });
    batch.set(db.collection('managers').doc(managerId), { managerId, uid, name, email, messId, role: 'manager' });
    await batch.commit();
    await createAuditLog(req.user.uid, 'CREATE_MANAGER', managerId, 'managers', 'Admin created manager account');
    res.json({ uid, email, tempPassword });
  } catch (err: any) {
    res.status(500).json({ error: `Failed to create manager: ${err.message}` });
  }
});

// POST /auth/importStudentsCSV
router.post('/importStudentsCSV', verifyToken, requireRole('admin'), async (req: AuthRequest, res: Response) => {
  const { students } = req.body;
  if (!Array.isArray(students) || students.length === 0) {
    return res.status(400).json({ error: 'Students array is required.' });
  }
  const db = getFirestore();
  const results = [];
  for (const student of students) {
    try {
      const tempPassword = Math.random().toString(36).slice(-8) + 'A1!';
      const userRecord = await getAuth().createUser({ email: student.email, password: tempPassword, displayName: student.name });
      const uid = userRecord.uid;
      await getAuth().setCustomUserClaims(uid, { role: 'student', studentId: student.studentId, messId: student.messId, hostelId: student.hostelId, status: 'active' });
      const batch = db.batch();
      batch.set(db.collection('users').doc(uid), { uid, email: student.email, name: student.name, role: 'student', status: 'active', createdAt: new Date().toISOString() });
      batch.set(db.collection('students').doc(student.studentId), { studentId: student.studentId, uid, name: student.name, email: student.email, messId: student.messId, hostelId: student.hostelId, roomNumber: student.roomNumber, role: 'student' });
      await batch.commit();
      results.push({ studentId: student.studentId, success: true });
    } catch (err: any) {
      results.push({ studentId: student.studentId, success: false, error: err.message });
    }
  }
  await createAuditLog(req.user.uid, 'IMPORT_STUDENTS', 'batch', 'students', `Imported ${students.length} students`);
  res.json({ results });
});

// POST /auth/syncRoster - 1-Click Sync of 112 students to Firestore
router.post('/syncRoster', async (req, res) => {
  const { students } = req.body;
  const list = Array.isArray(students) && students.length > 0 ? students : [];
  if (list.length === 0) {
    return res.status(400).json({ error: 'No students provided' });
  }

  const db = getFirestore();
  let count = 0;
  let batch = db.batch();

  try {
    for (const s of list) {
      const ref = db.collection('students').doc(s.registrationNo || s.studentId);
      batch.set(ref, {
        studentId: s.registrationNo || s.studentId,
        slNo: s.slNo,
        name: s.name,
        rollNo: s.rollNo,
        mobile: s.mobile,
        email: s.email || null,
        branch: s.branch,
        registrationNo: s.registrationNo || s.studentId,
        semester: s.semester || '6th',
        cgpa: s.cgpa || 8.0,
        hostel: s.hostel || 'Hostel Number 4',
        roomNo: s.roomNo,
        messId: 'mess_h4',
        status: 'active',
        role: 'student',
        updatedAt: new Date().toISOString()
      }, { merge: true });

      count++;
      if (count % 40 === 0) {
        await batch.commit();
        batch = db.batch();
      }
    }

    if (count % 40 !== 0) {
      await batch.commit();
    }

    res.json({ success: true, count });
  } catch (err: any) {
    res.status(500).json({ error: err.message, count });
  }
});

// POST /auth/setUserStatus
router.post('/setUserStatus', verifyToken, requireRole('admin'), async (req: AuthRequest, res: Response) => {
  const { uid, status } = req.body;
  if (!uid || !['active', 'suspended'].includes(status)) {
    return res.status(400).json({ error: 'Valid UID and status required.' });
  }
  try {
    const userRecord = await getAuth().getUser(uid);
    const currentClaims = userRecord.customClaims || {};
    await getAuth().setCustomUserClaims(uid, { ...currentClaims, status });
    if (status === 'suspended') await getAuth().revokeRefreshTokens(uid);
    await getFirestore().collection('users').doc(uid).update({ status });
    await createAuditLog(req.user.uid, 'SET_USER_STATUS', uid, 'users', `Status set to ${status}`);
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ error: `Failed to update status: ${err.message}` });
  }
});

export default router;
