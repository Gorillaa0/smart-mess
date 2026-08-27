import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import * as admin from 'firebase-admin';
import { readFileSync, existsSync } from 'fs';
import { startCronJobs } from './cron/jobs';

import authRoutes from './routes/auth';
import mealsRoutes from './routes/meals';
import messoffRoutes from './routes/messoff';
import predictionRoutes from './routes/prediction';
import wastageRoutes from './routes/wastage';
import billingRoutes from './routes/billing';
import notificationsRoutes from './routes/notifications';
import eventsRoutes from './routes/events';

// Initialize Firebase Admin SDK
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './service_account.json';
if (existsSync(serviceAccountPath)) {
  try {
    const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    console.log('[FIREBASE] Initialized with service_account.json');
  } catch (e: any) {
    admin.initializeApp({ projectId: 'smart-mess-sih' });
    console.log('[FIREBASE] Initialized with projectId fallback');
  }
} else {
  admin.initializeApp({ projectId: 'smart-mess-sih' });
  console.log('[FIREBASE] Initialized with default credentials');
}

const app = express();
const PORT = parseInt(process.env.PORT || '3001');

const rawOrigins = process.env.ALLOWED_ORIGINS || '*';
if (rawOrigins === '*') {
  app.use(cors());
} else {
  const allowedOrigins = rawOrigins.split(',').map(o => o.trim());
  app.use(cors({ origin: allowedOrigins, credentials: true }));
}
app.use(express.json({ limit: '10mb' }));

app.get('/health', (req, res) => res.json({ status: 'ok', timestamp: new Date().toISOString(), service: 'Smart Mess Backend API' }));

app.use('/auth', authRoutes);
app.use('/meals', mealsRoutes);
app.use('/messoff', messoffRoutes);
app.use('/prediction', predictionRoutes);
app.use('/wastage', wastageRoutes);
app.use('/billing', billingRoutes);
app.use('/notifications', notificationsRoutes);
app.use('/events', eventsRoutes);

app.use((req, res) => res.status(404).json({ error: `Route ${req.method} ${req.path} not found` }));

app.listen(PORT, () => {
  console.log(`🚀 Smart Mess Backend API running on port ${PORT}`);
  startCronJobs();
});

export default app;
