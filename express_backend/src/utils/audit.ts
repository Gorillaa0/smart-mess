import { getFirestore } from 'firebase-admin/firestore';

export const createAuditLog = async (
  actorUid: string,
  action: string,
  targetId: string,
  targetCollection: string,
  reason?: string,
  metadata?: any
) => {
  const db = getFirestore();
  const logRef = db.collection('auditLogs').doc();
  await logRef.set({
    logId: logRef.id,
    actorUid,
    action,
    targetId,
    targetCollection,
    timestamp: new Date().toISOString(),
    reason: reason || null,
    metadata: metadata || null,
  });
};
