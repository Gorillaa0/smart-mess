import { collection, query, getDocs } from 'firebase/firestore';
import { db } from '../lib/firebase';

export const billingService = {
  getBills: async () => {
    const q = collection(db, 'bills');
    const snapshot = await getDocs(q);
    return snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
  },
  triggerBilling: async () => {
    // In reality, this would call a Cloud Function
    return { success: true, message: 'Billing triggered successfully' };
  }
};
