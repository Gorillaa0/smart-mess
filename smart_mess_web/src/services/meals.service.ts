import { collection, query, where, getDocs, addDoc, updateDoc, doc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import type { Meal } from '../types';

export const mealsService = {
  getMealsByMess: async (messId: string) => {
    const q = query(collection(db, 'meals'), where('messId', '==', messId));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(d => ({ id: d.id, ...d.data() } as Meal));
  },
  createMeal: async (meal: Omit<Meal, 'id'>) => {
    const docRef = await addDoc(collection(db, 'meals'), meal);
    return { id: docRef.id, ...meal };
  },
  updateMeal: async (id: string, data: Partial<Meal>) => {
    await updateDoc(doc(db, 'meals', id), data);
  }
};
