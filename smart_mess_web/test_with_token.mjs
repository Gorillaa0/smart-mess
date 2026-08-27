import { initializeApp } from 'firebase/app';
import { getAuth, signInWithEmailAndPassword } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E",
  authDomain: "smart-mess-sih.firebaseapp.com",
  projectId: "smart-mess-sih",
  storageBucket: "smart-mess-sih.firebasestorage.app",
  messagingSenderId: "190175767796",
  appId: "1:190175767796:web:9d8da3ec9adbe2fd9882a1"
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

async function testWithToken() {
  console.log("Signing in to get valid user ID token...");
  try {
    const userCredential = await signInWithEmailAndPassword(auth, "priyanshugandhi64@gmail.com", "TempPass@123456");
    const idToken = await userCredential.user.getIdToken();
    console.log("Got ID token successfully!");

    console.log("Fetching /notifications from databases/default with Authorization token...");
    const res = await fetch(`https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/notifications`, {
      headers: {
        'Authorization': `Bearer ${idToken}`
      }
    });

    console.log("HTTP Status with Auth Token:", res.status);
    const data = await res.json();
    console.log("Notifications Data:", JSON.stringify(data, null, 2));

  } catch (err) {
    console.error("Error during auth or fetch:", err);
  }
}

testWithToken();
