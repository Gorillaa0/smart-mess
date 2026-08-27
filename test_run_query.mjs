const apiKey = "AIzaSyA99YZY3BKk7J-LZCKQaEPLnVkjC_mXE2E";
const projectId = "smart-mess-sih";

async function testRunQuery() {
  console.log("=== Testing runQuery on databases/default ===");
  try {
    const res = await fetch(`https://firestore.googleapis.com/v1/projects/${projectId}/databases/default/documents:runQuery?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        structuredQuery: {
          from: [{ collectionId: 'notifications' }]
        }
      })
    });
    console.log("Status:", res.status);
    const data = await res.json();
    console.log("Results count:", data.length);
    data.forEach((item, idx) => {
      if (item.document) {
        console.log(`[${idx}]`, item.document.name, item.document.fields);
      }
    });
  } catch (err) {
    console.error("runQuery error:", err);
  }
}

testRunQuery();
