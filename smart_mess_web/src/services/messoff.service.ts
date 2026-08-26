import { collection, query, where, getDocs, updateDoc, doc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import type { MessOff } from '../types';

export const messoffService = {
  getMessOffsByMeal: async (mealId: string) => {
    const q = query(collection(db, 'messOffs'), where('mealId', '==', mealId));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(d => ({ id: d.id, ...d.data() } as MessOff));
  },
  updateStatus: async (id: string, status: MessOff['status']) => {
    await updateDoc(doc(db, 'messOffs', id), { status });
  }
};
