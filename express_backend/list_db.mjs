import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { readFileSync, existsSync } from 'fs';

const serviceAccountPath = './service_account.json';
if (existsSync(serviceAccountPath)) {
  const sa = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
  initializeApp({ credential: cert(sa), projectId: 'smart-mess-sih' });
} else {
  initializeApp({ projectId: 'smart-mess-sih' });
}

// In firebase-admin, to get named database 'default':
const db = getFirestore('default');

async function listAll() {
  console.log("=== Querying database 'default' with Admin SDK ===");
  try {
    const notifsSnap = await db.collection('notifications').get();
    console.log(`Found ${notifsSnap.size} notifications:`);
    notifsSnap.forEach(d => console.log(d.id, "=>", d.data()));

    const eventsSnap = await db.collection('events').get();
    console.log(`Found ${eventsSnap.size} events:`);
    eventsSnap.forEach(d => console.log(d.id, "=>", d.data()));
  } catch (err) {
    console.error("Admin query error:", err);
  }
}

listAll();
