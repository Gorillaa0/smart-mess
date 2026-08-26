import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { createAuditLog } from '../audit/createAuditLog';
import { UserDocument, StudentProfile } from '../types';

export const importStudentsCSV = onCall(async (request) => {
  if (!request.auth || request.auth.token.role !== 'admin') {
    throw new HttpsError('permission-denied', 'Only admins can import students.');
  }

  const { students } = request.data; 

  if (!Array.isArray(students) || students.length === 0) {
    throw new HttpsError('invalid-argument', 'Students array is required.');
  }

  const db = getFirestore();
  const results = [];

  for (const student of students) {
    try {
      const tempPassword = Math.random().toString(36).slice(-8) + 'A1!';
      const userRecord = await getAuth().createUser({
        email: student.email,
        password: tempPassword,
        displayName: student.name,
      });

      const uid = userRecord.uid;
      const claims = { role: 'student', studentId: student.studentId, messId: student.messId, hostelId: student.hostelId, status: 'active' };
      await getAuth().setCustomUserClaims(uid, claims);

      const batch = db.batch();

      const userRef = db.collection('users').doc(uid);
      const userDoc: UserDocument = {
        uid,
        email: student.email,
        name: student.name,
        role: 'student',
        status: 'active',
        createdAt: new Date().toISOString(),
      };
      batch.set(userRef, userDoc);

      const studentRef = db.collection('students').doc(student.studentId);
      const studentProfile: StudentProfile = {
        studentId: student.studentId,
        uid,
        name: student.name,
        email: student.email,
        messId: student.messId,
        hostelId: student.hostelId,
        roomNumber: student.roomNumber,
        role: 'student',
      };
      batch.set(studentRef, studentProfile);

      await batch.commit();
      
      results.push({ studentId: student.studentId, success: true });
    } catch (error: any) {
      results.push({ studentId: student.studentId, success: false, error: error.message });
    }
  }

  await createAuditLog(request.auth.uid, 'IMPORT_STUDENTS', 'batch', 'students', `Imported ${students.length} students`);

  return { results };
});
