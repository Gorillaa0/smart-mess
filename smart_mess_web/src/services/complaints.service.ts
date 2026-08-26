import { collection, query, where, getDocs, updateDoc, doc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import type { Complaint } from '../types';

export const complaintsService = {
  getComplaints: async (messId: string) => {
    const q = query(collection(db, 'complaints'), where('messId', '==', messId));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(d => ({ id: d.id, ...d.data() } as Complaint));
  },
  updateComplaint: async (id: string, update: Partial<Complaint>) => {
    await updateDoc(doc(db, 'complaints', id), update);
  }
};
