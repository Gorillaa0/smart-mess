import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';

export const seedData = onCall(async (request) => {
  if (!request.auth || request.auth.token.role !== 'admin') {
    throw new HttpsError('permission-denied', 'Only admins can seed data.');
  }

  const db = getFirestore();
  
  try {
    const batch = db.batch();

    const hostels = ['H1', 'H2', 'H3'];
    for (const id of hostels) {
      batch.set(db.collection('hostels').doc(id), { hostelId: id, name: `Hostel ${id}` });
    }

    const messes = ['M1', 'M2', 'M3', 'M4', 'M5'];
    for (const id of messes) {
      batch.set(db.collection('messes').doc(id), { messId: id, name: `Mess ${id}`, capacity: 500 });
    }

    for (let i = 1; i <= 200; i++) {
      const studentId = `S${i.toString().padStart(4, '0')}`;
      const uid = `test-uid-${studentId}`;
      const messId = messes[i % 5];
      const hostelId = hostels[i % 3];
      
      batch.set(db.collection('users').doc(uid), {
        uid, email: `student${i}@example.com`, name: `Student ${i}`, role: 'student', status: 'active', createdAt: new Date().toISOString()
      });

      batch.set(db.collection('students').doc(studentId), {
        studentId, uid, name: `Student ${i}`, email: `student${i}@example.com`, messId, hostelId, role: 'student'
      });
    }

    await batch.commit();

    return { success: true, message: 'Seeded messes, hostels, and 200 students successfully.' };
  } catch (error: any) {
    throw new HttpsError('internal', `Failed to seed data: ${error.message}`);
  }
});
