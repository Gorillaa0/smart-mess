const apiKey = "AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E";
const projectId = "smart-mess-sih";

async function checkNotifications() {
  console.log("Fetching notifications from Firestore databases/default via REST...");
  try {
    const res = await fetch(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/default/documents/notifications?key=${apiKey}`);
    console.log("HTTP Status:", res.status);
    const data = await res.json();
    console.log("Response:", JSON.stringify(data, null, 2));
  } catch (e) {
    console.error("Error:", e);
  }
}

checkNotifications();
