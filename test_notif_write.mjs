const apiKey = "AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E";
const projectId = "smart-mess-sih";

async function testNotifs() {
  console.log("=== Writing notification to databases/default/documents/notifications ===");
  const notifId = `notif_${Date.now()}`;
  const res = await fetch(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/default/documents/notifications/${notifId}?key=${apiKey}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      fields: {
        id: { stringValue: notifId },
        title: { stringValue: "⏰ Dinner Mess-Off Closes in 30 Minutes" },
        body: { stringValue: "Please apply on your mobile app before 05:00 PM." },
        category: { stringValue: "messoff" },
        sender: { stringValue: "Hostel H4 Mess Manager" },
        createdAt: { stringValue: new Date().toISOString() },
        read: { booleanValue: false },
        deliveredCount: { integerValue: "112" }
      }
    })
  });
  console.log("Write Status:", res.status);
  const data = await res.json();
  console.log("Response:", JSON.stringify(data, null, 2));

  console.log("\n=== Reading back from databases/default/documents/notifications ===");
  const readRes = await fetch(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/default/documents/notifications?key=${apiKey}`);
  console.log("Read Status:", readRes.status);
  const readData = await readRes.json();
  console.log("Read Data:", JSON.stringify(readData, null, 2));
}

testNotifs();
