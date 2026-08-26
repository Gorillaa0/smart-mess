import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore } from 'firebase-admin/firestore';
import { createAuditLog } from '../audit/createAuditLog';
import { QRSession } from '../types';
import * as crypto from 'crypto';

export const generateQR = onCall(async (request) => {
  if (!request.auth || !['admin', 'manager'].includes(request.auth.token.role)) {
    throw new HttpsError('permission-denied', 'Only managers/admins can generate QRs.');
  }

  const { mealId, messId } = request.data;

  if (request.auth.token.role === 'manager' && request.auth.token.messId !== messId) {
    throw new HttpsError('permission-denied', 'Cannot generate QR for another mess.');
  }

  try {
    const db = getFirestore();
    
    const existingSessions = await db.collection('qrSessions')
      .where('mealId', '==', mealId)
      .where('expiresAt', '>', new Date().toISOString())
      .get();
      
    const batch = db.batch();
    existingSessions.docs.forEach(doc => {
      batch.update(doc.ref, { expiresAt: new Date().toISOString() });
    });

    const sessionRef = db.collection('qrSessions').doc();
    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 1000).toISOString(); 

    const session: QRSession = {
      sessionId: sessionRef.id,
      token,
      mealId,
      messId,
      expiresAt,
      createdBy: request.auth.uid,
      createdAt: new Date().toISOString()
    };

    batch.set(sessionRef, session);
    await batch.commit();

    await createAuditLog(request.auth.uid, 'GENERATE_QR', session.sessionId, 'qrSessions');

    return { token, expiresAt, sessionId: session.sessionId };
  } catch (error: any) {
    throw new HttpsError('internal', `Failed to generate QR: ${error.message}`);
  }
});
