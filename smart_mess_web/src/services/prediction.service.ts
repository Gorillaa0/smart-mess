import { collection, query, where, getDocs, updateDoc, doc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import type { Prediction } from '../types';

export const predictionService = {
  getPrediction: async (mealId: string) => {
    const q = query(collection(db, 'predictions'), where('mealId', '==', mealId));
    const snapshot = await getDocs(q);
    if (snapshot.empty) return null;
    return { id: snapshot.docs[0].id, ...snapshot.docs[0].data() } as Prediction;
  },
  approvePrediction: async (id: string, approvedCount: number) => {
    await updateDoc(doc(db, 'predictions', id), { approvedCount });
  }
};
