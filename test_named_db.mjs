const apiKey = "AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E";
const projectId = "smart-mess-sih";

async function testDatabaseDefault() {
  console.log("=== Testing REST API on databases/default ===");
  try {
    const res = await fetch(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/default/documents/hostels?key=${apiKey}`);
    const data = await res.json();
    console.log("Status:", res.status);
    console.log("Hostels:", JSON.stringify(data, null, 2));
  } catch (err) {
    console.error("Error:", err);
  }
}

testDatabaseDefault();
