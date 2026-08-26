import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { createAuditLog } from '../audit/createAuditLog';

export const setUserStatus = onCall(async (request) => {
  if (!request.auth || request.auth.token.role !== 'admin') {
    throw new HttpsError('permission-denied', 'Only admins can change user status.');
  }

  const { uid, status } = request.data; 

  if (!uid || !['active', 'suspended'].includes(status)) {
    throw new HttpsError('invalid-argument', 'Valid UID and status required.');
  }

  try {
    const userRecord = await getAuth().getUser(uid);
    const currentClaims = userRecord.customClaims || {};
    
    await getAuth().setCustomUserClaims(uid, {
      ...currentClaims,
      status,
    });

    if (status === 'suspended') {
      await getAuth().revokeRefreshTokens(uid);
    }

    const db = getFirestore();
    await db.collection('users').doc(uid).update({ status });

    await createAuditLog(request.auth.uid, 'SET_USER_STATUS', uid, 'users', `Status set to ${status}`);

    return { success: true };
  } catch (error: any) {
    throw new HttpsError('internal', `Failed to update user status: ${error.message}`);
  }
});
