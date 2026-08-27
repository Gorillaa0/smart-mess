import { initializeApp } from 'firebase/app';
import { getFirestore, collection, addDoc, getDocs, doc, setDoc } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E",
  authDomain: "smart-mess-sih.firebaseapp.com",
  projectId: "smart-mess-sih",
  storageBucket: "smart-mess-sih.firebasestorage.app",
  messagingSenderId: "190175767796",
  appId: "1:190175767796:web:9d8da3ec9adbe2fd9882a1"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function test() {
  console.log("Testing Firestore with config...");
  try {
    const testDoc = {
      title: "Test Broadcast from Node",
      body: "Testing real-time sync across devices",
      category: "alert",
      createdAt: new Date().toISOString(),
      sender: "Hostel H4 Mess Manager"
    };
    const ref = await addDoc(collection(db, 'notifications'), testDoc);
    console.log("SUCCESSFULLY WRITTEN! Doc ID:", ref.id);

    const snapshot = await getDocs(collection(db, 'notifications'));
    console.log(`Read back ${snapshot.size} documents:`);
    snapshot.forEach(d => console.log(d.id, "=>", d.data()));
  } catch (err) {
    console.error("FIRESTORE ERROR:", err);
  }
}

test();
