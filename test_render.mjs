import https from 'https';

function getUrl(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { timeout: 15000 }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve({ status: res.statusCode, data }));
    }).on('error', reject);
  });
}

async function testRender() {
  console.log("Testing Render backend endpoints...");
  try {
    const res1 = await getUrl('https://smart-mess-backend-yh6q.onrender.com/notifications');
    console.log("Render /notifications:", res1.status, res1.data);
  } catch (err) {
    console.error("Render /notifications error:", err.message);
  }

  try {
    const res2 = await getUrl('https://smart-mess-backend-yh6q.onrender.com/events');
    console.log("Render /events:", res2.status, res2.data);
  } catch (err) {
    console.error("Render /events error:", err.message);
  }
}

testRender();
