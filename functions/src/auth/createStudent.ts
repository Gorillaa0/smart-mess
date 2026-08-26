import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { createAuditLog } from '../audit/createAuditLog';
import { UserDocument, StudentProfile } from '../types';

export const createStudent = onCall(async (request) => {
  if (!request.auth || request.auth.token.role !== 'admin') {
    throw new HttpsError('permission-denied', 'Only admins can create students.');
  }

  const { email, name, studentId, messId, hostelId, roomNumber } = request.data;

  if (!email || !name || !studentId || !messId || !hostelId) {
    throw new HttpsError('invalid-argument', 'Missing required fields.');
  }

  try {
    const tempPassword = Math.random().toString(36).slice(-8) + 'A1!';
    const userRecord = await getAuth().createUser({
      email,
      password: tempPassword,
      displayName: name,
    });

    const uid = userRecord.uid;
    const claims = { role: 'student', studentId, messId, hostelId, status: 'active' };
    await getAuth().setCustomUserClaims(uid, claims);

    const db = getFirestore();
    const batch = db.batch();

    const userRef = db.collection('users').doc(uid);
    const userDoc: UserDocument = {
      uid,
      email,
      name,
      role: 'student',
      status: 'active',
      createdAt: new Date().toISOString(),
    };
    batch.set(userRef, userDoc);

    const studentRef = db.collection('students').doc(studentId);
    const studentProfile: StudentProfile = {
      studentId,
      uid,
      name,
      email,
      messId,
      hostelId,
      roomNumber,
      role: 'student',
    };
    batch.set(studentRef, studentProfile);

    await batch.commit();

    await createAuditLog(request.auth.uid, 'CREATE_STUDENT', studentId, 'students', 'Admin created student account');

    return { uid, email, tempPassword };
  } catch (error: any) {
    throw new HttpsError('internal', `Failed to create student: ${error.message}`);
  }
});
