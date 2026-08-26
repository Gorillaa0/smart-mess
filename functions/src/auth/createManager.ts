import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { createAuditLog } from '../audit/createAuditLog';
import { UserDocument, ManagerProfile } from '../types';

export const createManager = onCall(async (request) => {
  if (!request.auth || request.auth.token.role !== 'admin') {
    throw new HttpsError('permission-denied', 'Only admins can create managers.');
  }

  const { email, name, managerId, messId } = request.data;

  if (!email || !name || !managerId || !messId) {
    throw new HttpsError('invalid-argument', 'Missing required fields.');
  }

  try {
    const tempPassword = Math.random().toString(36).slice(-8) + 'A1!';
    const userRecord = await getAuth().createUser({
      email,
      password: tempPassword,
      displayName: name,
    });

    const uid = userRecord.uid;
    const claims = { role: 'manager', managerId, messId, status: 'active' };
    await getAuth().setCustomUserClaims(uid, claims);

    const db = getFirestore();
    const batch = db.batch();

    const userRef = db.collection('users').doc(uid);
    const userDoc: UserDocument = {
      uid,
      email,
      name,
      role: 'manager',
      status: 'active',
      createdAt: new Date().toISOString(),
    };
    batch.set(userRef, userDoc);

    const managerRef = db.collection('managers').doc(managerId);
    const managerProfile: ManagerProfile = {
      managerId,
      uid,
      name,
      email,
      messId,
      role: 'manager',
    };
    batch.set(managerRef, managerProfile);

    await batch.commit();

    await createAuditLog(request.auth.uid, 'CREATE_MANAGER', managerId, 'managers', 'Admin created manager account');

    return { uid, email, tempPassword };
  } catch (error: any) {
    throw new HttpsError('internal', `Failed to create manager: ${error.message}`);
  }
});
