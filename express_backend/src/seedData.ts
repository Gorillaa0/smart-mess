import * as admin from 'firebase-admin';
import { readFileSync, existsSync } from 'fs';
import { H4_STUDENTS_LIST } from './data/h4StudentsData';

const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './service_account.json';
if (existsSync(serviceAccountPath)) {
  try {
    const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  } catch {
    admin.initializeApp({ projectId: 'smart-mess-sih' });
  }
} else {
  admin.initializeApp({ projectId: 'smart-mess-sih' });
}

const db = admin.firestore();
const auth = admin.auth();

async function seed() {
  console.log(`Starting Firestore Cloud Seeding for ${H4_STUDENTS_LIST.length} students...`);

  // 1. Seed Hostel & Mess
  await db.collection('hostels').doc('hostel_h4').set({
    hostelId: 'hostel_h4',
    name: 'Hostel Number 4',
    capacity: 150,
    roomsCount: 75,
    wardenName: 'Dr. R. K. Sharma',
    wardenContact: '+91 9431200001'
  });

  await db.collection('messes').doc('mess_h4').set({
    messId: 'mess_h4',
    name: 'Hostel Number 4 Central Mess',
    hostelId: 'hostel_h4',
    managerId: 'manager_dhaneshwar',
    capacity: 150,
    activeDiners: 112
  });

  console.log('✅ Hostel & Mess documents created');

  // 2. Seed Manager
  await db.collection('managers').doc('manager_dhaneshwar').set({
    managerId: 'manager_dhaneshwar',
    uid: 'mgr_dhaneshwar_01',
    name: 'Dhaneshwar Yadav',
    email: '6200432942@smartmess.edu',
    mobile: '6200432942',
    messId: 'mess_h4',
    role: 'manager',
    status: 'active'
  });

  console.log('✅ Mess Manager profile created');

  // 3. Seed Students (in batches of 50)
  let batch = db.batch();
  let count = 0;
  let batchNum = 1;

  for (const s of H4_STUDENTS_LIST) {
    const studentRef = db.collection('students').doc(s.registrationNo);
    batch.set(studentRef, {
      studentId: s.registrationNo,
      slNo: s.slNo,
      name: s.name,
      rollNo: s.rollNo,
      mobile: s.mobile,
      email: s.email || null,
      branch: s.branch,
      registrationNo: s.registrationNo,
      semester: s.semester,
      cgpa: s.cgpa,
      hostel: s.hostel,
      roomNo: s.roomNo,
      messId: 'mess_h4',
      status: 'active',
      role: 'student',
      createdAt: new Date().toISOString()
    });

    count++;
    if (count % 40 === 0) {
      await batch.commit();
      console.log(`✅ Committed batch ${batchNum} (${count} students saved)...`);
      batch = db.batch();
      batchNum++;
    }
  }

  if (count % 40 !== 0) {
    await batch.commit();
    console.log(`✅ Committed final batch (${count} total students saved to Cloud Firestore)`);
  }

  console.log('🎉 Seeding successfully completed on Cloud Firestore!');
}

seed().catch(err => {
  console.log('Seeding note:', err.message);
});

