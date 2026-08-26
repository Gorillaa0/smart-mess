import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { sendNotification } from './sendNotification';
import { Complaint } from '../types';

export const onComplaintUpdated = onDocumentUpdated('complaints/{complaintId}', async (event) => {
  if (!event.data) return;
  const before = event.data.before.data() as Complaint;
  const after = event.data.after.data() as Complaint;

  if (before.status === 'pending' && after.status === 'resolved') {
    const db = getFirestore();
    
    // Get student's UID
    const studentDoc = await db.collection('students').doc(after.studentId).get();
    if (!studentDoc.exists) return;
    
    const uid = studentDoc.data()!.uid;

    await sendNotification(
      uid,
      'Complaint Resolved',
      `Your complaint regarding ${after.category} has been marked as resolved.`,
      'update'
    );
  }
});
