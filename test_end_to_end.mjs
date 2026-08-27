const notifId = `notif_user_test_${Date.now()}`;
const title = "⚠️ Urgent Mess Announcement: Power Maintenance";
const message = "Mess Hall will operate on generator backup from 07:00 PM to 09:00 PM.";
const category = "alert";
const target = "All Residents (112 Students)";

async function simulateManagerSend() {
  console.log("Simulating Manager sending broadcast from Web Dashboard...");
  try {
    const res = await fetch(
      `https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/notifications/${notifId}?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E`,
      {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fields: {
            id: { stringValue: notifId },
            title: { stringValue: title },
            body: { stringValue: message },
            category: { stringValue: category },
            target: { stringValue: target },
            sender: { stringValue: 'Hostel H4 Mess Manager' },
            createdAt: { stringValue: new Date().toISOString() },
            read: { booleanValue: false },
            deliveredCount: { integerValue: '112' }
          }
        })
      }
    );
    console.log("Status:", res.status);
    const data = await res.json();
    console.log("Written doc name:", data.name);
  } catch (err) {
    console.error("Error:", err);
  }
}

async function simulateAdminEventPublish() {
  const eventId = `evt_user_test_${Date.now()}`;
  console.log("\nSimulating Admin publishing event from Web Dashboard...");
  try {
    const res = await fetch(
      `https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents/events/${eventId}?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E`,
      {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fields: {
            id: { stringValue: eventId },
            title: { stringValue: "Holi & Spring Break 2026" },
            type: { stringValue: "Holiday" },
            startDate: { stringValue: "2026-03-20" },
            endDate: { stringValue: "2026-03-25" },
            impactLevel: { stringValue: "High" },
            expectedMessOffs: { stringValue: "85% Students Travelling" },
            description: { stringValue: "Annual spring break holiday." },
            advisoryForStudents: { stringValue: "Please apply for mess-off before departure." },
            createdAt: { stringValue: new Date().toISOString() }
          }
        })
      }
    );
    console.log("Status:", res.status);
    const data = await res.json();
    console.log("Written event doc name:", data.name);
  } catch (err) {
    console.error("Error:", err);
  }
}

async function verifyStudentQueries() {
  console.log("\n=== Simulating Student App query for notifications ===");
  const notifRes = await fetch(
    'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        structuredQuery: {
          from: [{ collectionId: 'notifications' }]
        }
      })
    }
  );
  const notifs = await notifRes.json();
  console.log(`Student received ${notifs.length} notifications:`);
  notifs.forEach(item => {
    if (item.document) console.log("  -", item.document.fields.title.stringValue, "|", item.document.fields.body?.stringValue);
  });

  console.log("\n=== Simulating Student App query for events ===");
  const eventRes = await fetch(
    'https://firestore.googleapis.com/v1/projects/smart-mess-sih/databases/default/documents:runQuery?key=AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        structuredQuery: {
          from: [{ collectionId: 'events' }]
        }
      })
    }
  );
  const events = await eventRes.json();
  console.log(`Student received ${events.length} events:`);
  events.forEach(item => {
    if (item.document) console.log("  -", item.document.fields.title.stringValue, "|", item.document.fields.type?.stringValue);
  });
}

async function run() {
  await simulateManagerSend();
  await simulateAdminEventPublish();
  await verifyStudentQueries();
}

run();
