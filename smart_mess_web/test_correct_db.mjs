import { initializeApp } from 'firebase/app';
import { getFirestore, collection, getDocs, addDoc } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E",
  authDomain: "smart-mess-sih.firebaseapp.com",
  projectId: "smart-mess-sih",
  storageBucket: "smart-mess-sih.firebasestorage.app",
  messagingSenderId: "190175767796",
  appId: "1:190175767796:web:9d8da3ec9adbe2fd9882a1"
};

const app = initializeApp(firebaseConfig);
// Do NOT pass 'default' - use getFirestore(app)
const db = getFirestore(app);

async function check() {
  console.log("Connecting with getFirestore(app)...");
  try {
    const snap = await getDocs(collection(db, 'hostels'));
    console.log(`SUCCESS! Found ${snap.size} hostels:`);
    snap.forEach(d => console.log(d.id, "=>", d.data()));

    // Test writing a notification
    const testNotif = {
      title: "🔥 Real-Time Broadcast Connection Established",
      body: "Mess Manager announcements are now live and streaming directly to student dashboards.",
      category: "alert",
      createdAt: new Date().toISOString(),
      sender: "Hostel H4 Mess Manager"
    };
    const notifRef = await addDoc(collection(db, 'notifications'), testNotif);
    console.log("SUCCESS! Created notification with ID:", notifRef.id);

    // Test writing an event
    const testEvent = {
      title: "Mid-Semester Examinations (6th Semester)",
      type: "Exam",
      startDate: "2026-09-02",
      endDate: "2026-09-08",
      impactLevel: "Medium",
      expectedMessOffs: "35% Higher Attendance in Mess (Night Snacks Active)",
      description: "6th Semester university theory examinations across CSE, Civil, ECE, EE, and ME.",
      advisoryForStudents: "Extended dining hours will be active. Students staying in hostel need not apply for mess-off.",
      createdAt: new Date().toISOString()
    };
    const eventRef = await addDoc(collection(db, 'events'), testEvent);
    console.log("SUCCESS! Created event with ID:", eventRef.id);

  } catch (err) {
    console.error("ERROR:", err);
  }
}

check();
